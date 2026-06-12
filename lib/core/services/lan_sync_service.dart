import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../shared/models/sync_manifest.dart';
import 'db_sync_service.dart';

final Provider<LanSyncService> lanSyncServiceProvider =
    Provider<LanSyncService>((Ref ref) {
  final LanSyncService service =
      LanSyncService(sync: ref.watch(dbSyncServiceProvider));
  // The screen stops the service on dispose; this covers container
  // teardown (mobile in-place restart) so sockets never outlive the scope.
  ref.onDispose(service.stop);
  return service;
});

/// A device discovered on the local network.
class LanPeer {
  /// Creates a [LanPeer].
  const LanPeer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
  });

  /// Random per-session instance id; filters out our own announcements.
  final String id;

  /// Human-readable device name.
  final String name;

  /// Peer address.
  final InternetAddress address;

  /// Peer HTTP port.
  final int port;
}

/// Direct device-to-device transfer over the local network.
///
/// Pull model on top of the snapshot engine: while the sync screen is
/// open, the service announces itself over UDP broadcast and serves the
/// manifest and a fresh snapshot over a loopback-grade HTTP server; the
/// receiving side picks a peer, downloads the snapshot and swaps it in
/// via [DbSyncService]. Every snapshot download must be approved on the
/// serving device.
class LanSyncService {
  /// Creates a [LanSyncService].
  LanSyncService({required DbSyncService sync}) : _sync = sync;

  /// UDP port used for discovery announcements.
  static const int discoveryPort = 47813;

  static const String _announceApp = 'xerabora-sync';
  static const Duration _announceEvery = Duration(seconds: 1);
  static const Duration _peerTtl = Duration(seconds: 5);

  static final Logger _log = Logger('LanSyncService');

  final DbSyncService _sync;

  static final Random _random = Random();

  final String _instanceId =
      _random.nextInt(0x7fffffff).toRadixString(36) +
          _random.nextInt(0x7fffffff).toRadixString(36);

  HttpServer? _httpServer;
  RawDatagramSocket? _udp;
  Timer? _announceTimer;
  Timer? _pruneTimer;
  // Bumped by stop(); a start() that awaited past a stop() call tears
  // its freshly bound resources right back down instead of leaking them.
  int _generation = 0;
  String _deviceName = '';
  Future<bool> Function(String requesterName)? _onSnapshotRequest;
  bool _approvalPending = false;

  final Map<String, (LanPeer, DateTime)> _peersById =
      <String, (LanPeer, DateTime)>{};
  final Map<String, DateTime> _lastPongById = <String, DateTime>{};
  List<int> _announcement = <int>[];

  /// Live list of currently visible peers.
  final ValueNotifier<List<LanPeer>> peers =
      ValueNotifier<List<LanPeer>>(<LanPeer>[]);

  /// Whether the service is announcing and serving.
  bool get isRunning => _httpServer != null;

  /// Port the HTTP server is bound to, or `null` when stopped.
  int? get port => _httpServer?.port;

  /// Starts the HTTP server and discovery.
  ///
  /// [onSnapshotRequest] is asked before any snapshot leaves this device;
  /// it should show a confirmation to the user.
  Future<void> start({
    required String deviceName,
    required Future<bool> Function(String requesterName) onSnapshotRequest,
  }) async {
    if (isRunning) return;
    _deviceName = deviceName;
    _onSnapshotRequest = onSnapshotRequest;
    final int generation = _generation;

    final HttpServer server =
        await HttpServer.bind(InternetAddress.anyIPv4, 0);
    if (generation != _generation) {
      await server.close(force: true);
      return;
    }
    _httpServer = server;
    server.listen(_handleRequest, onError: (Object e) {
      _log.warning('HTTP server error', e);
    });
    _log.info('LAN sync serving on port ${server.port}');

    await _startDiscovery(server.port);
  }

  /// Stops the server and discovery; the peer list empties.
  Future<void> stop() async {
    _generation++;
    _announceTimer?.cancel();
    _announceTimer = null;
    _pruneTimer?.cancel();
    _pruneTimer = null;
    _udp?.close();
    _udp = null;
    await _httpServer?.close(force: true);
    _httpServer = null;
    _peersById.clear();
    _lastPongById.clear();
    _announcement = <int>[];
    peers.value = <LanPeer>[];
  }

  Future<void> _startDiscovery(int servicePort) async {
    final int generation = _generation;
    try {
      final RawDatagramSocket udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
      );
      if (generation != _generation) {
        udp.close();
        return;
      }
      _udp = udp;
      udp.broadcastEnabled = true;
      udp.listen((RawSocketEvent event) {
        if (event != RawSocketEvent.read) return;
        final Datagram? datagram = udp.receive();
        if (datagram == null) return;
        _onAnnouncement(datagram);
      });

      _announcement = utf8.encode(jsonEncode(<String, Object>{
        'app': _announceApp,
        'id': _instanceId,
        'name': _deviceName,
        'port': servicePort,
      }));
      _announceTimer = Timer.periodic(_announceEvery, (_) {
        try {
          udp.send(
            _announcement,
            InternetAddress('255.255.255.255'),
            discoveryPort,
          );
        } on SocketException {
          // No network right now; keep announcing, Wi-Fi may come back.
        }
      });
      _pruneTimer = Timer.periodic(_peerTtl, (_) => _prunePeers());
    } on SocketException catch (e) {
      // Discovery is best-effort: the HTTP server still works if the
      // discovery port is taken (e.g. another instance on this machine).
      _log.warning('Discovery unavailable', e);
    }
  }

  void _onAnnouncement(Datagram datagram) {
    final LanPeer? peer = parseAnnouncement(datagram.data, datagram.address);
    if (peer == null || peer.id == _instanceId) return;
    _peersById[peer.id] = (peer, DateTime.now());
    _publishPeers();
    _pongTo(peer);
  }

  /// Replies with a unicast announcement so the sender learns about us
  /// even when broadcasts do not reach it: Windows may broadcast through
  /// the wrong interface (virtual adapters) and many Android firmwares
  /// filter incoming broadcasts. Rate-limited per peer to stop the two
  /// sides from ping-ponging on every packet.
  void _pongTo(LanPeer peer) {
    final RawDatagramSocket? udp = _udp;
    if (udp == null || _announcement.isEmpty) return;

    final DateTime now = DateTime.now();
    final DateTime? last = _lastPongById[peer.id];
    if (last != null && now.difference(last) < _announceEvery) return;
    _lastPongById[peer.id] = now;

    try {
      udp.send(_announcement, peer.address, discoveryPort);
    } on SocketException {
      // Peer may have just left the network.
    }
  }

  void _prunePeers() {
    final DateTime cutoff = DateTime.now().subtract(_peerTtl);
    _peersById.removeWhere(
      (String _, (LanPeer, DateTime) entry) => entry.$2.isBefore(cutoff),
    );
    _publishPeers();
  }

  void _publishPeers() {
    final List<LanPeer> list = _peersById.values
        .map(((LanPeer, DateTime) entry) => entry.$1)
        .toList()
      ..sort((LanPeer a, LanPeer b) => a.name.compareTo(b.name));
    // Announcements repeat every second; skip identical lists so the
    // ValueNotifier does not rebuild the device list for nothing.
    if (_samePeers(peers.value, list)) return;
    peers.value = list;
  }

  static bool _samePeers(List<LanPeer> a, List<LanPeer> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].name != b[i].name ||
          a[i].port != b[i].port ||
          a[i].address.address != b[i].address.address) {
        return false;
      }
    }
    return true;
  }

  /// Parses a discovery datagram; `null` for foreign or malformed packets.
  @visibleForTesting
  static LanPeer? parseAnnouncement(List<int> data, InternetAddress address) {
    try {
      final Object? decoded = jsonDecode(utf8.decode(data));
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['app'] != _announceApp) return null;
      final String? id = decoded['id'] as String?;
      final String? name = decoded['name'] as String?;
      final int? port = decoded['port'] as int?;
      if (id == null || name == null || port == null) return null;
      if (port <= 0 || port > 65535) return null;
      return LanPeer(id: id, name: name, address: address, port: port);
    } on FormatException {
      return null;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final InternetAddress? remote =
          request.connectionInfo?.remoteAddress;
      if (remote == null || !_isLocalNetwork(remote)) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }

      switch (request.uri.path) {
        case '/manifest':
          await _serveManifest(request);
        case '/snapshot':
          await _serveSnapshot(request);
        default:
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
      }
    } on Exception catch (e) {
      _log.warning('Request handling failed', e);
      try {
        // The error text travels to the requesting device's log — the
        // serving side (often a phone) rarely has a console attached.
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(e.toString());
        await request.response.close();
      } on Exception {
        // Connection already gone.
      }
    }
  }

  Future<void> _serveManifest(HttpRequest request) async {
    final SyncManifest manifest = await _sync.buildManifest();
    request.response.headers.contentType = ContentType.json;
    request.response.write(manifest.toJsonString());
    await request.response.close();
  }

  Future<void> _serveSnapshot(HttpRequest request) async {
    // Trust model: the requester name is a plain string with no
    // authentication behind it — the security boundary is the human
    // pressing Allow on this device plus the private-subnet guard. Any
    // automated flow built on top must add real peer authentication.
    final String requester =
        request.uri.queryParameters['name'] ?? '?';

    // One approval dialog at a time on the serving side.
    if (_approvalPending) {
      request.response.statusCode = HttpStatus.tooManyRequests;
      await request.response.close();
      return;
    }

    final Future<bool> Function(String)? ask = _onSnapshotRequest;
    bool approved = false;
    if (ask != null) {
      _approvalPending = true;
      try {
        approved = await ask(requester);
      } finally {
        _approvalPending = false;
      }
    }
    if (!approved) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    final Directory tmpDir =
        await Directory.systemTemp.createTemp('xerabora_lan_out');
    try {
      await _sync.sendSnapshot(tmpDir.path);
      final File snapshot =
          File(p.join(tmpDir.path, DbSyncService.snapshotFileName));
      request.response.headers.contentType = ContentType.binary;
      request.response.contentLength = snapshot.lengthSync();
      await request.response.addStream(snapshot.openRead());
      await request.response.close();
      _log.info('Snapshot served to $requester');
    } finally {
      if (tmpDir.existsSync()) {
        await tmpDir.delete(recursive: true);
      }
    }
  }

  /// Loopback plus RFC1918/link-local ranges; everything else is refused.
  static bool _isLocalNetwork(InternetAddress address) {
    if (address.isLoopback || address.isLinkLocal) return true;
    if (address.type != InternetAddressType.IPv4) return false;
    final List<int> b = address.rawAddress;
    if (b[0] == 10) return true;
    if (b[0] == 172 && b[1] >= 16 && b[1] <= 31) return true;
    if (b[0] == 192 && b[1] == 168) return true;
    return false;
  }

  /// Fetches the peer's manifest, or `null` when it does not answer.
  Future<SyncManifest?> fetchManifest(LanPeer peer) async {
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final HttpClientRequest request = await client.getUrl(
        Uri.http('${peer.address.address}:${peer.port}', '/manifest'),
      );
      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode != HttpStatus.ok) return null;
      final String body = await response.transform(utf8.decoder).join();
      return SyncManifest.fromJsonString(body);
    } on Exception catch (e) {
      _log.warning('Manifest fetch from ${peer.name} failed', e);
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Thrown when the serving device refuses the snapshot request.
  static const String deniedMessage = 'denied';

  /// Downloads the peer's snapshot into [targetDir]; the timeout is long
  /// because the serving side waits for a human to approve the request.
  ///
  /// Throws [StateError] with [deniedMessage] on refusal.
  Future<void> downloadSnapshot(
    LanPeer peer,
    String targetDir, {
    required String requesterName,
  }) async {
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final HttpClientRequest request = await client.getUrl(
        Uri.http(
          '${peer.address.address}:${peer.port}',
          '/snapshot',
          <String, String>{'name': requesterName},
        ),
      );
      final HttpClientResponse response =
          await request.close().timeout(const Duration(minutes: 3));
      if (response.statusCode == HttpStatus.forbidden ||
          response.statusCode == HttpStatus.tooManyRequests) {
        throw StateError(deniedMessage);
      }
      if (response.statusCode != HttpStatus.ok) {
        final String body = await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 5), onTimeout: () => '');
        throw StateError('HTTP ${response.statusCode}: $body');
      }

      final File target =
          File(p.join(targetDir, DbSyncService.snapshotFileName));
      await Directory(targetDir).create(recursive: true);
      final IOSink sink = target.openWrite();
      try {
        await sink.addStream(response);
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
  }
}

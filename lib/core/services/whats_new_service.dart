import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/providers/settings_provider.dart';

/// Release notes for one version.
class WhatsNewContent {
  const WhatsNewContent({required this.version, required this.body});

  final String version;

  /// Mini-markdown body. EN only.
  final String body;
}

/// Decides whether the "What's new" dialog is due after an app update.
class WhatsNewService {
  /// [currentVersionOverride] replaces `PackageInfo.fromPlatform()` and
  /// [notesLoader] replaces the bundled-asset read in tests.
  WhatsNewService({
    required SharedPreferences prefs,
    String? currentVersionOverride,
    Future<String> Function()? notesLoader,
  })  : _prefs = prefs,
        _currentVersionOverride = currentVersionOverride,
        _notesLoader = notesLoader;

  final SharedPreferences _prefs;
  final String? _currentVersionOverride;
  final Future<String> Function()? _notesLoader;

  static const String _seenVersionKey = 'changelog_seen_version';

  /// First launch (no stored version) counts as seen — a fresh install gets
  /// the welcome wizard, not release notes. No notes section = seen silently.
  Future<WhatsNewContent?> pendingWhatsNew() async {
    final String currentVersion = await _resolveVersion();
    final String? seenVersion = _prefs.getString(_seenVersionKey);

    if (seenVersion == null || seenVersion == currentVersion) {
      if (seenVersion == null) {
        await markSeen(currentVersion);
      }
      return null;
    }

    final String notes;
    try {
      notes = await (_notesLoader?.call() ??
          rootBundle.loadString('assets/whats_new.md'));
    } on Exception {
      return null;
    }

    final String? section = extractSection(notes, currentVersion);
    if (section == null) {
      await markSeen(currentVersion);
      return null;
    }

    return WhatsNewContent(
      version: currentVersion,
      body: formatForDisplay(section),
    );
  }

  /// Remembers [version] so its notes are not shown again.
  Future<void> markSeen(String version) async {
    await _prefs.setString(_seenVersionKey, version);
  }

  /// Debug preview: the newest (first) section in the notes file, ignoring
  /// the running version and the seen marker. Never marks anything seen.
  Future<WhatsNewContent?> previewLatest() async {
    final String notes;
    try {
      notes = await (_notesLoader?.call() ??
          rootBundle.loadString('assets/whats_new.md'));
    } on Exception {
      return null;
    }

    final RegExpMatch? heading =
        RegExp(r'^# (\S+)', multiLine: true).firstMatch(notes);
    if (heading == null) return null;
    final String version = heading.group(1)!;
    final String? section = extractSection(notes, version);
    if (section == null) return null;

    return WhatsNewContent(
      version: version,
      body: formatForDisplay(section),
    );
  }

  Future<String> _resolveVersion() async {
    if (_currentVersionOverride != null) return _currentVersionOverride;
    final PackageInfo info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Cuts the `# <version>` section out of the notes file.
  static String? extractSection(String notes, String version) {
    final List<String> lines = notes.split('\n');
    final int start = lines.indexWhere(
      (String line) => line.trimRight() == '# $version',
    );
    if (start == -1) return null;

    int end = lines.length;
    for (int i = start + 1; i < lines.length; i++) {
      if (lines[i].startsWith('# ')) {
        end = i;
        break;
      }
    }
    return lines.sublist(start + 1, end).join('\n').trim();
  }

  /// Adapts hand-written markdown to MiniMarkdownText's subset: list
  /// markers become `•`, sub-headings become bold lines.
  static String formatForDisplay(String section) {
    final StringBuffer out = StringBuffer();
    for (final String line in section.split('\n')) {
      final String trimmed = line.trimLeft();
      if (trimmed.startsWith('- ')) {
        out.writeln('• ${trimmed.substring(2)}');
      } else if (trimmed.startsWith('#')) {
        out.writeln('**${trimmed.replaceFirst(RegExp(r'^#+\s*'), '')}**');
      } else {
        out.writeln(line.trimRight());
      }
    }
    return out.toString().trim();
  }
}

final Provider<WhatsNewService> whatsNewServiceProvider =
    Provider<WhatsNewService>((Ref ref) {
  return WhatsNewService(prefs: ref.watch(sharedPreferencesProvider));
});

/// Resolves once per app run, on first read.
final FutureProvider<WhatsNewContent?> whatsNewProvider =
    FutureProvider<WhatsNewContent?>((Ref ref) {
  return ref.read(whatsNewServiceProvider).pendingWhatsNew();
});

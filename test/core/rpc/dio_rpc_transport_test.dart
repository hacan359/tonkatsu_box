import 'dart:convert';
import 'dart:typed_data';

import 'package:core/rpc/protocol.dart';
import 'package:core/rpc/rpc_transport.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/rpc/dio_rpc_transport.dart';

/// Answers from a canned envelope, so the tests drive the wire format rather
/// than a socket.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.status = 200});

  final Object? body;
  final int status;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _UnreachableAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'refused',
    );
  }

  @override
  void close({bool force = false}) {}
}

DioRpcTransport _transportWith(HttpClientAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://server'));
  dio.httpClientAdapter = adapter;
  return DioRpcTransport(dio: dio);
}

Matcher _rpcErrorOfKind(String kind) => throwsA(
      isA<RpcException>().having((RpcException e) => e.kind, 'kind', kind),
    );

void main() {
  group('DioRpcTransport', () {
    group('call', () {
      test('should send the envelope the protocol describes', () async {
        final _StubAdapter adapter =
            _StubAdapter(<String, Object?>{'ok': true, 'result': null});

        await _transportWith(adapter).call(
          'GameDao',
          'deleteGame',
          <String, Object?>{'id': '42'},
        );

        expect(adapter.lastOptions?.path, '/rpc');
        expect(adapter.lastOptions?.method, 'POST');
        expect(adapter.lastOptions?.data, <String, Object?>{
          'protocol': kProtocolVersion,
          'dao': 'GameDao',
          'method': 'deleteGame',
          'args': <String, Object?>{'id': '42'},
        });
      });

      test('should return the result of a successful call', () async {
        final DioRpcTransport transport = _transportWith(
          _StubAdapter(<String, Object?>{
            'ok': true,
            'result': <Object?>['1', '2'],
          }),
        );

        expect(
          await transport.call('GameDao', 'getAllGames', <String, Object?>{}),
          <Object?>['1', '2'],
        );
      });

      test('should pass a null result through', () async {
        final DioRpcTransport transport = _transportWith(
          _StubAdapter(<String, Object?>{'ok': true, 'result': null}),
        );

        expect(
          await transport.call('GameDao', 'getGame', <String, Object?>{}),
          isNull,
        );
      });

      test('should rethrow a DAO failure with its kind and message', () async {
        final DioRpcTransport transport = _transportWith(
          _StubAdapter(<String, Object?>{
            'ok': false,
            'error': <String, Object?>{
              'kind': 'database',
              'message': 'UNIQUE constraint failed',
            },
          }),
        );

        await expectLater(
          transport.call('GameDao', 'insertGame', <String, Object?>{}),
          throwsA(
            isA<RpcException>()
                .having((RpcException e) => e.kind, 'kind', 'database')
                .having(
                  (RpcException e) => e.message,
                  'message',
                  contains('UNIQUE'),
                ),
          ),
        );
      });

      test('should read the error payload behind a 4xx status', () async {
        final DioRpcTransport transport = _transportWith(
          _StubAdapter(
            <String, Object?>{
              'ok': false,
              'error': <String, Object?>{
                'kind': 'protocol',
                'message': 'reload the page',
              },
            },
            status: 400,
          ),
        );

        await expectLater(
          transport.call('GameDao', 'getAllGames', <String, Object?>{}),
          _rpcErrorOfKind('protocol'),
        );
      });

      test('should report an unreachable server as a transport failure',
          () async {
        await expectLater(
          _transportWith(_UnreachableAdapter())
              .call('GameDao', 'getAllGames', <String, Object?>{}),
          _rpcErrorOfKind('transport'),
        );
      });

      test('should reject a body that is not an envelope', () async {
        await expectLater(
          _transportWith(_StubAdapter('not an object'))
              .call('GameDao', 'getAllGames', <String, Object?>{}),
          _rpcErrorOfKind('protocol'),
        );
      });

      test('should name the call when the failure carries no message',
          () async {
        final DioRpcTransport transport = _transportWith(
          _StubAdapter(<String, Object?>{'ok': false}),
        );

        await expectLater(
          transport.call('GameDao', 'getAllGames', <String, Object?>{}),
          throwsA(
            isA<RpcException>()
                .having((RpcException e) => e.kind, 'kind', 'internal')
                .having(
                  (RpcException e) => e.message,
                  'message',
                  contains('GameDao.getAllGames'),
                ),
          ),
        );
      });
    });
  });
}

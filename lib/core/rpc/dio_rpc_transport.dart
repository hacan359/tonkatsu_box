import 'package:core/rpc/protocol.dart';
import 'package:core/rpc/rpc_codec.dart';
import 'package:core/rpc/rpc_transport.dart';
import 'package:dio/dio.dart';

import '../api/api_dio.dart';
import '../selfhost/server_origin.dart';

/// Carries the generated stubs to `/rpc`. One DAO method per round trip, so a
/// transaction stays whole on the server side.
class DioRpcTransport implements RpcTransport {
  DioRpcTransport({Dio? dio, String? baseUrl})
      : _dio = dio ??
            createApiDio(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 60),
              baseUrl: baseUrl ?? serverBaseUrl(),
            );

  final Dio _dio;

  @override
  Future<Object?> call(
    String dao,
    String method,
    Map<String, Object?> args,
  ) async {
    try {
      final Response<Object?> response = await _dio.post<Object?>(
        '/rpc',
        data: <String, Object?>{
          'protocol': kProtocolVersion,
          'dao': dao,
          'method': method,
          'args': args,
        },
      );
      return _unwrap(dao, method, response.data);
    } on DioException catch (e) {
      // A protocol error answers 4xx *with* an error payload, and Dio raises
      // on the status before the caller ever sees the body.
      final Object? data = e.response?.data;
      if (data != null) return _unwrap(dao, method, data);
      throw RpcException(
        'transport',
        '$dao.$method: ${e.message ?? e.type.name}',
      );
    }
  }

  Object? _unwrap(String dao, String method, Object? body) {
    final Map<String, Object?> envelope;
    try {
      envelope = asObject(body);
    } on RpcCodecException catch (e) {
      throw RpcException('protocol', '$dao.$method: ${e.message}');
    }

    if (envelope['ok'] == true) return envelope['result'];

    final Object? error = envelope['error'];
    final Map<String, Object?> fields =
        error is Map<String, Object?> ? error : const <String, Object?>{};
    final Object? kind = fields['kind'];
    final Object? message = fields['message'];
    throw RpcException(
      kind is String ? kind : 'internal',
      message is String ? message : '$dao.$method failed without a message',
    );
  }
}

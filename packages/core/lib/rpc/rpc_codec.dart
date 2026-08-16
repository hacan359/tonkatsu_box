import 'dart:convert';
import 'dart:typed_data';

/// Thrown when a payload does not match what the signature promised.
class RpcCodecException implements Exception {
  const RpcCodecException(this.message);

  final String message;

  @override
  String toString() => 'RpcCodecException: $message';
}

/// Every `int` crosses the wire as a string: dart2js compiles `int` to a
/// double, and the `fnv1a64` ids in real databases are already 63-bit.
String encodeInt(int value) => value.toString();

int decodeInt(Object? value) {
  if (value is String) {
    final int? parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  // A bare number means the peer skipped the contract; accept it only when it
  // is still exact, so the mistake surfaces instead of corrupting an id.
  if (value is int) return value;
  throw RpcCodecException('Expected an int-as-string, got ${value.runtimeType}');
}

String? encodeIntOrNull(int? value) => value?.toString();

int? decodeIntOrNull(Object? value) => value == null ? null : decodeInt(value);

/// UTC ISO-8601. Local offsets would make the same instant read differently on
/// a server and a browser in another timezone.
String encodeDateTime(DateTime value) => value.toUtc().toIso8601String();

DateTime decodeDateTime(Object? value) {
  if (value is! String) {
    throw RpcCodecException('Expected an ISO-8601 string, got ${value.runtimeType}');
  }
  return DateTime.parse(value).toUtc();
}

String? encodeDateTimeOrNull(DateTime? value) =>
    value == null ? null : encodeDateTime(value);

DateTime? decodeDateTimeOrNull(Object? value) =>
    value == null ? null : decodeDateTime(value);

/// Enums travel by `name`, never by index — reordering a Dart enum must not
/// change what an already-stored value means.
String encodeEnum(Enum value) => value.name;

T decodeEnum<T extends Enum>(Object? value, List<T> values) {
  if (value is! String) {
    throw RpcCodecException('Expected an enum name, got ${value.runtimeType}');
  }
  for (final T candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw RpcCodecException('Unknown enum value "$value"');
}

T? decodeEnumOrNull<T extends Enum>(Object? value, List<T> values) =>
    value == null ? null : decodeEnum<T>(value, values);

/// Lets the generator stay ignorant of Dart's flow analysis: without this it
/// had to guess whether a null guard would promote the expression.
Object? encodeNullable<T extends Object>(T? value, Object? Function(T) encode) =>
    value == null ? null : encode(value);

T? decodeNullable<T extends Object>(
  Object? value,
  T Function(Object?) decode,
) =>
    value == null ? null : decode(value);

const String _intTag = r'$i';
const String _bytesTag = r'$b';

/// For a value whose static type is `dynamic`. Ints are tagged, not just
/// stringified — the far side could not tell one from a genuine `String`.
Object? encodeDynamic(Object? value) {
  if (value == null || value is String || value is double || value is bool) {
    return value;
  }
  if (value is int) return <String, String>{_intTag: value.toString()};
  if (value is Uint8List) {
    return <String, String>{_bytesTag: base64Encode(value)};
  }
  if (value is List) return value.map(encodeDynamic).toList();
  if (value is Map) {
    return value.map((Object? k, Object? v) =>
        MapEntry<String, Object?>(k.toString(), encodeDynamic(v)));
  }
  throw RpcCodecException('No wire rule for ${value.runtimeType}');
}

Object? decodeDynamic(Object? value) {
  if (value is Map) {
    final Object? tagged = value[_intTag];
    if (tagged is String && value.length == 1) return int.parse(tagged);
    final Object? bytes = value[_bytesTag];
    if (bytes is String && value.length == 1) return base64Decode(bytes);
    return value.map((Object? k, Object? v) =>
        MapEntry<String, Object?>(k.toString(), decodeDynamic(v)));
  }
  if (value is List) return value.map(decodeDynamic).toList();
  return value;
}

/// A database row: keys are column names, values are whatever SQLite stored.
Map<String, Object?> encodeRow(Map<String, Object?> row) {
  return row.map((String k, Object? v) =>
      MapEntry<String, Object?>(k, encodeDynamic(v)));
}

Map<String, Object?> decodeRow(Object? value) {
  if (value is! Map) {
    throw RpcCodecException('Expected a row object, got ${value.runtimeType}');
  }
  return value.map((Object? k, Object? v) =>
      MapEntry<String, Object?>(k.toString(), decodeDynamic(v)));
}

/// Casts a decoded JSON array, failing loudly rather than at a later `as`.
List<Object?> asList(Object? value) {
  if (value is! List) {
    throw RpcCodecException('Expected a list, got ${value.runtimeType}');
  }
  return value;
}

/// Generated decoders call this once per field, so the common case — what
/// `jsonDecode` already produced — must not copy the map.
Map<String, Object?> asObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is! Map) {
    throw RpcCodecException('Expected an object, got ${value.runtimeType}');
  }
  return value.map((Object? k, Object? v) =>
      MapEntry<String, Object?>(k.toString(), v));
}

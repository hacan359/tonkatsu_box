import 'dart:convert';
import 'dart:typed_data';

import 'package:core/models/item_status.dart';
import 'package:core/rpc/rpc_codec.dart';
import 'package:test/test.dart';

/// Mirrors what the wire actually does to a payload.
Object? throughJson(Object? value) => jsonDecode(jsonEncode(value));

void main() {
  group('int', () {
    test('should survive a value above 2^53 as a string', () {
      const int stableId = 8747386780253552735;

      expect(decodeInt(throughJson(encodeInt(stableId))), stableId);
    });

    test('should accept a bare number the peer sent off-contract', () {
      expect(decodeInt(42), 42);
    });

    test('should reject a value that is neither', () {
      expect(() => decodeInt(<String>['1']), throwsA(isA<RpcCodecException>()));
    });

    test('should pass null through the nullable pair', () {
      expect(encodeIntOrNull(null), isNull);
      expect(decodeIntOrNull(null), isNull);
      expect(decodeIntOrNull(encodeIntOrNull(7)), 7);
    });
  });

  group('DateTime', () {
    test('should normalise to UTC in both directions', () {
      final DateTime local = DateTime(2026, 8, 9, 12, 30);

      final DateTime back = decodeDateTime(throughJson(encodeDateTime(local)));

      expect(back.isUtc, isTrue);
      expect(back.millisecondsSinceEpoch, local.millisecondsSinceEpoch);
    });

    test('should reject a non-string', () {
      expect(() => decodeDateTime(123), throwsA(isA<RpcCodecException>()));
    });
  });

  group('enum', () {
    test('should round-trip by name', () {
      expect(
        decodeEnum<ItemStatus>(
          encodeEnum(ItemStatus.inProgress),
          ItemStatus.values,
        ),
        ItemStatus.inProgress,
      );
    });

    test('should reject a name no longer in the enum', () {
      expect(
        () => decodeEnum<ItemStatus>('abandoned', ItemStatus.values),
        throwsA(isA<RpcCodecException>()),
      );
    });

    test('should pass null through the nullable pair', () {
      expect(decodeEnumOrNull<ItemStatus>(null, ItemStatus.values), isNull);
    });
  });

  group('dynamic', () {
    test('should tag an int so it is not confused with a string', () {
      final Object? wire = throughJson(encodeDynamic(9007199254740993));

      expect(wire, isA<Map<String, Object?>>());
      expect(decodeDynamic(wire), 9007199254740993);
    });

    test('should leave a genuine string a string', () {
      expect(decodeDynamic(throughJson(encodeDynamic('123'))), '123');
    });

    test('should round-trip bytes through base64', () {
      final Uint8List bytes = Uint8List.fromList(<int>[0, 127, 255]);

      final Object? back = decodeDynamic(throughJson(encodeDynamic(bytes)));

      expect(back, isA<List<int>>());
      expect(back as List<int>, <int>[0, 127, 255]);
    });

    test('should recurse into lists and maps', () {
      final Object? wire = throughJson(encodeDynamic(<String, Object?>{
        'id': 8747386780253552735,
        'tags': <Object?>['a', 2, null],
      }));

      final Map<String, Object?> back = decodeRow(wire);

      expect(back['id'], 8747386780253552735);
      expect(back['tags'], <Object?>['a', 2, null]);
    });

    test('should refuse a type with no wire rule', () {
      expect(
        () => encodeDynamic(Duration.zero),
        throwsA(isA<RpcCodecException>()),
      );
    });

    test('should keep a two-key map that merely looks tagged', () {
      final Object? wire = throughJson(
        encodeDynamic(<String, Object?>{r'$i': 'x', 'other': 1}),
      );

      expect(decodeDynamic(wire), isA<Map<String, Object?>>());
      expect((decodeDynamic(wire)! as Map<String, Object?>)['other'], 1);
    });
  });

  group('shape guards', () {
    test('should reject a list where an object was promised', () {
      expect(() => asObject(<int>[1]), throwsA(isA<RpcCodecException>()));
    });

    test('should reject an object where a list was promised', () {
      expect(
        () => asList(<String, Object?>{}),
        throwsA(isA<RpcCodecException>()),
      );
    });

    test('should not copy a map that already has the right shape', () {
      final Map<String, Object?> original = <String, Object?>{'a': 1};

      expect(identical(asObject(original), original), isTrue);
    });
  });
}

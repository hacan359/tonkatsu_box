import 'package:core/database/query_chunk.dart';
import 'package:test/test.dart';

void main() {
  group('queryByIdsInChunks', () {
    test('returns empty without invoking the query for an empty list',
        () async {
      int calls = 0;
      final List<int> result = await queryByIdsInChunks<int>(
        <int>[],
        (List<int> chunk) async {
          calls++;
          return chunk;
        },
      );
      expect(result, isEmpty);
      expect(calls, 0);
    });

    test('runs a single chunk when ids fit the limit', () async {
      int calls = 0;
      final List<int> ids = List<int>.generate(50, (int i) => i);
      final List<int> result = await queryByIdsInChunks<int>(
        ids,
        (List<int> chunk) async {
          calls++;
          return chunk;
        },
        chunkSize: 100,
      );
      expect(calls, 1);
      expect(result, ids);
    });

    test('splits into multiple chunks past the limit, covering every id',
        () async {
      final List<List<int>> seenChunks = <List<int>>[];
      final List<int> ids = List<int>.generate(2500, (int i) => i);
      final List<int> result = await queryByIdsInChunks<int>(
        ids,
        (List<int> chunk) async {
          seenChunks.add(chunk);
          return chunk;
        },
        chunkSize: 900,
      );
      // 2500 / 900 → 3 chunks (900 + 900 + 700).
      expect(seenChunks.length, 3);
      expect(seenChunks.map((List<int> c) => c.length), <int>[900, 900, 700]);
      // No chunk exceeds the limit, and the flattened result equals the input.
      expect(seenChunks.every((List<int> c) => c.length <= 900), isTrue);
      expect(result, ids);
    });

    test('default chunk size stays within the SQLite floor (999)', () {
      expect(kInClauseChunkSize, lessThan(999));
    });
  });
}

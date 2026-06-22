import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/game_time_to_beat.dart';

void main() {
  group('GameTimeToBeat', () {
    group('fromJson', () {
      test('parses all fields', () {
        final GameTimeToBeat ttb = GameTimeToBeat.fromJson(<String, dynamic>{
          'game_id': 1942,
          'hastily': 134552,
          'normally': 254778,
          'completely': 581483,
          'count': 41,
        });

        expect(ttb.hastily, 134552);
        expect(ttb.normally, 254778);
        expect(ttb.completely, 581483);
        expect(ttb.count, 41);
      });

      test('leaves missing time fields null and count defaults to 0', () {
        final GameTimeToBeat ttb = GameTimeToBeat.fromJson(<String, dynamic>{
          'game_id': 293842,
        });

        expect(ttb.hastily, isNull);
        expect(ttb.normally, isNull);
        expect(ttb.completely, isNull);
        expect(ttb.count, 0);
      });
    });

    group('primarySeconds', () {
      test('prefers normally', () {
        const GameTimeToBeat ttb = GameTimeToBeat(
          hastily: 3600,
          normally: 7200,
          completely: 10800,
        );

        expect(ttb.primarySeconds, 7200);
      });

      test('falls back to hastily when normally is null', () {
        const GameTimeToBeat ttb =
            GameTimeToBeat(hastily: 3600, completely: 10800);

        expect(ttb.primarySeconds, 3600);
      });

      test('falls back to completely when normally and hastily are null', () {
        const GameTimeToBeat ttb = GameTimeToBeat(completely: 10800);

        expect(ttb.primarySeconds, 10800);
      });

      test('is null when no times are present', () {
        const GameTimeToBeat ttb = GameTimeToBeat();

        expect(ttb.primarySeconds, isNull);
      });
    });

    group('primaryHours', () {
      test('rounds seconds to nearest hour', () {
        const GameTimeToBeat ttb = GameTimeToBeat(normally: 254778);

        expect(ttb.primaryHours, 71);
      });

      test('clamps sub-hour times up to 1', () {
        const GameTimeToBeat ttb = GameTimeToBeat(completely: 100);

        expect(ttb.primaryHours, 1);
      });

      test('is null when there is no time data', () {
        const GameTimeToBeat ttb = GameTimeToBeat();

        expect(ttb.primaryHours, isNull);
      });
    });
  });
}

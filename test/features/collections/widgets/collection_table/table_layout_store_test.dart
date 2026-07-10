import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_table/table_layout_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const TableColumnLayout layout = TableColumnLayout(
    order: <String>['name', 'rating'],
    widths: <String, double>{'name': 200, 'rating': 80},
    hidden: <String>{'rating'},
  );

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('TableLayoutStore', () {
    test('should round-trip a saved layout when reloaded', () async {
      await TableLayoutStore.save('p1', 1, layout);
      final TableColumnLayout? loaded = await TableLayoutStore.load('p1', 1);

      expect(loaded, isNotNull);
      expect(loaded!.order, layout.order);
      expect(loaded.widths, layout.widths);
      expect(loaded.hidden, layout.hidden);
    });

    test('should isolate layouts across profiles sharing a collection id',
        () async {
      await TableLayoutStore.save('p1', 1, layout);

      expect(await TableLayoutStore.load('p2', 1), isNull);
    });

    test('should return null when nothing was saved', () async {
      expect(await TableLayoutStore.load('p1', 42), isNull);
    });

    test('should return null when stored json is not an object', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'collection_table_layout_p1_1': '[1,2,3]',
      });

      expect(await TableLayoutStore.load('p1', 1), isNull);
    });

    test('should return null when stored json is malformed', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'collection_table_layout_p1_1': '{not json',
      });

      expect(await TableLayoutStore.load('p1', 1), isNull);
    });
  });
}

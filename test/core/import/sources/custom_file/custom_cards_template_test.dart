import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/import/sources/custom_file/custom_card_entry.dart';
import 'package:tonkatsu_box/core/import/sources/custom_file/custom_cards_parser.dart';
import 'package:tonkatsu_box/core/import/sources/custom_file/custom_cards_template.dart';

void main() {
  group('CustomCardsTemplate', () {
    test('CSV template is exactly the full header row', () {
      expect(
        CustomCardsTemplate.csv(),
        '${CustomCardFields.ordered.join(',')}\n',
      );
    });

    test('CSV template mentions every schema field once', () {
      final List<String> header =
          CustomCardsTemplate.csv().trim().split(',');
      expect(header.toSet(), CustomCardFields.ordered.toSet());
      expect(header.length, CustomCardFields.ordered.length);
    });

    test('JSON template round-trips through the parser without issues', () {
      final List<CustomCardRow> rows =
          const CustomCardsParser().parseJson(CustomCardsTemplate.json());

      expect(rows, isNotEmpty);
      for (final CustomCardRow row in rows) {
        expect(row.isValid, isTrue,
            reason: row.issues
                .map((CustomCardIssue i) => '${i.code} ${i.field}')
                .join(', '));
      }
    });

    test('JSON template examples cover every schema field', () {
      final String json = CustomCardsTemplate.json();
      for (final String field in CustomCardFields.ordered) {
        expect(json.contains('"$field"'), isTrue, reason: field);
      }
    });
  });
}

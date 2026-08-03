import 'package:core/utils/html_text.dart';
import 'package:test/test.dart';

void main() {
  group('stripHtmlText', () {
    test('returns null when input is null', () {
      expect(stripHtmlText(null), isNull);
    });

    test('removes HTML tags', () {
      expect(stripHtmlText('<p>Hello <b>world</b></p>'), 'Hello world');
    });

    test('decodes common entities', () {
      expect(
        stripHtmlText('Tom &amp; Jerry &lt;3 &quot;quoted&quot; it&#39;s'),
        'Tom & Jerry <3 "quoted" it\'s',
      );
    });

    test('collapses &nbsp; to a space and trims', () {
      expect(stripHtmlText('  &nbsp;text&nbsp; '), 'text');
    });

    test('returns null when nothing readable remains', () {
      expect(stripHtmlText('<br/>'), isNull);
      expect(stripHtmlText('   '), isNull);
    });
  });
}

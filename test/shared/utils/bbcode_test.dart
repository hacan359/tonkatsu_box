import 'package:flutter_test/flutter_test.dart';
import 'package:core/utils/bbcode.dart';

void main() {
  group('stripBbCodes', () {
    test('returns empty input unchanged', () {
      expect(stripBbCodes(''), '');
    });

    test('removes simple formatting tags, keeps inner text', () {
      expect(stripBbCodes('[b]Bold[/b] and [i]italic[/i]'), 'Bold and italic');
    });

    test('keeps the label of a [url=…] link', () {
      expect(
        stripBbCodes('See [url=https://x.ru]the site[/url] now'),
        'See the site now',
      );
    });

    test('keeps the inner text of a [USER=…] tag', () {
      expect(stripBbCodes('by [USER=79]Nog[/USER]'), 'by Nog');
    });

    test('strips unknown / unbalanced bb-codes gracefully', () {
      expect(stripBbCodes('[spoiler]secret'), 'secret');
    });

    test('strips HTML / LINK tags', () {
      expect(
        stripBbCodes('A <a href="http://x">link</a> here'),
        'A link here',
      );
    });

    test('decodes common HTML entities', () {
      expect(
        stripBbCodes('Tom &amp; Jerry &laquo;quoted&raquo; &mdash; end'),
        'Tom & Jerry «quoted» — end',
      );
    });

    test('normalises CRLF and collapses blank-line runs', () {
      expect(stripBbCodes('a\r\n\r\n\r\n\r\nb'), 'a\n\nb');
    });

    test('trims surrounding whitespace', () {
      expect(stripBbCodes('  [b]x[/b]  '), 'x');
    });
  });
}

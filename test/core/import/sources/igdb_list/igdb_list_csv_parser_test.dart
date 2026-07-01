import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/import/sources/igdb_list/igdb_list_csv_parser.dart';

void main() {
  const IgdbListCsvParser parser = IgdbListCsvParser();

  const String header =
      'id,game,url,rating,category,release_date,platforms,genres,'
      'themes,companies,description';

  group('IgdbListCsvParser', () {
    test('parses id and name from a plain row', () {
      final List<IgdbListEntry> entries = parser.parseString(
        '$header\n'
        '111130,Apsulov: End of Gods,https://igdb.com/g/2dqy,7.7,Main Game,'
        '[],[],[],[],[],',
      );

      expect(entries, hasLength(1));
      expect(entries.single.id, 111130);
      expect(entries.single.name, 'Apsulov: End of Gods');
    });

    test('honours quoted fields holding JSON arrays with commas', () {
      final List<IgdbListEntry> entries = parser.parseString(
        '$header\n'
        '98,Need for Speed: Most Wanted,url,8.4,Main Game,'
        '"[""Nov 15, 2005 (NA)"", ""Nov 22, 2005 (NA)""]",'
        '"[""PC (Microsoft Windows)"", ""Xbox 360""]",'
        '"[""Racing""]","[""Open world""]","[""EA""]",',
      );

      expect(entries, hasLength(1));
      expect(entries.single.id, 98);
      expect(entries.single.name, 'Need for Speed: Most Wanted');
    });

    test('handles doubled quotes as a literal quote in the name', () {
      final List<IgdbListEntry> entries = parser.parseString(
        '$header\n'
        '5,"Marvel""s Spider-Man",url,9,Main Game,[],[],[],[],[],',
      );

      expect(entries.single.name, 'Marvel"s Spider-Man');
    });

    test('addresses columns by header name, not position', () {
      final List<IgdbListEntry> entries = parser.parseString(
        'game,id\n'
        'Portal,7',
      );

      expect(entries.single.id, 7);
      expect(entries.single.name, 'Portal');
    });

    test('skips rows with a non-numeric id', () {
      final List<IgdbListEntry> entries = parser.parseString(
        '$header\n'
        'not-a-number,Bad Row,url,1,Main Game,[],[],[],[],[],\n'
        '42,Good Row,url,1,Main Game,[],[],[],[],[],',
      );

      expect(entries, hasLength(1));
      expect(entries.single.id, 42);
    });

    test('falls back to a synthetic name when the title is blank', () {
      final List<IgdbListEntry> entries = parser.parseString(
        'id,game\n'
        '77,',
      );

      expect(entries.single.name, 'Game #77');
    });

    test('tolerates CRLF line endings and a trailing newline', () {
      final List<IgdbListEntry> entries = parser.parseString(
        'id,game\r\n1,One\r\n2,Two\r\n',
      );

      expect(entries.map((IgdbListEntry e) => e.id), <int>[1, 2]);
    });

    test('strips a UTF-8 BOM before the header', () {
      final Uint8List bytes = Uint8List.fromList(<int>[
        0xEF, 0xBB, 0xBF, // BOM
        ...utf8.encode('id,game\n9,Nine'),
      ]);

      final List<IgdbListEntry> entries = parser.parseBytes(bytes);

      expect(entries.single.id, 9);
      expect(entries.single.name, 'Nine');
    });

    test('throws when the id column is missing', () {
      expect(
        () => parser.parseString('game,url\nPortal,x'),
        throwsA(isA<IgdbListParseException>()),
      );
    });

    test('throws on an empty file', () {
      expect(
        () => parser.parseString(''),
        throwsA(isA<IgdbListParseException>()),
      );
    });
  });
}

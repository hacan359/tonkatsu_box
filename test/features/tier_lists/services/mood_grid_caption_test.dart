import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/features/tier_lists/services/mood_grid_caption.dart';
import 'package:tonkatsu_box/features/tier_lists/widgets/mood_grid_cell_media.dart';

MoodGridCellMedia _media({
  String? title,
  int? year,
  String? genre,
  double? rating,
}) {
  return MoodGridCellMedia(
    title: title,
    coverUrl: null,
    imageType: ImageType.gameCover,
    placeholderIcon: Icons.image,
    year: year,
    genre: genre,
    rating: rating,
  );
}

void main() {
  group('renderRowCaption', () {
    test('substitutes name', () {
      final MoodGridCellMedia m = _media(title: 'Elden Ring');
      expect(renderRowCaption('{{name}}', m), 'Elden Ring');
    });

    test('substitutes year', () {
      final MoodGridCellMedia m = _media(title: 'Elden Ring', year: 2022);
      expect(renderRowCaption('{{name}} ({{year}})', m), 'Elden Ring (2022)');
    });

    test('substitutes genre and rating', () {
      final MoodGridCellMedia m = _media(
        title: 'Bloodborne',
        genre: 'Action, Soulslike',
        rating: 8.6,
      );
      expect(
        renderRowCaption('{{name}} — {{genre}} — {{rating}}', m),
        'Bloodborne — Action, Soulslike — 8.6',
      );
    });

    test('missing values render as empty and gaps collapse', () {
      final MoodGridCellMedia m = _media(title: 'Mystery');
      expect(
        renderRowCaption('{{name}} {{year}} ({{genre}})', m),
        'Mystery ()',
      );
    });

    test('empty template returns empty string', () {
      final MoodGridCellMedia m = _media(title: 'X');
      expect(renderRowCaption('', m), '');
    });

    test('completely empty media renders empty', () {
      expect(
        renderRowCaption('{{name}} {{year}}', MoodGridCellMedia.empty),
        '',
      );
    });

    test('rating is formatted with one decimal', () {
      final MoodGridCellMedia m = _media(title: 'X', rating: 9.0);
      expect(renderRowCaption('{{rating}}', m), '9.0');
    });

    test('kMoodGridCaptionTokens lists each supported token once', () {
      expect(
        kMoodGridCaptionTokens,
        <String>['name', 'year', 'genre', 'rating'],
      );
    });
  });
}

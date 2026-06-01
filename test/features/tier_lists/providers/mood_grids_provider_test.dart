import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/database/dao/mood_grid_dao.dart';
import 'package:tonkatsu_box/features/tier_lists/providers/mood_grids_provider.dart';

void main() {
  group('aboutMeTonkatsuBoxCells', () {
    test('returns 5 cells matching the documented preset', () {
      final List<String?> labels = aboutMeTonkatsuBoxCells()
          .map((MoodGridCellSpec spec) => spec.label)
          .toList();

      expect(labels, <String>[
        'Favorite Game',
        'Favorite Movie',
        'Favorite TV Show',
        'Favorite Anime',
        'Favorite Manga',
      ]);
    });
  });

  test('kDefaultMoodGridTitle is "About Me: Tonkatsu Box"', () {
    expect(kDefaultMoodGridTitle, 'About Me: Tonkatsu Box');
  });
}

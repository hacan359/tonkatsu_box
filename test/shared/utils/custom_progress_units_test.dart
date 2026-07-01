import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations_en.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/utils/custom_progress_units.dart';

void main() {
  final SEn l = SEn();

  group('CustomProgressUnits.fineLabel', () {
    test('reads as episodes for screen-based types', () {
      for (final MediaType type in <MediaType>[
        MediaType.tvShow,
        MediaType.animation,
        MediaType.anime,
      ]) {
        expect(CustomProgressUnits.fineLabel(type, l), l.customUnitEpisodes);
      }
    });

    test('reads as chapters for manga and pages for books', () {
      expect(
        CustomProgressUnits.fineLabel(MediaType.manga, l),
        l.customUnitChapters,
      );
      expect(
        CustomProgressUnits.fineLabel(MediaType.book, l),
        l.customUnitPages,
      );
    });

    test('falls back to parts for types without a natural unit', () {
      expect(
        CustomProgressUnits.fineLabel(MediaType.game, l),
        l.customUnitParts,
      );
    });
  });

  group('CustomProgressUnits.groupLabel', () {
    test('is seasons for series, volumes for manga', () {
      expect(
        CustomProgressUnits.groupLabel(MediaType.tvShow, l),
        l.customUnitSeasons,
      );
      expect(
        CustomProgressUnits.groupLabel(MediaType.animation, l),
        l.customUnitSeasons,
      );
      expect(
        CustomProgressUnits.groupLabel(MediaType.manga, l),
        l.customUnitVolumes,
      );
    });

    test('is null for types without a coarse axis', () {
      expect(CustomProgressUnits.groupLabel(MediaType.game, l), isNull);
      expect(CustomProgressUnits.groupLabel(MediaType.book, l), isNull);
      expect(CustomProgressUnits.groupLabel(MediaType.anime, l), isNull);
    });
  });

  group('CustomProgressUnits.hasGroupAxis', () {
    test('matches the types that expose a group label', () {
      expect(CustomProgressUnits.hasGroupAxis(MediaType.tvShow), isTrue);
      expect(CustomProgressUnits.hasGroupAxis(MediaType.animation), isTrue);
      expect(CustomProgressUnits.hasGroupAxis(MediaType.manga), isTrue);
      expect(CustomProgressUnits.hasGroupAxis(MediaType.game), isFalse);
      expect(CustomProgressUnits.hasGroupAxis(MediaType.anime), isFalse);
      expect(CustomProgressUnits.hasGroupAxis(MediaType.book), isFalse);
    });
  });
}

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/theme/app_typography.dart';

void main() {
  group('AppTypography', () {
    group('posterTitleFor / posterSubtitleFor', () {
      test('компактный вариант мельче обычного', () {
        expect(
          AppTypography.posterTitleFor(compact: true).fontSize,
          lessThan(AppTypography.posterTitleFor(compact: false).fontSize!),
        );
        expect(
          AppTypography.posterSubtitleFor(compact: true).fontSize,
          lessThan(AppTypography.posterSubtitleFor(compact: false).fontSize!),
        );
      });

      test('обычный вариант отдаёт базовые стили без изменений', () {
        expect(
          AppTypography.posterTitleFor(compact: false),
          same(AppTypography.posterTitle),
        );
        expect(
          AppTypography.posterSubtitleFor(compact: false),
          same(AppTypography.posterSubtitle),
        );
      });
    });

    group('posterTextBlockHeight', () {
      test('должен вмещать две строки названия и строку подписи', () {
        final TextStyle title = AppTypography.posterTitleFor(compact: false);
        final TextStyle subtitle =
            AppTypography.posterSubtitleFor(compact: false);
        final double exact = 2 * title.fontSize! * title.height! +
            subtitle.fontSize! * subtitle.height!;

        final double height = AppTypography.posterTextBlockHeight(
          compact: false,
          textScaler: TextScaler.noScaling,
        );

        expect(height, greaterThanOrEqualTo(exact));
        expect(height - exact, lessThan(1));
      });

      test('должен округляться вверх до целого', () {
        final double height = AppTypography.posterTextBlockHeight(
          compact: false,
          textScaler: TextScaler.noScaling,
        );
        expect(height, equals(height.roundToDouble()));
      });

      test('компактный блок ниже обычного', () {
        expect(
          AppTypography.posterTextBlockHeight(
            compact: true,
            textScaler: TextScaler.noScaling,
          ),
          lessThan(
            AppTypography.posterTextBlockHeight(
              compact: false,
              textScaler: TextScaler.noScaling,
            ),
          ),
        );
      });

      test('должен учитывать системный масштаб шрифта', () {
        final double normal = AppTypography.posterTextBlockHeight(
          compact: false,
          textScaler: TextScaler.noScaling,
        );
        final double scaled = AppTypography.posterTextBlockHeight(
          compact: false,
          textScaler: const TextScaler.linear(2),
        );

        expect(scaled, closeTo(2 * normal, 2));
      });
    });
  });
}

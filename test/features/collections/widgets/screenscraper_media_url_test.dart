import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/screenscraper_api.dart';
import 'package:tonkatsu_box/features/collections/widgets/screenscraper_gallery_section.dart';
import 'package:tonkatsu_box/shared/constants/platform_features.dart';

const SsMedia _screenshot = SsMedia(
  type: 'ss',
  url: 'https://neoclone.screenscraper.fr/api2/mediaJeu.php?media=ss(wor)',
  format: 'png',
  region: 'wor',
);

void main() {
  group('ssMediaCacheId', () {
    test('should key on the game, the type and the region', () {
      expect(
        ssMediaCacheId(gameId: 2143, media: _screenshot),
        '2143_ss_wor.png',
      );
    });

    test('should separate two regions of the same media', () {
      final String wor = ssMediaCacheId(gameId: 2143, media: _screenshot);
      const SsMedia jp = SsMedia(
        type: 'ss',
        url: 'https://neoclone.screenscraper.fr/api2/mediaJeu.php',
        format: 'png',
        region: 'jp',
      );

      expect(ssMediaCacheId(gameId: 2143, media: jp), isNot(wor));
    });

    test('should fall back to png when the format is missing', () {
      const SsMedia noFormat = SsMedia(
        type: 'box-2D',
        url: 'https://neoclone.screenscraper.fr/api2/mediaJeu.php',
        region: 'wor',
      );

      expect(
        ssMediaCacheId(gameId: 7, media: noFormat),
        '7_box_2d_wor.png',
      );
    });

    test('should stay a safe file name for a region-less media', () {
      const SsMedia fanart = SsMedia(
        type: 'fanart',
        url: 'https://neoclone.screenscraper.fr/api2/mediaJeu.php',
        format: 'jpg',
      );

      expect(ssMediaCacheId(gameId: 7, media: fanart), '7_fanart_none.jpg');
      expect(
        ssMediaCacheId(gameId: 7, media: fanart),
        matches(RegExp(r'^[a-z0-9_]+\.[a-z0-9]+$')),
      );
    });
  });

  group('ssMediaUrl', () {
    test('should hand the upstream URL straight to a desktop client', () {
      // The proxy path only exists on web; everywhere else SS is reachable.
      expect(
        ssMediaUrl(gameId: 2143, media: _screenshot),
        kIsWebBuild ? contains('/img/screenscraper_media/') : _screenshot.url,
      );
    });
  });
}

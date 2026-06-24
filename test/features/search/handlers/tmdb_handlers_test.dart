import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/features/search/handlers/movie_handler.dart';
import 'package:tonkatsu_box/features/search/handlers/tv_show_handler.dart';
import 'package:tonkatsu_box/features/search/services/search_collection_adder.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/movie.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';

import '../../../helpers/test_helpers.dart';

class _MockAdder extends Mock implements SearchCollectionAdder {}

/// Captured args for the most recent `addToCollections` call.
class _Capture {
  Set<int>? collectionIds;
  MediaType? mediaType;
  int? externalId;
  int? platformId;
  String? title;
  ImageType? imageType;
  String? imageId;
  String? imageUrl;
  Future<void> Function()? afterAdd;
}

void main() {
  setUpAll(registerAllFallbacks);

  late _MockAdder adder;
  late _Capture cap;

  setUp(() {
    adder = _MockAdder();
    cap = _Capture();
    when(() => adder.addToCollections(
          context: any(named: 'context'),
          collectionIds: any(named: 'collectionIds'),
          mediaType: any(named: 'mediaType'),
          externalId: any(named: 'externalId'),
          platformId: any(named: 'platformId'),
          title: any(named: 'title'),
          upsert: any(named: 'upsert'),
          imageType: any(named: 'imageType'),
          imageId: any(named: 'imageId'),
          imageUrl: any(named: 'imageUrl'),
          afterAdd: any(named: 'afterAdd'),
        )).thenAnswer((Invocation inv) async {
      cap
        ..collectionIds = inv.namedArguments[#collectionIds] as Set<int>?
        ..mediaType = inv.namedArguments[#mediaType] as MediaType?
        ..externalId = inv.namedArguments[#externalId] as int?
        ..platformId = inv.namedArguments[#platformId] as int?
        ..title = inv.namedArguments[#title] as String?
        ..imageType = inv.namedArguments[#imageType] as ImageType?
        ..imageId = inv.namedArguments[#imageId] as String?
        ..imageUrl = inv.namedArguments[#imageUrl] as String?
        ..afterAdd =
            inv.namedArguments[#afterAdd] as Future<void> Function()?;
    });
  });

  group('MovieHandler.onTap with target collections', () {
    testWidgets('regular movie → platformId is null, adds to all targets',
        (WidgetTester tester) async {
      final MovieHandler handler = MovieHandler(
        ref: MockWidgetRef(),
        adder: adder,
        targetCollections: () => <int>{42, 43},
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await handler.onTap(
        tester.element(find.byType(SizedBox)),
        const Movie(tmdbId: 100, title: 'M'),
        MediaType.movie,
      );

      expect(cap.collectionIds, <int>{42, 43});
      expect(cap.mediaType, MediaType.movie);
      expect(cap.externalId, 100);
      expect(cap.platformId, isNull);
      expect(cap.imageType, ImageType.moviePoster);
    });

    testWidgets('animation movie → platformId = AnimationSource.movie',
        (WidgetTester tester) async {
      final MovieHandler handler = MovieHandler(
        ref: MockWidgetRef(),
        adder: adder,
        targetCollections: () => <int>{42},
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await handler.onTap(
        tester.element(find.byType(SizedBox)),
        const Movie(tmdbId: 100, title: 'M'),
        MediaType.animation,
      );

      expect(cap.mediaType, MediaType.animation);
      expect(cap.platformId, 0);
    });
  });

  group('TvShowHandler.onTap with target collections', () {
    testWidgets('regular tv show → platformId is null, afterAdd is set',
        (WidgetTester tester) async {
      final TvShowHandler handler = TvShowHandler(
        ref: MockWidgetRef(),
        adder: adder,
        targetCollections: () => <int>{7},
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await handler.onTap(
        tester.element(find.byType(SizedBox)),
        const TvShow(tmdbId: 200, title: 'T'),
        MediaType.tvShow,
      );

      expect(cap.collectionIds, <int>{7});
      expect(cap.mediaType, MediaType.tvShow);
      expect(cap.platformId, isNull);
      expect(cap.imageType, ImageType.tvShowPoster);
      expect(cap.afterAdd, isNotNull);
    });

    testWidgets('animation tv → platformId = AnimationSource.tvShow',
        (WidgetTester tester) async {
      final TvShowHandler handler = TvShowHandler(
        ref: MockWidgetRef(),
        adder: adder,
        targetCollections: () => <int>{7},
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await handler.onTap(
        tester.element(find.byType(SizedBox)),
        const TvShow(tmdbId: 200, title: 'T'),
        MediaType.animation,
      );

      expect(cap.mediaType, MediaType.animation);
      expect(cap.platformId, 1);
    });
  });
}

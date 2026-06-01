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

/// Captured args for the most recent `addToCollection` call.
class _Capture {
  int? collectionId;
  String? collectionName;
  MediaType? mediaType;
  int? externalId;
  int? platformId;
  String? title;
  ImageType? imageType;
  String? imageId;
  String? imageUrl;
}

void main() {
  setUpAll(registerAllFallbacks);

  late _MockAdder adder;
  late _Capture cap;

  setUp(() {
    adder = _MockAdder();
    cap = _Capture();
    when(() => adder.addToCollection(
          context: any(named: 'context'),
          collectionId: any(named: 'collectionId'),
          mediaType: any(named: 'mediaType'),
          externalId: any(named: 'externalId'),
          platformId: any(named: 'platformId'),
          title: any(named: 'title'),
          upsert: any(named: 'upsert'),
          imageType: any(named: 'imageType'),
          imageId: any(named: 'imageId'),
          imageUrl: any(named: 'imageUrl'),
          afterAdd: any(named: 'afterAdd'),
          collectionName: any(named: 'collectionName'),
        )).thenAnswer((Invocation inv) async {
      cap
        ..collectionId = inv.namedArguments[#collectionId] as int?
        ..collectionName = inv.namedArguments[#collectionName] as String?
        ..mediaType = inv.namedArguments[#mediaType] as MediaType?
        ..externalId = inv.namedArguments[#externalId] as int?
        ..platformId = inv.namedArguments[#platformId] as int?
        ..title = inv.namedArguments[#title] as String?
        ..imageType = inv.namedArguments[#imageType] as ImageType?
        ..imageId = inv.namedArguments[#imageId] as String?
        ..imageUrl = inv.namedArguments[#imageUrl] as String?;
      return true;
    });
  });

  group('MovieHandler.onTap with targetCollectionId', () {
    testWidgets('regular movie → platformId is null',
        (WidgetTester tester) async {
      final MovieHandler handler = MovieHandler(
        ref: MockWidgetRef(),
        adder: adder,
        targetCollectionId: 42,
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await handler.onTap(
        tester.element(find.byType(SizedBox)),
        const Movie(tmdbId: 100, title: 'M'),
        MediaType.movie,
      );

      expect(cap.collectionId, 42);
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
        targetCollectionId: 42,
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

  group('TvShowHandler.onTap with targetCollectionId', () {
    testWidgets('regular tv show → platformId is null, afterAdd is set',
        (WidgetTester tester) async {
      final TvShowHandler handler = TvShowHandler(
        ref: MockWidgetRef(),
        adder: adder,
        targetCollectionId: 7,
      );
      Future<void> Function()? capturedAfterAdd;
      when(() => adder.addToCollection(
            context: any(named: 'context'),
            collectionId: any(named: 'collectionId'),
            mediaType: any(named: 'mediaType'),
            externalId: any(named: 'externalId'),
            platformId: any(named: 'platformId'),
            title: any(named: 'title'),
            upsert: any(named: 'upsert'),
            imageType: any(named: 'imageType'),
            imageId: any(named: 'imageId'),
            imageUrl: any(named: 'imageUrl'),
            afterAdd: any(named: 'afterAdd'),
            collectionName: any(named: 'collectionName'),
          )).thenAnswer((Invocation inv) async {
        capturedAfterAdd =
            inv.namedArguments[#afterAdd] as Future<void> Function()?;
        cap
          ..mediaType = inv.namedArguments[#mediaType] as MediaType?
          ..platformId = inv.namedArguments[#platformId] as int?
          ..imageType = inv.namedArguments[#imageType] as ImageType?;
        return true;
      });

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await handler.onTap(
        tester.element(find.byType(SizedBox)),
        const TvShow(tmdbId: 200, title: 'T'),
        MediaType.tvShow,
      );

      expect(cap.mediaType, MediaType.tvShow);
      expect(cap.platformId, isNull);
      expect(cap.imageType, ImageType.tvShowPoster);
      expect(capturedAfterAdd, isNotNull);
    });

    testWidgets('animation tv → platformId = AnimationSource.tvShow',
        (WidgetTester tester) async {
      final TvShowHandler handler = TvShowHandler(
        ref: MockWidgetRef(),
        adder: adder,
        targetCollectionId: 7,
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

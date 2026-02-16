import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/models/tv_sub_filter.dart';

void main() {
  group('TvSubFilter', () {
    test('has 4 values', () {
      expect(TvSubFilter.values, hasLength(4));
    });

    test('all has correct value and label', () {
      expect(TvSubFilter.all.value, 'all');
      expect(TvSubFilter.all.label, 'All');
    });

    test('movies has correct value and label', () {
      expect(TvSubFilter.movies.value, 'movies');
      expect(TvSubFilter.movies.label, 'Movies');
    });

    test('tvShows has correct value and label', () {
      expect(TvSubFilter.tvShows.value, 'tvShows');
      expect(TvSubFilter.tvShows.label, 'TV Shows');
    });

    test('animation has correct value and label', () {
      expect(TvSubFilter.animation.value, 'animation');
      expect(TvSubFilter.animation.label, 'Animation');
    });

    group('fromString', () {
      test('returns all for "all"', () {
        expect(TvSubFilter.fromString('all'), TvSubFilter.all);
      });

      test('returns movies for "movies"', () {
        expect(TvSubFilter.fromString('movies'), TvSubFilter.movies);
      });

      test('returns tvShows for "tvShows"', () {
        expect(TvSubFilter.fromString('tvShows'), TvSubFilter.tvShows);
      });

      test('returns animation for "animation"', () {
        expect(TvSubFilter.fromString('animation'), TvSubFilter.animation);
      });

      test('returns all for unknown value', () {
        expect(TvSubFilter.fromString('unknown'), TvSubFilter.all);
      });

      test('returns all for empty string', () {
        expect(TvSubFilter.fromString(''), TvSubFilter.all);
      });

      test('is case sensitive', () {
        expect(TvSubFilter.fromString('Movies'), TvSubFilter.all);
        expect(TvSubFilter.fromString('ALL'), TvSubFilter.all);
      });
    });
  });
}

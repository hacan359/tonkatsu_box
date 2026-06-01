import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/tmdb_review.dart';

void main() {
  group('TmdbReview', () {
    group('constructor', () {
      test('should create экземпляр со всеми полями', () {
        final DateTime date = DateTime(2024, 3, 15, 10, 30);
        final TmdbReview review = TmdbReview(
          author: 'JohnDoe',
          content: 'Great movie!',
          createdAt: date,
          avatarPath: 'https://image.tmdb.org/t/p/w45/avatar.jpg',
          authorRating: 8.5,
          url: 'https://www.themoviedb.org/review/abc123',
        );

        expect(review.author, 'JohnDoe');
        expect(review.content, 'Great movie!');
        expect(review.createdAt, date);
        expect(review.avatarPath,
            'https://image.tmdb.org/t/p/w45/avatar.jpg');
        expect(review.authorRating, 8.5);
        expect(review.url, 'https://www.themoviedb.org/review/abc123');
      });

      test('should create экземпляр только с обязательными полями', () {
        final DateTime date = DateTime(2024, 1, 1);
        final TmdbReview review = TmdbReview(
          author: 'Anonymous',
          content: '',
          createdAt: date,
        );

        expect(review.author, 'Anonymous');
        expect(review.content, '');
        expect(review.createdAt, date);
        expect(review.avatarPath, isNull);
        expect(review.authorRating, isNull);
        expect(review.url, isNull);
      });
    });

    group('fromJson', () {
      test('should create из полного JSON с author_details', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'MovieCritic42',
          'content': 'An absolute masterpiece of cinema.',
          'created_at': '2024-06-15T14:30:00.000Z',
          'url': 'https://www.themoviedb.org/review/abc123',
          'author_details': <String, dynamic>{
            'avatar_path': '/abc123def.jpg',
            'rating': 9.0,
          },
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.author, 'MovieCritic42');
        expect(review.content, 'An absolute masterpiece of cinema.');
        expect(review.createdAt, DateTime.parse('2024-06-15T14:30:00.000Z'));
        expect(review.url, 'https://www.themoviedb.org/review/abc123');
        expect(review.avatarPath,
            'https://image.tmdb.org/t/p/w45/abc123def.jpg');
        expect(review.authorRating, 9.0);
      });

      test('should handle отсутствие author_details', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'SimpleUser',
          'content': 'Nice film.',
          'created_at': '2024-01-10T08:00:00.000Z',
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.author, 'SimpleUser');
        expect(review.content, 'Nice film.');
        expect(review.avatarPath, isNull);
        expect(review.authorRating, isNull);
        expect(review.url, isNull);
      });

      test('should handle avatar_path начинающийся с /http (полный URL)',
          () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'UserWithGravatar',
          'content': 'Good movie.',
          'created_at': '2024-03-20T12:00:00.000Z',
          'author_details': <String, dynamic>{
            'avatar_path':
                '/https://secure.gravatar.com/avatar/abc123.jpg',
            'rating': 7.0,
          },
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.avatarPath,
            'https://secure.gravatar.com/avatar/abc123.jpg');
      });

      test('should handle обычный avatar_path (путь TMDB)', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'TmdbUser',
          'content': 'Decent.',
          'created_at': '2024-05-01T09:15:00.000Z',
          'author_details': <String, dynamic>{
            'avatar_path': '/my_avatar.jpg',
            'rating': 6.0,
          },
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.avatarPath,
            'https://image.tmdb.org/t/p/w45/my_avatar.jpg');
      });

      test('should handle пустой avatar_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'NoAvatarUser',
          'content': 'Boring.',
          'created_at': '2024-02-28T16:45:00.000Z',
          'author_details': <String, dynamic>{
            'avatar_path': '',
            'rating': 3.0,
          },
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.avatarPath, isNull);
        expect(review.authorRating, 3.0);
      });

      test('should handle null avatar_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'NullAvatarUser',
          'content': 'Average.',
          'created_at': '2024-04-10T11:00:00.000Z',
          'author_details': <String, dynamic>{
            'avatar_path': null,
            'rating': 5.0,
          },
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.avatarPath, isNull);
        expect(review.authorRating, 5.0);
      });

      test('should handle null rating в author_details', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'NoRatingUser',
          'content': 'No score given.',
          'created_at': '2024-07-01T00:00:00.000Z',
          'author_details': <String, dynamic>{
            'avatar_path': '/some_avatar.jpg',
            'rating': null,
          },
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.authorRating, isNull);
        expect(review.avatarPath,
            'https://image.tmdb.org/t/p/w45/some_avatar.jpg');
      });

      test('should handle rating как int в author_details', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'IntRatingUser',
          'content': 'Gave an integer rating.',
          'created_at': '2024-08-15T10:00:00.000Z',
          'author_details': <String, dynamic>{
            'avatar_path': null,
            'rating': 8,
          },
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.authorRating, 8.0);
        expect(review.authorRating, isA<double>());
      });

      test('должен подставить "Anonymous" если author == null', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': null,
          'content': 'Anonymous review.',
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.author, 'Anonymous');
      });

      test('должен подставить пустую строку если content == null', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'ContentlessUser',
          'content': null,
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.content, '');
      });

      test('должен подставить текущую дату если created_at == null', () {
        final DateTime beforeTest = DateTime.now();

        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'NoDateUser',
          'content': 'No date.',
          'created_at': null,
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        final DateTime afterTest = DateTime.now();

        expect(review.createdAt.isAfter(beforeTest) ||
            review.createdAt.isAtSameMomentAs(beforeTest), isTrue);
        expect(review.createdAt.isBefore(afterTest) ||
            review.createdAt.isAtSameMomentAs(afterTest), isTrue);
      });

      test('должен подставить текущую дату если created_at невалидная строка',
          () {
        final DateTime beforeTest = DateTime.now();

        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'BadDateUser',
          'content': 'Invalid date.',
          'created_at': 'not-a-date',
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        final DateTime afterTest = DateTime.now();

        expect(review.createdAt.isAfter(beforeTest) ||
            review.createdAt.isAtSameMomentAs(beforeTest), isTrue);
        expect(review.createdAt.isBefore(afterTest) ||
            review.createdAt.isAtSameMomentAs(afterTest), isTrue);
      });

      test('должен подставить текущую дату если created_at пустая строка',
          () {
        final DateTime beforeTest = DateTime.now();

        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'EmptyDateUser',
          'content': 'Empty date string.',
          'created_at': '',
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        final DateTime afterTest = DateTime.now();

        expect(review.createdAt.isAfter(beforeTest) ||
            review.createdAt.isAtSameMomentAs(beforeTest), isTrue);
        expect(review.createdAt.isBefore(afterTest) ||
            review.createdAt.isAtSameMomentAs(afterTest), isTrue);
      });

      test('should handle отсутствие author в JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'content': 'No author key at all.',
          'created_at': '2024-06-01T12:00:00.000Z',
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.author, 'Anonymous');
      });

      test('should handle отсутствие content в JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'AuthorOnly',
          'created_at': '2024-06-01T12:00:00.000Z',
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.content, '');
      });

      test('should handle отсутствие created_at в JSON', () {
        final DateTime beforeTest = DateTime.now();

        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'NoCreatedAt',
          'content': 'Missing created_at key.',
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        final DateTime afterTest = DateTime.now();

        expect(review.createdAt.isAfter(beforeTest) ||
            review.createdAt.isAtSameMomentAs(beforeTest), isTrue);
        expect(review.createdAt.isBefore(afterTest) ||
            review.createdAt.isAtSameMomentAs(afterTest), isTrue);
      });

      test('should handle минимальный JSON (все поля отсутствуют)', () {
        final DateTime beforeTest = DateTime.now();

        final Map<String, dynamic> json = <String, dynamic>{};

        final TmdbReview review = TmdbReview.fromJson(json);

        final DateTime afterTest = DateTime.now();

        expect(review.author, 'Anonymous');
        expect(review.content, '');
        expect(review.createdAt.isAfter(beforeTest) ||
            review.createdAt.isAtSameMomentAs(beforeTest), isTrue);
        expect(review.createdAt.isBefore(afterTest) ||
            review.createdAt.isAtSameMomentAs(afterTest), isTrue);
        expect(review.avatarPath, isNull);
        expect(review.authorRating, isNull);
        expect(review.url, isNull);
      });

      test('should handle author_details с null значениями', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'author': 'DetailedNulls',
          'content': 'All details null.',
          'created_at': '2024-09-01T00:00:00.000Z',
          'author_details': <String, dynamic>{
            'avatar_path': null,
            'rating': null,
          },
        };

        final TmdbReview review = TmdbReview.fromJson(json);

        expect(review.avatarPath, isNull);
        expect(review.authorRating, isNull);
      });
    });

    group('formattedRating', () {
      test('should return отформатированный рейтинг для целого числа', () {
        final TmdbReview review = TmdbReview(
          author: 'User',
          content: 'Text',
          createdAt: DateTime(2024),
          authorRating: 8.0,
        );

        expect(review.formattedRating, '8');
      });

      test('should return отформатированный рейтинг с округлением', () {
        final TmdbReview review = TmdbReview(
          author: 'User',
          content: 'Text',
          createdAt: DateTime(2024),
          authorRating: 7.6,
        );

        expect(review.formattedRating, '8');
      });

      test('should return отформатированный рейтинг для 10.0', () {
        final TmdbReview review = TmdbReview(
          author: 'User',
          content: 'Text',
          createdAt: DateTime(2024),
          authorRating: 10.0,
        );

        expect(review.formattedRating, '10');
      });

      test('should return отформатированный рейтинг для 0.0', () {
        final TmdbReview review = TmdbReview(
          author: 'User',
          content: 'Text',
          createdAt: DateTime(2024),
          authorRating: 0.0,
        );

        expect(review.formattedRating, '0');
      });

      test('should return null если authorRating == null', () {
        final TmdbReview review = TmdbReview(
          author: 'User',
          content: 'Text',
          createdAt: DateTime(2024),
        );

        expect(review.formattedRating, isNull);
      });
    });

    group('toString', () {
      test('should return строковое представление с именем автора', () {
        final TmdbReview review = TmdbReview(
          author: 'CinemaFan99',
          content: 'Some review text.',
          createdAt: DateTime(2024, 6, 15),
        );

        expect(review.toString(), 'TmdbReview(author: CinemaFan99)');
      });

      test('should return строковое представление для Anonymous', () {
        final TmdbReview review = TmdbReview.fromJson(
          <String, dynamic>{
            'content': 'Anonymous review.',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
        );

        expect(review.toString(), 'TmdbReview(author: Anonymous)');
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/collection_sort_mode.dart';

void main() {
  group('CollectionSortMode', () {
    group('значения enum', () {
      test('should contain 8 значений', () {
        expect(CollectionSortMode.values.length, 8);
      });

      test('should contain все режимы сортировки', () {
        expect(CollectionSortMode.values, contains(CollectionSortMode.manual));
        expect(
          CollectionSortMode.values,
          contains(CollectionSortMode.addedDate),
        );
        expect(CollectionSortMode.values, contains(CollectionSortMode.status));
        expect(CollectionSortMode.values, contains(CollectionSortMode.name));
        expect(CollectionSortMode.values, contains(CollectionSortMode.rating));
        expect(
          CollectionSortMode.values,
          contains(CollectionSortMode.favorite),
        );
        expect(
          CollectionSortMode.values,
          contains(CollectionSortMode.externalRating),
        );
      });
    });

    group('value', () {
      test('manual должен иметь значение "manual"', () {
        expect(CollectionSortMode.manual.value, 'manual');
      });

      test('addedDate должен иметь значение "added_date"', () {
        expect(CollectionSortMode.addedDate.value, 'added_date');
      });

      test('status должен иметь значение "status"', () {
        expect(CollectionSortMode.status.value, 'status');
      });

      test('name должен иметь значение "name"', () {
        expect(CollectionSortMode.name.value, 'name');
      });

      test('rating должен иметь значение "rating"', () {
        expect(CollectionSortMode.rating.value, 'rating');
      });

      test('externalRating должен иметь значение "external_rating"', () {
        expect(CollectionSortMode.externalRating.value, 'external_rating');
      });
    });

    group('displayLabel', () {
      test('manual должен отображаться как "Manual"', () {
        expect(CollectionSortMode.manual.displayLabel, 'Manual');
      });

      test('addedDate должен отображаться как "Date Added"', () {
        expect(CollectionSortMode.addedDate.displayLabel, 'Date Added');
      });

      test('status должен отображаться как "Status"', () {
        expect(CollectionSortMode.status.displayLabel, 'Status');
      });

      test('name должен отображаться как "Name"', () {
        expect(CollectionSortMode.name.displayLabel, 'Name');
      });

      test('rating должен отображаться как "My Rating"', () {
        expect(CollectionSortMode.rating.displayLabel, 'My Rating');
      });

      test('externalRating должен отображаться как "External Rating"', () {
        expect(
          CollectionSortMode.externalRating.displayLabel,
          'External Rating',
        );
      });
    });

    group('shortLabel', () {
      test('manual должен иметь shortLabel "Manual"', () {
        expect(CollectionSortMode.manual.shortLabel, 'Manual');
      });

      test('addedDate должен иметь shortLabel "Date"', () {
        expect(CollectionSortMode.addedDate.shortLabel, 'Date');
      });

      test('status должен иметь shortLabel "Status"', () {
        expect(CollectionSortMode.status.shortLabel, 'Status');
      });

      test('name должен иметь shortLabel "A-Z"', () {
        expect(CollectionSortMode.name.shortLabel, 'A-Z');
      });

      test('rating должен иметь shortLabel "Rating"', () {
        expect(CollectionSortMode.rating.shortLabel, 'Rating');
      });

      test('externalRating должен иметь shortLabel "IGDB/TMDB"', () {
        expect(CollectionSortMode.externalRating.shortLabel, 'IGDB/TMDB');
      });
    });

    group('description', () {
      test('manual должен иметь описание "Custom order"', () {
        expect(CollectionSortMode.manual.description, 'Custom order');
      });

      test('addedDate должен иметь описание "Newest first"', () {
        expect(CollectionSortMode.addedDate.description, 'Newest first');
      });

      test('status должен иметь описание "Active first"', () {
        expect(CollectionSortMode.status.description, 'Active first');
      });

      test('name должен иметь описание "A to Z"', () {
        expect(CollectionSortMode.name.description, 'A to Z');
      });

      test('rating должен иметь описание "Highest first"', () {
        expect(CollectionSortMode.rating.description, 'Highest first');
      });

      test('externalRating должен иметь описание "Highest first"', () {
        expect(CollectionSortMode.externalRating.description, 'Highest first');
      });
    });

    group('localizedDirectionLabel', () {
      Future<S> loadLocalizations(WidgetTester tester) async {
        late S l;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Builder(
              builder: (BuildContext context) {
                l = S.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        return l;
      }

      testWidgets('spells out a non-empty label that changes with direction',
          (WidgetTester tester) async {
        final S l = await loadLocalizations(tester);

        for (final CollectionSortMode mode in CollectionSortMode.values) {
          final String forward =
              mode.localizedDirectionLabel(l, descending: false);
          final String reverse =
              mode.localizedDirectionLabel(l, descending: true);

          expect(forward, isNotEmpty);
          expect(reverse, isNotEmpty);
          if (mode == CollectionSortMode.manual) {
            // Manual order is not reversible, so both directions read the same.
            expect(forward, reverse);
          } else {
            expect(forward, isNot(reverse));
          }
        }
      });
    });

    group('fromString', () {
      test('should return manual для "manual"', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('manual');

        expect(result, CollectionSortMode.manual);
      });

      test('should return addedDate для "added_date"', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('added_date');

        expect(result, CollectionSortMode.addedDate);
      });

      test('should return status для "status"', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('status');

        expect(result, CollectionSortMode.status);
      });

      test('should return name для "name"', () {
        final CollectionSortMode result = CollectionSortMode.fromString('name');

        expect(result, CollectionSortMode.name);
      });

      test('should return rating для "rating"', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('rating');

        expect(result, CollectionSortMode.rating);
      });

      test('should return externalRating для "external_rating"', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('external_rating');

        expect(result, CollectionSortMode.externalRating);
      });

      test('should return addedDate для неизвестного значения', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('unknown_mode');

        expect(result, CollectionSortMode.addedDate);
      });

      test('should return addedDate для пустой строки', () {
        final CollectionSortMode result = CollectionSortMode.fromString('');

        expect(result, CollectionSortMode.addedDate);
      });

      test('должен быть чувствительным к регистру', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString('Manual');

        expect(result, CollectionSortMode.addedDate);
      });

      test('should return addedDate для строки с пробелами', () {
        final CollectionSortMode result =
            CollectionSortMode.fromString(' manual ');

        expect(result, CollectionSortMode.addedDate);
      });
    });

    group('полнота свойств', () {
      test('каждый режим должен иметь непустое value', () {
        for (final CollectionSortMode mode in CollectionSortMode.values) {
          expect(
            mode.value.isNotEmpty,
            isTrue,
            reason: '${mode.name} value должен быть непустым',
          );
        }
      });

      test('каждый режим должен иметь непустой displayLabel', () {
        for (final CollectionSortMode mode in CollectionSortMode.values) {
          expect(
            mode.displayLabel.isNotEmpty,
            isTrue,
            reason: '${mode.name} displayLabel должен быть непустым',
          );
        }
      });

      test('каждый режим должен иметь непустой shortLabel', () {
        for (final CollectionSortMode mode in CollectionSortMode.values) {
          expect(
            mode.shortLabel.isNotEmpty,
            isTrue,
            reason: '${mode.name} shortLabel должен быть непустым',
          );
        }
      });

      test('каждый режим должен иметь непустой description', () {
        for (final CollectionSortMode mode in CollectionSortMode.values) {
          expect(
            mode.description.isNotEmpty,
            isTrue,
            reason: '${mode.name} description должен быть непустым',
          );
        }
      });

      test('все значения value должны быть уникальными', () {
        final List<String> allValues =
            CollectionSortMode.values.map((CollectionSortMode m) => m.value).toList();
        final Set<String> uniqueValues = allValues.toSet();

        expect(uniqueValues.length, allValues.length);
      });
    });
  });
}

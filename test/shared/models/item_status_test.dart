// Тесты для модели ItemStatus

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

void main() {
  group('ItemStatus', () {
    group('значения enum', () {
      test('должен содержать 6 значений', () {
        expect(ItemStatus.values.length, 6);
      });

      test('должен содержать все статусы', () {
        expect(ItemStatus.values, contains(ItemStatus.notStarted));
        expect(ItemStatus.values, contains(ItemStatus.inProgress));
        expect(ItemStatus.values, contains(ItemStatus.completed));
        expect(ItemStatus.values, contains(ItemStatus.dropped));
        expect(ItemStatus.values, contains(ItemStatus.planned));
        expect(ItemStatus.values, contains(ItemStatus.onHold));
      });
    });

    group('value', () {
      test('notStarted должен иметь значение "not_started"', () {
        expect(ItemStatus.notStarted.value, 'not_started');
      });

      test('inProgress должен иметь значение "in_progress"', () {
        expect(ItemStatus.inProgress.value, 'in_progress');
      });

      test('completed должен иметь значение "completed"', () {
        expect(ItemStatus.completed.value, 'completed');
      });

      test('dropped должен иметь значение "dropped"', () {
        expect(ItemStatus.dropped.value, 'dropped');
      });

      test('planned должен иметь значение "planned"', () {
        expect(ItemStatus.planned.value, 'planned');
      });

      test('onHold должен иметь значение "on_hold"', () {
        expect(ItemStatus.onHold.value, 'on_hold');
      });
    });

    group('fromString', () {
      test('должен вернуть notStarted для "not_started"', () {
        final ItemStatus result = ItemStatus.fromString('not_started');

        expect(result, ItemStatus.notStarted);
      });

      test('должен вернуть inProgress для "in_progress"', () {
        final ItemStatus result = ItemStatus.fromString('in_progress');

        expect(result, ItemStatus.inProgress);
      });

      test('должен вернуть completed для "completed"', () {
        final ItemStatus result = ItemStatus.fromString('completed');

        expect(result, ItemStatus.completed);
      });

      test('должен вернуть dropped для "dropped"', () {
        final ItemStatus result = ItemStatus.fromString('dropped');

        expect(result, ItemStatus.dropped);
      });

      test('должен вернуть planned для "planned"', () {
        final ItemStatus result = ItemStatus.fromString('planned');

        expect(result, ItemStatus.planned);
      });

      test('должен вернуть onHold для "on_hold"', () {
        final ItemStatus result = ItemStatus.fromString('on_hold');

        expect(result, ItemStatus.onHold);
      });

      test('должен маппить legacy "playing" в inProgress', () {
        final ItemStatus result = ItemStatus.fromString('playing');

        expect(result, ItemStatus.inProgress);
      });

      test('должен вернуть notStarted для неизвестного значения', () {
        final ItemStatus result = ItemStatus.fromString('unknown_status');

        expect(result, ItemStatus.notStarted);
      });

      test('должен вернуть notStarted для пустой строки', () {
        final ItemStatus result = ItemStatus.fromString('');

        expect(result, ItemStatus.notStarted);
      });
    });

    group('dbValue', () {
      test('inProgress для game должен вернуть "playing"', () {
        final String result = ItemStatus.inProgress.dbValue(MediaType.game);

        expect(result, 'playing');
      });

      test('inProgress для movie должен вернуть "in_progress"', () {
        final String result = ItemStatus.inProgress.dbValue(MediaType.movie);

        expect(result, 'in_progress');
      });

      test('inProgress для tvShow должен вернуть "in_progress"', () {
        final String result = ItemStatus.inProgress.dbValue(MediaType.tvShow);

        expect(result, 'in_progress');
      });

      test('completed для game должен вернуть "completed"', () {
        final String result = ItemStatus.completed.dbValue(MediaType.game);

        expect(result, 'completed');
      });

      test('notStarted для movie должен вернуть "not_started"', () {
        final String result = ItemStatus.notStarted.dbValue(MediaType.movie);

        expect(result, 'not_started');
      });

      test('dropped для tvShow должен вернуть "dropped"', () {
        final String result = ItemStatus.dropped.dbValue(MediaType.tvShow);

        expect(result, 'dropped');
      });

      test('planned для game должен вернуть "planned"', () {
        final String result = ItemStatus.planned.dbValue(MediaType.game);

        expect(result, 'planned');
      });

      test('onHold для tvShow должен вернуть "on_hold"', () {
        final String result = ItemStatus.onHold.dbValue(MediaType.tvShow);

        expect(result, 'on_hold');
      });
    });

    group('displayLabel', () {
      test('notStarted должен отображаться как "Not Started"', () {
        expect(
          ItemStatus.notStarted.displayLabel(MediaType.game),
          'Not Started',
        );
      });

      test('inProgress для game должен отображаться как "Playing"', () {
        expect(
          ItemStatus.inProgress.displayLabel(MediaType.game),
          'Playing',
        );
      });

      test('inProgress для movie должен отображаться как "Watching"', () {
        expect(
          ItemStatus.inProgress.displayLabel(MediaType.movie),
          'Watching',
        );
      });

      test('inProgress для tvShow должен отображаться как "Watching"', () {
        expect(
          ItemStatus.inProgress.displayLabel(MediaType.tvShow),
          'Watching',
        );
      });

      test('completed должен отображаться как "Completed"', () {
        expect(
          ItemStatus.completed.displayLabel(MediaType.game),
          'Completed',
        );
      });

      test('dropped должен отображаться как "Dropped"', () {
        expect(
          ItemStatus.dropped.displayLabel(MediaType.movie),
          'Dropped',
        );
      });

      test('planned должен отображаться как "Planned"', () {
        expect(
          ItemStatus.planned.displayLabel(MediaType.tvShow),
          'Planned',
        );
      });

      test('onHold должен отображаться как "On Hold"', () {
        expect(
          ItemStatus.onHold.displayLabel(MediaType.tvShow),
          'On Hold',
        );
      });
    });

    group('icon', () {
      test('каждый статус должен иметь непустую иконку', () {
        for (final ItemStatus status in ItemStatus.values) {
          expect(status.icon, isNotEmpty, reason: '${status.name} icon');
        }
      });

      test('notStarted должен иметь иконку', () {
        expect(ItemStatus.notStarted.icon, isA<String>());
        expect(ItemStatus.notStarted.icon.isNotEmpty, isTrue);
      });

      test('inProgress должен иметь иконку', () {
        expect(ItemStatus.inProgress.icon, isA<String>());
        expect(ItemStatus.inProgress.icon.isNotEmpty, isTrue);
      });

      test('completed должен иметь иконку', () {
        expect(ItemStatus.completed.icon, isA<String>());
        expect(ItemStatus.completed.icon.isNotEmpty, isTrue);
      });

      test('dropped должен иметь иконку', () {
        expect(ItemStatus.dropped.icon, isA<String>());
        expect(ItemStatus.dropped.icon.isNotEmpty, isTrue);
      });

      test('planned должен иметь иконку', () {
        expect(ItemStatus.planned.icon, isA<String>());
        expect(ItemStatus.planned.icon.isNotEmpty, isTrue);
      });

      test('onHold должен иметь иконку', () {
        expect(ItemStatus.onHold.icon, isA<String>());
        expect(ItemStatus.onHold.icon.isNotEmpty, isTrue);
      });
    });

    group('displayText', () {
      test('должен содержать иконку и метку для game inProgress', () {
        final String result =
            ItemStatus.inProgress.displayText(MediaType.game);

        expect(result, contains(ItemStatus.inProgress.icon));
        expect(result, contains('Playing'));
      });

      test('должен содержать иконку и метку для movie inProgress', () {
        final String result =
            ItemStatus.inProgress.displayText(MediaType.movie);

        expect(result, contains(ItemStatus.inProgress.icon));
        expect(result, contains('Watching'));
      });

      test('должен содержать иконку и метку для completed', () {
        final String result =
            ItemStatus.completed.displayText(MediaType.game);

        expect(result, contains(ItemStatus.completed.icon));
        expect(result, contains('Completed'));
      });

      test('должен возвращать строку формата "icon label"', () {
        final String result =
            ItemStatus.notStarted.displayText(MediaType.game);
        final String expectedIcon = ItemStatus.notStarted.icon;
        final String expectedLabel =
            ItemStatus.notStarted.displayLabel(MediaType.game);

        expect(result, '$expectedIcon $expectedLabel');
      });
    });
  });
}

// Реестр всех миграций БД.
import 'migration.dart';
import 'migration_v2.dart';
import 'migration_v3.dart';
import 'migration_v4.dart';
import 'migration_v5.dart';
import 'migration_v6.dart';
import 'migration_v7.dart';
import 'migration_v8.dart';
import 'migration_v9.dart';
import 'migration_v10.dart';
import 'migration_v11.dart';
import 'migration_v12.dart';
import 'migration_v13.dart';
import 'migration_v14.dart';
import 'migration_v15.dart';
import 'migration_v16.dart';
import 'migration_v17.dart';
import 'migration_v18.dart';
import 'migration_v19.dart';
import 'migration_v20.dart';
import 'migration_v21.dart';
import 'migration_v22.dart';
import 'migration_v23.dart';
import 'migration_v24.dart';
import 'migration_v25.dart';
import 'migration_v26.dart';
import 'migration_v27.dart';
import 'migration_v28.dart';

/// Реестр всех миграций базы данных.
///
/// Содержит полный список миграций в порядке версий
/// и метод для получения ожидающих выполнения миграций.
abstract final class MigrationRegistry {
  /// Все миграции в порядке версий.
  static final List<Migration> all = <Migration>[
    MigrationV2(),
    MigrationV3(),
    MigrationV4(),
    MigrationV5(),
    MigrationV6(),
    MigrationV7(),
    MigrationV8(),
    MigrationV9(),
    MigrationV10(),
    MigrationV11(),
    MigrationV12(),
    MigrationV13(),
    MigrationV14(),
    MigrationV15(),
    MigrationV16(),
    MigrationV17(),
    MigrationV18(),
    MigrationV19(),
    MigrationV20(),
    MigrationV21(),
    MigrationV22(),
    MigrationV23(),
    MigrationV24(),
    MigrationV25(),
    MigrationV26(),
    MigrationV27(),
    MigrationV28(),
  ];

  /// Возвращает миграции, ожидающие выполнения для данной версии.
  static List<Migration> pending(int oldVersion) {
    return all
        .where((Migration m) => m.version > oldVersion)
        .toList();
  }
}

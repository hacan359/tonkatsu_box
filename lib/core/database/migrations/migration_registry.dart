import 'migration.dart';
import 'migration_v1.dart';
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
import 'migration_v29.dart';
import 'migration_v30.dart';
import 'migration_v31.dart';
import 'migration_v32.dart';
import 'migration_v33.dart';
import 'migration_v34.dart';
import 'migration_v35.dart';
import 'migration_v36.dart';
import 'migration_v37.dart';
import 'migration_v38.dart';
import 'migration_v39.dart';
import 'migration_v40.dart';
import 'migration_v41.dart';
import 'migration_v42.dart';
import 'migration_v43.dart';
import 'migration_v44.dart';
import 'migration_v45.dart';
import 'migration_v46.dart';
import 'migration_v47.dart';
import 'migration_v48.dart';
import 'migration_v49.dart';
import 'migration_v50.dart';
import 'migration_v51.dart';
import 'migration_v52.dart';

abstract final class MigrationRegistry {
  static final List<Migration> all = <Migration>[
    MigrationV1(),
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
    MigrationV29(),
    MigrationV30(),
    MigrationV31(),
    MigrationV32(),
    MigrationV33(),
    MigrationV34(),
    MigrationV35(),
    MigrationV36(),
    MigrationV37(),
    MigrationV38(),
    MigrationV39(),
    MigrationV40(),
    MigrationV41(),
    MigrationV42(),
    MigrationV43(),
    MigrationV44(),
    MigrationV45(),
    MigrationV46(),
    MigrationV47(),
    MigrationV48(),
    MigrationV49(),
    MigrationV50(),
    MigrationV51(),
    MigrationV52(),
  ];

  /// Schema version this build can open; newer databases must be rejected.
  static int get latestVersion => all.last.version;

  static List<Migration> pending(int oldVersion) {
    return all
        .where((Migration m) => m.version > oldVersion)
        .toList();
  }
}

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract class Migration {
  int get version;
  String get description;
  Future<void> migrate(Database db);
}

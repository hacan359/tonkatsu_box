import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Phase-2 stopgap: in-browser SQLite so the UI boots with an empty DB.
/// The real web backend is the DAO-RPC server (phase 3).
void initPlatform() {
  databaseFactory = databaseFactoryFfiWeb;
}

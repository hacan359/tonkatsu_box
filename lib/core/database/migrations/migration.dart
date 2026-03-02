// Базовый класс миграции БД.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Абстрактный класс миграции базы данных.
///
/// Каждая миграция имеет версию, описание и метод [migrate],
/// выполняющий SQL-операции для обновления схемы.
abstract class Migration {
  /// Версия БД, к которой применяется миграция.
  int get version;

  /// Краткое описание миграции на английском.
  String get description;

  /// Выполняет миграцию на переданной базе данных.
  Future<void> migrate(Database db);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/wishlist_item.dart';

/// Провайдер для репозитория вишлиста.
final Provider<WishlistRepository> wishlistRepositoryProvider =
    Provider<WishlistRepository>((Ref ref) {
  return WishlistRepository(
    db: ref.watch(databaseServiceProvider),
  );
});

/// Репозиторий для работы с элементами вишлиста.
class WishlistRepository {
  /// Создаёт экземпляр [WishlistRepository].
  WishlistRepository({required DatabaseService db}) : _db = db;

  final DatabaseService _db;

  /// Добавляет элемент в вишлист.
  Future<WishlistItem> add({
    required String text,
    MediaType? mediaTypeHint,
    String? note,
  }) async {
    return _db.addWishlistItem(
      text: text,
      mediaTypeHint: mediaTypeHint,
      note: note,
    );
  }

  /// Возвращает все элементы вишлиста.
  Future<List<WishlistItem>> getAll({
    bool includeResolved = true,
  }) async {
    return _db.getWishlistItems(includeResolved: includeResolved);
  }

  /// Возвращает количество элементов вишлиста.
  Future<int> getCount({bool onlyActive = true}) async {
    return _db.getWishlistItemCount(onlyActive: onlyActive);
  }

  /// Обновляет элемент вишлиста.
  Future<void> update(
    int id, {
    String? text,
    MediaType? mediaTypeHint,
    bool clearMediaTypeHint = false,
    String? note,
    bool clearNote = false,
  }) async {
    return _db.updateWishlistItem(
      id,
      text: text,
      mediaTypeHint: mediaTypeHint,
      clearMediaTypeHint: clearMediaTypeHint,
      note: note,
      clearNote: clearNote,
    );
  }

  /// Помечает элемент как resolved.
  Future<void> resolve(int id) async {
    return _db.resolveWishlistItem(id);
  }

  /// Снимает отметку resolved.
  Future<void> unresolve(int id) async {
    return _db.unresolveWishlistItem(id);
  }

  /// Удаляет элемент.
  Future<void> delete(int id) async {
    return _db.deleteWishlistItem(id);
  }

  /// Удаляет все resolved элементы.
  Future<int> clearResolved() async {
    return _db.clearResolvedWishlistItems();
  }
}

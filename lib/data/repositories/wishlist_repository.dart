import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/wishlist_item.dart';

final Provider<WishlistRepository> wishlistRepositoryProvider =
    Provider<WishlistRepository>((Ref ref) {
  return WishlistRepository(
    db: ref.watch(databaseServiceProvider),
  );
});

class WishlistRepository {
  WishlistRepository({required DatabaseService db}) : _db = db;

  final DatabaseService _db;

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

  Future<List<WishlistItem>> getAll({
    bool includeResolved = true,
  }) async {
    return _db.getWishlistItems(includeResolved: includeResolved);
  }

  Future<int> getCount({bool onlyActive = true}) async {
    return _db.getWishlistItemCount(onlyActive: onlyActive);
  }

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

  Future<void> resolve(int id) async {
    return _db.resolveWishlistItem(id);
  }

  Future<void> unresolve(int id) async {
    return _db.unresolveWishlistItem(id);
  }

  Future<void> delete(int id) async {
    return _db.deleteWishlistItem(id);
  }

  Future<WishlistItem?> findUnresolved(String text) async {
    return _db.findUnresolvedWishlistItem(text);
  }

  Future<int> clearResolved() async {
    return _db.clearResolvedWishlistItems();
  }
}

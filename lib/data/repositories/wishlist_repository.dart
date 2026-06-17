import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/dao/wishlist_dao.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/wishlist_item.dart';
import '../../shared/models/wishlist_tag.dart';

final Provider<WishlistRepository> wishlistRepositoryProvider =
    Provider<WishlistRepository>((Ref ref) {
  return WishlistRepository(
    wishlistDao: ref.watch(wishlistDaoProvider),
  );
});

class WishlistRepository {
  WishlistRepository({required WishlistDao wishlistDao})
      : _wishlistDao = wishlistDao;

  final WishlistDao _wishlistDao;

  Future<WishlistItem> add({
    required String text,
    MediaType? mediaTypeHint,
    String? note,
    String? tag,
  }) async {
    return _wishlistDao.addWishlistItem(
      text: text,
      mediaTypeHint: mediaTypeHint,
      note: note,
      tag: tag,
    );
  }

  /// Bulk-inserts wishlist entries in one transaction (used by imports).
  /// Callers dedup against existing entries first. Returns the count inserted.
  Future<int> addWishlistItemsBatch(List<Map<String, dynamic>> rows) {
    return _wishlistDao.addWishlistItemsBatch(rows);
  }

  Future<List<WishlistItem>> getAll({
    bool includeResolved = true,
    WishlistTagFilter tagFilter = const WishlistTagFilter.all(),
  }) async {
    return _wishlistDao.getWishlistItemsFiltered(
      includeResolved: includeResolved,
      tagFilter: tagFilter,
    );
  }

  Future<int> getCount({bool onlyActive = true}) async {
    return _wishlistDao.getWishlistItemCount(onlyActive: onlyActive);
  }

  Future<void> update(
    int id, {
    String? text,
    MediaType? mediaTypeHint,
    bool clearMediaTypeHint = false,
    String? note,
    bool clearNote = false,
    String? tag,
    bool clearTag = false,
  }) async {
    return _wishlistDao.updateWishlistItem(
      id,
      text: text,
      mediaTypeHint: mediaTypeHint,
      clearMediaTypeHint: clearMediaTypeHint,
      note: note,
      clearNote: clearNote,
      tag: tag,
      clearTag: clearTag,
    );
  }

  Future<void> resolve(int id) async {
    return _wishlistDao.resolveWishlistItem(id);
  }

  Future<void> unresolve(int id) async {
    return _wishlistDao.unresolveWishlistItem(id);
  }

  Future<void> delete(int id) async {
    return _wishlistDao.deleteWishlistItem(id);
  }

  Future<WishlistItem?> findUnresolved(String text) async {
    return _wishlistDao.findUnresolvedByText(text);
  }

  Future<int> clearResolved() async {
    return _wishlistDao.clearResolvedWishlistItems();
  }

  Future<int> deleteByTag(String? tag) async {
    return _wishlistDao.deleteWishlistItemsByTag(tag);
  }

  Future<int> renameTag(String? from, String to) async {
    return _wishlistDao.renameWishlistTag(from, to);
  }
}

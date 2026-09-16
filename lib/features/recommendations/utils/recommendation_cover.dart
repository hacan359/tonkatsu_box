import '../../../core/services/image_cache_service.dart';
import '../../../shared/utils/cover_cache_slot.dart';
import '../providers/recommendations_provider.dart';

/// Cache slot of a recommended title's poster, shared by every widget that
/// draws one so the hub preview and the full row hit the same cached file.
({ImageType type, String id}) recommendationCoverCache(RecommendedItem item) =>
    coverCacheSlot(
      mediaType: item.mediaType,
      externalId: item.externalId,
      source: item.source,
    );

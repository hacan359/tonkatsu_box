import 'package:core/models/image_type.dart';

import '../../../shared/utils/cover_cache_slot.dart';
import '../models/showcase_item.dart';

({ImageType type, String id}) showcaseCoverCache(ShowcaseItem item) =>
    coverCacheSlot(
      mediaType: item.mediaType,
      externalId: item.externalId,
      source: item.source,
    );

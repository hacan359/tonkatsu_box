/// Wire-format revision of `/rpc`. Bump on any DAO surface change so a stale
/// tab or a not-yet-updated server errors clearly instead of failing per call.
// v2: renamed getCollectionIdsWithStatuses, added AudioDao + listen-count stats.
const int kProtocolVersion = 2;

/// Wire-format revision of `/rpc`. Bump on any DAO surface change so a stale
/// tab or a not-yet-updated server errors clearly instead of failing per call.
const int kProtocolVersion = 3;

/// The server answers HTTP 401 with this kind when `--auth token` is on and
/// the request carries no valid bearer; the client then asks for the token.
const String kRpcErrorKindAuth = 'auth';

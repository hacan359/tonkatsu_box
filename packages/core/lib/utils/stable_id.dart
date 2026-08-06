// dart2js ints are doubles, so only that target pays for exact BigInt wrap
// math; native keeps raw int math. Both produce identical values (see tests).
export 'stable_id_io.dart' if (dart.library.js_interop) 'stable_id_web.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pins an autoDispose provider for [ttl] once its value is in; call it after
/// the await so a failed fetch stays disposable and the next listener retries.
void cacheFor(Ref ref, Duration ttl) {
  final KeepAliveLink link = ref.keepAlive();
  final Timer timer = Timer(ttl, link.close);
  ref.onDispose(timer.cancel);
}

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// hex sha1(key + secret + unixTime) — the Podcast Index request signature.
/// Shared by the app's auth interceptor and the selfhost proxy on purpose:
/// a second copy would drift and break one of the two ends.
String podcastIndexSignature(String key, String secret, int unixTime) =>
    sha1.convert(utf8.encode('$key$secret$unixTime')).toString();

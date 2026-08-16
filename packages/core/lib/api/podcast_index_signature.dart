import 'dart:convert';

import 'package:crypto/crypto.dart';

/// hex sha1(key + secret + unixTime). Shared by the app's interceptor and the
/// selfhost proxy on purpose — a second copy would drift and break one end.
String podcastIndexSignature(String key, String secret, int unixTime) =>
    sha1.convert(utf8.encode('$key$secret$unixTime')).toString();

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tap handler opening [url], or null when there is nothing to open — lets a
/// widget stay non-interactive for items without an external page.
VoidCallback? openUrlCallback(String? url) =>
    url == null || url.isEmpty ? null : () => launchExternalUrl(url);

/// Best-effort open of [url] in the external browser/app; failures are
/// swallowed since a dead link is non-critical.
Future<void> launchExternalUrl(String url) async {
  try {
    final Uri uri = Uri.parse(url);
    // Only web links: URLs here come from user notes, imports and APIs, so a
    // scheme allowlist keeps a malicious link from launching file:// or a
    // custom-scheme handler.
    if (uri.scheme != 'http' && uri.scheme != 'https') return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } on Exception {
    // Non-critical: the link simply does not open.
  }
}

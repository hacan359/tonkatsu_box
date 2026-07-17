// "What's new" on version change: shows the current version's CHANGELOG
// section once, then remembers the version (mirrors UpdateService's shape).

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/providers/settings_provider.dart';

/// Changelog section for one released version.
class WhatsNewContent {
  const WhatsNewContent({required this.version, required this.body});

  final String version;

  /// Mini-markdown body (topics + prose, file lists stripped). EN only.
  final String body;
}

/// Decides whether the "What's new" dialog is due after an app update.
class WhatsNewService {
  /// [currentVersionOverride] replaces `PackageInfo.fromPlatform()` and
  /// [changelogLoader] replaces the bundled-asset read in tests.
  WhatsNewService({
    required SharedPreferences prefs,
    String? currentVersionOverride,
    Future<String> Function()? changelogLoader,
  })  : _prefs = prefs,
        _currentVersionOverride = currentVersionOverride,
        _changelogLoader = changelogLoader;

  final SharedPreferences _prefs;
  final String? _currentVersionOverride;
  final Future<String> Function()? _changelogLoader;

  static const String _seenVersionKey = 'changelog_seen_version';

  /// Returns the changelog for the current version when it has not been
  /// shown yet, `null` otherwise.
  ///
  /// The first launch ever (no stored version) is treated as already seen:
  /// a fresh install starts with the welcome wizard, not release notes.
  /// A version without a CHANGELOG section is marked seen silently.
  Future<WhatsNewContent?> pendingWhatsNew() async {
    final String currentVersion = await _resolveVersion();
    final String? seenVersion = _prefs.getString(_seenVersionKey);

    if (seenVersion == null || seenVersion == currentVersion) {
      if (seenVersion == null) {
        await markSeen(currentVersion);
      }
      return null;
    }

    final String changelog;
    try {
      changelog = await (_changelogLoader?.call() ??
          rootBundle.loadString('CHANGELOG.md'));
    } on Exception {
      return null;
    }

    final String? section = extractSection(changelog, currentVersion);
    if (section == null) {
      await markSeen(currentVersion);
      return null;
    }

    return WhatsNewContent(
      version: currentVersion,
      body: simplifyForDisplay(section),
    );
  }

  /// Remembers [version] so its notes are not shown again.
  Future<void> markSeen(String version) async {
    await _prefs.setString(_seenVersionKey, version);
  }

  Future<String> _resolveVersion() async {
    if (_currentVersionOverride != null) return _currentVersionOverride;
    final PackageInfo info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Cuts the `## [version]` section out of a Keep-a-Changelog document.
  static String? extractSection(String changelog, String version) {
    final List<String> lines = changelog.split('\n');
    final int start = lines.indexWhere(
      (String line) => line.startsWith('## [$version]'),
    );
    if (start == -1) return null;

    int end = lines.length;
    for (int i = start + 1; i < lines.length; i++) {
      if (lines[i].startsWith('## [')) {
        end = i;
        break;
      }
    }
    return lines.sublist(start + 1, end).join('\n').trim();
  }

  /// Strips developer noise from a changelog section for end users: the
  /// per-file `* path (Symbol): ...` lists with their indented continuation
  /// lines. Topic bullets become `•`, `### Added` headers become bold.
  static String simplifyForDisplay(String section) {
    final StringBuffer out = StringBuffer();
    bool inFileList = false;

    for (final String line in section.split('\n')) {
      final String trimmed = line.trimLeft();

      if (trimmed.startsWith('* ')) {
        inFileList = true;
        continue;
      }
      // Continuations of a file bullet are indented deeper than the bullet.
      if (inFileList && line.startsWith('    ') && trimmed.isNotEmpty) {
        continue;
      }
      inFileList = false;

      if (trimmed.startsWith('### ')) {
        out.writeln('**${trimmed.substring(4)}**');
      } else if (trimmed.startsWith('- ')) {
        out.writeln('• ${trimmed.substring(2)}');
      } else {
        out.writeln(line.trimRight());
      }
    }

    // Collapse the blank runs left behind by removed file lists.
    return out
        .toString()
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

final Provider<WhatsNewService> whatsNewServiceProvider =
    Provider<WhatsNewService>((Ref ref) {
  return WhatsNewService(prefs: ref.watch(sharedPreferencesProvider));
});

/// Resolves once per app run, on first read.
final FutureProvider<WhatsNewContent?> whatsNewProvider =
    FutureProvider<WhatsNewContent?>((Ref ref) {
  return ref.read(whatsNewServiceProvider).pendingWhatsNew();
});

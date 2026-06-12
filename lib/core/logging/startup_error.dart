// On-screen reporter for fatal startup errors.
//
// A failed DB migration or a throw in main() before runApp() would otherwise
// leave the user on a frozen splash logo with no clue what broke — and no
// logcat access on a release device. This module keeps the first fatal error
// in a global notifier; main(), the platform error handler and the splash
// screen feed it, and an overlay in app.dart paints the details over the UI so
// they can be read and copied off the device.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';

/// The first captured fatal startup error, or null while startup is healthy.
/// Watched by the overlay in `app.dart`.
final ValueNotifier<StartupErrorInfo?> startupError =
    ValueNotifier<StartupErrorInfo?>(null);

/// Records [error]/[stack] as the startup error and returns the effective
/// value. The first error wins, so a cascade of follow-up failures can't bury
/// the original cause.
StartupErrorInfo recordStartupError(
  String source,
  Object error,
  StackTrace? stack,
) {
  final StartupErrorInfo? existing = startupError.value;
  if (existing != null) {
    return existing;
  }
  final StartupErrorInfo info = StartupErrorInfo(
    source: source,
    error: error.toString(),
    stack: stack?.toString() ?? '<no stack trace>',
  );
  startupError.value = info;
  return info;
}

/// Captured error payload rendered by [StartupErrorView].
class StartupErrorInfo {
  const StartupErrorInfo({
    required this.source,
    required this.error,
    required this.stack,
  });

  /// Where the error was caught (e.g. `database`, `zone`, `_loadAppState`).
  final String source;

  /// `toString()` of the thrown object.
  final String error;

  /// `toString()` of the stack trace.
  final String stack;

  /// Full copyable text: source, message and stack joined for the clipboard.
  String get details => 'source: $source\n\n$error\n\n$stack';
}

/// Full-screen error dump. Used as an overlay over the running app and, for
/// crashes before runApp's real UI exists, inside [StartupErrorApp].
class StartupErrorView extends StatelessWidget {
  const StartupErrorView({required this.info, super.key});

  final StartupErrorInfo info;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 26,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      // The overlay also catches runtime zone errors, so the
                      // header doesn't claim "startup".
                      'Error',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _CopyButton(text: info.details),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'source: ${info.source}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SelectableText(
                        info.error,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 15,
                          height: 1.35,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SelectableText(
                        info.stack,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Copies [text] to the clipboard and flips its label to a confirmation for a
/// couple of seconds.
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _copy,
      icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
      label: Text(_copied ? 'Copied' : 'Copy'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        // The global theme forces minimumSize Size(infinity, 48); inside a
        // Row that means "BoxConstraints forces an infinite width".
        minimumSize: const Size(0, AppSpacing.buttonHeightCompact),
      ),
    );
  }
}

/// Standalone app for crashes that happen before runApp's real app is shown.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.info, super.key});

  final StartupErrorInfo info;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartupErrorView(info: info),
    );
  }
}

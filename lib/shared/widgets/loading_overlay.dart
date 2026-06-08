import 'package:flutter/material.dart';

/// Runs [action] behind a modal, non-dismissible spinner so the user sees that
/// something is happening during a slow step (a network fetch, a heavy save).
///
/// The overlay is always torn down, even if [action] throws. Reusable for any
/// awaited gap that would otherwise look frozen.
Future<T> withBlockingSpinner<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
  navigator.push(
    DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext _) => const PopScope<Object?>(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
  );
  try {
    return await action();
  } finally {
    if (navigator.mounted) navigator.pop();
  }
}

import 'package:core/rpc/protocol.dart';
import 'package:core/rpc/rpc_transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../core/selfhost/server_auth_token.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart' show AppRestartScope;
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Shown instead of the home screen when the server answers the first call
/// with 401: the browser has no token yet, or holds a stale one.
class ServerTokenScreen extends ConsumerStatefulWidget {
  const ServerTokenScreen({super.key});

  @override
  ConsumerState<ServerTokenScreen> createState() => _ServerTokenScreenState();
}

class _ServerTokenScreenState extends ConsumerState<ServerTokenScreen> {
  static const double _maxWidth = 480;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final String token = _controller.text.trim();
    if (token.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await ServerAuthToken.write(token);
    try {
      await ref.read(databaseServiceProvider).warmUp();
    } on Object catch (e) {
      if (!mounted) return;
      final bool rejected = e is RpcException && e.kind == kRpcErrorKindAuth;
      setState(() {
        _busy = false;
        _error = rejected ? S.of(context).serverTokenRejected : '$e';
      });
      // Submitting dropped the focus; hand it back with the text selected so
      // the next paste replaces the rejected value instead of appending.
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      _focusNode.requestFocus();
      return;
    }
    if (!mounted) return;
    // The boot copied the server-held keys before the token existed; the
    // restart redoes it and lands on the splash with the server answering.
    await AppRestartScope.restart(context);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(Icons.key, size: 48, color: AppColors.brand),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.serverTokenTitle,
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.serverTokenBody,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l.serverTokenFieldLabel,
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _connect(),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _busy ? null : _connect,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.serverTokenConnect),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

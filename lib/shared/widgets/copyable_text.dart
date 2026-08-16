import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Copies its text on tap; the icon flips to a checkmark as feedback.
class CopyableText extends StatefulWidget {
  const CopyableText({
    required this.text,
    required this.child,
    this.iconSize = 14,
    super.key,
  });

  final String text;

  final Widget child;

  final double iconSize;

  @override
  State<CopyableText> createState() => _CopyableTextState();
}

class _CopyableTextState extends State<CopyableText> {
  bool _hovering = false;
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _copied = false;
      }),
      child: GestureDetector(
        onTap: _copy,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(child: widget.child),
            if (_hovering) ...<Widget>[
              const SizedBox(width: 4),
              Icon(
                _copied ? Icons.check : Icons.copy,
                size: widget.iconSize,
                color: _copied
                    ? AppColors.success
                    : AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

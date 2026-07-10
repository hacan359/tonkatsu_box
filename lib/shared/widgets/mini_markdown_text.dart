import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../models/card_link.dart';
import '../models/collection_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'card_link_chip.dart';

/// Renders mini-markdown text: `**bold**`, `*italic*`, `[text](url)`, bare URLs
/// and `[[card:…]]` cross-links (chip when resolved via [resolvedLinks]).
class MiniMarkdownText extends StatefulWidget {
  const MiniMarkdownText({
    required this.text,
    this.style,
    this.resolvedLinks = const <CardLinkRef, CollectionItem>{},
    this.onCardLink,
    super.key,
  });

  final String text;
  final TextStyle? style;

  /// Pre-resolved card links; a missing key renders as an inactive link.
  final Map<CardLinkRef, CollectionItem> resolvedLinks;

  /// Card-link tap handler; `null` renders card links as inactive text.
  final void Function(CardLinkRef ref)? onCardLink;

  @override
  State<MiniMarkdownText> createState() => _MiniMarkdownTextState();
}

class _MiniMarkdownTextState extends State<MiniMarkdownText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(MiniMarkdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      for (final TapGestureRecognizer recognizer in _recognizers) {
        recognizer.dispose();
      }
      _recognizers.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _parse(widget.text, widget.style ?? AppTypography.body),
    );
  }

  static final RegExp _pattern = RegExp(
    r'\*\*(.+?)\*\*'
    r'|\*(.+?)\*'
    r'|\[([^\]]+)\]\(([^\)]+)\)'
    r'|(https?://\S+)'
    r'|\[\[card:([^\]|]*)(?:\|([^\]]*))?\]\]',
  );

  TextSpan _parse(String input, TextStyle baseStyle) {
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final List<InlineSpan> children = <InlineSpan>[];
    int lastEnd = 0;

    for (final RegExpMatch match in _pattern.allMatches(input)) {
      if (match.start > lastEnd) {
        children.add(TextSpan(
          text: input.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(1) != null) {
        // **bold**
        children.add(TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (match.group(2) != null) {
        // *italic*
        children.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null && match.group(4) != null) {
        // [text](url)
        children.add(_buildLink(match.group(3)!, match.group(4)!, baseStyle));
      } else if (match.group(5) != null) {
        // bare URL
        final String url = match.group(5)!;
        children.add(_buildLink(url, url, baseStyle));
      } else if (match.group(6) != null) {
        // [[card:payload|display]]
        children.add(_buildCardLink(match.group(6)!, match.group(7), baseStyle));
      }

      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      children.add(TextSpan(
        text: input.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return TextSpan(children: children);
  }

  TextSpan _buildLink(String text, String url, TextStyle baseStyle) {
    final TapGestureRecognizer recognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl(url);
    _recognizers.add(recognizer);

    return TextSpan(
      text: text,
      style: baseStyle.copyWith(
        color: AppColors.brand,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.brand,
      ),
      recognizer: recognizer,
    );
  }

  InlineSpan _buildCardLink(
    String payload,
    String? display,
    TextStyle baseStyle,
  ) {
    final CardLinkRef? ref = parseCardLink(payload, display);
    final CollectionItem? target =
        ref == null ? null : widget.resolvedLinks[ref];

    if (ref == null || target == null || widget.onCardLink == null) {
      final String label = ref?.display ?? (display ?? '').trim();
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Tooltip(
          message: S.of(context).cardLinkNotFound,
          child: Text(
            label.isEmpty ? S.of(context).cardLinkNotFound : label,
            style: baseStyle.copyWith(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: CardLinkChip(
        item: target,
        baseStyle: baseStyle,
        onTap: () => widget.onCardLink!(ref),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

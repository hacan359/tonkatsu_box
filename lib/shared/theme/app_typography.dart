// App typography.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/platform_features.dart';
import 'app_colors.dart';

/// Text styles for every level of the hierarchy.
///
/// Every style uses the Inter font and [AppColors.textPrimary] by default.
abstract final class AppTypography {
  /// Default font family.
  static const String fontFamily = 'Inter';

  /// The base scale is dense, tuned for desktop; on phones it reads too small,
  /// so every style gets +1px.
  static final double _bump = kIsMobile ? 1 : 0;

  /// Large heading (app name, screen title).
  static final TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26 + _bump,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Section heading.
  static final TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18 + _bump,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  /// Subheading (card title, list item).
  static final TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14 + _bump,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Body text.
  static final TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13 + _bump,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Small text (dates, meta information).
  static final TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12 + _bump,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Caption (badge, chip, label).
  static final TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11 + _bump,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    height: 1.2,
  );

  /// Title on a poster card.
  static final TextStyle posterTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13 + _bump,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Subtitle on a poster card (year, genre).
  static final TextStyle posterSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11 + _bump,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  /// [posterTitle] for a compact (landscape-phone) card.
  static TextStyle posterTitleFor({required bool compact}) =>
      compact ? posterTitle.copyWith(fontSize: 9) : posterTitle;

  /// [posterSubtitle] for a compact (landscape-phone) card.
  static TextStyle posterSubtitleFor({required bool compact}) =>
      compact ? posterSubtitle.copyWith(fontSize: 7) : posterSubtitle;

  static double _lineHeight(TextStyle style, TextScaler textScaler) =>
      textScaler.scale(style.fontSize ?? 14) * (style.height ?? 1.0);

  /// Source logo on a poster card, as a multiple of the subtitle font size.
  /// Lives here because it sets the subtitle row's height, which
  /// [posterTextBlockHeight] must budget for.
  static const double posterSourceLogoScale = 1.1;

  /// Height of a poster card's text block — two title lines plus one subtitle
  /// line — derived from the styles so it tracks the +1px bump and font scale.
  ///
  /// The subtitle row is as tall as the taller of its text and the source logo:
  /// the logo is [posterSourceLogoScale] of the font size, so budgeting the
  /// line height alone overflows a card that carries one.
  static double posterTextBlockHeight({
    required bool compact,
    required TextScaler textScaler,
  }) {
    final TextStyle subtitle = posterSubtitleFor(compact: compact);
    final double subtitleRow = math.max(
      _lineHeight(subtitle, textScaler),
      textScaler.scale(subtitle.fontSize ?? 11) * posterSourceLogoScale,
    );
    return (2 * _lineHeight(posterTitleFor(compact: compact), textScaler) +
            subtitleRow)
        .ceilToDouble();
  }

  /// Title on a grid card.
  static final TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13 + _bump,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Subtitle on a grid card.
  static final TextStyle cardSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11 + _bump,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );
}

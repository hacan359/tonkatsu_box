import 'package:flutter/widgets.dart';

/// The floating nav chrome reports what it covers through
/// `MediaQuery.padding`: the capsule at the bottom on phones, the rail on
/// the left on desktop. Scroll views and headers add the slice they need.
extension BottomInsetX on BuildContext {
  EdgeInsets get bottomInset =>
      EdgeInsets.only(bottom: MediaQuery.paddingOf(this).bottom);

  EdgeInsets get leftInset =>
      EdgeInsets.only(left: MediaQuery.paddingOf(this).left);

  EdgeInsets get topInset =>
      EdgeInsets.only(top: MediaQuery.paddingOf(this).top);

  /// Both at once, for a full-width scroll view that runs under the rail.
  EdgeInsets get navInset {
    final EdgeInsets p = MediaQuery.paddingOf(this);
    return EdgeInsets.only(left: p.left, bottom: p.bottom);
  }
}

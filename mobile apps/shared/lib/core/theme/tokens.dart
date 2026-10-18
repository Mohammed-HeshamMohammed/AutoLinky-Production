import 'package:flutter/widgets.dart';

/// Spacing scale: every gap and padding in the app is one of these.
abstract final class AppSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Side padding of a screen.
  static const double page = 24;
}

abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 22;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Widest a column of content gets (tablets, web): phones are never limited.
abstract final class AppLayout {
  static const double contentMaxWidth = 560;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

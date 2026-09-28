import 'package:flutter/widgets.dart';

/// The three layouts this app ships. Every responsive decision resolves to one
/// of these, never to a raw `MediaQuery.sizeOf(context).width > n` comparison
/// written at the call site: two screens that pick their own numbers stop
/// switching at the same width, and the app reflows in pieces.
enum FormFactor {
  /// Bottom navigation, one column, content edge to edge.
  compact,

  /// Navigation rail collapsed to icons, one centred column.
  medium,

  /// Navigation rail extended with labels, centred column plus side panel.
  expanded;

  bool get isCompact => this == FormFactor.compact;
  bool get isExpanded => this == FormFactor.expanded;

  /// True from tablet up — i.e. wherever the rail replaces the bottom bar.
  bool get hasRail => this != FormFactor.compact;
}

abstract final class AppBreakpoints {
  /// Where the bottom bar becomes a rail.
  static const medium = 700.0;

  /// Where the rail extends and the side panel appears.
  static const expanded = 1100.0;

  /// The widest a reading column is allowed to get. Past this, line length
  /// hurts legibility more than the extra space helps.
  static const contentMaxWidth = 640.0;

  static FormFactor of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// Pure so widget tests and the guard test can exercise the boundaries
  /// without pumping a MediaQuery.
  static FormFactor fromWidth(double width) => switch (width) {
    >= expanded => FormFactor.expanded,
    >= medium => FormFactor.medium,
    _ => FormFactor.compact,
  };
}

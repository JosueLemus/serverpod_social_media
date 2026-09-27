import 'package:flutter/widgets.dart';

abstract final class AppBreakpoints {
  static const tablet = 700.0;
  static const desktop = 1100.0;
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

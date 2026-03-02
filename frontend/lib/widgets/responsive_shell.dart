import 'package:flutter/material.dart';
import 'mobile_nav_scaffold.dart';
import 'desktop_nav_scaffold.dart';

class ResponsiveShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigationChanged;

  const ResponsiveShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigationChanged,
  });

  static const int mobileBreakpoint = 800;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return MobileNavScaffold(
            currentIndex: currentIndex,
            onNavigationChanged: onNavigationChanged,
            child: child,
          );
        } else {
          return DesktopNavScaffold(
            currentIndex: currentIndex,
            onNavigationChanged: onNavigationChanged,
            child: child,
          );
        }
      },
    );
  }
}

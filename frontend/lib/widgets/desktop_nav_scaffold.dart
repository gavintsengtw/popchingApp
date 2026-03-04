import 'package:flutter/material.dart';
import 'app_sidebar.dart';

class DesktopNavScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigationChanged;

  const DesktopNavScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 250,
            child: AppSidebar(
              currentIndex: currentIndex,
              onNavigationChanged: onNavigationChanged,
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

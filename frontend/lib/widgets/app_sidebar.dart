import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import '../providers/auth_provider.dart';

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigationChanged;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
  });

  IconData _getIconData(String? iconName) {
    if (iconName == null || iconName.isEmpty) return Icons.folder_outlined;
    switch (iconName.toLowerCase()) {
      case 'dashboard':
        return Icons.dashboard_outlined;
      case 'inventory':
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      case 'settings':
        return Icons.settings_outlined;
      case 'people':
      case 'person':
        return Icons.people_outline;
      case 'build':
      case 'widgets':
      case 'functions':
        return Icons.widgets_outlined;
      case 'security':
      case 'roles':
        return Icons.security_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavProvider>(
      builder: (context, nav, _) {
        final functions = nav.functions;

        if (nav.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (functions.isEmpty) {
          return const Center(child: Text('無可用功能'));
        }

        // Grouping logic:
        // Parents are functions WITHOUT a hyphen, e.g., 'fc001', 'fc002'
        // Children are functions WITH a hyphen, e.g., 'fc001-001', 'fc001-002'
        final Map<String, dynamic> parentMap = {};
        final Map<String, List<dynamic>> childrenMap = {};

        for (var i = 0; i < functions.length; i++) {
          final func = functions[i];
          final String funcId = func['funcId'] ?? '';

          // Inject original index so we know which index to route to when tapped
          func['_originalIndex'] = i;

          if (funcId.contains('-')) {
            // It's a child. Extract parent ID (e.g., 'fc001' from 'fc001-001')
            final parentId = funcId.split('-').first;
            childrenMap.putIfAbsent(parentId, () => []).add(func);
          } else {
            // It's a parent
            parentMap[funcId] = func;
          }
        }

        return ListView(
          controller: ScrollController(),
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  'CAMS 資產管理系統',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ...parentMap.values.map((parentFunc) {
              final String parentId = parentFunc['funcId'];
              final parentName = parentFunc['name'] ?? 'Unknown';
              final iconStr = parentFunc['icon'] as String?;
              final children = childrenMap[parentId] ?? [];

              if (children.isEmpty) {
                // Render as a single clickable tile if it has no children
                final int index = parentFunc['_originalIndex'];
                return ListTile(
                  leading: Icon(_getIconData(iconStr)),
                  title: Text(parentName),
                  selected: currentIndex == index,
                  onTap: () {
                    onNavigationChanged(index);
                    if (Scaffold.of(context).isDrawerOpen) {
                      Navigator.pop(context); // Close mobile drawer
                    }
                  },
                );
              }

              // Render as an expandable tile if it has children
              // Auto-expand if the currently selected index is one of its children
              final bool isExpanded = children.any(
                (c) => c['_originalIndex'] == currentIndex,
              );

              return ExpansionTile(
                initiallyExpanded: isExpanded,
                leading: Icon(_getIconData(iconStr)),
                title: Text(parentName),
                children: children.map((childFunc) {
                  final childName = childFunc['name'] ?? 'Unknown';
                  final childIconStr = childFunc['icon'] as String?;
                  final int index = childFunc['_originalIndex'];

                  return ListTile(
                    contentPadding: const EdgeInsets.only(
                      left: 48.0,
                      right: 16.0,
                    ),
                    leading: Icon(
                      childIconStr != null && childIconStr.isNotEmpty
                          ? _getIconData(childIconStr)
                          : Icons.radio_button_unchecked,
                      size: 20,
                    ),
                    title: Text(childName),
                    selected: currentIndex == index,
                    onTap: () {
                      onNavigationChanged(index);
                      if (Scaffold.of(context).isDrawerOpen) {
                        Navigator.pop(context); // Close mobile drawer
                      }
                    },
                  );
                }).toList(),
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('個人資料 (My Profile)'),
              onTap: () {
                if (Scaffold.of(context).isDrawerOpen) {
                  Navigator.pop(context); // Close mobile drawer
                }
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                '登出 (Logout)',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // Execute logout process
                context.read<AuthProvider>().logout();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }
}

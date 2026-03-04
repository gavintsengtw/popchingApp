import 'package:flutter/material.dart';
import 'change_password_page.dart';
import 'login_page.dart';
import 'widgets/responsive_shell.dart';
import 'pages/asset/asset_list_page.dart';
import 'pages/settings/settings_dashboard_page.dart';

import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/nav_provider.dart';
import 'pages/settings/function_list_page.dart';
import 'pages/settings/user_list_page.dart';
import 'pages/asset/main_class_page.dart';
import 'pages/asset/mid_class_page.dart';
import 'pages/asset/floor_page.dart';
import 'pages/asset/region_page.dart';
import 'pages/settings/role_list_page.dart';
import 'pages/settings/department_list_page.dart';
import 'pages/settings/role_function_list_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAMS 資產管理',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/home': (context) => const MainScreen(),
        '/login': (context) => const LoginPage(),
        '/change-password': (context) => const ChangePasswordPage(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch functions upon initializing the main screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavProvider>().loadFunctions();
    });
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Maps the database `funcId` to an actual Flutter Widget Page
  Widget _mapFuncIdToPage(String funcId) {
    switch (funcId) {
      case 'DASHBOARD': // Example ID
        return const Center(child: Text('儀表板 (Dashboard)'));
      case 'ASSET_MGMT':
        return const AssetListPage();
      case 'SYS_MGMT':
        return const SettingsDashboardPage();
      case 'USER_MGMT':
        return const UserListPage();
      case 'FUNC_MGMT':
        return const FunctionListPage();
      case 'fc001-001':
        return const MainClassPage();
      case 'fc001-002':
        return const MidClassPage();
      case 'fc001-003':
        return const FloorPage();
      case 'fc001-004':
        return const RegionPage();
      case 'fc003-001':
        return const RoleListPage();
      case 'fc003-002':
        return const UserListPage();
      case 'fc003-003':
        return const DepartmentListPage();
      case 'fc003-004':
        return const RoleFunctionListPage();
      default:
        // Fallback for unmapped or new database entries
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '頁面 [$funcId] 建置中 (Coming Soon)',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavProvider>(
      builder: (context, nav, child) {
        if (nav.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final functions = nav.functions;
        if (functions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('無權限 / 系統維護中')),
            body: const Center(child: Text('您目前沒有任何可用的系統功能功能選單。')),
          );
        }

        // Validate index is in bounds (in case functions change after reload)
        if (_selectedIndex >= functions.length) {
          _selectedIndex = 0;
        }

        // Determine the actual widget to show
        final currentFunc = functions[_selectedIndex];
        final String funcId = currentFunc['funcId'] ?? '';
        final Widget currentPage = _mapFuncIdToPage(funcId);

        return ResponsiveShell(
          currentIndex: _selectedIndex,
          onNavigationChanged: _onNavigationChanged,
          child: currentPage,
        );
      },
    );
  }
}

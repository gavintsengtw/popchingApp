import 'package:flutter/material.dart';
import 'change_password_page.dart';
import 'login_page.dart';
import 'widgets/responsive_shell.dart';
import 'pages/asset/asset_list_page.dart';

void main() {
  runApp(const MyApp());
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

  static const List<Widget> _pages = <Widget>[
    Center(child: Text('儀表板 (Dashboard)')),
    AssetListPage(),
    Center(child: Text('設定 (Settings)')),
  ];

  void _onNavigationChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      currentIndex: _selectedIndex,
      onNavigationChanged: _onNavigationChanged,
      child: _pages[_selectedIndex],
    );
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/asset_model.dart';
import '../pages/asset/asset_form_page.dart';
import '../config/api_config.dart';
import '../pages/scan/qr_scan_page.dart';

class MobileNavScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigationChanged;

  const MobileNavScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigationChanged,
  });

  Future<void> _handleScan(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScanPage()),
    );

    if (result != null && result is String && context.mounted) {
      final String scannedCode = result;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      try {
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: 'jwt_token');

        final response = await http.get(
          Uri.parse(ApiConfig.assetsUrl),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (context.mounted) Navigator.pop(context); // Close loading

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(
            utf8.decode(response.bodyBytes),
          );
          final assets = data.map((e) => Asset.fromJson(e)).toList();

          try {
            final asset = assets.firstWhere((a) => a.assetCode == scannedCode);
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssetFormPage(asset: asset),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('找不到資產編號: $scannedCode')));
            }
          }
        }
      } catch (e) {
        if (context.mounted) Navigator.pop(context); // Close loading on error
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleScan(context),
        child: const Icon(Icons.qr_code_scanner),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onNavigationChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '儀表板',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '資產',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

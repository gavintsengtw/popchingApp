import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../models/asset_model.dart';
import '../pages/asset/asset_form_page.dart';
import '../pages/scan/qr_scan_page.dart';
import 'app_sidebar.dart';

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
        final apiService = ApiService();
        final response = await apiService.get('/assets');

        if (context.mounted) Navigator.pop(context); // Close loading

        if (response != null && response is List) {
          final assets = response.map((e) => Asset.fromJson(e)).toList();

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
      appBar: AppBar(title: const Text('CAMS 資產管理系統'), elevation: 1),
      drawer: Drawer(
        child: AppSidebar(
          currentIndex: currentIndex,
          onNavigationChanged: onNavigationChanged,
        ),
      ),
      body: Scaffold(
        body: child,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _handleScan(context),
          child: const Icon(Icons.qr_code_scanner),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

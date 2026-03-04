import 'package:flutter/material.dart';
import '../../models/asset_model.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

import 'asset_form_page.dart';
import '../../config/api_config.dart';

import '../../services/api_service.dart';

class AssetListPage extends StatefulWidget {
  const AssetListPage({super.key});

  @override
  State<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends State<AssetListPage> {
  final ApiService _apiService = ApiService();
  List<Asset> _assets = [];
  List<Asset> _filteredAssets = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAssets();
    _searchController.addListener(_filterAssets);
  }

  Future<void> _fetchAssets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/assets');

      if (response != null && response is List) {
        setState(() {
          _assets = response.map((e) => Asset.fromJson(e)).toList();
          _filteredAssets = _assets;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load assets: Invalid response format'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterAssets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAssets = _assets.where((asset) {
        return asset.name.toLowerCase().contains(query) ||
            asset.assetCode.toLowerCase().contains(query) ||
            (asset.custodian?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _navigateToForm([Asset? asset]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AssetFormPage(asset: asset)),
    );

    if (result == true) {
      _fetchAssets();
    }
  }

  Future<void> _deleteAsset(String id) async {
    try {
      await _apiService.delete('/assets/$id');

      // Assuming successful delete returns some response or null if empty
      _fetchAssets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('資產列表'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAssets),
          if (authProvider.canAdd)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToForm(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '搜尋 (名稱, 編號, 保管人)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth > 800 ? 3 : 1,
                          childAspectRatio: 3, // Wide cards
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredAssets.length,
                        itemBuilder: (context, index) {
                          final asset = _filteredAssets[index];
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              leading: asset.images.isNotEmpty
                                  ? Image.network(
                                      ApiConfig.resolveImageUrl(
                                        asset.images.first.url,
                                      ),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.image),
                                    )
                                  : const Icon(Icons.inventory_2, size: 40),
                              title: Text(asset.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('編號: ${asset.assetCode}'),
                                  Text('保管人: ${asset.custodian ?? "無"}'),
                                ],
                              ),
                              onTap: authProvider.canEdit
                                  ? () => _navigateToForm(asset)
                                  : null,
                              trailing: authProvider.canDelete
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteAsset(asset.id),
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

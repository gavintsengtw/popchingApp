import 'package:flutter/material.dart';
import '../../models/asset_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'asset_form_page.dart';
import '../../config/api_config.dart';

class AssetListPage extends StatefulWidget {
  const AssetListPage({super.key});

  @override
  State<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends State<AssetListPage> {
  List<Asset> _assets = [];
  List<Asset> _filteredAssets = [];
  bool _isLoading = true;
  final _storage = const FlutterSecureStorage();
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
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(ApiConfig.assetsUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _assets = data.map((e) => Asset.fromJson(e)).toList();
          _filteredAssets = _assets;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load assets: ${response.statusCode}'),
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
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${ApiConfig.assetsUrl}/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchAssets();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${response.statusCode}')),
          );
        }
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('資產列表'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAssets),
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
                              onTap: () => _navigateToForm(asset),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteAsset(asset.id),
                              ),
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

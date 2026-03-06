import 'package:flutter/material.dart';
import '../../models/asset_model.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'asset_form_page.dart';
import '../../services/api_service.dart';

class DropdownItem {
  final String value;
  final String label;
  DropdownItem({required this.value, required this.label});
}

class AssetListPage extends StatefulWidget {
  const AssetListPage({super.key});

  @override
  State<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends State<AssetListPage> {
  final ApiService _apiService = ApiService();

  // Search state
  String? _mainClass;
  String? _midClass;
  String? _year;
  String? _custodian;
  String? _location;
  final TextEditingController _keywordController = TextEditingController();

  // Pagination state
  int _currentPage = 0;
  int _pageSize = 10;
  int _totalRecords = 0;
  bool _isLoading = false;

  List<Asset> _assets = [];
  final Set<String> _selectedAssetIds = {};

  // Dropdown options (mocked or loaded from API in real scenario)
  List<DropdownItem> _mainClasses = []; // 設備大類
  List<DropdownItem> _midClasses = []; // 設備中類
  final List<DropdownItem> _years = List.generate(
    20,
    (index) => DropdownItem(
      value: (100 + index).toString(),
      label: (100 + index).toString(),
    ),
  ); // 選擇民國年
  List<DropdownItem> _custodians = [];
  List<DropdownItem> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchMainClasses();
    _fetchMidClasses();
    _fetchCustodians();
    _fetchLocations();
    _fetchAssets();
  }

  Future<void> _fetchMainClasses() async {
    try {
      final response = await _apiService.get('/dictionary/code/MAINCLASS');
      if (response != null && response is List) {
        setState(() {
          _mainClasses = response
              .map<DropdownItem>(
                (item) => DropdownItem(
                  value: item['itemId']?.toString() ?? '',
                  label: item['itemName']?.toString() ?? '',
                ),
              )
              .where((item) => item.label.isNotEmpty && item.value.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching main classes: $e');
    }
  }

  Future<void> _fetchMidClasses() async {
    try {
      final response = await _apiService.get('/dictionary/code/MIDCLASS');
      if (response != null && response is List) {
        setState(() {
          _midClasses = response
              .map<DropdownItem>(
                (item) => DropdownItem(
                  value: item['itemId']?.toString() ?? '',
                  label: item['itemName']?.toString() ?? '',
                ),
              )
              .where((item) => item.label.isNotEmpty && item.value.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching mid classes: $e');
    }
  }

  Future<void> _fetchCustodians() async {
    try {
      final response = await _apiService.get('/users');
      if (response != null && response is List) {
        setState(() {
          _custodians = response
              .map<DropdownItem>(
                (user) => DropdownItem(
                  value: user['username']?.toString() ?? '',
                  label: user['fullName']?.toString() ?? '',
                ),
              )
              .where((item) => item.label.isNotEmpty && item.value.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching custodians: $e');
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await _apiService.get('/dictionary/code/FLOOR');
      if (response != null && response is List) {
        setState(() {
          _locations = response
              .map<DropdownItem>(
                (item) => DropdownItem(
                  value: item['itemId']?.toString() ?? '',
                  label: item['itemName']?.toString() ?? '',
                ),
              )
              .where((item) => item.label.isNotEmpty && item.value.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    }
  }

  Future<void> _fetchAssets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'page': _currentPage.toString(),
        'size': _pageSize.toString(),
      };

      if (_mainClass != null && _mainClass!.isNotEmpty) {
        queryParams['mainClass'] = _mainClass;
      }
      if (_midClass != null && _midClass!.isNotEmpty) {
        queryParams['midClass'] = _midClass;
      }
      if (_year != null && _year!.isNotEmpty) {
        queryParams['year'] = _year;
      }
      if (_custodian != null && _custodian!.isNotEmpty) {
        queryParams['custodian'] = _custodian;
      }
      if (_location != null && _location!.isNotEmpty) {
        queryParams['location'] = _location;
      }
      if (_keywordController.text.isNotEmpty) {
        queryParams['keyword'] = _keywordController.text;
      }

      // Add a timestamp to bypass browser caching which is common in Flutter Web
      queryParams['t'] = DateTime.now().millisecondsSinceEpoch.toString();

      // Construct query string
      final queryString = Uri(queryParameters: queryParams).query;
      final response = await _apiService.get('/assets?$queryString');

      if (response != null && response is Map<String, dynamic>) {
        final content = response['content'] as List<dynamic>? ?? [];
        setState(() {
          _assets = content.map((e) => Asset.fromJson(e)).toList();
          _totalRecords = response['totalElements'] ?? 0;
          _selectedAssetIds
              .clear(); // Clear selections when fetching new page or search
        });
      } else {
        _showError(
          '無法載入資料: 回傳格式錯誤/Failed to load assets: Invalid response format',
        );
      }
    } catch (e) {
      _showError('發生錯誤/Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _resetSearch() {
    setState(() {
      _mainClass = null;
      _midClass = null;
      _year = null;
      _custodian = null;
      _location = null;
      _keywordController.clear();
      _currentPage = 0;
    });
    _fetchAssets();
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

  Future<void> _voidAsset(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認作廢 (Confirm Void)'),
        content: const Text(
          '確定要作廢此筆資產嗎？/Are you sure you want to void this asset?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消 (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '作廢 (Void)',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.delete('/assets/$id'); // In backend this now voids
      _fetchAssets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('作廢成功 (Voided Successfully)')),
        );
      }
    } catch (e) {
      _showError('發生錯誤/Error: $e');
    }
  }

  Future<void> _showBatchCustodianDialog() async {
    if (_selectedAssetIds.isEmpty) return;

    String? selectedCustodian;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('批次變更保管人'),
          content: StatefulBuilder(
            builder: (context, setStateSB) {
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '選擇新保管人',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedCustodian,
                items: _custodians
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.value,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setStateSB(() {
                    selectedCustodian = val;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCustodian != null) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('請選擇保管人')));
                }
              },
              child: const Text('確認'),
            ),
          ],
        );
      },
    );

    if (result == true && selectedCustodian != null) {
      try {
        setState(() => _isLoading = true);
        await _apiService.put('/assets/batch/custodian', {
          'assetIds': _selectedAssetIds.toList(),
          'newValue': selectedCustodian,
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('批次變更保管人成功')));
        }
        _fetchAssets();
      } catch (e) {
        _showError('發生錯誤: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showBatchLocationDialog() async {
    if (_selectedAssetIds.isEmpty) return;

    String? selectedLocation;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('批次變更存放位置'),
          content: StatefulBuilder(
            builder: (context, setStateSB) {
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '選擇新存放位置',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedLocation,
                items: _locations
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.value,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setStateSB(() {
                    selectedLocation = val;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedLocation != null) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('請選擇存放位置')));
                }
              },
              child: const Text('確認'),
            ),
          ],
        );
      },
    );

    if (result == true && selectedLocation != null) {
      try {
        setState(() => _isLoading = true);
        await _apiService.put('/assets/batch/location', {
          'assetIds': _selectedAssetIds.toList(),
          'newValue': selectedLocation,
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('批次變更存放位置成功')));
        }
        _fetchAssets();
      } catch (e) {
        _showError('發生錯誤: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSearchPanel() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '查詢條件',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              children: [
                _buildDropdown(
                  '設備大類',
                  _mainClass,
                  _mainClasses,
                  (val) => setState(() => _mainClass = val),
                ),
                _buildDropdown(
                  '設備中類',
                  _midClass,
                  _midClasses,
                  (val) => setState(() => _midClass = val),
                ),
                _buildDropdown(
                  '購買年度(民國年)',
                  _year,
                  _years,
                  (val) => setState(() => _year = val),
                ),
                _buildDropdown(
                  '保管人',
                  _custodian,
                  _custodians,
                  (val) => setState(() => _custodian = val),
                ),
                _buildDropdown(
                  '存放位置',
                  _location,
                  _locations,
                  (val) => setState(() => _location = val),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _keywordController,
                    decoration: const InputDecoration(
                      labelText: '全文檢索 (名稱, 型號, 編號)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) {
                      _currentPage = 0;
                      _fetchAssets();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _resetSearch,
                  icon: const Icon(Icons.clear),
                  label: const Text('清除條件'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentPage = 0;
                    });
                    _fetchAssets();
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('查詢'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<DropdownItem> items,
    ValueChanged<String?> onChanged,
  ) {
    // 檢查目前選取的值是否存在於 items 中，避免 value 不存在導致 error
    bool valueExists = items.any((item) => item.value == value);
    String? safeValue = valueExists ? value : null;

    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        initialValue: safeValue,
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('全部')),
          ...items.map(
            (e) =>
                DropdownMenuItem<String>(value: e.value, child: Text(e.label)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設備清單'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('新增設備', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () => _navigateToForm(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchPanel(),
          Expanded(
            child: _isLoading && _assets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    margin: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Button row for batch updates
                        if (authProvider.canEdit)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _selectedAssetIds.isNotEmpty
                                      ? _showBatchCustodianDialog
                                      : null,
                                  icon: const Icon(Icons.person),
                                  label: const Text('變更保管人'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _selectedAssetIds.isNotEmpty
                                      ? _showBatchLocationDialog
                                      : null,
                                  icon: const Icon(Icons.location_on),
                                  label: const Text('變更存放位置'),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '已選取 ${_selectedAssetIds.length} 筆',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Data Table container
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                onSelectAll: (bool? selected) {
                                  setState(() {
                                    if (selected == true) {
                                      _selectedAssetIds.addAll(
                                        _assets.map((a) => a.id),
                                      );
                                    } else {
                                      _selectedAssetIds.clear();
                                    }
                                  });
                                },
                                headingRowColor: WidgetStateProperty.all(
                                  Colors.grey.shade200,
                                ),
                                columns: const [
                                  DataColumn(label: Text('動作 (Action)')),
                                  DataColumn(label: Text('資產編號')),
                                  DataColumn(label: Text('名稱')),
                                  DataColumn(label: Text('購買日期')),
                                  DataColumn(label: Text('型號/規格')),
                                  DataColumn(label: Text('數量')),
                                  DataColumn(label: Text('保管人/部門')),
                                  DataColumn(label: Text('存放位置')),
                                ],
                                rows: _assets
                                    .map(
                                      (asset) => DataRow(
                                        selected: _selectedAssetIds.contains(
                                          asset.id,
                                        ),
                                        onSelectChanged: (bool? selected) {
                                          setState(() {
                                            if (selected == true) {
                                              _selectedAssetIds.add(asset.id);
                                            } else {
                                              _selectedAssetIds.remove(
                                                asset.id,
                                              );
                                            }
                                          });
                                        },
                                        cells: [
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (authProvider.canEdit)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _navigateToForm(asset),
                                                    tooltip: '編輯',
                                                  ),
                                                if (authProvider.canDelete)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.block,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _voidAsset(asset.id),
                                                    tooltip: '作廢',
                                                  ),
                                              ],
                                            ),
                                          ),
                                          DataCell(Text(asset.assetCode)),
                                          DataCell(Text(asset.name)),
                                          DataCell(
                                            Text(
                                              asset.purchaseDate != null
                                                  ? "${asset.purchaseDate!.year}-${asset.purchaseDate!.month.toString().padLeft(2, '0')}-${asset.purchaseDate!.day.toString().padLeft(2, '0')}"
                                                  : '',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${asset.brand ?? ""} / ${asset.specification ?? ""}',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              asset.quantity?.toString() ?? '',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${asset.custodianName ?? asset.custodian ?? ""} / ${asset.departmentName ?? asset.userDept ?? ""}',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              asset.locationName ??
                                                  asset.location ??
                                                  '',
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                        // Pagination Controls
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('共 $_totalRecords 筆資料'),
                              const SizedBox(width: 16),
                              const Text('每頁顯示:'),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: _pageSize,
                                items: [10, 20, 50, 100].map((size) {
                                  return DropdownMenuItem<int>(
                                    value: size,
                                    child: Text(size.toString()),
                                  );
                                }).toList(),
                                onChanged: (int? newSize) {
                                  if (newSize != null) {
                                    setState(() {
                                      _pageSize = newSize;
                                      _currentPage = 0;
                                    });
                                    _fetchAssets();
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 0
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                        _fetchAssets();
                                      }
                                    : null,
                              ),
                              Text('第 ${_currentPage + 1} 頁'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed:
                                    (_currentPage + 1) * _pageSize <
                                        _totalRecords
                                    ? () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                        _fetchAssets();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

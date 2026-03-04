import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegionPage extends StatefulWidget {
  const RegionPage({super.key});

  @override
  State<RegionPage> createState() => _RegionPageState();
}

class _RegionPageState extends State<RegionPage> {
  final ApiService _apiService = ApiService();
  final String _parentCodeId = 'FLOOR';
  final String _regionCodeId = 'REGION';
  final String _title = '位置區域設定';

  List<dynamic> _floorItems = [];
  List<dynamic> _allRegionItems = [];

  String? _selectedFloorId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final floorRes = await _apiService.get('/dictionary/code/$_parentCodeId');
      final regionRes = await _apiService.get(
        '/dictionary/code/$_regionCodeId',
      );

      setState(() {
        _floorItems = floorRes as List;
        _allRegionItems = regionRes as List;

        // Default to first floor if none selected yet
        if (_selectedFloorId == null && _floorItems.isNotEmpty) {
          _selectedFloorId = _floorItems.first['itemId']?.toString();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Filter regions based on the selected Floor ID
  // It should match 'F004-%' meaning it starts with 'F004-'
  List<dynamic> get _filteredRegionItems {
    if (_selectedFloorId == null) return [];
    final prefix = '$_selectedFloorId-';

    return _allRegionItems.where((item) {
      final itemId = item['itemId']?.toString() ?? '';
      return itemId.startsWith(prefix);
    }).toList();
  }

  // Auto-generates ITEMID: {FloorID}-{3-digit sequence}
  String _generateNextItemId(String floorId) {
    int maxCount = 0;
    final prefix = '$floorId-';

    // Find all children belonging to this specific floor
    final children = _allRegionItems.where((item) {
      final itemId = item['itemId']?.toString() ?? '';
      return itemId.startsWith(prefix);
    }).toList();

    // Parse the sequence number suffix
    for (var child in children) {
      String childId = child['itemId']?.toString() ?? '';
      if (childId.length > prefix.length) {
        String numPart = childId.substring(prefix.length);
        int? num = int.tryParse(numPart);
        if (num != null && num > maxCount) {
          maxCount = num;
        }
      }
    }

    maxCount++; // Next sequence number
    String paddedNum = maxCount.toString().padLeft(3, '0');
    return '$prefix$paddedNum';
  }

  // Recovers the FloorID out of a given RegionID for edit mode
  String? getFloorIdFromRegionId(String regionId) {
    for (var floor in _floorItems) {
      final fId = floor['itemId']?.toString() ?? '';
      if (fId.isNotEmpty && regionId.startsWith('$fId-')) {
        return fId;
      }
    }
    return null;
  }

  Future<void> _showItemDialog({Map<String, dynamic>? item}) async {
    final bool isEdit = item != null;
    final originalItemId = item?['itemId'] as String? ?? '';
    final nameController = TextEditingController(
      text: item?['itemName'] as String? ?? '',
    );

    // Set up dialog state parent tracker
    String? dialogFloorId = isEdit
        ? getFloorIdFromRegionId(originalItemId)
        : _selectedFloorId;

    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Determine preview ID
            String generatedId = '';
            if (isEdit) {
              generatedId = originalItemId;
            } else if (dialogFloorId != null) {
              generatedId = _generateNextItemId(dialogFloorId!);
            }

            return AlertDialog(
              title: Text(isEdit ? '編輯位置區域' : '新增位置區域'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Floor Dropdown
                    DropdownButton<String>(
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      value: dialogFloorId,
                      hint: const Text('選擇存放位置 (FLOOR)'),
                      items: _floorItems.map((f) {
                        return DropdownMenuItem<String>(
                          value: f['itemId']?.toString() ?? '',
                          child: Text(f['itemName']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: isEdit
                          ? null
                          : (val) {
                              setDialogState(() {
                                dialogFloorId = val;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    // Auto-assigned ITEMID display
                    TextField(
                      controller: TextEditingController(text: generatedId),
                      decoration: const InputDecoration(
                        labelText: '區域代碼 (ITEMID)',
                        hintText: '系統自動取號 (FloorID-三碼)',
                      ),
                      enabled: false,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    // Region Name Input
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '區域名稱 (ITEMNAME)',
                        hintText: '例如: 庫房A-第1排',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dialogFloorId == null ||
                        nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('存放位置與區域名稱不可為空')),
                      );
                      return;
                    }

                    try {
                      final name = nameController.text.trim();
                      final payload = {
                        'codeId': _regionCodeId,
                        'itemId': generatedId,
                        'itemName': name,
                        'deleteMark': null,
                      };

                      if (isEdit) {
                        await _apiService.put(
                          '/dictionary/$_regionCodeId/$originalItemId',
                          payload,
                        );
                      } else {
                        await _apiService.post('/dictionary', payload);
                      }

                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('儲存失敗: $e')));
                      }
                    }
                  },
                  child: const Text('儲存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (success == true) {
      _fetchData();
    }
  }

  Future<void> _deleteItem(String itemId, String itemName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除位置區域 "$itemName" ($itemId) 嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.delete('/dictionary/$_regionCodeId/$itemId');
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刪除失敗: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('載入失敗: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchData, child: const Text('重試')),
          ],
        ),
      );
    } else if (_floorItems.isEmpty) {
      content = const Center(child: Text('查無存放位置資料，請先設定存放位置 (FLOOR)'));
    } else {
      final filteredList = _filteredRegionItems;

      content = Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                const Text(
                  '過濾條件：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedFloorId,
                    hint: const Text('選擇存放位置 (FLOOR)'),
                    items: _floorItems.map((f) {
                      return DropdownMenuItem<String>(
                        value: f['itemId']?.toString() ?? '',
                        child: Text(f['itemName']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedFloorId = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // List View
          Expanded(
            child: filteredList.isEmpty
                ? const Center(child: Text('此存放位置底下目前沒有任何區域資料'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final itemId = item['itemId']?.toString() ?? '';
                      final itemName = item['itemName']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(
                              Icons.share_location,
                              color: Colors.orange,
                            ),
                          ),
                          title: Text(itemName),
                          subtitle: Text('區域代碼: $itemId'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (authProvider.canEdit)
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showItemDialog(item: item),
                                ),
                              if (authProvider.canDelete)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _deleteItem(itemId, itemName),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: content,
      floatingActionButton:
          (_floorItems.isEmpty || _isLoading) || !authProvider.canAdd
          ? null
          : FloatingActionButton(
              onPressed: () => _showItemDialog(),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

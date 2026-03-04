import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class FloorPage extends StatefulWidget {
  const FloorPage({super.key});

  @override
  State<FloorPage> createState() => _FloorPageState();
}

class _FloorPageState extends State<FloorPage> {
  final ApiService _apiService = ApiService();
  final String _codeId = 'FLOOR';
  final String _title = '存放位置設定';

  List<dynamic> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.get('/dictionary/code/$_codeId');
      setState(() {
        _items = response as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Auto-generates ITEMID in format F + 3 digits (e.g. F001)
  String _generateNextItemId() {
    int maxCount = 0;

    // Parse all existing F-prefixed items to find the highest number
    for (var item in _items) {
      final String id = item['itemId']?.toString().toUpperCase() ?? '';
      if (id.startsWith('F') && id.length > 1) {
        final String numStr = id.substring(1);
        final int? num = int.tryParse(numStr);
        if (num != null && num > maxCount) {
          maxCount = num;
        }
      }
    }

    maxCount++; // Go to next sequence

    // Pad to 3 digits minimum (001, 010, 100)
    final String paddedNum = maxCount.toString().padLeft(3, '0');
    return 'F$paddedNum';
  }

  Future<void> _showItemDialog({Map<String, dynamic>? item}) async {
    final bool isEdit = item != null;
    final originalItemId = item?['itemId'] as String? ?? '';

    // Handle Add vs Edit payload mapping
    final String targetId = isEdit ? originalItemId : _generateNextItemId();
    final nameController = TextEditingController(
      text: item?['itemName'] as String? ?? '',
    );

    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? '編輯存放位置' : '新增存放位置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: TextEditingController(text: targetId),
                  decoration: const InputDecoration(
                    labelText: '位置代碼 (ITEMID)',
                    hintText: '系統自動取號 (F+三碼)',
                  ),
                  enabled:
                      false, // Enforce read-only constraint for both Edit and Add primary keys
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '位置名稱 (ITEMNAME)',
                    hintText: '例如: 板橋庫房A',
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('名稱不可為空')));
                  return;
                }

                try {
                  final payload = {
                    'codeId': _codeId,
                    'itemId': targetId,
                    'itemName': name,
                    'deleteMark': null,
                  };

                  if (isEdit) {
                    await _apiService.put(
                      '/dictionary/$_codeId/$originalItemId',
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

    if (success == true) {
      _fetchItems();
    }
  }

  Future<void> _deleteItem(String itemId, String itemName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除存放位置 "$itemName" ($itemId) 嗎？'),
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
      await _apiService.delete('/dictionary/$_codeId/$itemId');
      _fetchItems();
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
            ElevatedButton(onPressed: _fetchItems, child: const Text('重試')),
          ],
        ),
      );
    } else if (_items.isEmpty) {
      content = const Center(child: Text('目前沒有任何存放位置資料'));
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final itemId = item['itemId']?.toString() ?? '';
          final itemName = item['itemName']?.toString() ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: const Icon(Icons.location_on, color: Colors.teal),
              ),
              title: Text(
                itemName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('位置代碼: $itemId'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (authProvider.canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showItemDialog(item: item),
                    ),
                  if (authProvider.canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(itemId, itemName),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchItems),
        ],
      ),
      body: content,
      floatingActionButton: authProvider.canAdd
          ? FloatingActionButton(
              onPressed: () => _showItemDialog(),
              backgroundColor: Colors.teal,
              // Using explicit specific icon to match thematic color mapping
              child: const Icon(Icons.add_location_alt, color: Colors.white),
            )
          : null,
    );
  }
}

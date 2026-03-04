import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MainClassPage extends StatefulWidget {
  const MainClassPage({super.key});

  @override
  State<MainClassPage> createState() => _MainClassPageState();
}

class _MainClassPageState extends State<MainClassPage> {
  final ApiService _apiService = ApiService();
  final String _codeId = 'MAINCLASS';
  final String _title = '設備大類設定';

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

  Future<void> _showItemDialog({Map<String, dynamic>? item}) async {
    final bool isEdit = item != null;
    final originalItemId = item?['itemId'] as String? ?? '';

    final idController = TextEditingController(text: originalItemId);
    final nameController = TextEditingController(
      text: item?['itemName'] as String? ?? '',
    );

    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? '編輯類別' : '新增類別'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: '類別代碼 (例如 A, B, C)',
                  ),
                  enabled: !isEdit, // Cannot change primary key components
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名稱 (例如 A.電腦設備)',
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
                final id = idController.text.trim();
                final name = nameController.text.trim();
                if (id.isEmpty || name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('代碼與名稱不可為空')));
                  return;
                }

                try {
                  final payload = {
                    'codeId': _codeId,
                    'itemId': id,
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

  Future<void> _deleteItem(String itemId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除代碼為 "$itemId" 的類別嗎？'),
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
      content = const Center(child: Text('目前沒有任何大類資料'));
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
              title: Text(itemName),
              subtitle: Text('類別代碼: $itemId'),
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
                      onPressed: () => _deleteItem(itemId),
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
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

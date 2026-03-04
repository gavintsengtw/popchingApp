import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MidClassPage extends StatefulWidget {
  const MidClassPage({super.key});

  @override
  State<MidClassPage> createState() => _MidClassPageState();
}

class _MidClassPageState extends State<MidClassPage> {
  final ApiService _apiService = ApiService();
  final String _mainCodeId = 'MAINCLASS';
  final String _midCodeId = 'MIDCLASS';
  final String _title = '設備中類設定';

  List<dynamic> _parentItems = [];
  List<dynamic> _allMidItems = [];

  String? _selectedParentId;
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
      final parentRes = await _apiService.get('/dictionary/code/$_mainCodeId');
      final midRes = await _apiService.get('/dictionary/code/$_midCodeId');

      setState(() {
        _parentItems = parentRes as List;
        _allMidItems = midRes as List;

        // Select first parent by default if available and none selected
        if (_selectedParentId == null && _parentItems.isNotEmpty) {
          _selectedParentId = _parentItems.first['itemId']?.toString();
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

  // Gets filtered list
  List<dynamic> get _filteredMidItems {
    if (_selectedParentId == null) return [];
    return _allMidItems.where((item) {
      final itemId = item['itemId']?.toString() ?? '';
      return itemId.startsWith(_selectedParentId!);
    }).toList();
  }

  // Generates next ItemID for a given parent ID
  String _generateNextItemId(String parentId) {
    final children = _allMidItems.where((e) {
      final id = e['itemId']?.toString() ?? '';
      return id.startsWith(parentId);
    }).toList();

    int maxCount = 0;
    for (var child in children) {
      String cId = child['itemId']?.toString() ?? '';
      if (cId.length > parentId.length) {
        String numPart = cId.substring(parentId.length);
        int? num = int.tryParse(numPart);
        if (num != null && num > maxCount) {
          maxCount = num;
        }
      }
    }

    maxCount++; // Next sequence
    String numStr = maxCount.toString().padLeft(2, '0');
    return '$parentId$numStr';
  }

  // Extracts the simple name without the 'A01.' prefix for editing
  String _extractInputName(String originalItemId, String originalItemName) {
    if (originalItemName.startsWith('$originalItemId.')) {
      return originalItemName.substring(originalItemId.length + 1);
    }
    return originalItemName;
  }

  Future<void> _showItemDialog({Map<String, dynamic>? item}) async {
    final bool isEdit = item != null;
    final originalItemId = item?['itemId'] as String? ?? '';
    final originalItemName = item?['itemName'] as String? ?? '';

    // For edit, extract input. For add, start empty.
    final nameController = TextEditingController(
      text: isEdit ? _extractInputName(originalItemId, originalItemName) : '',
    );

    // Temporarily track dialog parent state (incase user changes dropdown inside add dialog)
    String? dialogParentId = isEdit
        ? getParentIdFromMidId(originalItemId)
        : _selectedParentId;

    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Preview variables
            String previewItemId = isEdit ? originalItemId : '';
            String previewItemName = '';

            if (!isEdit && dialogParentId != null) {
              previewItemId = _generateNextItemId(dialogParentId!);
            }

            if (nameController.text.trim().isNotEmpty) {
              previewItemName = '$previewItemId.${nameController.text.trim()}';
            }

            return AlertDialog(
              title: Text(isEdit ? '編輯設備中類' : '新增設備中類'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parent Dropdown Selector
                    DropdownButton<String>(
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      value: dialogParentId,
                      hint: const Text('設備大類 (MAINCLASS)'),
                      items: _parentItems.map((p) {
                        return DropdownMenuItem<String>(
                          value: p['itemId']?.toString() ?? '',
                          child: Text(p['itemName']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: isEdit
                          ? null
                          : (val) {
                              setDialogState(() {
                                dialogParentId = val;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    // Name Input
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '輸入名稱 (例如: 螢幕)',
                        hintText: '只需要輸入純名稱，系統會自動加上編號前綴',
                      ),
                      onChanged: (val) {
                        setDialogState(() {}); // Trigger preview update
                      },
                    ),
                    const SizedBox(height: 16),
                    // Live Preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '預覽存檔結果:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('編號 (ITEMID): $previewItemId'),
                          Text('名稱 (ITEMNAME): $previewItemName'),
                        ],
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
                    if (dialogParentId == null ||
                        nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('大類與名稱不可為空')),
                      );
                      return;
                    }

                    try {
                      final generatedId = previewItemId;
                      final generatedName = previewItemName;

                      final payload = {
                        'codeId': _midCodeId,
                        'itemId': generatedId,
                        'itemName': generatedName,
                        'deleteMark': null,
                      };

                      if (isEdit) {
                        await _apiService.put(
                          '/dictionary/$_midCodeId/$originalItemId',
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
      _fetchData(); // Refresh UI after save
    }
  }

  // Helper to extract parent ID out of mid ID (safely handle lengths)
  String? getParentIdFromMidId(String midId) {
    for (var p in _parentItems) {
      final pId = p['itemId']?.toString() ?? '';
      if (pId.isNotEmpty && midId.startsWith(pId)) {
        return pId;
      }
    }
    return null;
  }

  Future<void> _deleteItem(String itemId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除中類代碼 "$itemId" 嗎？'),
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
      await _apiService.delete('/dictionary/$_midCodeId/$itemId');
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
    } else if (_parentItems.isEmpty) {
      content = const Center(child: Text('查無大類資料，請先設定設備大類'));
    } else {
      final filteredList = _filteredMidItems;

      content = Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
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
                    value: _selectedParentId,
                    hint: const Text('選擇設備大類'),
                    items: _parentItems.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['itemId']?.toString() ?? '',
                        child: Text(p['itemName']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedParentId = val;
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
                ? const Center(child: Text('此大類下目前沒有任何中類資料'))
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
                          title: Text(itemName),
                          subtitle: Text('類別代碼: $itemId'),
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
                                  onPressed: () => _deleteItem(itemId),
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
          (_parentItems.isEmpty || _isLoading) || !authProvider.canAdd
          ? null
          : FloatingActionButton(
              onPressed: () => _showItemDialog(),
              child: const Icon(Icons.add),
            ),
    );
  }
}

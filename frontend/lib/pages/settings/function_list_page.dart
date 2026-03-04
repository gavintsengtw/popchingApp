import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FunctionListPage extends StatefulWidget {
  const FunctionListPage({super.key});

  @override
  State<FunctionListPage> createState() => _FunctionListPageState();
}

class _FunctionListPageState extends State<FunctionListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _functions = [];

  @override
  void initState() {
    super.initState();
    _fetchFunctions();
  }

  Future<void> _fetchFunctions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _apiService.get('/functions');
      setState(() {
        _functions = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load system functions: $e')),
        );
      }
    }
  }

  Future<void> _deleteFunction(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this function?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/functions/$id');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Function deleted successfully')),
          );
        }
        _fetchFunctions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  Future<void> _showFunctionDialog([Map<String, dynamic>? function]) async {
    final bool isEdit = function != null;
    final idController = TextEditingController(
      text: isEdit ? function['id'] : '',
    );
    final funcIdController = TextEditingController(
      text: isEdit ? function['funcId'] : '',
    );
    final nameController = TextEditingController(
      text: isEdit ? function['name'] : '',
    );
    final descriptionController = TextEditingController(
      text: isEdit ? function['description'] : '',
    );
    final routeLinkController = TextEditingController(
      text: isEdit ? function['routeLink'] : '',
    );
    final iconController = TextEditingController(
      text: isEdit ? function['icon'] : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Function' : 'Add Function'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEdit)
                  TextField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: 'UID (ID)'),
                  ),
                TextField(
                  controller: funcIdController,
                  decoration: const InputDecoration(
                    labelText: 'Function ID (e.g. SYS_MGMT)',
                  ),
                  enabled: !isEdit,
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name (名稱)'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (描述)',
                  ),
                ),
                TextField(
                  controller: routeLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Route Link (路徑)',
                  ),
                ),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon String (圖示)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if ((!isEdit && idController.text.isEmpty) ||
                    funcIdController.text.isEmpty ||
                    nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('UID, Function ID, and Name are required'),
                    ),
                  );
                  return;
                }

                final payload = {
                  'id': idController.text,
                  'funcId': funcIdController.text,
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'routeLink': routeLinkController.text,
                  'icon': iconController.text,
                };

                try {
                  if (isEdit) {
                    await _apiService.put(
                      '/functions/${Uri.encodeComponent(function['id'])}',
                      payload,
                    );
                  } else {
                    await _apiService.post('/functions', payload);
                  }
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save function: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _fetchFunctions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('功能項目管理 (Functions)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _functions.isEmpty
          ? const Center(child: Text('No functions found.'))
          : ListView.builder(
              itemCount: _functions.length,
              itemBuilder: (context, index) {
                final func = _functions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: const Icon(Icons.widgets, color: Colors.white),
                    ),
                    title: Text(
                      '${func['funcId']} - ${func['name'] ?? 'Unknown'}',
                    ),
                    subtitle: Text(
                      '路徑: ${func['routeLink'] ?? 'N/A'}\n描述: ${func['description'] ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showFunctionDialog(func),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteFunction(func['id']),
                        ),
                      ],
                    ),
                    onTap: () => _showFunctionDialog(func),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFunctionDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

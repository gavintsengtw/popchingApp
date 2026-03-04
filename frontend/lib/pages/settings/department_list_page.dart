import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DepartmentListPage extends StatefulWidget {
  const DepartmentListPage({super.key});

  @override
  State<DepartmentListPage> createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends State<DepartmentListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _departments = [];
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await Future.wait([
        _apiService.get('/departments'),
        _apiService.get('/users'),
      ]);
      setState(() {
        _departments = results[0] ?? [];
        _users = results[1] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  Future<void> _showDepartmentDialog([Map<String, dynamic>? department]) async {
    final bool isEdit = department != null;
    final idController = TextEditingController(
      text: isEdit ? department['id'] : '',
    );
    final nameController = TextEditingController(
      text: isEdit ? department['name'] : '',
    );
    String? selectedManagerId;
    if (isEdit &&
        department['managerName'] != null &&
        department['managerName'] != '') {
      // Must verify the manager ID actually exists in our user list
      final managerExists = _users.any(
        (u) => u['id'].toString() == department['managerName'].toString(),
      );
      if (managerExists) {
        selectedManagerId = department['managerName'].toString();
      }
    }

    String? parentId;
    if (isEdit &&
        department['parentId'] != null &&
        department['parentId'] != '0') {
      final parentExists = _departments.any(
        (d) => d['id'].toString() == department['parentId'].toString(),
      );
      if (parentExists) {
        parentId = department['parentId'].toString();
      }
    }
    bool isEnabled = isEdit ? (department['enabled'] ?? false) : true;

    // Filter out the current department and its children to prevent circular parents
    List<dynamic> availableParents = _departments
        .where((d) => !isEdit || d['id'] != department['id'])
        .toList();

    // Only allow enabled users (closemark != 'Y') to be selected as a new manager
    List<dynamic> availableManagers = _users
        .where((u) => u['enabled'] == true)
        .toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? '編輯部門 (Edit Department)' : '新增部門 (Add Department)',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isEdit)
                      TextField(
                        controller: idController,
                        decoration: const InputDecoration(
                          labelText: 'Department ID (代號)',
                        ),
                      ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Department Name (名稱)',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Manager Name (主管)',
                      ),
                      initialValue: selectedManagerId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (無)'),
                        ),
                        // Add the currently selected manager even if they are now disabled, so the selection doesn't break
                        if (selectedManagerId != null &&
                            !availableManagers.any(
                              (u) => u['id'].toString() == selectedManagerId,
                            ))
                          DropdownMenuItem<String>(
                            value: selectedManagerId,
                            child: Text(
                              '${_users.firstWhere((u) => u['id'].toString() == selectedManagerId)['fullName']} (Disabled)',
                            ),
                          ),
                        ...availableManagers.map((u) {
                          return DropdownMenuItem<String>(
                            value: u['id'].toString(),
                            child: Text('${u['fullName']} (${u['id']})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedManagerId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Parent Department (上層部門)',
                      ),
                      initialValue: parentId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (無)'),
                        ),
                        ...availableParents.map((d) {
                          return DropdownMenuItem<String>(
                            value: d['id'].toString(),
                            child: Text('${d['name']} (${d['id']})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          parentId = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Department Enabled (啟用)'),
                      value: isEnabled,
                      onChanged: (val) {
                        setDialogState(() {
                          isEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消 (Cancel)'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if ((!isEdit && idController.text.isEmpty) ||
                        nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill required fields (ID, Name)',
                          ),
                        ),
                      );
                      return;
                    }

                    final payload = {
                      'id': idController.text,
                      'name': nameController.text,
                      'managerName': selectedManagerId ?? '',
                      'closemark': isEnabled ? 'N' : 'Y',
                      'parentId': parentId ?? '0',
                    };

                    try {
                      if (isEdit) {
                        await _apiService.put(
                          '/departments/${Uri.encodeComponent(department['id'])}',
                          payload,
                        );
                      } else {
                        await _apiService.post('/departments', payload);
                      }
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save department: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('儲存 (Save)'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('部門管理 (Departments)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _departments.isEmpty
          ? const Center(child: Text('No departments found.'))
          : ListView.builder(
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final dept = _departments[index];
                final bool isEnabled = dept['enabled'] ?? false;
                final String? pId = dept['parentId'];
                final String parentName = pId != null && pId != '0'
                    ? _departments.firstWhere(
                        (d) => d['id'] == pId,
                        orElse: () => {'name': 'Unknown'},
                      )['name']
                    : 'None';
                final String mId = dept['managerName'] ?? '';
                final String managerName = mId.isNotEmpty
                    ? _users.firstWhere(
                        (u) => u['id'] == mId,
                        orElse: () => {'fullName': mId},
                      )['fullName']
                    : 'None';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isEnabled ? Colors.blue : Colors.grey,
                      child: Icon(Icons.groups, color: Colors.white),
                    ),
                    title: Text('${dept['name']} (${dept['id']})'),
                    subtitle: Text(
                      'Manager: $managerName | Parent: $parentName',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (authProvider.canEdit)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showDepartmentDialog(dept),
                          ),
                        if (authProvider.canDelete)
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('確認刪除 (Confirm Delete)'),
                                  content: Text(
                                    '確定要刪除部門 "${dept['name']}" 嗎？\n(Are you sure you want to delete this department?)',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('取消 (Cancel)'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        '刪除 (Delete)',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await _apiService.delete(
                                    '/departments/${Uri.encodeComponent(dept['id'])}',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '刪除成功 (Successfully deleted)',
                                        ),
                                      ),
                                    );
                                    _fetchData(); // Refresh the list
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '刪除失敗 (Failed to delete): $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                      ],
                    ),
                    onTap: authProvider.canEdit
                        ? () => _showDepartmentDialog(dept)
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: authProvider.canAdd
          ? FloatingActionButton(
              onPressed: () => _showDepartmentDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

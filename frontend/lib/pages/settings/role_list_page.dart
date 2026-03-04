import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RoleListPage extends StatefulWidget {
  const RoleListPage({super.key});

  @override
  State<RoleListPage> createState() => _RoleListPageState();
}

class _RoleListPageState extends State<RoleListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _roles = [];

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _apiService.get('/roles');
      setState(() {
        _roles = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load roles: $e')));
      }
    }
  }

  String _formatMarks(Map<String, dynamic> role) {
    List<String> perms = [];
    if (role['adminMark'] == 'Y') perms.add('Admin');
    if (role['newMark'] == 'Y') perms.add('Create');
    if (role['modMark'] == 'Y') perms.add('Update');
    if (role['deleteMark'] == 'Y') perms.add('Delete');
    if (role['serchMark'] == 'Y') perms.add('Read');
    if (role['lockMark'] == 'Y') perms.add('Lock');
    if (role['unLockMark'] == 'Y') perms.add('Unlock');
    if (perms.isEmpty) return 'No Permissions';
    return perms.join(', ');
  }

  Future<void> _showRoleDialog([Map<String, dynamic>? role]) async {
    final bool isEdit = role != null;
    final int? uid = role?['uid'] as int?;
    final idController = TextEditingController(text: role?['groupId'] ?? '');
    final nameController = TextEditingController(text: role?['name'] ?? '');

    bool adminMark = role?['adminMark'] == 'Y';
    bool newMark = role?['newMark'] == 'Y';
    bool modMark = role?['modMark'] == 'Y';
    bool deleteMark = role?['deleteMark'] == 'Y';
    bool serchMark = role?['serchMark'] == 'Y';
    bool lockMark = role?['lockMark'] == 'Y';
    bool unLockMark = role?['unLockMark'] == 'Y';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? '編輯群組 (Edit Role)' : '新增群組 (Add Role)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(
                        labelText: '群組代碼 (Role ID)',
                      ),
                      enabled: !isEdit,
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '群組名稱 (Role Name)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '權限設定 (Permissions)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text('Admin (管理員)'),
                      value: adminMark,
                      onChanged: (val) =>
                          setDialogState(() => adminMark = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Create (新增)'),
                      value: newMark,
                      onChanged: (val) =>
                          setDialogState(() => newMark = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Update (修改)'),
                      value: modMark,
                      onChanged: (val) =>
                          setDialogState(() => modMark = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Delete (刪除)'),
                      value: deleteMark,
                      onChanged: (val) =>
                          setDialogState(() => deleteMark = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Read (查詢)'),
                      value: serchMark,
                      onChanged: (val) =>
                          setDialogState(() => serchMark = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Lock (鎖定)'),
                      value: lockMark,
                      onChanged: (val) =>
                          setDialogState(() => lockMark = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Unlock (解鎖)'),
                      value: unLockMark,
                      onChanged: (val) =>
                          setDialogState(() => unLockMark = val ?? false),
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
                    if (idController.text.isEmpty ||
                        nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '請填寫所有必填欄位 (Please fill required fields)',
                          ),
                        ),
                      );
                      return;
                    }

                    final payload = {
                      'groupId': idController.text,
                      'name': nameController.text,
                      'adminMark': adminMark ? 'Y' : 'N',
                      'newMark': newMark ? 'Y' : 'N',
                      'modMark': modMark ? 'Y' : 'N',
                      'deleteMark': deleteMark ? 'Y' : 'N',
                      'serchMark': serchMark ? 'Y' : 'N',
                      'lockMark': lockMark ? 'Y' : 'N',
                      'unLockMark': unLockMark ? 'Y' : 'N',
                    };

                    try {
                      if (isEdit) {
                        await _apiService.put('/roles/$uid', payload);
                      } else {
                        await _apiService.post('/roles', payload);
                      }
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('儲存失敗 (Failed to save): $e')),
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
      _fetchRoles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('群組權限管理 (Roles)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _roles.isEmpty
          ? const Center(child: Text('No roles found.'))
          : ListView.builder(
              itemCount: _roles.length,
              itemBuilder: (context, index) {
                final role = _roles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.security, color: Colors.white),
                    ),
                    title: Text(
                      '${role['groupId']} - ${role['name'] ?? 'Unknown Role'}',
                    ),
                    subtitle: Text('權限: ${_formatMarks(role)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (authProvider.canEdit)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showRoleDialog(role),
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
                                    '確定要刪除群組 "${role['name']}" 嗎？\n(Are you sure you want to delete this role?)',
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
                                    '/roles/${role['uid']}',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '刪除成功 (Successfully deleted)',
                                        ),
                                      ),
                                    );
                                    _fetchRoles(); // Refresh the list
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
                  ),
                );
              },
            ),
      floatingActionButton: authProvider.canAdd
          ? FloatingActionButton(
              onPressed: () {
                _showRoleDialog();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

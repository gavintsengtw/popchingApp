import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _users = [];
  List<dynamic> _departments = [];
  List<dynamic> _roles = [];

  // Search Filters
  final TextEditingController _searchKeywordController =
      TextEditingController();
  String? _selectedSearchDeptId;
  String? _selectedSearchGroupId;

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
        _apiService.get('/users'),
        _apiService.get('/departments'),
        _apiService.get('/roles'), // Fetch roles for grouping
      ]);
      setState(() {
        _users = results[0] ?? [];
        _departments = results[1] ?? [];
        _roles = results[2] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('403')) {
          msg =
              'Access Denied: You need Administrator privileges to view this page.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $msg')));
      }
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String query = '';
      final List<String> params = [];
      if (_searchKeywordController.text.isNotEmpty) {
        params.add(
          'keyword=${Uri.encodeComponent(_searchKeywordController.text)}',
        );
      }
      if (_selectedSearchDeptId != null) {
        params.add('deptId=${Uri.encodeComponent(_selectedSearchDeptId!)}');
      }
      if (_selectedSearchGroupId != null) {
        params.add('groupId=${Uri.encodeComponent(_selectedSearchGroupId!)}');
      }
      if (params.isNotEmpty) {
        query = '?${params.join('&')}';
      }

      final data = await _apiService.get('/users$query');
      setState(() {
        _users = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
      }
    }
  }

  Future<void> _showUserDialog([Map<String, dynamic>? user]) async {
    final bool isEdit = user != null;
    final idController = TextEditingController(text: isEdit ? user['id'] : '');
    final usernameController = TextEditingController(
      text: isEdit ? user['username'] : '',
    );
    final fullNameController = TextEditingController(
      text: isEdit ? user['fullName'] : '',
    );
    final passwordController = TextEditingController();
    final emailController = TextEditingController(
      text: isEdit ? user['email'] : '',
    );
    final cellphoneController = TextEditingController(
      text: isEdit ? user['cellphone'] : '',
    );

    String? selectedAgentId =
        isEdit && user['agent'] != null && user['agent'] != ''
        ? user['agent']
        : null;

    String? selectedDepartmentId =
        isEdit &&
            user['departments'] != null &&
            (user['departments'] as List).isNotEmpty
        ? user['departments'][0]['id']
        : null;

    String? selectedRoleId =
        isEdit &&
            user['roleIds'] != null &&
            (user['roleIds'] as List).isNotEmpty
        ? user['roleIds'][0]
        : null;

    bool isEnabled = isEdit ? (user['enabled'] ?? false) : true;

    // Filter available agents: must be enabled, and cannot be the user themselves
    List<dynamic> availableAgents = _users.where((u) {
      bool isAgentEnabled = u['enabled'] == true;
      bool isNotSelf = !isEdit || u['username'] != user['username'];
      return isAgentEnabled && isNotSelf;
    }).toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit User' : 'Add User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isEdit)
                      TextField(
                        controller: idController,
                        decoration: const InputDecoration(
                          labelText: 'Badge Number (ID)',
                        ),
                      ),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username (Account)',
                      ),
                      enabled: !isEdit,
                    ),
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: isEdit
                            ? 'New Password (leave blank to keep)'
                            : 'Password',
                      ),
                      obscureText: true,
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: cellphoneController,
                      decoration: const InputDecoration(labelText: 'Cellphone'),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Agent (代理人)',
                      ),
                      initialValue:
                          selectedAgentId != null &&
                              availableAgents.any(
                                (a) => a['username'] == selectedAgentId,
                              )
                          ? selectedAgentId
                          : null,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (無)'),
                        ),
                        // Add fallback if agent is currently disabled but was selected previously
                        if (selectedAgentId != null &&
                            !availableAgents.any(
                              (a) => a['username'] == selectedAgentId,
                            ))
                          DropdownMenuItem<String>(
                            value: selectedAgentId,
                            child: Text(
                              '${_users.firstWhere((u) => u['username'] == selectedAgentId, orElse: () => {'fullName': selectedAgentId})['fullName']} (Disabled)',
                            ),
                          ),
                        ...availableAgents.map((a) {
                          return DropdownMenuItem<String>(
                            value: a['username']
                                .toString(), // agent column maps to account
                            child: Text('${a['fullName']} (${a['username']})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAgentId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Department (所屬部門)',
                      ),
                      initialValue: selectedDepartmentId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (無)'),
                        ),
                        ..._departments.map((d) {
                          return DropdownMenuItem<String>(
                            value: d['id'].toString(),
                            child: Text('${d['name']} (${d['id']})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDepartmentId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Role Group (群組)',
                      ),
                      initialValue: selectedRoleId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (無)'),
                        ),
                        ..._roles.map((r) {
                          return DropdownMenuItem<String>(
                            value: r['groupId'].toString(),
                            child: Text('${r['name']} (${r['groupId']})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRoleId = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Account Enabled (啟用帳號)'),
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
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if ((!isEdit && idController.text.isEmpty) ||
                        usernameController.text.isEmpty ||
                        fullNameController.text.isEmpty ||
                        (!isEdit && passwordController.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                        ),
                      );
                      return;
                    }

                    final payload = {
                      'id': idController.text,
                      'username': usernameController.text,
                      'fullName': fullNameController.text,
                      'email': emailController.text,
                      'cellphone': cellphoneController.text,
                      'agent': selectedAgentId ?? '',
                      'closemark': isEnabled ? 'N' : 'Y',
                      if (selectedDepartmentId != null)
                        'departments': [
                          {'id': selectedDepartmentId},
                        ],
                      if (selectedRoleId != null) 'roleIds': [selectedRoleId],
                      if (passwordController.text.isNotEmpty)
                        'password': passwordController.text,
                    };

                    try {
                      if (isEdit) {
                        await _apiService.put(
                          '/users/${Uri.encodeComponent(user['id'])}',
                          payload,
                        );
                      } else {
                        await _apiService.post('/users', payload);
                      }
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save user: $e')),
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
      },
    );

    if (result == true) {
      _fetchUsers();
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重設密碼 (Reset Password)'),
        content: Text('確定要將使用者 ${user['fullName']} 的密碼重設為預設密碼 123456 嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消 (Cancel)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              '確定重設 (Confirm)',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.post(
          '/users/${Uri.encodeComponent(user['id'])}/reset-password',
          {},
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('密碼已成功重設為預設值。')));
          _fetchUsers(); // Optional: refresh if we want to show updated state, but no state is visible changed here except backend.
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('重設密碼失敗：$e')));
        }
      }
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final keywordField = TextField(
            controller: _searchKeywordController,
            decoration: const InputDecoration(
              labelText: '全文檢索 (Keyword)',
              hintText: 'Search ID, Account, Name...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _fetchUsers(),
          );

          final deptDropdown = DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '部門 (Department)',
              border: OutlineInputBorder(),
            ),
            value: _selectedSearchDeptId,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All (全部)'),
              ),
              ..._departments.map((d) {
                return DropdownMenuItem<String>(
                  value: d['id'].toString(),
                  child: Text('${d['name']}'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSearchDeptId = value;
              });
            },
          );

          final groupDropdown = DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '群組 (Group)',
              border: OutlineInputBorder(),
            ),
            value: _selectedSearchGroupId,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All (全部)'),
              ),
              ..._roles.map((r) {
                return DropdownMenuItem<String>(
                  value: r['groupId'].toString(),
                  child: Text('${r['name']}'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSearchGroupId = value;
              });
            },
          );

          return Column(
            children: [
              if (isNarrow)
                Column(
                  children: [
                    keywordField,
                    const SizedBox(height: 8),
                    deptDropdown,
                    const SizedBox(height: 8),
                    groupDropdown,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: keywordField),
                    const SizedBox(width: 8),
                    Expanded(child: deptDropdown),
                    const SizedBox(width: 8),
                    Expanded(child: groupDropdown),
                  ],
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _searchKeywordController.clear();
                      setState(() {
                        _selectedSearchDeptId = null;
                        _selectedSearchGroupId = null;
                      });
                      _fetchUsers();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Filter'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _fetchUsers,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        children: [
          _buildSearchBar(),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                ? const Center(child: Text('No users found.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.grey[200],
                        ),
                        columns: [
                          const DataColumn(label: Text('帳號 (Account)')),
                          const DataColumn(label: Text('差勤編號 (ID)')),
                          const DataColumn(label: Text('中文姓名 (Name)')),
                          const DataColumn(label: Text('部門 (Department)')),
                          const DataColumn(label: Text('群組 (Group)')),
                          const DataColumn(label: Text('代理人 (Agent)')),
                          const DataColumn(label: Text('啟用狀態 (Status)')),
                          if (authProvider.canEdit)
                            const DataColumn(label: Text('Actions')),
                        ],
                        rows: _users.map((user) {
                          final bool isEnabled = user['enabled'] ?? false;
                          final String deptName =
                              (user['departments'] != null &&
                                  (user['departments'] as List).isNotEmpty)
                              ? user['departments'][0]['name']
                              : 'None';
                          final String groupNames =
                              (user['roleNames'] != null &&
                                  (user['roleNames'] as List).isNotEmpty)
                              ? (user['roleNames'] as List).join(', ')
                              : 'None';

                          return DataRow(
                            cells: [
                              DataCell(Text(user['username'] ?? '')),
                              DataCell(Text(user['id'] ?? '')),
                              DataCell(Text(user['fullName'] ?? '')),
                              DataCell(Text(deptName)),
                              DataCell(Text(groupNames)),
                              DataCell(Text(user['agent'] ?? '')),
                              DataCell(
                                Icon(
                                  isEnabled ? Icons.check_circle : Icons.cancel,
                                  color: isEnabled ? Colors.green : Colors.red,
                                ),
                              ),
                              if (authProvider.canEdit)
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        tooltip: '編輯 (Edit)',
                                        onPressed: () => _showUserDialog(user),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.lock_reset,
                                          size: 20,
                                          color: Colors.orange,
                                        ),
                                        tooltip: '重設密碼 (Reset Password)',
                                        onPressed: () => _resetPassword(user),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: authProvider.canAdd
          ? FloatingActionButton(
              onPressed: () => _showUserDialog(),
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}

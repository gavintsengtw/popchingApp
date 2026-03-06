import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RoleFunctionListPage extends StatefulWidget {
  const RoleFunctionListPage({super.key});

  @override
  State<RoleFunctionListPage> createState() => _RoleFunctionListPageState();
}

class _RoleFunctionListPageState extends State<RoleFunctionListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _roleFunctions = [];
  List<dynamic> _roles = [];
  List<dynamic> _functions = [];

  // Search Filters
  String? _selectedSearchRoleId;
  String? _selectedSearchFuncId;

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
        _apiService.get('/role-functions'),
        _apiService.get('/roles'),
        _apiService.get('/functions'),
      ]);
      setState(() {
        _roleFunctions = results[0] ?? [];
        _roles = results[1] ?? [];
        _functions = results[2] ?? [];
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

  Future<void> _fetchRoleFunctions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String query = '';
      final List<String> params = [];
      if (_selectedSearchRoleId != null) {
        params.add('roleId=${Uri.encodeComponent(_selectedSearchRoleId!)}');
      }
      if (_selectedSearchFuncId != null) {
        params.add('funcId=${Uri.encodeComponent(_selectedSearchFuncId!)}');
      }
      if (params.isNotEmpty) {
        query = '?${params.join('&')}';
      }

      final data = await _apiService.get('/role-functions$query');
      setState(() {
        _roleFunctions = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load mapping data: $e')),
        );
      }
    }
  }

  Future<void> _showMappingDialog([Map<String, dynamic>? mapping]) async {
    final bool isEdit = mapping != null;
    String? selectedRoleId = isEdit ? mapping['roleId'] : null;
    String? selectedFuncId = isEdit ? mapping['funcId'] : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? 'Edit Mapping (編輯對應)' : 'Add Mapping (新增對應)',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Group (群組)',
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Function (功能)',
                      ),
                      initialValue: selectedFuncId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (無)'),
                        ),
                        ..._functions.map((f) {
                          return DropdownMenuItem<String>(
                            value: f['funcId'].toString(),
                            child: Text('${f['name']} (${f['funcId']})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedFuncId = value;
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
                    if (selectedRoleId == null || selectedFuncId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select both Group and Function',
                          ),
                        ),
                      );
                      return;
                    }

                    final payload = {
                      'roleId': selectedRoleId,
                      'funcId': selectedFuncId,
                    };

                    try {
                      if (isEdit) {
                        await _apiService.put(
                          '/role-functions/${Uri.encodeComponent(mapping['id'].toString())}',
                          payload,
                        );
                      } else {
                        await _apiService.post('/role-functions', payload);
                      }
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save mapping: $e')),
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
      _fetchRoleFunctions();
    }
  }

  Future<void> _deleteMapping(dynamic id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete (確認刪除)'),
        content: const Text(
          'Are you sure you want to delete this mapping? (確定要刪除此群組功能對應嗎？)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete(
          '/role-functions/${Uri.encodeComponent(id.toString())}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mapping deleted successfully')),
          );
          _fetchRoleFunctions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete mapping: $e')),
          );
        }
      }
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 400;

          final roleDropdown = DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '群組 (Group)',
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedSearchRoleId,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All (全部)'),
              ),
              ..._roles.map((r) {
                return DropdownMenuItem<String>(
                  value: r['groupId'].toString(),
                  child: Text('${r['name']} (${r['groupId']})'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSearchRoleId = value;
              });
            },
          );

          final funcDropdown = DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '功能 (Function)',
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedSearchFuncId,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All (全部)'),
              ),
              ..._functions.map((f) {
                return DropdownMenuItem<String>(
                  value: f['funcId'].toString(),
                  child: Text('${f['name']} (${f['funcId']})'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSearchFuncId = value;
              });
            },
          );

          return Column(
            children: [
              if (isNarrow)
                Column(
                  children: [
                    roleDropdown,
                    const SizedBox(height: 8),
                    funcDropdown,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: roleDropdown),
                    const SizedBox(width: 8),
                    Expanded(child: funcDropdown),
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
                      setState(() {
                        _selectedSearchRoleId = null;
                        _selectedSearchFuncId = null;
                      });
                      _fetchRoleFunctions();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Filter'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _fetchRoleFunctions,
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
      appBar: AppBar(title: const Text('Group Function Mapping (群組功能對應)')),
      body: Column(
        children: [
          _buildSearchBar(),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _roleFunctions.isEmpty
                ? const Center(child: Text('No mapping records found.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.resolveWith(
                          (states) => Colors.grey[200],
                        ),
                        columns: [
                          const DataColumn(label: Text('群組編號 (Group ID)')),
                          const DataColumn(label: Text('群組名稱 (Group Name)')),
                          const DataColumn(label: Text('功能編號 (Function ID)')),
                          const DataColumn(label: Text('功能名稱 (Function Name)')),
                          const DataColumn(
                            label: Text('上層功能 (Parent Function)'),
                          ),
                          if (authProvider.canEdit || authProvider.canDelete)
                            const DataColumn(label: Text('Actions')),
                        ],
                        rows: _roleFunctions.map((mapping) {
                          return DataRow(
                            cells: [
                              DataCell(Text(mapping['roleId'] ?? '')),
                              DataCell(Text(mapping['groupName'] ?? '')),
                              DataCell(Text(mapping['funcId'] ?? '')),
                              DataCell(Text(mapping['funcName'] ?? '')),
                              DataCell(
                                Text(
                                  mapping['parentFuncName'] != null &&
                                          mapping['parentFuncName']
                                              .toString()
                                              .isNotEmpty
                                      ? '${mapping['parentFuncName']} (${mapping['parentFuncId']})'
                                      : '',
                                ),
                              ),
                              if (authProvider.canEdit ||
                                  authProvider.canDelete)
                                DataCell(
                                  Row(
                                    children: [
                                      if (authProvider.canEdit)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () =>
                                              _showMappingDialog(mapping),
                                        ),
                                      if (authProvider.canDelete)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteMapping(mapping['id']),
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
              onPressed: () => _showMappingDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

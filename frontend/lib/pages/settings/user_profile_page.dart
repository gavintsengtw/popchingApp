import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Read-only fields
  String _badgeNumber = '';
  String _account = '';
  String _fullName = '';

  // Editable fields
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _cellphoneController = TextEditingController();
  String? _selectedAgentId;

  List<dynamic> _availableAgents = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch both profile and all users (for agent dropdown)
      final results = await Future.wait([
        _apiService.get('/users/profile'),
        _apiService.get('/users'),
      ]);

      final profileData = results[0];
      final allUsers = results[1] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _badgeNumber = profileData?['id'] ?? '';
          _account = profileData?['username'] ?? '';
          _fullName = profileData?['fullName'] ?? '';

          _emailController.text = profileData?['email'] ?? '';
          _cellphoneController.text = profileData?['cellphone'] ?? '';

          String? currentAgent = profileData?['agent'];
          if (currentAgent != null && currentAgent.isEmpty) {
            currentAgent = null;
          }

          // Filter available agents
          _availableAgents = allUsers.where((u) {
            bool isAgentEnabled = u['enabled'] == true;
            bool isNotSelf = u['username'] != _account;
            return isAgentEnabled && isNotSelf;
          }).toList();

          // Check if current agent still exists in valid agents, if not, allow selected temporarily
          bool agentExists =
              currentAgent == null ||
              _availableAgents.any((a) => a['username'] == currentAgent);
          if (!agentExists) {
            // Add a fallback option
            _availableAgents.add({
              'username': currentAgent,
              'fullName': '$currentAgent (Disabled/Not Found)',
            });
          }

          _selectedAgentId = currentAgent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '載入個人資料失敗: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      'email': _emailController.text,
      'cellphone': _cellphoneController.text,
      'agent': _selectedAgentId ?? '',
      if (_passwordController.text.isNotEmpty)
        'password': _passwordController.text,
    };

    try {
      await _apiService.put('/users/profile', payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('個人資料更新成功 (Profile updated successfuly)'),
          ),
        );
        setState(() {
          _isSaving = false;
          _passwordController.clear(); // Clear password field after save
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = '更新個人資料失敗: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    _cellphoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('個人資料 (My Profile)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const Text(
                              '基本資料 (不可變更) / Basic Info (Read-only)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _badgeNumber,
                              decoration: const InputDecoration(
                                labelText: '差勤編號 (Badge Number)',
                                border: OutlineInputBorder(),
                              ),
                              enabled: false,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _account,
                              decoration: const InputDecoration(
                                labelText: '帳號 (Account)',
                                border: OutlineInputBorder(),
                              ),
                              enabled: false,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _fullName,
                              decoration: const InputDecoration(
                                labelText: '姓名 (Name)',
                                border: OutlineInputBorder(),
                              ),
                              enabled: false,
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              '其他資料 (可變更) / Other Info (Editable)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: '新密碼 (New Password)',
                                border: OutlineInputBorder(),
                                hintText:
                                    '若不變更請留白 (Leave blank to keep current)',
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: '電子郵件 (Email)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cellphoneController,
                              decoration: const InputDecoration(
                                labelText: '手機 (Cellphone)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: '代理人 (Agent)',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _selectedAgentId,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('無 (None)'),
                                ),
                                ..._availableAgents.map((a) {
                                  return DropdownMenuItem<String>(
                                    value: a['username'].toString(),
                                    child: Text(
                                      '${a['fullName']} (${a['username']})',
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedAgentId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: _isSaving ? null : _updateProfile,
                              icon: _isSaving
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.save),
                              label: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      '儲存變更 (Save Changes)',
                                      style: TextStyle(fontSize: 16),
                                    ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

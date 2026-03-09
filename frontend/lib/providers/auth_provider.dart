import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  bool _isDefaultPassword = false;
  bool get isAuthenticated => _isAuthenticated;
  bool get isDefaultPassword => _isDefaultPassword;

  bool _canAdd = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _isAdmin = false;

  bool get canAdd => _isAdmin || _canAdd;
  bool get canEdit => _isAdmin || _canEdit;
  bool get canDelete => _isAdmin || _canDelete;
  bool get isAdmin => _isAdmin;

  Future<void> _fetchPermissions() async {
    try {
      final response = await _apiService.get('/auth/me');
      if (response != null && response is List) {
        _isAdmin = response.any((auth) => auth['authority'] == 'ROLE_ADMIN');
        _canAdd = response.any((auth) => auth['authority'] == 'PERM_ADD');
        _canEdit = response.any((auth) => auth['authority'] == 'PERM_EDIT');
        _canDelete = response.any((auth) => auth['authority'] == 'PERM_DELETE');
      }
    } catch (e) {
      debugPrint("Error fetching permissions: $e");
    }
  }

  Future<bool> checkLoginStatus() async {
    String? token = await StorageService.read(key: 'jwt_token');
    _isAuthenticated = token != null;
    if (_isAuthenticated) {
      await _fetchPermissions();
    }
    notifyListeners();
    return _isAuthenticated;
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.post('/auth/signin', {
        'usernameOrEmail': username,
        'password': password,
      });

      // The backend returns an 'accessToken' instead of 'token' in the JwtAuthenticationResponse
      if (response != null && response['accessToken'] != null) {
        await StorageService.write(
          key: 'jwt_token',
          value: response['accessToken'],
        );
        _isAuthenticated = true;
        _isDefaultPassword = response['isDefaultPassword'] == 1;
        await _fetchPermissions();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.delete(key: 'jwt_token');
    _isAuthenticated = false;
    _canAdd = false;
    _canEdit = false;
    _canDelete = false;
    _isAdmin = false;
    notifyListeners();
  }
}

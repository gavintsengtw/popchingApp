import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

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
    String? token = await _storage.read(key: 'jwt_token');
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
        await _storage.write(key: 'jwt_token', value: response['accessToken']);
        _isAuthenticated = true;
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
    await _storage.delete(key: 'jwt_token');
    _isAuthenticated = false;
    _canAdd = false;
    _canEdit = false;
    _canDelete = false;
    _isAdmin = false;
    notifyListeners();
  }
}

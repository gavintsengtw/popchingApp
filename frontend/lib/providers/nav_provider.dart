import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NavProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _functions = [];
  bool _isLoading = false;

  List<dynamic> get functions => _functions;
  bool get isLoading => _isLoading;

  Future<void> loadFunctions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.get('/functions/my-menu');
      if (data != null && data is List) {
        // Only keep enabled functions and maybe sort them if there's an order field
        _functions = data;
      } else {
        _functions = [];
      }
    } catch (e) {
      debugPrint('Error loading functions: $e');
      _functions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFunctions() {
    _functions = [];
    notifyListeners();
  }
}

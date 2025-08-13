import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  String? _error;
  
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  
  AuthProvider() {
    checkLoginStatus();
  }
  
  Future<void> checkLoginStatus() async {
    _isLoggedIn = await _apiService.isLoggedIn();
    if (_isLoggedIn) {
      await fetchProfile();
    }
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.login(email, password);
      
      if (response.statusCode == 200) {
        final data = response.data;
        await _apiService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        _user = data['user'];
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      String errorMessage = 'Invalid email or password';
      
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          final responseData = e.response?.data;
          if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Invalid email or password';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        }
      }
      
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<bool> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (response.statusCode == 201) {
        final data = response.data;
        await _apiService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        _user = data['user'];
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      String errorMessage = 'Failed to create account. Please try again.';
      
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          // Parse validation errors from backend
          final responseData = e.response?.data;
          if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e.response?.statusCode == 409) {
          errorMessage = 'An account with this email already exists.';
        }
      }
      
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  Future<void> fetchProfile() async {
    try {
      final response = await _apiService.getProfile();
      if (response.statusCode == 200) {
        _user = response.data;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  Future<void> logout() async {
    await _apiService.logout();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
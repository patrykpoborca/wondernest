import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/services/api_service.dart';
import '../core/services/timber_wrapper.dart';

// Export ApiService for convenience
export '../core/services/api_service.dart' show ApiService;

// API Service Provider - singleton instance
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Auth State Model
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final Map<String, dynamic>? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      error: error,
    );
  }
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState()) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final isLoggedIn = await _apiService.isLoggedIn();
    if (isLoggedIn) {
      await fetchProfile();
    } else {
      state = state.copyWith(isLoggedIn: false);
    }
  }

  Future<bool> login(String email, String password) async {
    Timber.i('[AuthProvider] Starting login process for email: $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      Timber.i('[AuthProvider] Calling API service login');
      final response = await _apiService.login(email, password);
      Timber.i('[AuthProvider] Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        Timber.i('[AuthProvider] Login response data: $responseData');
        
        // Handle the nested data structure from API
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          
          await _apiService.saveTokens(
            data['accessToken'],
            data['refreshToken'],
          );
          
          // Store user data from the response
          final userData = {
            'userId': data['userId'],
            'email': email,
            'hasPin': data['hasPin'] ?? false,
            'children': data['children'] ?? [],
          };
          
          Timber.i('[AuthProvider] Login successful, user data saved');
          state = state.copyWith(
            user: userData,
            isLoggedIn: true,
            isLoading: false,
          );
          return true;
        } else {
          Timber.w('[AuthProvider] Login response missing success/data: $responseData');
        }
      } else {
        Timber.w('[AuthProvider] Login failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      Timber.e('[AuthProvider] Login error: ${e.toString()}');
      String errorMessage = 'Invalid email or password';

      if (e is DioException) {
        Timber.e('[AuthProvider] DioException type: ${e.type}');
        Timber.e('[AuthProvider] DioException message: ${e.message}');
        if (e.response != null) {
          Timber.e('[AuthProvider] Response status: ${e.response?.statusCode}');
          Timber.e('[AuthProvider] Response data: ${e.response?.data}');
        }
        if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
          final responseData = e.response?.data;
          if (responseData is Map<String, dynamic>) {
            // Handle flat error structure: { "error": "UNAUTHORIZED", "message": "Authentication required" }
            if (responseData['message'] != null) {
              errorMessage = responseData['message'].toString();
            } else if (responseData['error'] is Map && responseData['error']['message'] != null) {
              // Handle nested error structure: { "error": { "message": "..." } }
              errorMessage = responseData['error']['message'].toString();
            } else if (responseData['error'] is String) {
              // Handle string error: { "error": "UNAUTHORIZED" }
              errorMessage = responseData['error'].toString();
            }
          }
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e.type == DioExceptionType.connectionTimeout || 
                   e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot connect to server. Please check if the server is running.';
        }
      }

      state = state.copyWith(
        error: errorMessage,
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        // Handle the nested data structure from API
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          
          await _apiService.saveTokens(
            data['accessToken'],
            data['refreshToken'],
          );
          
          // Mark that parent account has been created
          final secureStorage = const FlutterSecureStorage();
          await secureStorage.write(key: 'parent_account_created', value: 'true');
          
          // Store user data from the response
          final userData = {
            'userId': data['userId'],
            'email': data['email'] ?? email,
            'firstName': firstName,
            'lastName': lastName,
            'requiresPinSetup': data['requiresPinSetup'] ?? true,
          };
          
          state = state.copyWith(
            user: userData,
            isLoggedIn: true,
            isLoading: false,
          );
          return true;
        }
      }
    } catch (e) {
      String errorMessage = 'Failed to create account. Please try again.';

      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          final responseData = e.response?.data;
          if (responseData is Map<String, dynamic>) {
            // Handle flat error structure: { "error": "EMAIL_EXISTS", "message": "Account already exists" }
            if (responseData['message'] != null) {
              errorMessage = responseData['message'].toString();
            } else if (responseData['error'] is Map && responseData['error']['message'] != null) {
              // Handle nested error structure: { "error": { "message": "...", "code": "EMAIL_EXISTS" } }
              errorMessage = responseData['error']['message'].toString();
              // Check for specific error codes
              if (responseData['error']['code'] == 'EMAIL_EXISTS') {
                errorMessage = 'An account with this email already exists.';
              }
            } else if (responseData['error'] is String) {
              // Handle string error: { "error": "EMAIL_EXISTS" }
              if (responseData['error'] == 'EMAIL_EXISTS') {
                errorMessage = 'An account with this email already exists.';
              } else {
                errorMessage = responseData['error'].toString();
              }
            }
          }
        } else if (e.response?.statusCode == 409) {
          errorMessage = 'An account with this email already exists.';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e.type == DioExceptionType.connectionTimeout || 
                   e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot connect to server. Please check if the server is running.';
        }
      }

      state = state.copyWith(
        error: errorMessage,
        isLoading: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiService.getProfile();
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Handle the nested data structure from API
        if (responseData['success'] == true && responseData['data'] != null) {
          state = state.copyWith(
            user: responseData['data'],
            isLoggedIn: true,
          );
        }
      }
    } catch (e) {
      // Handle error silently - user might not be logged in
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = AuthState(); // Reset to initial state
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiServiceProvider)),
);

// Convenience providers
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
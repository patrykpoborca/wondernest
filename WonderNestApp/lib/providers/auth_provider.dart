import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/services/api_service.dart';

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
  final ApiService _apiService = ApiService();

  AuthNotifier() : super(AuthState()) {
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.login(email, password);

      if (response.statusCode == 200) {
        final data = response.data;
        await _apiService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        state = state.copyWith(
          user: data['user'],
          isLoggedIn: true,
          isLoading: false,
        );
        return true;
      }
    } catch (e) {
      String errorMessage = 'Invalid email or password';

      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          final responseData = e.response?.data;
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Invalid email or password';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
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

      if (response.statusCode == 201) {
        final data = response.data;
        await _apiService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        state = state.copyWith(
          user: data['user'],
          isLoggedIn: true,
          isLoading: false,
        );
        return true;
      }
    } catch (e) {
      String errorMessage = 'Failed to create account. Please try again.';

      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          // Parse validation errors from backend
          final responseData = e.response?.data;
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e.response?.statusCode == 409) {
          errorMessage = 'An account with this email already exists.';
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
        state = state.copyWith(
          user: response.data,
          isLoggedIn: true,
        );
      }
    } catch (e) {
      // Handle error silently
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
  (ref) => AuthNotifier(),
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
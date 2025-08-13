import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_mode.dart';
import '../models/child_profile.dart';

// App Mode State
class AppModeState {
  final AppMode currentMode;
  final bool isLocked;
  final DateTime? lastParentAccess;
  final Duration autoLockDuration;
  final ChildProfile? activeChild;

  AppModeState({
    required this.currentMode,
    required this.isLocked,
    this.lastParentAccess,
    this.autoLockDuration = const Duration(minutes: 15),
    this.activeChild,
  });

  AppModeState copyWith({
    AppMode? currentMode,
    bool? isLocked,
    DateTime? lastParentAccess,
    Duration? autoLockDuration,
    ChildProfile? activeChild,
  }) {
    return AppModeState(
      currentMode: currentMode ?? this.currentMode,
      isLocked: isLocked ?? this.isLocked,
      lastParentAccess: lastParentAccess ?? this.lastParentAccess,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
      activeChild: activeChild ?? this.activeChild,
    );
  }
}

// App Mode Notifier
class AppModeNotifier extends StateNotifier<AppModeState> {
  final FlutterSecureStorage _secureStorage;
  Timer? _autoLockTimer;

  AppModeNotifier(this._secureStorage)
      : super(AppModeState(
          currentMode: AppMode.kid, // Default to Kid Mode
          isLocked: true,
        )) {
    _initializeMode();
  }

  Future<void> _initializeMode() async {
    // Always start in Kid Mode for safety
    state = state.copyWith(currentMode: AppMode.kid, isLocked: true);
  }

  Future<bool> switchToParentMode(String pin) async {
    final storedPin = await _secureStorage.read(key: 'parent_pin');
    
    if (storedPin == null) {
      // First time setup - store the PIN
      await _secureStorage.write(key: 'parent_pin', value: pin);
      _switchToParentModeInternal();
      return true;
    }
    
    // Verify PIN (in production, use proper hashing)
    if (storedPin == pin) {
      _switchToParentModeInternal();
      return true;
    }
    
    return false;
  }

  void _switchToParentModeInternal() {
    state = state.copyWith(
      currentMode: AppMode.parent,
      isLocked: false,
      lastParentAccess: DateTime.now(),
    );
    _startAutoLockTimer();
  }

  void switchToKidMode() {
    _cancelAutoLockTimer();
    state = state.copyWith(
      currentMode: AppMode.kid,
      isLocked: true,
      lastParentAccess: null,
    );
  }

  void _startAutoLockTimer() {
    _cancelAutoLockTimer();
    _autoLockTimer = Timer(state.autoLockDuration, () {
      switchToKidMode();
    });
  }

  void _cancelAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  void resetActivity() {
    if (state.currentMode == AppMode.parent) {
      state = state.copyWith(lastParentAccess: DateTime.now());
      _startAutoLockTimer();
    }
  }

  void setActiveChild(ChildProfile child) {
    state = state.copyWith(activeChild: child);
  }

  void updateAutoLockDuration(Duration duration) {
    state = state.copyWith(autoLockDuration: duration);
    if (state.currentMode == AppMode.parent) {
      _startAutoLockTimer();
    }
  }

  Future<void> changeParentPin(String oldPin, String newPin) async {
    final storedPin = await _secureStorage.read(key: 'parent_pin');
    if (storedPin == oldPin) {
      await _secureStorage.write(key: 'parent_pin', value: newPin);
    } else {
      throw Exception('Invalid old PIN');
    }
  }

  @override
  void dispose() {
    _cancelAutoLockTimer();
    super.dispose();
  }
}

// Providers
final appModeProvider = StateNotifierProvider<AppModeNotifier, AppModeState>(
  (ref) => AppModeNotifier(const FlutterSecureStorage()),
);

final currentModeProvider = Provider<AppMode>((ref) {
  return ref.watch(appModeProvider).currentMode;
});

final isKidModeProvider = Provider<bool>((ref) {
  return ref.watch(currentModeProvider) == AppMode.kid;
});

final isParentModeProvider = Provider<bool>((ref) {
  return ref.watch(currentModeProvider) == AppMode.parent;
});

final activeChildProvider = Provider<ChildProfile?>((ref) {
  return ref.watch(appModeProvider).activeChild;
});
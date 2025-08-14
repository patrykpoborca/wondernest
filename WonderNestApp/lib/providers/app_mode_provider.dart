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
    bool clearActiveChild = false,
  }) {
    return AppModeState(
      currentMode: currentMode ?? this.currentMode,
      isLocked: isLocked ?? this.isLocked,
      lastParentAccess: lastParentAccess ?? this.lastParentAccess,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
      activeChild: clearActiveChild ? null : (activeChild ?? this.activeChild),
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
    print('[STATE] AppModeNotifier initialized with Kid Mode at ${DateTime.now()}');
    _initializeMode();
  }

  Future<void> _initializeMode() async {
    print('[STATE] _initializeMode() called at ${DateTime.now()}');
    // Always start in Kid Mode for safety and kid-first approach
    // Check if there was a previous parent session that might still be valid
    final lastParentAccessStr = await _secureStorage.read(key: 'last_parent_access');
    DateTime? lastParentAccess;
    
    if (lastParentAccessStr != null) {
      try {
        lastParentAccess = DateTime.parse(lastParentAccessStr);
      } catch (e) {
        // Invalid date format, ignore
      }
    }
    
    // Check if parent session is still valid (within auto-lock duration)
    bool isParentSessionValid = false;
    if (lastParentAccess != null) {
      final timeSinceLastAccess = DateTime.now().difference(lastParentAccess);
      isParentSessionValid = timeSinceLastAccess < state.autoLockDuration;
    }
    
    // Default to Kid Mode unless there's a valid parent session
    final initialMode = isParentSessionValid ? AppMode.parent : AppMode.kid;
    
    print('[STATE] Initial mode determined: $initialMode');
    print('[STATE] Parent session valid: $isParentSessionValid');
    
    state = state.copyWith(
      currentMode: initialMode,
      isLocked: initialMode == AppMode.kid,
      lastParentAccess: isParentSessionValid ? lastParentAccess : null,
    );
    
    print('[STATE] State after _initializeMode: mode=${state.currentMode}, activeChild=${state.activeChild?.name ?? 'null'}');
    
    // Start auto-lock timer if in parent mode
    if (initialMode == AppMode.parent) {
      _startAutoLockTimer();
    }
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

  void _switchToParentModeInternal() async {
    final now = DateTime.now();
    await _secureStorage.write(key: 'last_parent_access', value: now.toIso8601String());
    
    state = state.copyWith(
      currentMode: AppMode.parent,
      isLocked: false,
      lastParentAccess: now,
    );
    _startAutoLockTimer();
  }

  // Improved switchToKidMode - state updates first, async operations after
  Future<void> switchToKidMode({ChildProfile? child}) async {
    print('[STATE] switchToKidMode called at ${DateTime.now()}');
    print('[STATE] Previous state: mode=${state.currentMode}, activeChild=${state.activeChild?.name ?? 'null'}');
    print('[STATE] Child parameter: ${child?.name ?? 'null'} (id: ${child?.id ?? 'null'})');
    
    _cancelAutoLockTimer();
    
    final newActiveChild = child ?? state.activeChild;
    print('[STATE] newActiveChild determined: ${newActiveChild?.name ?? 'null'} (id: ${newActiveChild?.id ?? 'null'})');
    
    // Update state IMMEDIATELY and SYNCHRONOUSLY
    state = state.copyWith(
      currentMode: AppMode.kid,
      isLocked: true,
      lastParentAccess: null,
      activeChild: newActiveChild,
    );
    
    print('[STATE] State updated synchronously: mode=${state.currentMode}, activeChild=${state.activeChild?.name ?? 'null'}');
    
    // Clear storage asynchronously (non-blocking)
    _secureStorage.delete(key: 'last_parent_access').catchError((e) {
      print('[ERROR] Failed to clear last_parent_access: $e');
    });
    
    // State is ready immediately - no delay needed
    print('[STATE] switchToKidMode completed - ready for navigation');
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

  void resetActivity() async {
    if (state.currentMode == AppMode.parent) {
      final now = DateTime.now();
      await _secureStorage.write(key: 'last_parent_access', value: now.toIso8601String());
      
      state = state.copyWith(lastParentAccess: now);
      _startAutoLockTimer();
    }
  }

  void setActiveChild(ChildProfile child) {
    print('[STATE] setActiveChild called for ${child.name} (id: ${child.id}) at ${DateTime.now()}');
    state = state.copyWith(activeChild: child);
    print('[STATE] activeChild set to: ${state.activeChild?.name ?? 'null'}');
  }
  
  // New method: Select child and switch to kid mode in one synchronous operation
  void selectChildAndSwitchMode(ChildProfile child) {
    print('[STATE] selectChildAndSwitchMode called for ${child.name} at ${DateTime.now()}');
    
    _cancelAutoLockTimer();
    
    // Single atomic state update
    state = state.copyWith(
      currentMode: AppMode.kid,
      isLocked: true,
      lastParentAccess: null,
      activeChild: child,
    );
    
    print('[STATE] Mode switched to kid with active child: ${state.activeChild?.name}');
    
    // Clean up storage in background
    _secureStorage.delete(key: 'last_parent_access').catchError((e) {
      print('[ERROR] Failed to clear last_parent_access: $e');
    });
  }

  void clearActiveChild() {
    print('[STATE] clearActiveChild called at ${DateTime.now()}');
    state = state.copyWith(clearActiveChild: true);
    print('[STATE] activeChild cleared, now: ${state.activeChild?.name ?? 'null'}');
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
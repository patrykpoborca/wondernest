import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for story interaction preferences
final storyInteractionProvider = StateNotifierProvider<StoryInteractionNotifier, StoryInteractionSettings>((ref) {
  return StoryInteractionNotifier();
});

class StoryInteractionSettings {
  final TextRevealMode textRevealMode;
  final double textOpacity;
  final bool enableAnimations;
  final bool enableSoundEffects;
  final bool enableHaptics;
  final Duration autoHideHintDuration;
  final Duration textAnimationDuration;
  final TextPosition defaultTextPosition;
  final bool showPageIndicators;
  final bool enableGradientOverlay;
  final int ageGroup; // 0: 3-5, 1: 6-8, 2: 9-12
  
  const StoryInteractionSettings({
    this.textRevealMode = TextRevealMode.tapAnywhere,
    this.textOpacity = 0.9,
    this.enableAnimations = true,
    this.enableSoundEffects = true,
    this.enableHaptics = true,
    this.autoHideHintDuration = const Duration(seconds: 5),
    this.textAnimationDuration = const Duration(milliseconds: 400),
    this.defaultTextPosition = TextPosition.adaptive,
    this.showPageIndicators = true,
    this.enableGradientOverlay = true,
    this.ageGroup = 1, // 6-8 years default
  });
  
  StoryInteractionSettings copyWith({
    TextRevealMode? textRevealMode,
    double? textOpacity,
    bool? enableAnimations,
    bool? enableSoundEffects,
    bool? enableHaptics,
    Duration? autoHideHintDuration,
    Duration? textAnimationDuration,
    TextPosition? defaultTextPosition,
    bool? showPageIndicators,
    bool? enableGradientOverlay,
    int? ageGroup,
  }) {
    return StoryInteractionSettings(
      textRevealMode: textRevealMode ?? this.textRevealMode,
      textOpacity: textOpacity ?? this.textOpacity,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      autoHideHintDuration: autoHideHintDuration ?? this.autoHideHintDuration,
      textAnimationDuration: textAnimationDuration ?? this.textAnimationDuration,
      defaultTextPosition: defaultTextPosition ?? this.defaultTextPosition,
      showPageIndicators: showPageIndicators ?? this.showPageIndicators,
      enableGradientOverlay: enableGradientOverlay ?? this.enableGradientOverlay,
      ageGroup: ageGroup ?? this.ageGroup,
    );
  }
  
  /// Get age-appropriate defaults
  factory StoryInteractionSettings.forAge(int ageGroup) {
    switch (ageGroup) {
      case 0: // 3-5 years
        return const StoryInteractionSettings(
          textRevealMode: TextRevealMode.tapAnywhere,
          textOpacity: 0.95,
          enableAnimations: true,
          enableSoundEffects: true,
          enableHaptics: true,
          autoHideHintDuration: Duration(seconds: 3),
          textAnimationDuration: Duration(milliseconds: 600),
          defaultTextPosition: TextPosition.bottom,
          showPageIndicators: true,
          enableGradientOverlay: true,
          ageGroup: 0,
        );
      case 1: // 6-8 years
        return const StoryInteractionSettings(
          textRevealMode: TextRevealMode.tapAnywhere,
          textOpacity: 0.9,
          enableAnimations: true,
          enableSoundEffects: true,
          enableHaptics: true,
          autoHideHintDuration: Duration(seconds: 5),
          textAnimationDuration: Duration(milliseconds: 400),
          defaultTextPosition: TextPosition.adaptive,
          showPageIndicators: true,
          enableGradientOverlay: true,
          ageGroup: 1,
        );
      case 2: // 9-12 years
        return const StoryInteractionSettings(
          textRevealMode: TextRevealMode.tapZones,
          textOpacity: 0.85,
          enableAnimations: true,
          enableSoundEffects: false,
          enableHaptics: false,
          autoHideHintDuration: Duration(seconds: 7),
          textAnimationDuration: Duration(milliseconds: 300),
          defaultTextPosition: TextPosition.adaptive,
          showPageIndicators: false,
          enableGradientOverlay: false,
          ageGroup: 2,
        );
      default:
        return const StoryInteractionSettings();
    }
  }
}

enum TextRevealMode {
  tapAnywhere,     // Single tap anywhere reveals all text
  tapZones,        // Different zones reveal different text
  progressive,     // Tap multiple times to reveal text progressively
  gestureReveal,   // Swipe up to reveal, swipe down to hide
  autoReveal,      // Automatically show text after delay
}

enum TextPosition {
  top,
  bottom,
  adaptive,  // Position based on image content
  scattered, // Text appears near relevant image elements
}

class StoryInteractionNotifier extends StateNotifier<StoryInteractionSettings> {
  StoryInteractionNotifier() : super(const StoryInteractionSettings()) {
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final ageGroup = prefs.getInt('story_age_group') ?? 1;
    state = StoryInteractionSettings.forAge(ageGroup);
  }
  
  Future<void> setAgeGroup(int ageGroup) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('story_age_group', ageGroup);
    state = StoryInteractionSettings.forAge(ageGroup);
  }
  
  void updateSettings(StoryInteractionSettings settings) {
    state = settings;
  }
  
  void toggleAnimations() {
    state = state.copyWith(enableAnimations: !state.enableAnimations);
  }
  
  void setTextRevealMode(TextRevealMode mode) {
    state = state.copyWith(textRevealMode: mode);
  }
  
  void setTextOpacity(double opacity) {
    state = state.copyWith(textOpacity: opacity);
  }
}
import 'package:flutter/material.dart';
import '../models/sticker_models.dart';

/// Manages age-appropriate mode settings and configurations for the sticker book game
class StickerBookModeManager {
  final int childAge;
  final AgeMode _ageMode;
  
  StickerBookModeManager({required this.childAge})
      : _ageMode = childAge < 7 ? AgeMode.littleKid : AgeMode.bigKid;
  
  /// Current age mode
  AgeMode get ageMode => _ageMode;
  
  /// Whether the child is in little kid mode
  bool get isLittleKidMode => _ageMode == AgeMode.littleKid;
  
  /// Whether the child is in big kid mode
  bool get isBigKidMode => _ageMode == AgeMode.bigKid;
  
  /// Get UI scaling configuration
  UIScaling get uiScaling {
    return isLittleKidMode ? UIScaling.littleKid : UIScaling.bigKid;
  }
  
  /// Get tool configuration
  ToolConfig get toolConfig {
    return isLittleKidMode ? ToolConfig.littleKid : ToolConfig.bigKid;
  }
  
  /// Get canvas configuration
  CanvasConfig get canvasConfig {
    return isLittleKidMode ? CanvasConfig.littleKid : CanvasConfig.bigKid;
  }
  
  /// Get available tools for current mode
  Set<CanvasTool> get availableTools => toolConfig.availableTools;
  
  /// Get button size based on age mode
  double getButtonSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final baseSize = uiScaling.buttonSize;
    final scaleFactor = screenSize.width / 375.0; // iPhone 6/7/8 width as reference
    return (baseSize * scaleFactor.clamp(0.8, 1.5));
  }
  
  /// Get icon size based on age mode
  double getIconSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final baseSize = uiScaling.iconSize;
    final scaleFactor = screenSize.width / 375.0;
    return (baseSize * scaleFactor.clamp(0.8, 1.5));
  }
  
  /// Get font size based on age mode
  double getFontSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final baseSize = uiScaling.fontSize;
    final scaleFactor = screenSize.width / 375.0;
    return (baseSize * scaleFactor.clamp(0.8, 1.5));
  }
  
  /// Get color swatch size based on age mode
  double getColorSwatchSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final baseSize = uiScaling.colorSwatchSize;
    final scaleFactor = screenSize.width / 375.0;
    return (baseSize * scaleFactor.clamp(0.8, 1.5));
  }
  
  /// Get appropriate colors for age mode
  List<Color> getAgeAppropriateColors() {
    final allColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.black,
      Colors.brown,
      Colors.grey,
      Colors.indigo,
      Colors.cyan,
      Colors.lime,
      Colors.amber,
      Colors.deepOrange,
      Colors.teal,
    ];
    
    // Little kids get fewer, brighter colors
    if (isLittleKidMode) {
      return allColors.take(canvasConfig.maxColors).toList();
    }
    
    return allColors.take(canvasConfig.maxColors).toList();
  }
  
  /// Get tool display name with age-appropriate language
  String getToolDisplayName(CanvasTool tool) {
    if (isLittleKidMode) {
      switch (tool) {
        case CanvasTool.sticker:
          return 'Stickers';
        case CanvasTool.draw:
          return 'Crayon';
        case CanvasTool.eraser:
          return 'Eraser';
        case CanvasTool.text:
          return 'Words';
        case CanvasTool.select:
          return 'Move';
      }
    } else {
      switch (tool) {
        case CanvasTool.sticker:
          return 'Stickers';
        case CanvasTool.draw:
          return 'Draw';
        case CanvasTool.eraser:
          return 'Erase';
        case CanvasTool.text:
          return 'Text';
        case CanvasTool.select:
          return 'Select';
      }
    }
  }
  
  /// Get tool icon for age mode
  IconData getToolIcon(CanvasTool tool) {
    switch (tool) {
      case CanvasTool.sticker:
        return Icons.auto_awesome;
      case CanvasTool.draw:
        return isLittleKidMode ? Icons.create : Icons.brush;
      case CanvasTool.eraser:
        return Icons.cleaning_services;
      case CanvasTool.text:
        return Icons.text_fields;
      case CanvasTool.select:
        return Icons.pan_tool;
    }
  }
  
  /// Should show tool labels
  bool get shouldShowToolLabels => toolConfig.showToolLabels;
  
  /// Should use voice guidance
  bool get shouldUseVoiceGuidance => toolConfig.voiceGuidance;
  
  /// Should use simplified interactions
  bool get shouldUseSimplifiedInteractions => toolConfig.simplified;
  
  /// Should allow pan and zoom on canvas
  bool get allowPanZoom => canvasConfig.allowPanZoom;
  
  /// Should show infinite canvas options
  bool get showInfiniteCanvas => canvasConfig.showInfiniteCanvas;
  
  /// Should show zones feature
  bool get showZones => canvasConfig.showZones;
  
  /// Should auto-save frequently
  bool get autoSave => canvasConfig.autoSave;
  
  /// Get fixed canvas size for little kid mode
  Size? get fixedCanvasSize => canvasConfig.fixedCanvasSize;
  
  /// Get text style for labels
  TextStyle getLabelTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context),
      fontWeight: isLittleKidMode ? FontWeight.bold : FontWeight.normal,
      color: isLittleKidMode ? Colors.black87 : Colors.grey[700],
    );
  }
  
  /// Get button padding
  EdgeInsets getButtonPadding() {
    return uiScaling.padding;
  }
  
  /// Get minimum touch target size
  double get minTouchTargetSize => uiScaling.touchTargetMin;
  
  /// Determine if a tool should be available
  bool isToolAvailable(CanvasTool tool) {
    return availableTools.contains(tool);
  }
  
  /// Get encouragement message for age group
  String getEncouragementMessage() {
    if (isLittleKidMode) {
      const messages = [
        'Great job!',
        'You\'re so creative!',
        'Amazing work!',
        'Keep going!',
        'Fantastic!',
        'You\'re an artist!',
      ];
      return messages[DateTime.now().millisecond % messages.length];
    } else {
      const messages = [
        'Excellent creativity!',
        'Nice work!',
        'Looking good!',
        'Keep it up!',
        'Impressive!',
        'Great artistic skills!',
      ];
      return messages[DateTime.now().millisecond % messages.length];
    }
  }
  
  /// Get age-appropriate sticker pack filtering
  bool isStickerPackAppropriate(StickerPack pack) {
    // For now, all packs are appropriate
    // In the future, we could add age restrictions to sticker packs
    return true;
  }
  
  /// Get session length recommendation in minutes
  int getRecommendedSessionLength() {
    return isLittleKidMode ? 10 : 20;
  }
  
  /// Should show break reminder
  bool shouldShowBreakReminder(Duration sessionDuration) {
    final recommendedMinutes = getRecommendedSessionLength();
    return sessionDuration.inMinutes >= recommendedMinutes;
  }
}
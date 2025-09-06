// WonderNest Standardized Game AppBar
// Ensures consistent navigation and functionality across all games/applets

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';

/// Standardized app bar for all games and applets
/// Provides consistent back button, title display, and optional actions
class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showProgressIndicator;
  final double? progress; // 0.0 to 1.0
  final VoidCallback? onBackPressed;
  final bool showCloseButton; // Use close instead of back arrow
  final bool animated; // Add entrance animation
  final Widget? customTitle; // For complex titles

  const GameAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.showProgressIndicator = false,
    this.progress,
    this.onBackPressed,
    this.showCloseButton = false,
    this.animated = true,
    this.customTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primaryBlue;
    final effectiveForegroundColor = foregroundColor ?? Colors.white;

    return AppBar(
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: 0,
      leading: _buildLeading(context, effectiveForegroundColor),
      title: customTitle ?? _buildTitle(effectiveForegroundColor),
      actions: actions,
      bottom: showProgressIndicator && progress != null
          ? _buildProgressIndicator(effectiveBackgroundColor)
          : null,
    );
  }

  Widget _buildLeading(BuildContext context, Color color) {
    final backButton = IconButton(
      onPressed: onBackPressed ?? () => _handleBackPressed(context),
      icon: Icon(
        showCloseButton ? Icons.close : Icons.arrow_back,
        color: color,
        size: 24,
      ),
      tooltip: showCloseButton ? 'Close' : 'Back',
    );

    if (animated) {
      return backButton.animate().fadeIn(delay: 100.ms).slideX(begin: -0.3);
    }
    return backButton;
  }

  Widget _buildTitle(Color color) {
    final titleWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    if (animated) {
      return titleWidget.animate().fadeIn(delay: 200.ms).slideX(begin: 0.3);
    }
    return titleWidget;
  }

  PreferredSize? _buildProgressIndicator(Color backgroundColor) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(4),
      child: Container(
        height: 4,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: backgroundColor.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  void _handleBackPressed(BuildContext context) {
    // For games and applets, always navigate back to child home
    // This ensures we don't end up on black/undefined screens
    try {
      context.go('/child-home');
    } catch (e) {
      // Fallback - try to pop if go() fails
      try {
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          Navigator.of(context).pop();
        }
      } catch (fallbackError) {
        // Last resort - just pop with Navigator
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Size get preferredSize {
    double height = kToolbarHeight;
    if (showProgressIndicator && progress != null) {
      height += 4; // Add progress indicator height
    }
    return Size.fromHeight(height);
  }
}

/// Specialized game app bar for story/reading games
class StoryGameAppBar extends GameAppBar {
  const StoryGameAppBar({
    Key? key,
    required String title,
    String? subtitle,
    List<Widget>? actions,
    bool showProgressIndicator = true,
    double? progress,
    VoidCallback? onBackPressed,
  }) : super(
          key: key,
          title: title,
          subtitle: subtitle,
          actions: actions,
          backgroundColor: AppColors.accentPurple,
          showProgressIndicator: showProgressIndicator,
          progress: progress,
          onBackPressed: onBackPressed,
          showCloseButton: true, // Stories should show close button
        );
}

/// Specialized game app bar for creative games (sticker book, drawing, etc.)
class CreativeGameAppBar extends GameAppBar {
  const CreativeGameAppBar({
    Key? key,
    required String title,
    String? subtitle,
    List<Widget>? actions,
    VoidCallback? onBackPressed,
  }) : super(
          key: key,
          title: title,
          subtitle: subtitle,
          actions: actions,
          backgroundColor: AppColors.warningOrange,
          onBackPressed: onBackPressed,
          showCloseButton: false, // Creative games use back arrow
        );
}

/// Specialized game app bar for educational games
class EducationalGameAppBar extends GameAppBar {
  const EducationalGameAppBar({
    Key? key,
    required String title,
    String? subtitle,
    List<Widget>? actions,
    bool showProgressIndicator = false,
    double? progress,
    VoidCallback? onBackPressed,
  }) : super(
          key: key,
          title: title,
          subtitle: subtitle,
          actions: actions,
          backgroundColor: AppColors.kidSafeBlue,
          showProgressIndicator: showProgressIndicator,
          progress: progress,
          onBackPressed: onBackPressed,
        );
}
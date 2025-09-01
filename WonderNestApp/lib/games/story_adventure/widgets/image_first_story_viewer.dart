import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

/// Image-first story viewer that prioritizes visuals with tap-to-reveal text
class ImageFirstStoryViewer extends ConsumerStatefulWidget {
  final String? imageUrl;
  final String? narratorText;
  final List<CharacterDialogue>? dialogues;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final int currentPage;
  final int totalPages;
  final bool enableSound;

  const ImageFirstStoryViewer({
    super.key,
    this.imageUrl,
    this.narratorText,
    this.dialogues,
    this.onNextPage,
    this.onPreviousPage,
    required this.currentPage,
    required this.totalPages,
    this.enableSound = true,
  });

  @override
  ConsumerState<ImageFirstStoryViewer> createState() => _ImageFirstStoryViewerState();
}

class _ImageFirstStoryViewerState extends ConsumerState<ImageFirstStoryViewer> 
    with TickerProviderStateMixin {
  bool _textVisible = false;
  bool _hintShown = true;
  late AnimationController _pulseController;
  late AnimationController _revealController;
  late AnimationController _bubbleController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Auto-hide hint after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _hintShown = false);
      }
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _revealController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }
  
  void _toggleText() {
    if (widget.enableSound) {
      HapticFeedback.lightImpact();
    }
    
    setState(() {
      _textVisible = !_textVisible;
      _hintShown = false;
    });
    
    if (_textVisible) {
      _revealController.forward();
      _bubbleController.forward();
    } else {
      _revealController.reverse();
      _bubbleController.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isTablet = screenSize.width > 600;
    
    return Stack(
      children: [
        // Full-screen image or placeholder
        _buildImageLayer(),
        
        // Gradient overlay for better text readability (only when text visible)
        if (_textVisible) _buildGradientOverlay(),
        
        // Interactive tap detector
        _buildTapLayer(),
        
        // Text overlays
        if (_textVisible) _buildTextOverlays(isSmallScreen, isTablet),
        
        // Hint indicator (when text is available but hidden)
        if (!_textVisible && _hintShown && _hasText()) _buildHintIndicator(),
        
        // Page indicators
        _buildPageIndicators(),
        
        // Navigation areas
        _buildNavigationAreas(),
      ],
    );
  }
  
  Widget _buildImageLayer() {
    if (widget.imageUrl == null) {
      // Beautiful gradient placeholder when no image
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade200,
              Colors.blue.shade200,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: CustomPaint(
          painter: StoryBackgroundPainter(
            pageNumber: widget.currentPage,
            primaryColor: Colors.purple.shade300,
            secondaryColor: Colors.blue.shade300,
          ),
        ),
      );
    }
    
    return Positioned.fill(
      child: Image.network(
        widget.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade200, Colors.blue.shade200],
              ),
            ),
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 64, color: Colors.white30),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _revealController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3 * _revealController.value),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.4 * _revealController.value),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTapLayer() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleText,
        child: Container(color: Colors.transparent),
      ),
    );
  }
  
  Widget _buildTextOverlays(bool isSmallScreen, bool isTablet) {
    return Stack(
      children: [
        // Narrator text at top or bottom based on content
        if (widget.narratorText != null)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: _buildNarratorText(widget.narratorText!, isSmallScreen),
          ),
        
        // Character dialogues as speech bubbles
        if (widget.dialogues != null)
          ...widget.dialogues!.asMap().entries.map((entry) {
            final index = entry.key;
            final dialogue = entry.value;
            return _buildCharacterBubble(
              dialogue,
              index,
              isSmallScreen,
            );
          }),
      ],
    );
  }
  
  Widget _buildNarratorText(String text, bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _revealController.value)),
          child: Opacity(
            opacity: _revealController.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCharacterBubble(
    CharacterDialogue dialogue,
    int index,
    bool isSmallScreen,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final bubblePosition = _calculateBubblePosition(
      dialogue.position,
      index,
      screenSize,
    );
    
    return AnimatedBuilder(
      animation: _bubbleController,
      builder: (context, child) {
        final delay = index * 0.15;
        final progress = Curves.elasticOut.transform(
          (_bubbleController.value - delay).clamp(0.0, 1.0),
        );
        
        return Positioned(
          left: bubblePosition.left,
          right: bubblePosition.right,
          top: bubblePosition.top,
          bottom: bubblePosition.bottom,
          child: Transform.scale(
            scale: progress,
            alignment: dialogue.position == BubblePosition.left
                ? Alignment.centerLeft
                : dialogue.position == BubblePosition.right
                    ? Alignment.centerRight
                    : Alignment.center,
            child: _SpeechBubble(
              text: dialogue.text,
              characterName: dialogue.characterName,
              position: dialogue.position,
              color: dialogue.color ?? Colors.white,
              isSmallScreen: isSmallScreen,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHintIndicator() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 80,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.3 + (0.3 * _pulseController.value),
            child: Transform.scale(
              scale: 0.9 + (0.1 * _pulseController.value),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 20,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to read',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildPageIndicators() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.totalPages,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: index == widget.currentPage ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == widget.currentPage
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavigationAreas() {
    return Row(
      children: [
        // Left navigation area (previous page)
        if (widget.currentPage > 0)
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: widget.onPreviousPage,
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ),
              ),
            ),
          )
        else
          const Spacer(flex: 1),
        
        // Center area (for text toggle)
        const Spacer(flex: 3),
        
        // Right navigation area (next page)
        if (widget.currentPage < widget.totalPages - 1)
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: widget.onNextPage,
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ),
              ),
            ),
          )
        else
          const Spacer(flex: 1),
      ],
    );
  }
  
  bool _hasText() {
    return widget.narratorText != null || 
           (widget.dialogues != null && widget.dialogues!.isNotEmpty);
  }
  
  _BubblePositioning _calculateBubblePosition(
    BubblePosition position,
    int index,
    Size screenSize,
  ) {
    const double margin = 20;
    final double centerY = screenSize.height * 0.4 + (index * 80);
    
    switch (position) {
      case BubblePosition.left:
        return _BubblePositioning(
          left: margin,
          right: screenSize.width * 0.5,
          top: centerY,
        );
      case BubblePosition.right:
        return _BubblePositioning(
          left: screenSize.width * 0.5,
          right: margin,
          top: centerY,
        );
      case BubblePosition.bottom:
        return _BubblePositioning(
          left: margin,
          right: margin,
          bottom: 150 + (index * 60),
        );
      case BubblePosition.center:
        return _BubblePositioning(
          left: screenSize.width * 0.2,
          right: screenSize.width * 0.2,
          top: centerY,
        );
    }
  }
}

/// Speech bubble widget
class _SpeechBubble extends StatelessWidget {
  final String text;
  final String? characterName;
  final BubblePosition position;
  final Color color;
  final bool isSmallScreen;
  
  const _SpeechBubble({
    required this.text,
    this.characterName,
    required this.position,
    required this.color,
    required this.isSmallScreen,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isSmallScreen ? 200 : 280,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (characterName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                characterName!,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(color),
                ),
              ),
            ),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 15,
              color: _getTextColor(color),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.grey[900]! : Colors.white;
  }
}

/// Custom painter for illustrated backgrounds
class StoryBackgroundPainter extends CustomPainter {
  final int pageNumber;
  final Color primaryColor;
  final Color secondaryColor;
  
  StoryBackgroundPainter({
    required this.pageNumber,
    required this.primaryColor,
    required this.secondaryColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw decorative clouds
    _drawClouds(canvas, size);
    
    // Draw stars for night scenes
    if (pageNumber % 2 == 0) {
      _drawStars(canvas, size);
    }
  }
  
  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.2 + i * 0.3);
      final y = size.height * 0.2;
      
      canvas.drawCircle(Offset(x, y), 30, cloudPaint);
      canvas.drawCircle(Offset(x + 20, y), 25, cloudPaint);
      canvas.drawCircle(Offset(x - 15, y + 5), 20, cloudPaint);
    }
  }
  
  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(pageNumber);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.5;
      canvas.drawCircle(Offset(x, y), 2, starPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Data models
class CharacterDialogue {
  final String text;
  final String? characterName;
  final BubblePosition position;
  final Color? color;
  
  const CharacterDialogue({
    required this.text,
    this.characterName,
    required this.position,
    this.color,
  });
}

enum BubblePosition {
  left,
  right,
  bottom,
  center,
}

class _BubblePositioning {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  
  const _BubblePositioning({
    this.left,
    this.right,
    this.top,
    this.bottom,
  });
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wonder_nest/models/story/enhanced_story_models.dart' as story_models;
import 'package:wonder_nest/core/services/timber_wrapper.dart';

/// Widget that renders a styled text block from the story builder
class StyledTextBlock extends StatelessWidget {
  final story_models.TextBlock textBlock;
  final int childAge;
  final VoidCallback? onTap;
  final bool showVocabularyHints;

  const StyledTextBlock({
    Key? key,
    required this.textBlock,
    required this.childAge,
    this.onTap,
    this.showVocabularyHints = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the appropriate variant based on child age
    final variant = textBlock.getVariantForAge(childAge);
    if (variant == null) {
      return const SizedBox.shrink();
    }

    // Build the text widget with styling
    Widget textWidget = _buildStyledText(context, variant);

    // Apply background if specified
    if (textBlock.style?.background != null) {
      textWidget = _applyBackground(textWidget, textBlock.style!.background!);
    }

    // Apply effects if specified
    if (textBlock.style?.effects != null) {
      textWidget = _applyEffects(textWidget, textBlock.style!.effects!);
    }

    // Add tap handler if provided (before positioning)
    if (onTap != null) {
      textWidget = GestureDetector(
        onTap: onTap,
        child: textWidget,
      );
    }

    // Add vocabulary tooltip if enabled and vocabulary words exist (before positioning)
    if (showVocabularyHints && textBlock.vocabularyWords.isNotEmpty) {
      textWidget = Tooltip(
        message: 'Vocabulary: ${textBlock.vocabularyWords.join(', ')}',
        child: textWidget,
      );
    }

    // Position the text block absolutely if position is specified (must be last)
    if (textBlock.position != null) {
      textWidget = Positioned(
        left: textBlock.position.x,
        top: textBlock.position.y,
        width: textBlock.size?.width,
        height: textBlock.size?.height,
        child: textWidget,
      );
    }

    return textWidget;
  }

  Widget _buildStyledText(BuildContext context, story_models.TextVariant variant) {
    final textConfig = textBlock.style?.text;
    
    // Convert text style config to Flutter TextStyle
    TextStyle textStyle = TextStyle(
      color: textConfig?.color != null 
          ? _parseColor(textConfig!.color!) 
          : Colors.black,
      fontSize: textConfig?.fontSize ?? 16.0,
      fontWeight: textConfig?.fontWeight != null 
          ? _parseFontWeight(textConfig!.fontWeight!) 
          : FontWeight.normal,
      fontFamily: textConfig?.fontFamily,
      height: textConfig?.lineHeight,
      letterSpacing: textConfig?.letterSpacing,
      decoration: textConfig?.textDecoration != null 
          ? _parseTextDecoration(textConfig!.textDecoration!) 
          : TextDecoration.none,
      wordSpacing: textConfig?.wordSpacing,
    );

    // Apply text transform if specified
    String displayText = variant.content;
    if (textConfig?.textTransform != null) {
      switch (textConfig!.textTransform) {
        case 'uppercase':
          displayText = displayText.toUpperCase();
          break;
        case 'lowercase':
          displayText = displayText.toLowerCase();
          break;
        case 'capitalize':
          displayText = _capitalizeWords(displayText);
          break;
      }
    }

    // Apply text alignment
    TextAlign textAlign = TextAlign.left;
    if (textConfig?.textAlign != null) {
      switch (textConfig!.textAlign) {
        case 'center':
          textAlign = TextAlign.center;
          break;
        case 'right':
          textAlign = TextAlign.right;
          break;
        case 'justify':
          textAlign = TextAlign.justify;
          break;
      }
    }

    return Text(
      displayText,
      style: textStyle,
      textAlign: textAlign,
      overflow: TextOverflow.visible, // Allow text to be visible even if it extends beyond bounds
      softWrap: true, // Allow text to wrap to multiple lines
    );
  }

  Widget _applyBackground(Widget child, story_models.BackgroundStyle background) {
    BoxDecoration decoration = BoxDecoration();

    // Apply background based on type
    switch (background.type) {
      case 'solid':
        decoration = decoration.copyWith(
          color: background.color != null 
              ? _parseColor(background.color!).withOpacity(background.opacity ?? 1.0)
              : Colors.white,
        );
        break;
      case 'gradient':
        if (background.gradient != null) {
          decoration = decoration.copyWith(
            gradient: _buildGradient(background.gradient!),
          );
        }
        break;
      case 'image':
        if (background.image != null) {
          decoration = decoration.copyWith(
            image: DecorationImage(
              image: NetworkImage(background.image!.url),
              fit: _parseBoxFit(background.image!.size),
              repeat: _parseImageRepeat(background.image!.repeat),
            ),
          );
        }
        break;
    }

    // Apply border radius if specified
    if (background.borderRadius != null) {
      decoration = decoration.copyWith(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(background.borderRadius!.topLeft ?? 0),
          topRight: Radius.circular(background.borderRadius!.topRight ?? 0),
          bottomLeft: Radius.circular(background.borderRadius!.bottomLeft ?? 0),
          bottomRight: Radius.circular(background.borderRadius!.bottomRight ?? 0),
        ),
      );
    }

    // Apply padding if specified
    EdgeInsets padding = EdgeInsets.zero;
    if (background.padding != null) {
      padding = EdgeInsets.only(
        top: background.padding!.top ?? 0,
        right: background.padding!.right ?? 0,
        bottom: background.padding!.bottom ?? 0,
        left: background.padding!.left ?? 0,
      );
    }

    Widget result = Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );

    // Apply backdrop blur if specified
    if (background.blur != null && background.blur! > 0) {
      result = ClipRRect(
        borderRadius: decoration.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: background.blur!,
            sigmaY: background.blur!,
          ),
          child: result,
        ),
      );
    }

    return result;
  }

  Widget _applyEffects(Widget child, story_models.TextEffects effects) {
    List<BoxShadow> shadows = [];

    // Apply shadow effects
    if (effects.shadow != null) {
      for (final shadow in effects.shadow!) {
        shadows.add(BoxShadow(
          color: _parseColor(shadow.color),
          offset: Offset(shadow.x, shadow.y),
          blurRadius: shadow.blur,
          spreadRadius: shadow.spread ?? 0,
        ));
      }
    }

    // Apply glow effect
    if (effects.glow != null) {
      shadows.add(BoxShadow(
        color: _parseColor(effects.glow!.color)
            .withOpacity(effects.glow!.intensity),
        blurRadius: effects.glow!.radius,
        spreadRadius: effects.glow!.radius / 2,
      ));
    }

    if (shadows.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: shadows,
        ),
        child: child,
      );
    }

    return child;
  }

  Gradient _buildGradient(story_models.GradientStyle gradientStyle) {
    final stops = gradientStyle.colors.map((stop) {
      return _parseColor(stop.color).withOpacity(stop.opacity ?? 1.0);
    }).toList();

    final positions = gradientStyle.colors.map((stop) {
      return stop.position / 100; // Convert from percentage to 0-1
    }).toList();

    switch (gradientStyle.type) {
      case 'radial':
        return RadialGradient(
          colors: stops,
          stops: positions,
          center: gradientStyle.center != null
              ? Alignment(gradientStyle.center!.x, gradientStyle.center!.y)
              : Alignment.center,
        );
      case 'linear':
      default:
        return LinearGradient(
          colors: stops,
          stops: positions,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: gradientStyle.angle != null
              ? GradientRotation(gradientStyle.angle! * 3.14159 / 180)
              : null,
        );
    }
  }

  Color _parseColor(String color) {
    // Remove # if present
    color = color.replaceAll('#', '');
    
    // Parse hex color
    if (color.length == 6) {
      return Color(int.parse('FF$color', radix: 16));
    } else if (color.length == 8) {
      return Color(int.parse(color, radix: 16));
    }
    
    // Handle rgb/rgba format
    if (color.startsWith('rgb')) {
      final values = RegExp(r'\d+').allMatches(color)
          .map((m) => int.parse(m.group(0)!))
          .toList();
      if (values.length >= 3) {
        final r = values[0];
        final g = values[1];
        final b = values[2];
        final a = values.length > 3 ? values[3] / 255 : 1.0;
        return Color.fromRGBO(r, g, b, a);
      }
    }
    
    // Default to black if parsing fails
    return Colors.black;
  }

  FontWeight _parseFontWeight(int weight) {
    switch (weight) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  TextDecoration _parseTextDecoration(String decoration) {
    switch (decoration) {
      case 'underline':
        return TextDecoration.underline;
      case 'overline':
        return TextDecoration.overline;
      case 'line-through':
        return TextDecoration.lineThrough;
      default:
        return TextDecoration.none;
    }
  }

  BoxFit _parseBoxFit(String? size) {
    switch (size) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      default:
        return BoxFit.cover;
    }
  }

  ImageRepeat _parseImageRepeat(String? repeat) {
    switch (repeat) {
      case 'repeat':
        return ImageRepeat.repeat;
      case 'repeat-x':
        return ImageRepeat.repeatX;
      case 'repeat-y':
        return ImageRepeat.repeatY;
      case 'no-repeat':
      default:
        return ImageRepeat.noRepeat;
    }
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Widget that renders a full story page with all text blocks and images
class StoryPageWidget extends StatelessWidget {
  final story_models.EnhancedStoryPage page;
  final int childAge;
  final Function(String)? onVocabularyTap;
  final bool showVocabularyHints;

  const StoryPageWidget({
    Key? key,
    required this.page,
    required this.childAge,
    this.onVocabularyTap,
    this.showVocabularyHints = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaledStoryPageWidget(
      page: page,
      childAge: childAge,
      onVocabularyTap: onVocabularyTap,
      showVocabularyHints: showVocabularyHints,
      scaleFactor: 1.0,
    );
  }
}

/// Enhanced story page widget with proper scaling support
class ScaledStoryPageWidget extends StatelessWidget {
  final story_models.EnhancedStoryPage page;
  final int childAge;
  final Function(String)? onVocabularyTap;
  final bool showVocabularyHints;
  final double scaleFactor;

  const ScaledStoryPageWidget({
    Key? key,
    required this.page,
    required this.childAge,
    this.onVocabularyTap,
    this.showVocabularyHints = false,
    required this.scaleFactor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allow text to extend beyond stack bounds to prevent clipping
      children: [
        // Background image if specified - now covers the entire scaled area
        if (page.background != null)
          Positioned.fill(
            child: Image.network(
              page.background!,
              fit: BoxFit.cover, // Cover the entire scaled container
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

        // Text blocks with scaling applied to positions and sizes
        ...page.textBlocks.map((textBlock) {
          return ScaledTextBlock(
            textBlock: textBlock,
            childAge: childAge,
            showVocabularyHints: showVocabularyHints,
            scaleFactor: scaleFactor,
            onTap: () {
              // Handle vocabulary word taps
              for (final word in textBlock.vocabularyWords) {
                onVocabularyTap?.call(word);
              }
            },
          );
        }),

        // Popup images with scaling applied to positions and sizes
        ...page.popupImages.map((image) {
          return Positioned(
            left: image.position.x * scaleFactor,
            top: image.position.y * scaleFactor,
            width: image.size.width * scaleFactor,
            height: image.size.height * scaleFactor,
            child: Transform.rotate(
              angle: (image.rotation ?? 0) * 3.14159 / 180,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(
                    image.flipHorizontal == true ? -1.0 : 1.0,
                    image.flipVertical == true ? -1.0 : 1.0,
                  ),
                child: Image.network(
                  image.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Enhanced text block widget that handles scaling properly
class ScaledTextBlock extends StatelessWidget {
  final story_models.TextBlock textBlock;
  final int childAge;
  final VoidCallback? onTap;
  final bool showVocabularyHints;
  final double scaleFactor;

  const ScaledTextBlock({
    Key? key,
    required this.textBlock,
    required this.childAge,
    this.onTap,
    this.showVocabularyHints = false,
    required this.scaleFactor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the appropriate variant based on child age
    final variant = textBlock.getVariantForAge(childAge);
    if (variant == null) {
      return const SizedBox.shrink();
    }

    // Build the text widget with scaling applied to font size
    Widget textWidget = _buildStyledText(context, variant);

    // Apply background if specified
    if (textBlock.style?.background != null) {
      textWidget = _applyBackground(textWidget, textBlock.style!.background!);
    }

    // Apply effects if specified
    if (textBlock.style?.effects != null) {
      textWidget = _applyEffects(textWidget, textBlock.style!.effects!);
    }

    // Add tap handler if provided (before positioning)
    if (onTap != null) {
      textWidget = GestureDetector(
        onTap: onTap,
        child: textWidget,
      );
    }

    // Add vocabulary tooltip if enabled and vocabulary words exist (before positioning)
    if (showVocabularyHints && textBlock.vocabularyWords.isNotEmpty) {
      textWidget = Tooltip(
        message: 'Vocabulary: ${textBlock.vocabularyWords.join(', ')}',
        child: textWidget,
      );
    }

    // Position the text block absolutely with scaling applied to positions and sizes (must be last)
    if (textBlock.position != null) {
      final scaledX = textBlock.position.x * scaleFactor;
      final scaledY = textBlock.position.y * scaleFactor;
      final scaledWidth = textBlock.size?.width != null ? textBlock.size!.width * scaleFactor : null;
      
      // Log text block positioning for debugging
      Timber.d('ScaledTextBlock positioning: id=${textBlock.id}, '
          'original=(${textBlock.position.x}, ${textBlock.position.y}, ${textBlock.size?.width}x${textBlock.size?.height}), '
          'scaled=($scaledX, $scaledY, ${scaledWidth}x?), scaleFactor=$scaleFactor');
      
      // Position the text widget directly without intermediate layout widgets
      textWidget = Positioned(
        left: scaledX,
        top: scaledY,
        width: scaledWidth,
        // Remove fixed height constraint to prevent text clipping
        // Let text expand naturally based on content
        child: textWidget,
      );
    }

    return textWidget;
  }

  Widget _buildStyledText(BuildContext context, story_models.TextVariant variant) {
    final textConfig = textBlock.style?.text;
    
    // Convert text style config to Flutter TextStyle with scaled font size
    TextStyle textStyle = TextStyle(
      color: textConfig?.color != null 
          ? _parseColor(textConfig!.color!) 
          : Colors.black,
      fontSize: (textConfig?.fontSize ?? 16.0) * scaleFactor,  // Scale font size appropriately
      fontWeight: textConfig?.fontWeight != null 
          ? _parseFontWeight(textConfig!.fontWeight!) 
          : FontWeight.normal,
      fontFamily: textConfig?.fontFamily,
      height: textConfig?.lineHeight,
      letterSpacing: textConfig?.letterSpacing != null ? textConfig!.letterSpacing! * scaleFactor : null,
      decoration: textConfig?.textDecoration != null 
          ? _parseTextDecoration(textConfig!.textDecoration!) 
          : TextDecoration.none,
      wordSpacing: textConfig?.wordSpacing != null ? textConfig!.wordSpacing! * scaleFactor : null,
    );

    // Apply text transform if specified
    String displayText = variant.content;
    if (textConfig?.textTransform != null) {
      switch (textConfig!.textTransform) {
        case 'uppercase':
          displayText = displayText.toUpperCase();
          break;
        case 'lowercase':
          displayText = displayText.toLowerCase();
          break;
        case 'capitalize':
          displayText = _capitalizeWords(displayText);
          break;
      }
    }

    // Apply text alignment
    TextAlign textAlign = TextAlign.left;
    if (textConfig?.textAlign != null) {
      switch (textConfig!.textAlign) {
        case 'center':
          textAlign = TextAlign.center;
          break;
        case 'right':
          textAlign = TextAlign.right;
          break;
        case 'justify':
          textAlign = TextAlign.justify;
          break;
      }
    }

    return Text(
      displayText,
      style: textStyle,
      textAlign: textAlign,
      overflow: TextOverflow.visible, // Allow text to be visible even if it extends beyond bounds
      softWrap: true, // Allow text to wrap to multiple lines
    );
  }

  // Include all the helper methods from StyledTextBlock
  Widget _applyBackground(Widget child, story_models.BackgroundStyle background) {
    BoxDecoration decoration = BoxDecoration();

    // Apply background based on type
    switch (background.type) {
      case 'solid':
        decoration = decoration.copyWith(
          color: background.color != null 
              ? _parseColor(background.color!).withOpacity(background.opacity ?? 1.0)
              : Colors.white,
        );
        break;
      case 'gradient':
        if (background.gradient != null) {
          decoration = decoration.copyWith(
            gradient: _buildGradient(background.gradient!),
          );
        }
        break;
      case 'image':
        if (background.image != null) {
          decoration = decoration.copyWith(
            image: DecorationImage(
              image: NetworkImage(background.image!.url),
              fit: _parseBoxFit(background.image!.size),
              repeat: _parseImageRepeat(background.image!.repeat),
            ),
          );
        }
        break;
    }

    // Apply border radius if specified
    if (background.borderRadius != null) {
      decoration = decoration.copyWith(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(background.borderRadius!.topLeft ?? 0),
          topRight: Radius.circular(background.borderRadius!.topRight ?? 0),
          bottomLeft: Radius.circular(background.borderRadius!.bottomLeft ?? 0),
          bottomRight: Radius.circular(background.borderRadius!.bottomRight ?? 0),
        ),
      );
    }

    // Apply padding if specified
    EdgeInsets padding = EdgeInsets.zero;
    if (background.padding != null) {
      padding = EdgeInsets.only(
        top: background.padding!.top ?? 0,
        right: background.padding!.right ?? 0,
        bottom: background.padding!.bottom ?? 0,
        left: background.padding!.left ?? 0,
      );
    }

    Widget result = Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );

    // Apply backdrop blur if specified
    if (background.blur != null && background.blur! > 0) {
      result = ClipRRect(
        borderRadius: decoration.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: background.blur!,
            sigmaY: background.blur!,
          ),
          child: result,
        ),
      );
    }

    return result;
  }

  Widget _applyEffects(Widget child, story_models.TextEffects effects) {
    List<BoxShadow> shadows = [];

    // Apply shadow effects
    if (effects.shadow != null) {
      for (final shadow in effects.shadow!) {
        shadows.add(BoxShadow(
          color: _parseColor(shadow.color),
          offset: Offset(shadow.x, shadow.y),
          blurRadius: shadow.blur,
          spreadRadius: shadow.spread ?? 0,
        ));
      }
    }

    // Apply glow effect
    if (effects.glow != null) {
      shadows.add(BoxShadow(
        color: _parseColor(effects.glow!.color)
            .withOpacity(effects.glow!.intensity),
        blurRadius: effects.glow!.radius,
        spreadRadius: effects.glow!.radius / 2,
      ));
    }

    if (shadows.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: shadows,
        ),
        child: child,
      );
    }

    return child;
  }

  // Helper methods copied from StyledTextBlock
  Gradient _buildGradient(story_models.GradientStyle gradientStyle) {
    final stops = gradientStyle.colors.map((stop) {
      return _parseColor(stop.color).withOpacity(stop.opacity ?? 1.0);
    }).toList();

    final positions = gradientStyle.colors.map((stop) {
      return stop.position / 100; // Convert from percentage to 0-1
    }).toList();

    switch (gradientStyle.type) {
      case 'radial':
        return RadialGradient(
          colors: stops,
          stops: positions,
          center: gradientStyle.center != null
              ? Alignment(gradientStyle.center!.x, gradientStyle.center!.y)
              : Alignment.center,
        );
      case 'linear':
      default:
        return LinearGradient(
          colors: stops,
          stops: positions,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: gradientStyle.angle != null
              ? GradientRotation(gradientStyle.angle! * 3.14159 / 180)
              : null,
        );
    }
  }

  Color _parseColor(String color) {
    // Remove # if present
    color = color.replaceAll('#', '');
    
    // Parse hex color
    if (color.length == 6) {
      return Color(int.parse('FF$color', radix: 16));
    } else if (color.length == 8) {
      return Color(int.parse(color, radix: 16));
    }
    
    // Handle rgb/rgba format
    if (color.startsWith('rgb')) {
      final values = RegExp(r'\d+').allMatches(color)
          .map((m) => int.parse(m.group(0)!))
          .toList();
      if (values.length >= 3) {
        final r = values[0];
        final g = values[1];
        final b = values[2];
        final a = values.length > 3 ? values[3] / 255 : 1.0;
        return Color.fromRGBO(r, g, b, a);
      }
    }
    
    // Default to black if parsing fails
    return Colors.black;
  }

  FontWeight _parseFontWeight(int weight) {
    switch (weight) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  TextDecoration _parseTextDecoration(String decoration) {
    switch (decoration) {
      case 'underline':
        return TextDecoration.underline;
      case 'overline':
        return TextDecoration.overline;
      case 'line-through':
        return TextDecoration.lineThrough;
      default:
        return TextDecoration.none;
    }
  }

  BoxFit _parseBoxFit(String? size) {
    switch (size) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      default:
        return BoxFit.cover;
    }
  }

  ImageRepeat _parseImageRepeat(String? repeat) {
    switch (repeat) {
      case 'repeat':
        return ImageRepeat.repeat;
      case 'repeat-x':
        return ImageRepeat.repeatX;
      case 'repeat-y':
        return ImageRepeat.repeatY;
      case 'no-repeat':
      default:
        return ImageRepeat.noRepeat;
    }
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
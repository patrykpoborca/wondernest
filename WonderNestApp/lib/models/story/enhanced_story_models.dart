import 'package:json_annotation/json_annotation.dart';

part 'enhanced_story_models.g.dart';

/// Enhanced story model that matches the web builder structure
@JsonSerializable()
class EnhancedStory {
  final String id;
  final String title;
  final String? description;
  final StoryContent content;
  final StoryMetadata metadata;
  final String status; // draft, published, archived
  final int pageCount;
  final DateTime lastModified;
  final DateTime createdAt;
  final String? thumbnail;
  final List<String> collaborators;
  final int version;

  EnhancedStory({
    required this.id,
    required this.title,
    this.description,
    required this.content,
    required this.metadata,
    required this.status,
    required this.pageCount,
    required this.lastModified,
    required this.createdAt,
    this.thumbnail,
    required this.collaborators,
    required this.version,
  });

  factory EnhancedStory.fromJson(Map<String, dynamic> json) =>
      _$EnhancedStoryFromJson(json);
  Map<String, dynamic> toJson() => _$EnhancedStoryToJson(this);
}

/// Story content with pages
@JsonSerializable()
class StoryContent {
  final String version;
  final List<EnhancedStoryPage> pages;

  StoryContent({
    required this.version,
    required this.pages,
  });

  factory StoryContent.fromJson(Map<String, dynamic> json) =>
      _$StoryContentFromJson(json);
  Map<String, dynamic> toJson() => _$StoryContentToJson(this);
}

/// Enhanced story page with text blocks and images
@JsonSerializable()
class EnhancedStoryPage {
  final int pageNumber;
  final String? background;
  final List<TextBlock> textBlocks;
  final List<PopupImage> popupImages;

  EnhancedStoryPage({
    required this.pageNumber,
    this.background,
    required this.textBlocks,
    required this.popupImages,
  });

  factory EnhancedStoryPage.fromJson(Map<String, dynamic> json) =>
      _$EnhancedStoryPageFromJson(json);
  Map<String, dynamic> toJson() => _$EnhancedStoryPageToJson(this);
}

/// Text block with variants and styling
@JsonSerializable()
class TextBlock {
  final String id;
  final Position position;
  final Size? size;
  final List<TextVariant> variants;
  final String? activeVariantId;
  final TextBlockStyle? style;
  final TextBlockMetadata? metadata;
  final List<String> vocabularyWords;
  final List<TextInteraction>? interactions;

  TextBlock({
    required this.id,
    required this.position,
    this.size,
    required this.variants,
    this.activeVariantId,
    this.style,
    this.metadata,
    required this.vocabularyWords,
    this.interactions,
  });

  factory TextBlock.fromJson(Map<String, dynamic> json) =>
      _$TextBlockFromJson(json);
  Map<String, dynamic> toJson() => _$TextBlockToJson(this);

  /// Get the appropriate variant based on child age
  TextVariant? getVariantForAge(int childAge) {
    if (variants.isEmpty) return null;

    // First, try to find the primary variant
    final primaryVariant = variants.firstWhere(
      (v) => v.type == 'primary',
      orElse: () => variants.first,
    );

    // If no age specified, return primary
    if (childAge == 0) return primaryVariant;

    // Find best matching variant based on target age
    TextVariant? bestMatch;
    int bestAgeDiff = 999;

    for (final variant in variants) {
      final ageDiff = (variant.metadata.targetAge - childAge).abs();
      final inRange = childAge >= variant.metadata.ageRange[0] &&
          childAge <= variant.metadata.ageRange[1];

      // Prefer variants where child age is in range
      if (inRange && (bestMatch == null || ageDiff < bestAgeDiff)) {
        bestMatch = variant;
        bestAgeDiff = ageDiff;
      } else if (bestMatch == null && ageDiff < bestAgeDiff) {
        bestMatch = variant;
        bestAgeDiff = ageDiff;
      }
    }

    return bestMatch ?? primaryVariant;
  }
}

/// Text variant with metadata
@JsonSerializable()
class TextVariant {
  final String id;
  final String content;
  final String type; // primary or alternate
  final VariantMetadata metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? tags;

  TextVariant({
    required this.id,
    required this.content,
    required this.type,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
  });

  factory TextVariant.fromJson(Map<String, dynamic> json) =>
      _$TextVariantFromJson(json);
  Map<String, dynamic> toJson() => _$TextVariantToJson(this);
}

/// Variant metadata for intelligent selection
@JsonSerializable()
class VariantMetadata {
  final int targetAge;
  final List<int> ageRange; // [min, max]
  final String vocabularyDifficulty; // simple, moderate, advanced, complex
  final int vocabularyLevel; // 1-10 scale
  final int readingTime; // seconds
  final int wordCount;
  final int characterCount;
  final double? sentenceComplexity;
  final List<String>? educationalTags;
  final String? languageCode;

  VariantMetadata({
    required this.targetAge,
    required this.ageRange,
    required this.vocabularyDifficulty,
    required this.vocabularyLevel,
    required this.readingTime,
    required this.wordCount,
    required this.characterCount,
    this.sentenceComplexity,
    this.educationalTags,
    this.languageCode,
  });

  factory VariantMetadata.fromJson(Map<String, dynamic> json) =>
      _$VariantMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$VariantMetadataToJson(this);
}

/// Text block styling
@JsonSerializable()
class TextBlockStyle {
  final BackgroundStyle? background;
  final TextStyleConfig? text;
  final TextEffects? effects;
  final TextAnimation? animation;
  final ResponsiveStyle? responsive;
  final String? presetId;

  TextBlockStyle({
    this.background,
    this.text,
    this.effects,
    this.animation,
    this.responsive,
    this.presetId,
  });

  factory TextBlockStyle.fromJson(Map<String, dynamic> json) =>
      _$TextBlockStyleFromJson(json);
  Map<String, dynamic> toJson() => _$TextBlockStyleToJson(this);
}

/// Background styling
@JsonSerializable()
class BackgroundStyle {
  final String type; // solid, gradient, image, pattern
  final String? color;
  final double? opacity;
  final GradientStyle? gradient;
  final BackgroundImage? image;
  final BoxSpacing? padding;
  final BorderRadius? borderRadius;
  final double? blur;
  final String? mixBlendMode;

  BackgroundStyle({
    required this.type,
    this.color,
    this.opacity,
    this.gradient,
    this.image,
    this.padding,
    this.borderRadius,
    this.blur,
    this.mixBlendMode,
  });

  factory BackgroundStyle.fromJson(Map<String, dynamic> json) =>
      _$BackgroundStyleFromJson(json);
  Map<String, dynamic> toJson() => _$BackgroundStyleToJson(this);
}

/// Text styling (custom to avoid conflict with Flutter's TextStyle)
@JsonSerializable()
class TextStyleConfig {
  final String? color;
  final double? fontSize;
  final int? fontWeight;
  final String? fontFamily;
  final double? lineHeight;
  final double? letterSpacing;
  final String? textAlign;
  final String? textDecoration;
  final String? textTransform;
  final double? wordSpacing;

  TextStyleConfig({
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.lineHeight,
    this.letterSpacing,
    this.textAlign,
    this.textDecoration,
    this.textTransform,
    this.wordSpacing,
  });

  factory TextStyleConfig.fromJson(Map<String, dynamic> json) =>
      _$TextStyleConfigFromJson(json);
  Map<String, dynamic> toJson() => _$TextStyleConfigToJson(this);
}

/// Position for absolute positioning
@JsonSerializable()
class Position {
  final double x;
  final double y;

  Position({required this.x, required this.y});

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);
  Map<String, dynamic> toJson() => _$PositionToJson(this);
}

/// Size dimensions
@JsonSerializable()
class Size {
  final double width;
  final double height;

  Size({required this.width, required this.height});

  factory Size.fromJson(Map<String, dynamic> json) => _$SizeFromJson(json);
  Map<String, dynamic> toJson() => _$SizeToJson(this);
}

/// Popup image on page
@JsonSerializable()
class PopupImage {
  final String id;
  final String triggerWord;
  final String imageUrl;
  final Position position;
  final Size size;
  final double? rotation;
  final bool? flipHorizontal;
  final bool? flipVertical;
  final String? animation;

  PopupImage({
    required this.id,
    required this.triggerWord,
    required this.imageUrl,
    required this.position,
    required this.size,
    this.rotation,
    this.flipHorizontal,
    this.flipVertical,
    this.animation,
  });

  factory PopupImage.fromJson(Map<String, dynamic> json) =>
      _$PopupImageFromJson(json);
  Map<String, dynamic> toJson() => _$PopupImageToJson(this);
}

/// Story metadata
@JsonSerializable()
class StoryMetadata {
  final List<int> targetAge; // [min, max]
  final List<String> educationalGoals;
  final int estimatedReadTime; // seconds
  final List<String> vocabularyList;

  StoryMetadata({
    required this.targetAge,
    required this.educationalGoals,
    required this.estimatedReadTime,
    required this.vocabularyList,
  });

  factory StoryMetadata.fromJson(Map<String, dynamic> json) =>
      _$StoryMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$StoryMetadataToJson(this);
}

/// Text block metadata
@JsonSerializable()
class TextBlockMetadata {
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool? lockedForEditing;
  final bool? aiGenerated;
  final String? validationStatus;
  final List<String>? validationMessages;

  TextBlockMetadata({
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lockedForEditing,
    this.aiGenerated,
    this.validationStatus,
    this.validationMessages,
  });

  factory TextBlockMetadata.fromJson(Map<String, dynamic> json) =>
      _$TextBlockMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$TextBlockMetadataToJson(this);
}

/// Text interactions
@JsonSerializable()
class TextInteraction {
  final String type; // click, hover, focus
  final String action; // showDefinition, playSound, highlight, navigate
  final Map<String, dynamic>? payload;

  TextInteraction({
    required this.type,
    required this.action,
    this.payload,
  });

  factory TextInteraction.fromJson(Map<String, dynamic> json) =>
      _$TextInteractionFromJson(json);
  Map<String, dynamic> toJson() => _$TextInteractionToJson(this);
}

/// Supporting style classes
@JsonSerializable()
class GradientStyle {
  final String type; // linear, radial, conic
  final List<GradientStop> colors;
  final double? angle;
  final Position? center;

  GradientStyle({
    required this.type,
    required this.colors,
    this.angle,
    this.center,
  });

  factory GradientStyle.fromJson(Map<String, dynamic> json) =>
      _$GradientStyleFromJson(json);
  Map<String, dynamic> toJson() => _$GradientStyleToJson(this);
}

@JsonSerializable()
class GradientStop {
  final String color;
  final double position; // 0-100
  final double? opacity;

  GradientStop({
    required this.color,
    required this.position,
    this.opacity,
  });

  factory GradientStop.fromJson(Map<String, dynamic> json) =>
      _$GradientStopFromJson(json);
  Map<String, dynamic> toJson() => _$GradientStopToJson(this);
}

@JsonSerializable()
class BackgroundImage {
  final String url;
  final String? size;
  final String? position;
  final String? repeat;

  BackgroundImage({
    required this.url,
    this.size,
    this.position,
    this.repeat,
  });

  factory BackgroundImage.fromJson(Map<String, dynamic> json) =>
      _$BackgroundImageFromJson(json);
  Map<String, dynamic> toJson() => _$BackgroundImageToJson(this);
}

@JsonSerializable()
class BoxSpacing {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  BoxSpacing({this.top, this.right, this.bottom, this.left});

  factory BoxSpacing.fromJson(Map<String, dynamic> json) =>
      _$BoxSpacingFromJson(json);
  Map<String, dynamic> toJson() => _$BoxSpacingToJson(this);
}

@JsonSerializable()
class BorderRadius {
  final double? topLeft;
  final double? topRight;
  final double? bottomLeft;
  final double? bottomRight;

  BorderRadius({
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  });

  factory BorderRadius.fromJson(Map<String, dynamic> json) =>
      _$BorderRadiusFromJson(json);
  Map<String, dynamic> toJson() => _$BorderRadiusToJson(this);
}

@JsonSerializable()
class TextEffects {
  final List<ShadowEffect>? shadow;
  final GlowEffect? glow;
  final OutlineEffect? outline;
  final StrokeEffect? stroke;
  final String? filter;

  TextEffects({
    this.shadow,
    this.glow,
    this.outline,
    this.stroke,
    this.filter,
  });

  factory TextEffects.fromJson(Map<String, dynamic> json) =>
      _$TextEffectsFromJson(json);
  Map<String, dynamic> toJson() => _$TextEffectsToJson(this);
}

@JsonSerializable()
class ShadowEffect {
  final double x;
  final double y;
  final double blur;
  final double? spread;
  final String color;
  final bool? inset;

  ShadowEffect({
    required this.x,
    required this.y,
    required this.blur,
    this.spread,
    required this.color,
    this.inset,
  });

  factory ShadowEffect.fromJson(Map<String, dynamic> json) =>
      _$ShadowEffectFromJson(json);
  Map<String, dynamic> toJson() => _$ShadowEffectToJson(this);
}

@JsonSerializable()
class GlowEffect {
  final String color;
  final double radius;
  final double intensity;

  GlowEffect({
    required this.color,
    required this.radius,
    required this.intensity,
  });

  factory GlowEffect.fromJson(Map<String, dynamic> json) =>
      _$GlowEffectFromJson(json);
  Map<String, dynamic> toJson() => _$GlowEffectToJson(this);
}

@JsonSerializable()
class OutlineEffect {
  final double width;
  final String color;
  final String style;

  OutlineEffect({
    required this.width,
    required this.color,
    required this.style,
  });

  factory OutlineEffect.fromJson(Map<String, dynamic> json) =>
      _$OutlineEffectFromJson(json);
  Map<String, dynamic> toJson() => _$OutlineEffectToJson(this);
}

@JsonSerializable()
class StrokeEffect {
  final double width;
  final String color;

  StrokeEffect({
    required this.width,
    required this.color,
  });

  factory StrokeEffect.fromJson(Map<String, dynamic> json) =>
      _$StrokeEffectFromJson(json);
  Map<String, dynamic> toJson() => _$StrokeEffectToJson(this);
}

@JsonSerializable()
class TextAnimation {
  final String type;
  final double? duration;
  final double? delay;
  final dynamic iteration;
  final String? easing;
  final List<AnimationKeyframe>? customKeyframes;

  TextAnimation({
    required this.type,
    this.duration,
    this.delay,
    this.iteration,
    this.easing,
    this.customKeyframes,
  });

  factory TextAnimation.fromJson(Map<String, dynamic> json) =>
      _$TextAnimationFromJson(json);
  Map<String, dynamic> toJson() => _$TextAnimationToJson(this);
}

@JsonSerializable()
class AnimationKeyframe {
  final double offset;
  final Map<String, dynamic> properties;

  AnimationKeyframe({
    required this.offset,
    required this.properties,
  });

  factory AnimationKeyframe.fromJson(Map<String, dynamic> json) =>
      _$AnimationKeyframeFromJson(json);
  Map<String, dynamic> toJson() => _$AnimationKeyframeToJson(this);
}

@JsonSerializable()
class ResponsiveStyle {
  final TextBlockStyle? mobile;
  final TextBlockStyle? tablet;
  final TextBlockStyle? desktop;

  ResponsiveStyle({
    this.mobile,
    this.tablet,
    this.desktop,
  });

  factory ResponsiveStyle.fromJson(Map<String, dynamic> json) =>
      _$ResponsiveStyleFromJson(json);
  Map<String, dynamic> toJson() => _$ResponsiveStyleToJson(this);
}
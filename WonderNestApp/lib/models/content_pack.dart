import 'package:json_annotation/json_annotation.dart';

part 'content_pack.g.dart';

@JsonSerializable()
class ContentPackCategory {
  final String id;
  final String name;
  final String? description;
  final int displayOrder;
  final String? iconUrl;
  final String? colorHex;
  final bool isActive;
  final int ageMin;
  final int ageMax;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentPackCategory({
    required this.id,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.iconUrl,
    this.colorHex,
    this.isActive = true,
    this.ageMin = 3,
    this.ageMax = 12,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentPackCategory.fromJson(Map<String, dynamic> json) => 
      _$ContentPackCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ContentPackCategoryToJson(this);
}

@JsonSerializable()
class ContentPack {
  final String id;
  final String name;
  final String? description;
  final String? shortDescription;
  final String packType;
  final String? categoryId;
  final ContentPackCategory? category;
  
  // Pricing and availability
  final int priceCents;
  final bool isFree;
  final bool isFeatured;
  final bool isPremium;
  
  // Age and educational info
  final int ageMin;
  final int ageMax;
  final List<String> educationalGoals;
  final List<String> curriculumTags;
  
  // Visual and metadata
  final String? thumbnailUrl;
  final List<String> previewUrls;
  final String? bannerImageUrl;
  final Map<String, String>? colorPalette;
  final String? artStyle;
  final List<String> moodTags;
  
  // Technical metadata
  final int totalAssets;
  final int fileSizeBytes;
  final List<String> supportedPlatforms;
  final String? minAppVersion;
  final String performanceTier;
  
  // Status and timestamps
  final String status;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  
  // Search and discovery
  final String? searchKeywords;
  final double popularityScore;
  final int downloadCount;
  final double ratingAverage;
  final int ratingCount;
  
  // Related data
  final List<ContentPackAsset> assets;
  final UserPackOwnership? userOwnership;

  ContentPack({
    required this.id,
    required this.name,
    this.description,
    this.shortDescription,
    required this.packType,
    this.categoryId,
    this.category,
    this.priceCents = 0,
    this.isFree = false,
    this.isFeatured = false,
    this.isPremium = false,
    this.ageMin = 3,
    this.ageMax = 12,
    this.educationalGoals = const [],
    this.curriculumTags = const [],
    this.thumbnailUrl,
    this.previewUrls = const [],
    this.bannerImageUrl,
    this.colorPalette,
    this.artStyle,
    this.moodTags = const [],
    this.totalAssets = 0,
    this.fileSizeBytes = 0,
    this.supportedPlatforms = const ['ios', 'android', 'web'],
    this.minAppVersion,
    this.performanceTier = 'standard',
    this.status = 'draft',
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.searchKeywords,
    this.popularityScore = 0.0,
    this.downloadCount = 0,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
    this.assets = const [],
    this.userOwnership,
  });

  factory ContentPack.fromJson(Map<String, dynamic> json) => 
      _$ContentPackFromJson(json);
  Map<String, dynamic> toJson() => _$ContentPackToJson(this);

  // Helper methods
  bool get isOwned => userOwnership != null;
  bool get isDownloaded => userOwnership?.downloadStatus == 'completed';
  String get priceDisplay => isFree ? 'Free' : '\$${(priceCents / 100).toStringAsFixed(2)}';
  String get ageRangeDisplay => '$ageMin-$ageMax years';
  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

@JsonSerializable()
class ContentPackAsset {
  final String id;
  final String packId;
  final String name;
  final String? description;
  final String assetType;
  final String fileUrl;
  final String? thumbnailUrl;
  final String? fileFormat;
  final int? fileSizeBytes;
  final int? dimensionsWidth;
  final int? dimensionsHeight;
  final double? durationSeconds;
  final int? frameRate;
  final List<String> tags;
  final Map<String, String>? colorPalette;
  final bool transparencySupport;
  final Map<String, int>? loopPoints;
  final Map<String, dynamic>? interactionConfig;
  final List<String> animationTriggers;
  final int displayOrder;
  final String? groupName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentPackAsset({
    required this.id,
    required this.packId,
    required this.name,
    this.description,
    required this.assetType,
    required this.fileUrl,
    this.thumbnailUrl,
    this.fileFormat,
    this.fileSizeBytes,
    this.dimensionsWidth,
    this.dimensionsHeight,
    this.durationSeconds,
    this.frameRate,
    this.tags = const [],
    this.colorPalette,
    this.transparencySupport = false,
    this.loopPoints,
    this.interactionConfig,
    this.animationTriggers = const [],
    this.displayOrder = 0,
    this.groupName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentPackAsset.fromJson(Map<String, dynamic> json) => 
      _$ContentPackAssetFromJson(json);
  Map<String, dynamic> toJson() => _$ContentPackAssetToJson(this);
}

@JsonSerializable()
class UserPackOwnership {
  final String id;
  final String userId;
  final String packId;
  final String? childId;
  final DateTime acquiredAt;
  final String acquisitionType;
  final int purchasePriceCents;
  final String? transactionId;
  final String downloadStatus;
  final int downloadProgress;
  final DateTime? downloadedAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final bool isFavorite;
  final bool isHidden;
  final List<String> customTags;

  UserPackOwnership({
    required this.id,
    required this.userId,
    required this.packId,
    this.childId,
    required this.acquiredAt,
    this.acquisitionType = 'purchase',
    this.purchasePriceCents = 0,
    this.transactionId,
    this.downloadStatus = 'pending',
    this.downloadProgress = 0,
    this.downloadedAt,
    this.lastUsedAt,
    this.usageCount = 0,
    this.isFavorite = false,
    this.isHidden = false,
    this.customTags = const [],
  });

  factory UserPackOwnership.fromJson(Map<String, dynamic> json) => 
      _$UserPackOwnershipFromJson(json);
  Map<String, dynamic> toJson() => _$UserPackOwnershipToJson(this);
}

@JsonSerializable()
class ContentPackSearchRequest {
  final String? query;
  final String? category;
  final String? packType;
  final int? ageMin;
  final int? ageMax;
  final int? priceMin;
  final int? priceMax;
  final bool? isFree;
  final List<String> educationalGoals;
  final String sortBy;
  final String sortOrder;
  final int page;
  final int size;

  ContentPackSearchRequest({
    this.query,
    this.category,
    this.packType,
    this.ageMin,
    this.ageMax,
    this.priceMin,
    this.priceMax,
    this.isFree,
    this.educationalGoals = const [],
    this.sortBy = 'popularity',
    this.sortOrder = 'desc',
    this.page = 0,
    this.size = 20,
  });

  factory ContentPackSearchRequest.fromJson(Map<String, dynamic> json) => 
      _$ContentPackSearchRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ContentPackSearchRequestToJson(this);
}

@JsonSerializable()
class ContentPackSearchResponse {
  final List<ContentPack> packs;
  final int total;
  final int page;
  final int size;
  final bool hasNext;

  ContentPackSearchResponse({
    required this.packs,
    required this.total,
    required this.page,
    required this.size,
    required this.hasNext,
  });

  factory ContentPackSearchResponse.fromJson(Map<String, dynamic> json) => 
      _$ContentPackSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ContentPackSearchResponseToJson(this);
}

// Pack type enums for type safety
enum ContentPackType {
  characterBundle,
  backdropCollection,
  stickerPack,
  soundEffects,
  musicCollection,
  voicePack,
  emojiPack,
  spriteSheet,
  interactiveObjects,
  particleEffects,
  texturePack,
  animationBundle,
  educationalTheme,
}

enum MediaType {
  imageStatic,
  imageAnimated,
  spriteSheet,
  vectorAnimation,
  audioSound,
  audioMusic,
  audioVoice,
  videoShort,
  interactiveObject,
  particleSystem,
  texture3D,
  model3D,
  fontCustom,
}

extension ContentPackTypeExtension on ContentPackType {
  String get displayName {
    switch (this) {
      case ContentPackType.characterBundle:
        return 'Character Bundle';
      case ContentPackType.backdropCollection:
        return 'Backdrop Collection';
      case ContentPackType.stickerPack:
        return 'Sticker Pack';
      case ContentPackType.soundEffects:
        return 'Sound Effects';
      case ContentPackType.musicCollection:
        return 'Music Collection';
      case ContentPackType.voicePack:
        return 'Voice Pack';
      case ContentPackType.emojiPack:
        return 'Emoji Pack';
      case ContentPackType.spriteSheet:
        return 'Sprite Sheet';
      case ContentPackType.interactiveObjects:
        return 'Interactive Objects';
      case ContentPackType.particleEffects:
        return 'Particle Effects';
      case ContentPackType.texturePack:
        return 'Texture Pack';
      case ContentPackType.animationBundle:
        return 'Animation Bundle';
      case ContentPackType.educationalTheme:
        return 'Educational Theme';
    }
  }
}
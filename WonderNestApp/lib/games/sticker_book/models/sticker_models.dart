import 'package:flutter/material.dart';

/// Represents a sticker in the game
class Sticker {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String? imagePath;
  final String? imageUrl;
  final Color? backgroundColor;
  final Map<String, dynamic> metadata;

  const Sticker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.imagePath,
    this.imageUrl,
    this.backgroundColor,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'category': category,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'backgroundColor': backgroundColor?.value,
      'metadata': metadata,
    };
  }

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      category: json['category'],
      imagePath: json['imagePath'],
      imageUrl: json['imageUrl'],
      backgroundColor: json['backgroundColor'] != null 
          ? Color(json['backgroundColor']) 
          : null,
      metadata: json['metadata'] ?? {},
    );
  }

  Sticker copyWith({
    String? id,
    String? name,
    String? emoji,
    String? category,
    String? imagePath,
    String? imageUrl,
    Color? backgroundColor,
    Map<String, dynamic>? metadata,
  }) {
    return Sticker(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Represents a slot where a sticker can be placed
class StickerSlot {
  final String id;
  final String stickerId;
  final Offset position;
  final String hint;
  final Sticker targetSticker;
  final bool isUnlocked;
  final double? rotation;
  final double? scale;

  const StickerSlot({
    required this.id,
    required this.stickerId,
    required this.position,
    required this.hint,
    required this.targetSticker,
    this.isUnlocked = false,
    this.rotation,
    this.scale,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stickerId': stickerId,
      'position': {'x': position.dx, 'y': position.dy},
      'hint': hint,
      'targetSticker': targetSticker.toJson(),
      'isUnlocked': isUnlocked,
      'rotation': rotation,
      'scale': scale,
    };
  }

  factory StickerSlot.fromJson(Map<String, dynamic> json) {
    final positionData = json['position'] as Map<String, dynamic>;
    return StickerSlot(
      id: json['id'],
      stickerId: json['stickerId'],
      position: Offset(positionData['x'], positionData['y']),
      hint: json['hint'],
      targetSticker: Sticker.fromJson(json['targetSticker']),
      isUnlocked: json['isUnlocked'] ?? false,
      rotation: json['rotation'],
      scale: json['scale'],
    );
  }

  StickerSlot copyWith({
    String? id,
    String? stickerId,
    Offset? position,
    String? hint,
    Sticker? targetSticker,
    bool? isUnlocked,
    double? rotation,
    double? scale,
  }) {
    return StickerSlot(
      id: id ?? this.id,
      stickerId: stickerId ?? this.stickerId,
      position: position ?? this.position,
      hint: hint ?? this.hint,
      targetSticker: targetSticker ?? this.targetSticker,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }
}

/// Represents a page in a sticker book
class StickerPage {
  final String id;
  final String title;
  final String description;
  final List<StickerSlot> stickerSlots;
  final String? backgroundImagePath;
  final String? backgroundImageUrl;
  final StickerTheme theme;
  final int difficulty;
  final List<String> educationalTopics;

  const StickerPage({
    required this.id,
    required this.title,
    required this.description,
    required this.stickerSlots,
    required this.theme,
    this.backgroundImagePath,
    this.backgroundImageUrl,
    this.difficulty = 1,
    this.educationalTopics = const [],
  });

  double get completionPercentage {
    if (stickerSlots.isEmpty) return 0.0;
    final unlockedCount = stickerSlots.where((slot) => slot.isUnlocked).length;
    return unlockedCount / stickerSlots.length;
  }

  bool get isCompleted => completionPercentage >= 1.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'stickerSlots': stickerSlots.map((slot) => slot.toJson()).toList(),
      'backgroundImagePath': backgroundImagePath,
      'backgroundImageUrl': backgroundImageUrl,
      'theme': theme.toJson(),
      'difficulty': difficulty,
      'educationalTopics': educationalTopics,
    };
  }

  factory StickerPage.fromJson(Map<String, dynamic> json) {
    return StickerPage(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      stickerSlots: (json['stickerSlots'] as List)
          .map((slot) => StickerSlot.fromJson(slot))
          .toList(),
      backgroundImagePath: json['backgroundImagePath'],
      backgroundImageUrl: json['backgroundImageUrl'],
      theme: StickerTheme.fromJson(json['theme']),
      difficulty: json['difficulty'] ?? 1,
      educationalTopics: List<String>.from(json['educationalTopics'] ?? []),
    );
  }

  StickerPage copyWith({
    String? id,
    String? title,
    String? description,
    List<StickerSlot>? stickerSlots,
    String? backgroundImagePath,
    String? backgroundImageUrl,
    StickerTheme? theme,
    int? difficulty,
    List<String>? educationalTopics,
  }) {
    return StickerPage(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      stickerSlots: stickerSlots ?? this.stickerSlots,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      theme: theme ?? this.theme,
      difficulty: difficulty ?? this.difficulty,
      educationalTopics: educationalTopics ?? this.educationalTopics,
    );
  }
}

/// Represents a complete sticker book
class StickerBook {
  final String id;
  final String title;
  final String description;
  final List<StickerPage> pages;
  final StickerTheme theme;
  final bool isUnlocked;
  final int recommendedAge;
  final List<String> educationalTopics;

  const StickerBook({
    required this.id,
    required this.title,
    required this.description,
    required this.pages,
    required this.theme,
    this.isUnlocked = true,
    this.recommendedAge = 5,
    this.educationalTopics = const [],
  });

  double get completionPercentage {
    if (pages.isEmpty) return 0.0;
    final totalSlots = pages.fold<int>(0, (sum, page) => sum + page.stickerSlots.length);
    if (totalSlots == 0) return 0.0;
    
    final unlockedSlots = pages.fold<int>(0, (sum, page) => 
        sum + page.stickerSlots.where((slot) => slot.isUnlocked).length);
    
    return unlockedSlots / totalSlots;
  }

  bool get isCompleted => completionPercentage >= 1.0;

  int get totalStickers => pages.fold<int>(0, (sum, page) => sum + page.stickerSlots.length);

  int get unlockedStickers => pages.fold<int>(0, (sum, page) => 
      sum + page.stickerSlots.where((slot) => slot.isUnlocked).length);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pages': pages.map((page) => page.toJson()).toList(),
      'theme': theme.toJson(),
      'isUnlocked': isUnlocked,
      'recommendedAge': recommendedAge,
      'educationalTopics': educationalTopics,
    };
  }

  factory StickerBook.fromJson(Map<String, dynamic> json) {
    return StickerBook(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pages: (json['pages'] as List)
          .map((page) => StickerPage.fromJson(page))
          .toList(),
      theme: StickerTheme.fromJson(json['theme']),
      isUnlocked: json['isUnlocked'] ?? true,
      recommendedAge: json['recommendedAge'] ?? 5,
      educationalTopics: List<String>.from(json['educationalTopics'] ?? []),
    );
  }

  StickerBook copyWith({
    String? id,
    String? title,
    String? description,
    List<StickerPage>? pages,
    StickerTheme? theme,
    bool? isUnlocked,
    int? recommendedAge,
    List<String>? educationalTopics,
  }) {
    return StickerBook(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pages: pages ?? this.pages,
      theme: theme ?? this.theme,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      recommendedAge: recommendedAge ?? this.recommendedAge,
      educationalTopics: educationalTopics ?? this.educationalTopics,
    );
  }
}

/// Theme information for sticker book elements
class StickerTheme {
  final Color color;
  final IconData icon;
  final String name;
  final Color? secondaryColor;
  final Color? backgroundColor;

  const StickerTheme({
    required this.color,
    required this.icon,
    required this.name,
    this.secondaryColor,
    this.backgroundColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'color': color.value,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'name': name,
      'secondaryColor': secondaryColor?.value,
      'backgroundColor': backgroundColor?.value,
    };
  }

  factory StickerTheme.fromJson(Map<String, dynamic> json) {
    return StickerTheme(
      color: Color(json['color']),
      icon: IconData(
        json['iconCodePoint'],
        fontFamily: json['iconFontFamily'],
      ),
      name: json['name'],
      secondaryColor: json['secondaryColor'] != null 
          ? Color(json['secondaryColor']) 
          : null,
      backgroundColor: json['backgroundColor'] != null 
          ? Color(json['backgroundColor']) 
          : null,
    );
  }

  StickerTheme copyWith({
    Color? color,
    IconData? icon,
    String? name,
    Color? secondaryColor,
    Color? backgroundColor,
  }) {
    return StickerTheme(
      color: color ?? this.color,
      icon: icon ?? this.icon,
      name: name ?? this.name,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

/// Game state for the sticker book
class StickerBookGameState {
  final List<StickerBook> books;
  final Set<String> unlockedStickers;
  final String? currentBookId;
  final String? currentPageId;
  final int score;
  final int level;
  final int totalStickersCollected;
  final Map<String, dynamic> achievements;
  final DateTime? lastPlayDate;

  const StickerBookGameState({
    required this.books,
    required this.unlockedStickers,
    this.currentBookId,
    this.currentPageId,
    this.score = 0,
    this.level = 1,
    this.totalStickersCollected = 0,
    this.achievements = const {},
    this.lastPlayDate,
  });

  StickerBook? get currentBook {
    if (currentBookId == null) return null;
    try {
      return books.firstWhere((book) => book.id == currentBookId);
    } catch (e) {
      return null;
    }
  }

  StickerPage? get currentPage {
    final book = currentBook;
    if (book == null || currentPageId == null) return null;
    try {
      return book.pages.firstWhere((page) => page.id == currentPageId);
    } catch (e) {
      return null;
    }
  }

  double get overallCompletionPercentage {
    if (books.isEmpty) return 0.0;
    final totalStickers = books.fold<int>(0, (sum, book) => sum + book.totalStickers);
    if (totalStickers == 0) return 0.0;
    return totalStickersCollected / totalStickers;
  }

  Map<String, dynamic> toJson() {
    return {
      'books': books.map((book) => book.toJson()).toList(),
      'unlockedStickers': unlockedStickers.toList(),
      'currentBookId': currentBookId,
      'currentPageId': currentPageId,
      'score': score,
      'level': level,
      'totalStickersCollected': totalStickersCollected,
      'achievements': achievements,
      'lastPlayDate': lastPlayDate?.toIso8601String(),
    };
  }

  factory StickerBookGameState.fromJson(Map<String, dynamic> json) {
    return StickerBookGameState(
      books: (json['books'] as List)
          .map((book) => StickerBook.fromJson(book))
          .toList(),
      unlockedStickers: Set<String>.from(json['unlockedStickers'] ?? []),
      currentBookId: json['currentBookId'],
      currentPageId: json['currentPageId'],
      score: json['score'] ?? 0,
      level: json['level'] ?? 1,
      totalStickersCollected: json['totalStickersCollected'] ?? 0,
      achievements: json['achievements'] ?? {},
      lastPlayDate: json['lastPlayDate'] != null 
          ? DateTime.parse(json['lastPlayDate']) 
          : null,
    );
  }

  StickerBookGameState copyWith({
    List<StickerBook>? books,
    Set<String>? unlockedStickers,
    String? currentBookId,
    String? currentPageId,
    int? score,
    int? level,
    int? totalStickersCollected,
    Map<String, dynamic>? achievements,
    DateTime? lastPlayDate,
  }) {
    return StickerBookGameState(
      books: books ?? this.books,
      unlockedStickers: unlockedStickers ?? this.unlockedStickers,
      currentBookId: currentBookId ?? this.currentBookId,
      currentPageId: currentPageId ?? this.currentPageId,
      score: score ?? this.score,
      level: level ?? this.level,
      totalStickersCollected: totalStickersCollected ?? this.totalStickersCollected,
      achievements: achievements ?? this.achievements,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
    );
  }
}

/// Represents a mini-game activity to unlock stickers
class StickerActivity {
  final String id;
  final String type;
  final String title;
  final String description;
  final Map<String, dynamic> config;
  final int difficulty;

  const StickerActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.config = const {},
    this.difficulty = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'config': config,
      'difficulty': difficulty,
    };
  }

  factory StickerActivity.fromJson(Map<String, dynamic> json) {
    return StickerActivity(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      config: json['config'] ?? {},
      difficulty: json['difficulty'] ?? 1,
    );
  }
}
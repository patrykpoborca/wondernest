import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/services/timber_wrapper.dart';

/// Represents a sticker pack category
enum StickerCategory {
  animals,
  shapes,
  letters,
  numbers,
  vehicles,
  nature,
  food,
  emotions,
  seasonal,
  custom
}

/// Represents a sticker in the game
class Sticker {
  final String id;
  final String name;
  final String emoji;
  final StickerCategory category;
  final String? imagePath;
  final String? imageUrl;
  final Color? backgroundColor;
  final bool isCustom;
  final bool requiresUnlock;
  final Map<String, dynamic> metadata;

  const Sticker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.imagePath,
    this.imageUrl,
    this.backgroundColor,
    this.isCustom = false,
    this.requiresUnlock = false,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'category': category.name,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'backgroundColor': backgroundColor != null ? (backgroundColor!.a.round() << 24) | (backgroundColor!.r.round() << 16) | (backgroundColor!.g.round() << 8) | backgroundColor!.b.round() : null,
      'isCustom': isCustom,
      'requiresUnlock': requiresUnlock,
      'metadata': metadata,
    };
  }

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      category: StickerCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => StickerCategory.custom,
      ),
      imagePath: json['imagePath'],
      imageUrl: json['imageUrl'],
      backgroundColor: json['backgroundColor'] != null 
          ? Color(json['backgroundColor']) 
          : null,
      isCustom: json['isCustom'] ?? false,
      requiresUnlock: json['requiresUnlock'] ?? false,
      metadata: json['metadata'] ?? {},
    );
  }

  Sticker copyWith({
    String? id,
    String? name,
    String? emoji,
    StickerCategory? category,
    String? imagePath,
    String? imageUrl,
    Color? backgroundColor,
    bool? isCustom,
    bool? requiresUnlock,
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
      isCustom: isCustom ?? this.isCustom,
      requiresUnlock: requiresUnlock ?? this.requiresUnlock,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Represents a placed sticker on the canvas
class PlacedSticker {
  final String id;
  final Sticker sticker;
  final Offset position;
  final double rotation;
  final double scale;
  final int zIndex;
  final DateTime placedAt;

  const PlacedSticker({
    required this.id,
    required this.sticker,
    required this.position,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.zIndex = 0,
    required this.placedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sticker': sticker.toJson(),
      'position': {'x': position.dx, 'y': position.dy},
      'rotation': rotation,
      'scale': scale,
      'zIndex': zIndex,
      'placedAt': placedAt.toIso8601String(),
    };
  }

  factory PlacedSticker.fromJson(Map<String, dynamic> json) {
    final positionData = json['position'] as Map<String, dynamic>;
    return PlacedSticker(
      id: json['id'],
      sticker: Sticker.fromJson(json['sticker']),
      position: Offset(positionData['x'], positionData['y']),
      rotation: json['rotation'] ?? 0.0,
      scale: json['scale'] ?? 1.0,
      zIndex: json['zIndex'] ?? 0,
      placedAt: DateTime.parse(json['placedAt']),
    );
  }

  PlacedSticker copyWith({
    String? id,
    Sticker? sticker,
    Offset? position,
    double? rotation,
    double? scale,
    int? zIndex,
    DateTime? placedAt,
  }) {
    return PlacedSticker(
      id: id ?? this.id,
      sticker: sticker ?? this.sticker,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      zIndex: zIndex ?? this.zIndex,
      placedAt: placedAt ?? this.placedAt,
    );
  }
}

/// Represents a drawing stroke on the canvas
class DrawingStroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final Paint paintStyle;
  final DateTime createdAt;

  const DrawingStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.paintStyle,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    // DEBUG: Log DrawingStroke serialization
    Timber.d('[DrawingStroke.toJson] Serializing stroke $id with ${points.length} points');
    Timber.d('[DrawingStroke.toJson] Original color: $color');
    Timber.d('[DrawingStroke.toJson] Color alpha: ${color.a}, red: ${color.r}, green: ${color.g}, blue: ${color.b}');
    Timber.d('[DrawingStroke.toJson] Paint color: ${paintStyle.color}, alpha: ${paintStyle.color.a}');
    
    // Use the actual color from the Paint object if it's different, or the stored color
    final actualColor = paintStyle.color != color ? paintStyle.color : color;
    Timber.d('[DrawingStroke.toJson] Using actual color: $actualColor');
    
    // Convert double values (0.0-1.0) to integers (0-255)
    // Ensure we have proper alpha - if it's 0 (fully transparent), make it opaque
    final alpha = actualColor.a == 0.0 ? 255 : (actualColor.a * 255).round();
    final red = (actualColor.r * 255).round();
    final green = (actualColor.g * 255).round();
    final blue = (actualColor.b * 255).round();
    
    // Encode as 32-bit integer: (alpha << 24) | (red << 16) | (green << 8) | blue
    final colorInt = (alpha << 24) | (red << 16) | (green << 8) | blue;
    
    Timber.d('[DrawingStroke.toJson] Final ARGB: $alpha,$red,$green,$blue, encoded as: $colorInt (hex: 0x${colorInt.toRadixString(16).padLeft(8, '0')})');
    
    final result = {
      'id': id,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': colorInt,
      'strokeWidth': strokeWidth,
      'createdAt': createdAt.toIso8601String(),
    };
    Timber.d('[DrawingStroke.toJson] Serialized to: $result');
    return result;
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    // DEBUG: Log DrawingStroke deserialization
    Timber.d('[DrawingStroke.fromJson] Deserializing stroke: $json');
    
    final pointsData = json['points'] as List;
    final colorInt = json['color'] as int? ?? 0; // Handle null color
    final strokeWidth = (json['strokeWidth'] as num).toDouble();
    
    Timber.d('[DrawingStroke.fromJson] Raw color int from JSON: $colorInt (hex: 0x${colorInt.toRadixString(16).padLeft(8, '0')})');
    
    // Handle the case where colorInt is 0 (completely transparent/black) - default to opaque black
    final safeColorInt = colorInt == 0 ? 0xFF000000 : colorInt; // Opaque black as fallback
    
    // Explicitly reconstruct the Color with proper alpha channel handling
    // The color was stored as (a << 24) | (r << 16) | (g << 8) | b
    var alpha = (safeColorInt >> 24) & 0xFF;
    final red = (safeColorInt >> 16) & 0xFF;
    final green = (safeColorInt >> 8) & 0xFF;
    final blue = safeColorInt & 0xFF;
    
    Timber.d('[DrawingStroke.fromJson] Extracted ARGB: $alpha,$red,$green,$blue');
    
    // CRITICAL FIX: If alpha is 0 (which makes the color invisible), set it to 255 (fully opaque)
    if (alpha == 0) {
      alpha = 255;
      Timber.w('[DrawingStroke.fromJson] Alpha was 0 (invisible), corrected to 255 (opaque)');
    }
    
    // Create color with explicit ARGB values to ensure proper alpha
    final color = Color.fromARGB(alpha, red, green, blue);
    
    final points = pointsData.map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList();
    
    Timber.d('[DrawingStroke.fromJson] Deserialized ${points.length} points, final color: $color (alpha: ${color.a}), width: $strokeWidth');
    
    // Create Paint object with exact same properties used during creation
    final paintStyle = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    
    final stroke = DrawingStroke(
      id: json['id'],
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      paintStyle: paintStyle,
      createdAt: DateTime.parse(json['createdAt']),
    );
    
    Timber.d('[DrawingStroke.fromJson] Created DrawingStroke with final paint color: ${paintStyle.color} (alpha: ${paintStyle.color.a}), width: ${paintStyle.strokeWidth}');
    
    return stroke;
  }
}

/// Represents a text element on the canvas
class CanvasText {
  final String id;
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;
  final double rotation;
  final DateTime createdAt;

  const CanvasText({
    required this.id,
    required this.text,
    required this.position,
    required this.color,
    this.fontSize = 24.0,
    this.fontFamily = 'Comic Sans MS',
    this.fontWeight = FontWeight.normal,
    this.rotation = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'position': {'x': position.dx, 'y': position.dy},
      'color': (color.a.round() << 24) | (color.r.round() << 16) | (color.g.round() << 8) | color.b.round(),
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'fontWeight': fontWeight.index,
      'rotation': rotation,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CanvasText.fromJson(Map<String, dynamic> json) {
    final positionData = json['position'] as Map<String, dynamic>;
    return CanvasText(
      id: json['id'],
      text: json['text'],
      position: Offset(positionData['x'], positionData['y']),
      color: Color(json['color']),
      fontSize: json['fontSize'] ?? 24.0,
      fontFamily: json['fontFamily'] ?? 'Comic Sans MS',
      fontWeight: FontWeight.values[json['fontWeight'] ?? 0],
      rotation: json['rotation'] ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  CanvasText copyWith({
    String? id,
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
    String? fontFamily,
    FontWeight? fontWeight,
    double? rotation,
    DateTime? createdAt,
  }) {
    return CanvasText(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      rotation: rotation ?? this.rotation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Represents a background theme
class CanvasBackground {
  final String id;
  final String name;
  final Color? backgroundColor;
  final String? imagePath;
  final String? imageUrl;
  final List<Color>? gradient;
  final String category;

  const CanvasBackground({
    required this.id,
    required this.name,
    this.backgroundColor,
    this.imagePath,
    this.imageUrl,
    this.gradient,
    this.category = 'solid',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'backgroundColor': backgroundColor != null ? (backgroundColor!.a.round() << 24) | (backgroundColor!.r.round() << 16) | (backgroundColor!.g.round() << 8) | backgroundColor!.b.round() : null,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'gradient': gradient?.map((c) => (c.a.round() << 24) | (c.r.round() << 16) | (c.g.round() << 8) | c.b.round()).toList(),
      'category': category,
    };
  }

  factory CanvasBackground.fromJson(Map<String, dynamic> json) {
    return CanvasBackground(
      id: json['id'],
      name: json['name'],
      backgroundColor: json['backgroundColor'] != null 
          ? Color(json['backgroundColor']) 
          : null,
      imagePath: json['imagePath'],
      imageUrl: json['imageUrl'],
      gradient: json['gradient'] != null 
          ? (json['gradient'] as List).map((c) => Color(c)).toList()
          : null,
      category: json['category'] ?? 'solid',
    );
  }
}

/// Viewport information for infinite canvas
class CanvasViewport {
  final double zoom;
  final Offset center; // Center point in canvas coordinates
  final Size screenSize; // Size of the visible area
  
  const CanvasViewport({
    this.zoom = 1.0,
    this.center = Offset.zero,
    required this.screenSize,
  });
  
  // Computed property for bounds
  Rect get bounds => Rect.fromCenter(
    center: center,
    width: screenSize.width / zoom,
    height: screenSize.height / zoom,
  );
  
  CanvasViewport copyWith({
    double? zoom,
    Offset? center,
    Size? screenSize,
  }) {
    return CanvasViewport(
      zoom: zoom ?? this.zoom,
      center: center ?? this.center,
      screenSize: screenSize ?? this.screenSize,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'zoom': zoom,
      'center': {'x': center.dx, 'y': center.dy},
      'screenSize': {'width': screenSize.width, 'height': screenSize.height},
    };
  }
  
  factory CanvasViewport.fromJson(Map<String, dynamic> json) {
    final centerData = json['center'] as Map<String, dynamic>;
    final screenSizeData = json['screenSize'] as Map<String, dynamic>;
    return CanvasViewport(
      zoom: json['zoom'] ?? 1.0,
      center: Offset(centerData['x'], centerData['y']),
      screenSize: Size(screenSizeData['width'], screenSizeData['height']),
    );
  }
}

/// Represents a thematic zone in the infinite canvas
class StickerZone {
  final String id;
  final String name;
  final String theme; // e.g., 'zoo', 'city', 'underwater', 'forest'
  final Offset center;
  final double radius;
  final Color color;
  final List<String> stickerIds; // IDs of stickers in this zone
  final DateTime createdAt;
  
  const StickerZone({
    required this.id,
    required this.name,
    required this.theme,
    required this.center,
    this.radius = 200.0,
    required this.color,
    this.stickerIds = const [],
    required this.createdAt,
  });
  
  bool containsPoint(Offset point) {
    return (point - center).distance <= radius;
  }
  
  StickerZone copyWith({
    String? id,
    String? name,
    String? theme,
    Offset? center,
    double? radius,
    Color? color,
    List<String>? stickerIds,
    DateTime? createdAt,
  }) {
    return StickerZone(
      id: id ?? this.id,
      name: name ?? this.name,
      theme: theme ?? this.theme,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      color: color ?? this.color,
      stickerIds: stickerIds ?? this.stickerIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'theme': theme,
      'center': {'x': center.dx, 'y': center.dy},
      'radius': radius,
      'color': (color.a.round() << 24) | (color.r.round() << 16) | (color.g.round() << 8) | color.b.round(),
      'stickerIds': stickerIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory StickerZone.fromJson(Map<String, dynamic> json) {
    final centerData = json['center'] as Map<String, dynamic>;
    return StickerZone(
      id: json['id'],
      name: json['name'],
      theme: json['theme'],
      center: Offset(centerData['x'], centerData['y']),
      radius: json['radius'] ?? 200.0,
      color: Color(json['color']),
      stickerIds: List<String>.from(json['stickerIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Represents a creative canvas (infinite mode or single page)
class CreativeCanvas {
  final String id;
  final String name;
  final CanvasBackground background;
  final List<PlacedSticker> stickers;
  final List<DrawingStroke> drawings;
  final List<CanvasText> texts;
  final List<StickerZone> zones; // New: thematic zones for infinite canvas
  final DateTime createdAt;
  final DateTime lastModified;
  final Size canvasSize; // For finite canvas mode
  final CanvasViewport viewport; // For infinite canvas mode
  final bool isInfinite; // New: distinguishes infinite vs finite canvas

  const CreativeCanvas({
    required this.id,
    required this.name,
    required this.background,
    this.stickers = const [],
    this.drawings = const [],
    this.texts = const [],
    this.zones = const [],
    required this.createdAt,
    required this.lastModified,
    this.canvasSize = const Size(800, 600),
    this.viewport = const CanvasViewport(screenSize: Size(800, 600)),
    this.isInfinite = false,
  });
  
  /// Constructor for infinite canvas
  CreativeCanvas.infinite({
    required this.id,
    required this.name,
    required this.background,
    this.stickers = const [],
    this.drawings = const [],
    this.texts = const [],
    this.zones = const [],
    required this.createdAt,
    required this.lastModified,
    required this.viewport,
  }) : canvasSize = const Size(800, 600), // Not used for infinite
       isInfinite = true;

  /// Gets stickers that are visible in the current viewport (for infinite canvas)
  List<PlacedSticker> get visibleStickers {
    if (!isInfinite) return stickers;
    
    return stickers.where((sticker) {
      return viewport.bounds.contains(sticker.position);
    }).toList();
  }
  
  /// Gets zones that are visible in the current viewport
  List<StickerZone> get visibleZones {
    if (!isInfinite) return zones;
    
    return zones.where((zone) {
      return viewport.bounds.overlaps(Rect.fromCenter(
        center: zone.center,
        width: zone.radius * 2,
        height: zone.radius * 2,
      ));
    }).toList();
  }
  
  /// Gets the bounding box that contains all stickers
  Rect? get contentBounds {
    if (stickers.isEmpty) return null;
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final sticker in stickers) {
      minX = math.min(minX, sticker.position.dx);
      minY = math.min(minY, sticker.position.dy);
      maxX = math.max(maxX, sticker.position.dx);
      maxY = math.max(maxY, sticker.position.dy);
    }
    
    return Rect.fromLTRB(minX - 50, minY - 50, maxX + 50, maxY + 50);
  }

  Map<String, dynamic> toJson() {
    // DEBUG: Log CreativeCanvas serialization
    Timber.d('[CreativeCanvas.toJson] Serializing canvas $id with ${drawings.length} drawings');
    final result = {
      'id': id,
      'name': name,
      'background': background.toJson(),
      'stickers': stickers.map((s) => s.toJson()).toList(),
      'drawings': drawings.map((d) => d.toJson()).toList(),
      'texts': texts.map((t) => t.toJson()).toList(),
      'zones': zones.map((z) => z.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'canvasSize': {'width': canvasSize.width, 'height': canvasSize.height},
      'viewport': viewport.toJson(),
      'isInfinite': isInfinite,
    };
    Timber.d('[CreativeCanvas.toJson] Serialized drawings array length: ${(result['drawings'] as List?)?.length}');
    return result;
  }

  factory CreativeCanvas.fromJson(Map<String, dynamic> json) {
    // DEBUG: Log CreativeCanvas deserialization
    Timber.d('[CreativeCanvas.fromJson] Deserializing canvas: ${json["id"]}');
    final drawingsJson = json['drawings'] as List? ?? [];
    Timber.d('[CreativeCanvas.fromJson] Found ${drawingsJson.length} drawings in JSON');
    
    final canvasSizeData = json['canvasSize'] as Map<String, dynamic>;
    final isInfinite = json['isInfinite'] ?? false;
    
    final drawings = drawingsJson.map((d) => DrawingStroke.fromJson(d)).toList();
    Timber.d('[CreativeCanvas.fromJson] Deserialized ${drawings.length} drawings');
    
    return CreativeCanvas(
      id: json['id'],
      name: json['name'],
      background: CanvasBackground.fromJson(json['background']),
      stickers: (json['stickers'] as List? ?? [])
          .map((s) => PlacedSticker.fromJson(s))
          .toList(),
      drawings: drawings,
      texts: (json['texts'] as List? ?? [])
          .map((t) => CanvasText.fromJson(t))
          .toList(),
      zones: (json['zones'] as List? ?? [])
          .map((z) => StickerZone.fromJson(z))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      canvasSize: Size(canvasSizeData['width'], canvasSizeData['height']),
      viewport: json['viewport'] != null 
          ? CanvasViewport.fromJson(json['viewport'])
          : CanvasViewport(screenSize: Size(canvasSizeData['width'], canvasSizeData['height'])),
      isInfinite: isInfinite,
    );
  }

  CreativeCanvas copyWith({
    String? id,
    String? name,
    CanvasBackground? background,
    List<PlacedSticker>? stickers,
    List<DrawingStroke>? drawings,
    List<CanvasText>? texts,
    List<StickerZone>? zones,
    DateTime? createdAt,
    DateTime? lastModified,
    Size? canvasSize,
    CanvasViewport? viewport,
    bool? isInfinite,
  }) {
    return CreativeCanvas(
      id: id ?? this.id,
      name: name ?? this.name,
      background: background ?? this.background,
      stickers: stickers ?? this.stickers,
      drawings: drawings ?? this.drawings,
      texts: texts ?? this.texts,
      zones: zones ?? this.zones,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      canvasSize: canvasSize ?? this.canvasSize,
      viewport: viewport ?? this.viewport,
      isInfinite: isInfinite ?? this.isInfinite,
    );
  }
}

/// Represents a flip book with multiple pages
class FlipBook {
  final String id;
  final String name;
  final String description;
  final List<CreativeCanvas> pages;
  final DateTime createdAt;
  final DateTime lastModified;
  final int currentPageIndex;

  const FlipBook({
    required this.id,
    required this.name,
    this.description = '',
    this.pages = const [],
    required this.createdAt,
    required this.lastModified,
    this.currentPageIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pages': pages.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'currentPageIndex': currentPageIndex,
    };
  }

  factory FlipBook.fromJson(Map<String, dynamic> json) {
    return FlipBook(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      pages: (json['pages'] as List)
          .map((p) => CreativeCanvas.fromJson(p))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      currentPageIndex: json['currentPageIndex'] ?? 0,
    );
  }

  FlipBook copyWith({
    String? id,
    String? name,
    String? description,
    List<CreativeCanvas>? pages,
    DateTime? createdAt,
    DateTime? lastModified,
    int? currentPageIndex,
  }) {
    return FlipBook(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }

  CreativeCanvas? get currentPage {
    if (currentPageIndex >= 0 && currentPageIndex < pages.length) {
      return pages[currentPageIndex];
    }
    return null;
  }
}

/// Tool types for the creative canvas
enum CanvasTool {
  select,
  sticker,
  draw,
  text,
  eraser,
}

/// Drawing brush types
enum BrushType {
  normal,
  thick,
  thin,
  marker,
  crayon,
}

/// Creation mode for the sticker book
enum CreationMode {
  infiniteCanvas,
  flipBook,
}

/// Represents sticker book project
class StickerBookProject {
  final String id;
  final String name;
  final String description;
  final CreationMode mode;
  final CreativeCanvas? infiniteCanvas;
  final FlipBook? flipBook;
  final DateTime createdAt;
  final DateTime lastModified;
  final String? thumbnailPath;

  const StickerBookProject({
    required this.id,
    required this.name,
    this.description = '',
    required this.mode,
    this.infiniteCanvas,
    this.flipBook,
    required this.createdAt,
    required this.lastModified,
    this.thumbnailPath,
  });

  /// Check if project is completed (basic implementation)
  bool get isCompleted {
    // Simple completion check - could be enhanced based on actual content
    return infiniteCanvas != null || flipBook != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'mode': mode.name,
      'infiniteCanvas': infiniteCanvas?.toJson(),
      'flipBook': flipBook?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'thumbnailPath': thumbnailPath,
    };
  }

  factory StickerBookProject.fromJson(Map<String, dynamic> json) {
    return StickerBookProject(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      mode: CreationMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => CreationMode.infiniteCanvas,
      ),
      infiniteCanvas: json['infiniteCanvas'] != null 
          ? CreativeCanvas.fromJson(json['infiniteCanvas'])
          : null,
      flipBook: json['flipBook'] != null 
          ? FlipBook.fromJson(json['flipBook'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      thumbnailPath: json['thumbnailPath'],
    );
  }

  StickerBookProject copyWith({
    String? id,
    String? name,
    String? description,
    CreationMode? mode,
    CreativeCanvas? infiniteCanvas,
    FlipBook? flipBook,
    DateTime? createdAt,
    DateTime? lastModified,
    String? thumbnailPath,
  }) {
    return StickerBookProject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mode: mode ?? this.mode,
      infiniteCanvas: infiniteCanvas ?? this.infiniteCanvas,
      flipBook: flipBook ?? this.flipBook,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}

/// Represents sticker pack for organization
class StickerPack {
  final String id;
  final String name;
  final String description;
  final StickerCategory category;
  final List<Sticker> stickers;
  final String? thumbnailPath;
  final bool isUnlocked;
  final bool isPremium;

  const StickerPack({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.stickers,
    this.thumbnailPath,
    this.isUnlocked = true,
    this.isPremium = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'stickers': stickers.map((s) => s.toJson()).toList(),
      'thumbnailPath': thumbnailPath,
      'isUnlocked': isUnlocked,
      'isPremium': isPremium,
    };
  }

  factory StickerPack.fromJson(Map<String, dynamic> json) {
    return StickerPack(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: StickerCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => StickerCategory.custom,
      ),
      stickers: (json['stickers'] as List)
          .map((s) => Sticker.fromJson(s))
          .toList(),
      thumbnailPath: json['thumbnailPath'],
      isUnlocked: json['isUnlocked'] ?? true,
      isPremium: json['isPremium'] ?? false,
    );
  }

  StickerPack copyWith({
    String? id,
    String? name,
    String? description,
    StickerCategory? category,
    List<Sticker>? stickers,
    String? thumbnailPath,
    bool? isUnlocked,
    bool? isPremium,
  }) {
    return StickerPack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      stickers: stickers ?? this.stickers,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

/// Game state for the enhanced sticker book
class StickerBookGameState {
  final List<StickerBookProject> projects;
  final List<StickerPack> stickerPacks;
  final Set<String> unlockedStickers;
  final String? currentProjectId;
  final String? currentlyEditingProjectId; // Track when editing an existing saved project
  final CreationMode defaultMode;
  final CanvasTool selectedTool;
  final Color selectedColor;
  final double selectedBrushSize;
  final BrushType selectedBrushType;
  final Map<String, dynamic> settings;
  final int totalCreations;
  final DateTime? lastPlayDate;
  final AgeMode ageMode;
  final int childAge;

  const StickerBookGameState({
    this.projects = const [],
    this.stickerPacks = const [],
    this.unlockedStickers = const {},
    this.currentProjectId,
    this.currentlyEditingProjectId,
    this.defaultMode = CreationMode.infiniteCanvas,
    this.selectedTool = CanvasTool.sticker,
    this.selectedColor = Colors.black,
    this.selectedBrushSize = 5.0,
    this.selectedBrushType = BrushType.normal,
    this.settings = const {},
    this.totalCreations = 0,
    this.lastPlayDate,
    this.ageMode = AgeMode.bigKid,
    this.childAge = 8,
  });

  StickerBookProject? get currentProject {
    if (currentProjectId == null) return null;
    try {
      return projects.firstWhere((project) => project.id == currentProjectId);
    } catch (e) {
      return null;
    }
  }

  List<Sticker> get availableStickers {
    return stickerPacks
        .where((pack) => pack.isUnlocked)
        .expand((pack) => pack.stickers)
        .where((sticker) => !sticker.requiresUnlock || unlockedStickers.contains(sticker.id))
        .toList();
  }

  /// Total number of stickers collected by the child
  int get totalStickersCollected {
    return unlockedStickers.length;
  }

  /// Current score based on creations and achievements  
  int get score {
    return (totalCreations * 10) + (unlockedStickers.length * 5);
  }

  /// Current level based on score
  int get level {
    return (score / 100).floor() + 1;
  }

  /// List of sticker books (same as projects for compatibility)
  List<StickerBookProject> get books {
    return projects;
  }
  
  /// Get UI scaling configuration based on age mode
  UIScaling get uiScaling {
    return ageMode == AgeMode.littleKid ? UIScaling.littleKid : UIScaling.bigKid;
  }
  
  /// Get tool configuration based on age mode
  ToolConfig get toolConfig {
    return ageMode == AgeMode.littleKid ? ToolConfig.littleKid : ToolConfig.bigKid;
  }
  
  /// Get canvas configuration based on age mode
  CanvasConfig get canvasConfig {
    return ageMode == AgeMode.littleKid ? CanvasConfig.littleKid : CanvasConfig.bigKid;
  }
  
  /// Get available tools for current age mode
  Set<CanvasTool> get availableTools {
    return toolConfig.availableTools;
  }
  
  /// Should show tool labels based on age mode
  bool get shouldShowToolLabels {
    return toolConfig.showToolLabels;
  }
  
  /// Should use voice guidance based on age mode
  bool get shouldUseVoiceGuidance {
    return toolConfig.voiceGuidance;
  }

  Map<String, dynamic> toJson() {
    return {
      'projects': projects.map((p) => p.toJson()).toList(),
      'stickerPacks': stickerPacks.map((p) => p.toJson()).toList(),
      'unlockedStickers': unlockedStickers.toList(),
      'currentProjectId': currentProjectId,
      'currentlyEditingProjectId': currentlyEditingProjectId,
      'defaultMode': defaultMode.name,
      'selectedTool': selectedTool.name,
      'selectedColor': (selectedColor.a.round() << 24) | (selectedColor.r.round() << 16) | (selectedColor.g.round() << 8) | selectedColor.b.round(),
      'selectedBrushSize': selectedBrushSize,
      'selectedBrushType': selectedBrushType.name,
      'settings': settings,
      'totalCreations': totalCreations,
      'lastPlayDate': lastPlayDate?.toIso8601String(),
      'ageMode': ageMode.name,
      'childAge': childAge,
    };
  }

  factory StickerBookGameState.fromJson(Map<String, dynamic> json) {
    return StickerBookGameState(
      projects: (json['projects'] as List? ?? [])
          .map((p) => StickerBookProject.fromJson(p))
          .toList(),
      stickerPacks: (json['stickerPacks'] as List? ?? [])
          .map((p) => StickerPack.fromJson(p))
          .toList(),
      unlockedStickers: Set<String>.from(json['unlockedStickers'] ?? []),
      currentProjectId: json['currentProjectId'],
      currentlyEditingProjectId: json['currentlyEditingProjectId'],
      defaultMode: CreationMode.values.firstWhere(
        (e) => e.name == json['defaultMode'],
        orElse: () => CreationMode.infiniteCanvas,
      ),
      selectedTool: CanvasTool.values.firstWhere(
        (e) => e.name == json['selectedTool'],
        orElse: () => CanvasTool.sticker,
      ),
      selectedColor: Color(json['selectedColor'] ?? ((Colors.black.a.round() << 24) | (Colors.black.r.round() << 16) | (Colors.black.g.round() << 8) | Colors.black.b.round())),
      selectedBrushSize: (json['selectedBrushSize'] ?? 5.0).toDouble(),
      selectedBrushType: BrushType.values.firstWhere(
        (e) => e.name == json['selectedBrushType'],
        orElse: () => BrushType.normal,
      ),
      settings: json['settings'] ?? {},
      totalCreations: json['totalCreations'] ?? 0,
      lastPlayDate: json['lastPlayDate'] != null 
          ? DateTime.parse(json['lastPlayDate']) 
          : null,
      ageMode: AgeMode.values.firstWhere(
        (e) => e.name == json['ageMode'],
        orElse: () => AgeMode.bigKid,
      ),
      childAge: json['childAge'] ?? 8,
    );
  }

  StickerBookGameState copyWith({
    List<StickerBookProject>? projects,
    List<StickerPack>? stickerPacks,
    Set<String>? unlockedStickers,
    String? currentProjectId,
    String? currentlyEditingProjectId,
    CreationMode? defaultMode,
    CanvasTool? selectedTool,
    Color? selectedColor,
    double? selectedBrushSize,
    BrushType? selectedBrushType,
    Map<String, dynamic>? settings,
    int? totalCreations,
    DateTime? lastPlayDate,
    AgeMode? ageMode,
    int? childAge,
  }) {
    return StickerBookGameState(
      projects: projects ?? this.projects,
      stickerPacks: stickerPacks ?? this.stickerPacks,
      unlockedStickers: unlockedStickers ?? this.unlockedStickers,
      currentProjectId: currentProjectId ?? this.currentProjectId,
      currentlyEditingProjectId: currentlyEditingProjectId ?? this.currentlyEditingProjectId,
      defaultMode: defaultMode ?? this.defaultMode,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedBrushSize: selectedBrushSize ?? this.selectedBrushSize,
      selectedBrushType: selectedBrushType ?? this.selectedBrushType,
      settings: settings ?? this.settings,
      totalCreations: totalCreations ?? this.totalCreations,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
      ageMode: ageMode ?? this.ageMode,
      childAge: childAge ?? this.childAge,
    );
  }
}

/// Age mode for sticker game
enum AgeMode {
  littleKid, // Ages 3-6
  bigKid,    // Ages 7-12
}

/// UI scaling configuration
class UIScaling {
  final double buttonSize;
  final double iconSize;
  final double fontSize;
  final double touchTargetMin;
  final double colorSwatchSize;
  final EdgeInsets padding;
  
  const UIScaling({
    required this.buttonSize,
    required this.iconSize,
    required this.fontSize,
    required this.touchTargetMin,
    required this.colorSwatchSize,
    required this.padding,
  });
  
  static const UIScaling littleKid = UIScaling(
    buttonSize: 64.0,
    iconSize: 32.0,
    fontSize: 18.0,
    touchTargetMin: 64.0,
    colorSwatchSize: 48.0,
    padding: EdgeInsets.all(16.0),
  );
  
  static const UIScaling bigKid = UIScaling(
    buttonSize: 48.0,
    iconSize: 24.0,
    fontSize: 14.0,
    touchTargetMin: 44.0,
    colorSwatchSize: 32.0,
    padding: EdgeInsets.all(12.0),
  );
}

/// Tool configuration for different age modes
class ToolConfig {
  final Set<CanvasTool> availableTools;
  final bool showToolLabels;
  final bool voiceGuidance;
  final bool simplified;
  
  const ToolConfig({
    required this.availableTools,
    required this.showToolLabels,
    required this.voiceGuidance,
    required this.simplified,
  });
  
  static const ToolConfig littleKid = ToolConfig(
    availableTools: {
      CanvasTool.sticker,
      CanvasTool.draw,
      CanvasTool.eraser,
    },
    showToolLabels: true,
    voiceGuidance: true,
    simplified: true,
  );
  
  static const ToolConfig bigKid = ToolConfig(
    availableTools: {
      CanvasTool.select,
      CanvasTool.sticker,
      CanvasTool.draw,
      CanvasTool.text,
      CanvasTool.eraser,
    },
    showToolLabels: false,
    voiceGuidance: false,
    simplified: false,
  );
}

/// Canvas behavior configuration
class CanvasConfig {
  final bool allowPanZoom;
  final bool showInfiniteCanvas;
  final bool showZones;
  final bool autoSave;
  final int maxColors;
  final Size? fixedCanvasSize;
  
  const CanvasConfig({
    required this.allowPanZoom,
    required this.showInfiniteCanvas,
    required this.showZones,
    required this.autoSave,
    required this.maxColors,
    this.fixedCanvasSize,
  });
  
  static const CanvasConfig littleKid = CanvasConfig(
    allowPanZoom: false,
    showInfiniteCanvas: false,
    showZones: false,
    autoSave: true,
    maxColors: 8,
    fixedCanvasSize: Size(600, 450), // 4:3 aspect ratio
  );
  
  static const CanvasConfig bigKid = CanvasConfig(
    allowPanZoom: true,
    showInfiniteCanvas: true,
    showZones: true,
    autoSave: true,
    maxColors: 16,
  );
}

/// Export format options
enum ExportFormat {
  png,
  jpeg,
  pdf,
  gif, // For flip books
}

/// Represents export settings
class ExportSettings {
  final ExportFormat format;
  final int quality; // 1-100 for JPEG
  final Size? customSize;
  final bool includeBackground;
  final bool highResolution;

  const ExportSettings({
    this.format = ExportFormat.png,
    this.quality = 90,
    this.customSize,
    this.includeBackground = true,
    this.highResolution = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'format': format.name,
      'quality': quality,
      'customSize': customSize != null 
          ? {'width': customSize!.width, 'height': customSize!.height}
          : null,
      'includeBackground': includeBackground,
      'highResolution': highResolution,
    };
  }

  factory ExportSettings.fromJson(Map<String, dynamic> json) {
    final customSizeData = json['customSize'] as Map<String, dynamic>?;
    return ExportSettings(
      format: ExportFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => ExportFormat.png,
      ),
      quality: json['quality'] ?? 90,
      customSize: customSizeData != null 
          ? Size(customSizeData['width'], customSizeData['height'])
          : null,
      includeBackground: json['includeBackground'] ?? true,
      highResolution: json['highResolution'] ?? false,
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
      'color': (color.a.round() << 24) | (color.r.round() << 16) | (color.g.round() << 8) | color.b.round(),
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'name': name,
      'secondaryColor': secondaryColor != null ? (secondaryColor!.a.round() << 24) | (secondaryColor!.r.round() << 16) | (secondaryColor!.g.round() << 8) | secondaryColor!.b.round() : null,
      'backgroundColor': backgroundColor != null ? (backgroundColor!.a.round() << 24) | (backgroundColor!.r.round() << 16) | (backgroundColor!.g.round() << 8) | backgroundColor!.b.round() : null,
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

/// Represents a slot where a sticker can be placed (for mini-games)
class StickerSlot {
  final String id;
  final Sticker targetSticker;
  final bool isUnlocked;
  final String difficulty;
  final String? hint;

  const StickerSlot({
    required this.id,
    required this.targetSticker,
    this.isUnlocked = false,
    this.difficulty = 'easy',
    this.hint,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetSticker': targetSticker.toJson(),
      'isUnlocked': isUnlocked,
      'difficulty': difficulty,
    };
  }

  factory StickerSlot.fromJson(Map<String, dynamic> json) {
    return StickerSlot(
      id: json['id'],
      targetSticker: Sticker.fromJson(json['targetSticker']),
      isUnlocked: json['isUnlocked'] ?? false,
      difficulty: json['difficulty'] ?? 'easy',
    );
  }

  StickerSlot copyWith({
    String? id,
    Sticker? targetSticker,
    bool? isUnlocked,
    String? difficulty,
  }) {
    return StickerSlot(
      id: id ?? this.id,
      targetSticker: targetSticker ?? this.targetSticker,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

/// Represents a page in a sticker book with completion tracking
class StickerPage {
  final String id;
  final String title;
  final String? description;
  final List<StickerSlot> slots;
  final int requiredStickers;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? theme;

  const StickerPage({
    required this.id,
    required this.title,
    this.description,
    required this.slots,
    required this.requiredStickers,
    this.isCompleted = false,
    this.completedAt,
    this.theme,
  });

  double get completionProgress {
    if (slots.isEmpty) return 0.0;
    final unlockedCount = slots.where((slot) => slot.isUnlocked).length;
    return unlockedCount / slots.length;
  }

  /// Alias for slots property for compatibility
  List<StickerSlot> get stickerSlots => slots;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'slots': slots.map((s) => s.toJson()).toList(),
      'requiredStickers': requiredStickers,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory StickerPage.fromJson(Map<String, dynamic> json) {
    return StickerPage(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      slots: (json['slots'] as List? ?? [])
          .map((s) => StickerSlot.fromJson(s))
          .toList(),
      requiredStickers: json['requiredStickers'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }

  StickerPage copyWith({
    String? id,
    String? title,
    String? description,
    List<StickerSlot>? slots,
    int? requiredStickers,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return StickerPage(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      slots: slots ?? this.slots,
      requiredStickers: requiredStickers ?? this.requiredStickers,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Represents a complete sticker book with multiple pages
class StickerBook {
  final String id;
  final String title;
  final String? description;
  final List<StickerPage> pages;
  final StickerCategory category;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? theme;

  const StickerBook({
    required this.id,
    required this.title,
    this.description,
    required this.pages,
    required this.category,
    this.isCompleted = false,
    this.completedAt,
    this.theme,
  });

  double get completionProgress {
    if (pages.isEmpty) return 0.0;
    final totalSlots = pages.expand((page) => page.slots).length;
    if (totalSlots == 0) return 0.0;
    final unlockedSlots = pages
        .expand((page) => page.slots)
        .where((slot) => slot.isUnlocked)
        .length;
    return unlockedSlots / totalSlots;
  }

  int get totalStickers {
    return pages.expand((page) => page.slots).length;
  }

  int get unlockedStickers {
    return pages
        .expand((page) => page.slots)
        .where((slot) => slot.isUnlocked)
        .length;
  }

  /// Completion progress as percentage (0-100)
  double get completionPercentage {
    return completionProgress * 100;
  }

  /// Educational topics covered by this book
  List<String> get educationalTopics {
    return [category.name]; // Basic implementation using category
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pages': pages.map((p) => p.toJson()).toList(),
      'category': category.name,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory StickerBook.fromJson(Map<String, dynamic> json) {
    return StickerBook(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pages: (json['pages'] as List? ?? [])
          .map((p) => StickerPage.fromJson(p))
          .toList(),
      category: StickerCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => StickerCategory.custom,
      ),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }

  StickerBook copyWith({
    String? id,
    String? title,
    String? description,
    List<StickerPage>? pages,
    StickerCategory? category,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return StickerBook(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pages: pages ?? this.pages,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}


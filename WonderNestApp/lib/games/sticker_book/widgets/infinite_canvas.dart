import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/sticker_models.dart';

/// Truly infinite canvas widget with zoom, pan, zones, and minimap
class InfiniteCanvasWidget extends StatefulWidget {
  final CreativeCanvas canvas;
  final List<Sticker> availableStickers;
  final CanvasTool selectedTool;
  final Color selectedColor;
  final double selectedBrushSize;
  final BrushType selectedBrushType;
  final Function(CreativeCanvas) onCanvasChanged;
  final VoidCallback? onToolRequest;

  const InfiniteCanvasWidget({
    super.key,
    required this.canvas,
    required this.availableStickers,
    required this.selectedTool,
    required this.selectedColor,
    required this.selectedBrushSize,
    required this.selectedBrushType,
    required this.onCanvasChanged,
    this.onToolRequest,
  });

  @override
  State<InfiniteCanvasWidget> createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends State<InfiniteCanvasWidget>
    with TickerProviderStateMixin {
  late CanvasViewport _viewport;
  final TransformationController _transformController = TransformationController();
  
  // Selection and interaction state
  PlacedSticker? _selectedSticker;
  CanvasText? _selectedText;
  StickerZone? _selectedZone;
  
  // Drawing state
  List<Offset> _currentStroke = [];
  bool _isDrawing = false;
  
  // Text editing
  TextEditingController? _textController;
  bool _isEditingText = false;
  
  // Zone creation
  bool _isCreatingZone = false;
  Offset? _zoneStartPoint;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  
  // Constants for infinite canvas behavior
  static const double _minZoom = 0.1;
  static const double _maxZoom = 5.0;
  static const double _homePosition = 0.0; // Origin point
  
  @override
  void initState() {
    super.initState();
    _viewport = widget.canvas.viewport;
    _setupTransform();
    _setupAnimations();
  }

  void _setupTransform() {
    final matrix = Matrix4.identity()
      ..scale(_viewport.zoom)
      ..translate(-_viewport.center.dx, -_viewport.center.dy);
    _transformController.value = matrix;
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    _textController?.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          children: [
            // Main infinite canvas
            _buildInfiniteCanvas(screenSize),
            
            // Minimap
            _buildMinimap(screenSize),
            
            // Navigation controls
            _buildNavigationControls(),
            
            // Zone controls
            _buildZoneControls(),
            
            // Text input overlay
            if (_isEditingText) _buildTextInput(),
          ],
        );
      },
    );
  }

  Widget _buildInfiniteCanvas(Size screenSize) {
    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: _minZoom,
      maxScale: _maxZoom,
      onInteractionStart: _handleInteractionStart,
      onInteractionUpdate: _handleInteractionUpdate,
      onInteractionEnd: _handleInteractionEnd,
      child: CustomPaint(
        painter: InfiniteCanvasPainter(
          canvas: widget.canvas,
          viewport: _viewport,
          selectedSticker: _selectedSticker,
          selectedText: _selectedText,
          selectedZone: _selectedZone,
          currentStroke: _currentStroke,
          selectedColor: widget.selectedColor,
          selectedBrushSize: widget.selectedBrushSize,
          isDrawing: _isDrawing,
          isCreatingZone: _isCreatingZone,
          zoneStartPoint: _zoneStartPoint,
          showGrid: true,
        ),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimap(Size screenSize) {
    final minimapSize = Size(200, 150);
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        width: minimapSize.width,
        height: minimapSize.height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: MinimapPainter(
              canvas: widget.canvas,
              viewport: _viewport,
              screenSize: screenSize,
              minimapSize: minimapSize,
            ),
            child: GestureDetector(
              onTapDown: _handleMinimapTap,
              onPanUpdate: _handleMinimapPan,
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        children: [
          // Home button
          FloatingActionButton.small(
            heroTag: "home",
            onPressed: _goToHome,
            backgroundColor: Colors.blue[100],
            child: const Icon(Icons.home, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          
          // Zoom to fit content
          FloatingActionButton.small(
            heroTag: "fit",
            onPressed: _zoomToFitContent,
            backgroundColor: Colors.green[100],
            child: const Icon(Icons.fit_screen, color: Colors.green),
          ),
          const SizedBox(height: 8),
          
          // Find stickers
          FloatingActionButton.small(
            heroTag: "find",
            onPressed: _showStickerFinder,
            backgroundColor: Colors.orange[100],
            child: const Icon(Icons.search, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneControls() {
    return Positioned(
      bottom: 100,
      left: 20,
      child: Column(
        children: [
          // Create zone button
          FloatingActionButton.small(
            heroTag: "zone",
            onPressed: _toggleZoneCreation,
            backgroundColor: _isCreatingZone ? Colors.red[100] : Colors.purple[100],
            child: Icon(
              _isCreatingZone ? Icons.close : Icons.add_location,
              color: _isCreatingZone ? Colors.red : Colors.purple,
            ),
          ),
          if (widget.canvas.zones.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Zone navigation
            FloatingActionButton.small(
              heroTag: "zones",
              onPressed: _showZoneNavigator,
              backgroundColor: Colors.teal[100],
              child: const Icon(Icons.map, color: Colors.teal),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Text',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type your text here...',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _cancelTextInput,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmTextInput,
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Event handlers
  void _handleInteractionStart(ScaleStartDetails details) {
    _clearSelection();
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    _updateViewportFromTransform();
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    _updateViewportFromTransform();
    _updateCanvas();
  }

  void _handleTapDown(TapDownDetails details) {
    final canvasPosition = _screenToCanvasPosition(details.localPosition);
    
    switch (widget.selectedTool) {
      case CanvasTool.select:
        _selectAtPosition(canvasPosition);
        break;
      case CanvasTool.sticker:
        _requestStickerPlacement(canvasPosition);
        break;
      case CanvasTool.text:
        _startTextInput(canvasPosition);
        break;
      case CanvasTool.draw:
        _startDrawing(canvasPosition);
        break;
      case CanvasTool.eraser:
        _eraseAtPosition(canvasPosition);
        break;
    }
    
    if (_isCreatingZone) {
      _handleZoneCreation(canvasPosition);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    final canvasPosition = _screenToCanvasPosition(details.localPosition);
    
    if (widget.selectedTool == CanvasTool.draw) {
      _startDrawing(canvasPosition);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final canvasPosition = _screenToCanvasPosition(details.localPosition);
    
    if (widget.selectedTool == CanvasTool.draw && _isDrawing) {
      _continueDrawing(canvasPosition);
    } else if (widget.selectedTool == CanvasTool.eraser) {
      _eraseAtPosition(canvasPosition);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.selectedTool == CanvasTool.draw && _isDrawing) {
      _finishDrawing();
    }
  }

  void _handleMinimapTap(TapDownDetails details) {
    final minimapPosition = details.localPosition;
    final canvasPosition = _minimapToCanvasPosition(minimapPosition, Size(200, 150));
    _animateToPosition(canvasPosition);
  }

  void _handleMinimapPan(DragUpdateDetails details) {
    final minimapPosition = details.localPosition;
    final canvasPosition = _minimapToCanvasPosition(minimapPosition, Size(200, 150));
    _jumpToPosition(canvasPosition);
  }

  // Coordinate transformation methods
  Offset _screenToCanvasPosition(Offset screenPosition) {
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();
    
    // Transform screen position to canvas position
    final canvasX = (screenPosition.dx - translation.x) / scale;
    final canvasY = (screenPosition.dy - translation.y) / scale;
    
    return Offset(canvasX, canvasY);
  }

  Offset _minimapToCanvasPosition(Offset minimapPosition, Size minimapSize) {
    final contentBounds = widget.canvas.contentBounds ?? const Rect.fromLTWH(-500, -500, 1000, 1000);
    
    final x = contentBounds.left + (minimapPosition.dx / minimapSize.width) * contentBounds.width;
    final y = contentBounds.top + (minimapPosition.dy / minimapSize.height) * contentBounds.height;
    
    return Offset(x, y);
  }

  void _updateViewportFromTransform() {
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();
    
    final center = Offset(-translation.x / scale, -translation.y / scale);
    
    setState(() {
      _viewport = _viewport.copyWith(
        zoom: scale,
        center: center,
      );
    });
  }

  // Navigation methods
  void _goToHome() {
    _animateToPosition(const Offset(_homePosition, _homePosition));
  }

  void _zoomToFitContent() {
    final contentBounds = widget.canvas.contentBounds;
    if (contentBounds == null) {
      _goToHome();
      return;
    }
    
    final screenSize = MediaQuery.of(context).size;
    final contentSize = contentBounds.size;
    
    final scaleX = screenSize.width * 0.8 / contentSize.width;
    final scaleY = screenSize.height * 0.8 / contentSize.height;
    final scale = math.min(scaleX, scaleY).clamp(_minZoom, _maxZoom);
    
    _animateToPositionWithZoom(contentBounds.center, scale);
  }

  void _animateToPosition(Offset canvasPosition) {
    _animateToPositionWithZoom(canvasPosition, _viewport.zoom);
  }

  void _animateToPositionWithZoom(Offset canvasPosition, double zoom) {
    final targetMatrix = Matrix4.identity()
      ..scale(zoom)
      ..translate(-canvasPosition.dx, -canvasPosition.dy);
    
    _transformController.value = targetMatrix;
    _updateViewportFromTransform();
    _updateCanvas();
  }

  void _jumpToPosition(Offset canvasPosition) {
    final targetMatrix = Matrix4.identity()
      ..scale(_viewport.zoom)
      ..translate(-canvasPosition.dx, -canvasPosition.dy);
    
    _transformController.value = targetMatrix;
    _updateViewportFromTransform();
    _updateCanvas();
  }

  // Tool-specific methods
  void _selectAtPosition(Offset canvasPosition) {
    // Find the topmost sticker at this position
    PlacedSticker? foundSticker;
    for (final sticker in widget.canvas.visibleStickers.reversed) {
      final distance = (sticker.position - canvasPosition).distance;
      if (distance <= 30) {
        foundSticker = sticker;
        break;
      }
    }
    
    if (foundSticker != null) {
      setState(() {
        _selectedSticker = foundSticker;
        _selectedText = null;
        _selectedZone = null;
      });
      return;
    }
    
    // Check for text
    CanvasText? foundText;
    for (final text in widget.canvas.texts.reversed) {
      final distance = (text.position - canvasPosition).distance;
      if (distance <= 50) {
        foundText = text;
        break;
      }
    }
    
    if (foundText != null) {
      setState(() {
        _selectedText = foundText;
        _selectedSticker = null;
        _selectedZone = null;
      });
      return;
    }
    
    // Check for zones
    StickerZone? foundZone;
    for (final zone in widget.canvas.zones) {
      if (zone.containsPoint(canvasPosition)) {
        foundZone = zone;
        break;
      }
    }
    
    if (foundZone != null) {
      setState(() {
        _selectedZone = foundZone;
        _selectedSticker = null;
        _selectedText = null;
      });
    }
  }

  void _requestStickerPlacement(Offset canvasPosition) {
    widget.onToolRequest?.call();
    _showStickerPicker(canvasPosition);
  }

  void _showStickerPicker(Offset canvasPosition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose a Sticker'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: math.min(widget.availableStickers.length, 16),
            itemBuilder: (context, index) {
              final sticker = widget.availableStickers[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  _addSticker(sticker, canvasPosition);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      sticker.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _addSticker(Sticker sticker, Offset position) {
    final placedSticker = PlacedSticker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sticker: sticker,
      position: position,
      placedAt: DateTime.now(),
    );

    final updatedCanvas = widget.canvas.copyWith(
      stickers: [...widget.canvas.stickers, placedSticker],
      viewport: _viewport,
      lastModified: DateTime.now(),
    );

    widget.onCanvasChanged(updatedCanvas);
    _playHapticFeedback();
    _bounceController.forward().then((_) => _bounceController.reverse());
  }

  void _startDrawing(Offset position) {
    setState(() {
      _isDrawing = true;
      _currentStroke = [position];
    });
  }

  void _continueDrawing(Offset position) {
    if (!_isDrawing) return;
    
    setState(() {
      _currentStroke.add(position);
    });
  }

  void _finishDrawing() {
    if (!_isDrawing || _currentStroke.isEmpty) return;

    final stroke = DrawingStroke(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: List.from(_currentStroke),
      color: widget.selectedColor,
      strokeWidth: widget.selectedBrushSize,
      paintStyle: Paint()
        ..color = widget.selectedColor
        ..strokeWidth = widget.selectedBrushSize
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      createdAt: DateTime.now(),
    );

    final updatedCanvas = widget.canvas.copyWith(
      drawings: [...widget.canvas.drawings, stroke],
      viewport: _viewport,
      lastModified: DateTime.now(),
    );

    widget.onCanvasChanged(updatedCanvas);

    setState(() {
      _isDrawing = false;
      _currentStroke.clear();
    });
    
    _playHapticFeedback();
  }

  void _eraseAtPosition(Offset position) {
    const eraseRadius = 30.0;
    bool hasChanges = false;

    // Remove stickers within erase radius
    final remainingStickers = widget.canvas.stickers.where((sticker) {
      final distance = (sticker.position - position).distance;
      final shouldRemove = distance <= eraseRadius;
      if (shouldRemove) hasChanges = true;
      return !shouldRemove;
    }).toList();

    // Remove texts within erase radius
    final remainingTexts = widget.canvas.texts.where((text) {
      final distance = (text.position - position).distance;
      final shouldRemove = distance <= eraseRadius;
      if (shouldRemove) hasChanges = true;
      return !shouldRemove;
    }).toList();

    // Remove drawing strokes that intersect with erase area
    final remainingDrawings = widget.canvas.drawings.where((drawing) {
      final hasIntersection = drawing.points.any((point) {
        return (point - position).distance <= eraseRadius;
      });
      if (hasIntersection) hasChanges = true;
      return !hasIntersection;
    }).toList();

    if (hasChanges) {
      final updatedCanvas = widget.canvas.copyWith(
        stickers: remainingStickers,
        texts: remainingTexts,
        drawings: remainingDrawings,
        viewport: _viewport,
        lastModified: DateTime.now(),
      );

      widget.onCanvasChanged(updatedCanvas);
      _playHapticFeedback();
    }
  }

  // Text methods
  void _startTextInput(Offset position) {
    _textController = TextEditingController();
    setState(() {
      _isEditingText = true;
    });
  }

  void _confirmTextInput() {
    if (_textController?.text.isNotEmpty == true) {
      final text = CanvasText(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _textController!.text,
        position: _viewport.center,
        color: widget.selectedColor,
        createdAt: DateTime.now(),
      );

      final updatedCanvas = widget.canvas.copyWith(
        texts: [...widget.canvas.texts, text],
        viewport: _viewport,
        lastModified: DateTime.now(),
      );

      widget.onCanvasChanged(updatedCanvas);
      _playHapticFeedback();
    }
    
    _cancelTextInput();
  }

  void _cancelTextInput() {
    setState(() {
      _isEditingText = false;
    });
    _textController?.dispose();
    _textController = null;
  }

  // Zone methods
  void _toggleZoneCreation() {
    setState(() {
      _isCreatingZone = !_isCreatingZone;
      _zoneStartPoint = null;
    });
  }

  void _handleZoneCreation(Offset position) {
    if (_zoneStartPoint == null) {
      setState(() {
        _zoneStartPoint = position;
      });
    } else {
      _createZone(_zoneStartPoint!, position);
      setState(() {
        _isCreatingZone = false;
        _zoneStartPoint = null;
      });
    }
  }

  void _createZone(Offset start, Offset end) {
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final radius = (start - end).distance / 2;
    
    showDialog(
      context: context,
      builder: (context) => _ZoneCreationDialog(
        onZoneCreated: (name, theme, color) {
          final zone = StickerZone(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            theme: theme,
            center: center,
            radius: radius.clamp(50.0, 500.0),
            color: color,
            createdAt: DateTime.now(),
          );

          final updatedCanvas = widget.canvas.copyWith(
            zones: [...widget.canvas.zones, zone],
            viewport: _viewport,
            lastModified: DateTime.now(),
          );

          widget.onCanvasChanged(updatedCanvas);
        },
      ),
    );
  }

  void _showStickerFinder() {
    showDialog(
      context: context,
      builder: (context) => _StickerFinderDialog(
        stickers: widget.canvas.stickers,
        onStickerSelected: (sticker) {
          Navigator.of(context).pop();
          _animateToPosition(sticker.position);
        },
      ),
    );
  }

  void _showZoneNavigator() {
    showDialog(
      context: context,
      builder: (context) => _ZoneNavigatorDialog(
        zones: widget.canvas.zones,
        onZoneSelected: (zone) {
          Navigator.of(context).pop();
          _animateToPosition(zone.center);
        },
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedSticker = null;
      _selectedText = null;
      _selectedZone = null;
    });
  }

  void _updateCanvas() {
    final updatedCanvas = widget.canvas.copyWith(
      viewport: _viewport,
      lastModified: DateTime.now(),
    );
    widget.onCanvasChanged(updatedCanvas);
  }

  void _playHapticFeedback() {
    HapticFeedback.lightImpact();
  }
}

/// Custom painter for the infinite canvas
class InfiniteCanvasPainter extends CustomPainter {
  final CreativeCanvas canvas;
  final CanvasViewport viewport;
  final PlacedSticker? selectedSticker;
  final CanvasText? selectedText;
  final StickerZone? selectedZone;
  final List<Offset> currentStroke;
  final Color selectedColor;
  final double selectedBrushSize;
  final bool isDrawing;
  final bool isCreatingZone;
  final Offset? zoneStartPoint;
  final bool showGrid;

  InfiniteCanvasPainter({
    required this.canvas,
    required this.viewport,
    this.selectedSticker,
    this.selectedText,
    this.selectedZone,
    this.currentStroke = const [],
    required this.selectedColor,
    required this.selectedBrushSize,
    this.isDrawing = false,
    this.isCreatingZone = false,
    this.zoneStartPoint,
    this.showGrid = true,
  });

  @override
  void paint(Canvas paintCanvas, Size size) {
    // Draw grid background
    if (showGrid) {
      _drawGrid(paintCanvas, size);
    }

    // Draw zones
    for (final zone in canvas.visibleZones) {
      _drawZone(paintCanvas, zone, zone == selectedZone);
    }

    // Draw existing drawings
    for (final drawing in canvas.drawings) {
      if (_isDrawingVisible(drawing)) {
        _drawStroke(paintCanvas, drawing);
      }
    }

    // Draw current stroke while drawing
    if (isDrawing && currentStroke.length > 1) {
      _drawCurrentStroke(paintCanvas);
    }

    // Draw stickers
    for (final sticker in canvas.visibleStickers) {
      _drawSticker(paintCanvas, sticker, sticker == selectedSticker);
    }

    // Draw texts
    for (final text in canvas.texts) {
      if (viewport.bounds.contains(text.position)) {
        _drawText(paintCanvas, text, text == selectedText);
      }
    }

    // Draw zone creation preview
    if (isCreatingZone && zoneStartPoint != null) {
      _drawZoneCreationPreview(paintCanvas);
    }

    // Draw center indicator
    _drawCenterIndicator(paintCanvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    const gridSpacing = 100.0;
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    final bounds = viewport.bounds;
    final startX = (bounds.left / gridSpacing).floor() * gridSpacing;
    final startY = (bounds.top / gridSpacing).floor() * gridSpacing;

    // Draw vertical lines
    for (double x = startX; x <= bounds.right + gridSpacing; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, bounds.top),
        Offset(x, bounds.bottom),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = startY; y <= bounds.bottom + gridSpacing; y += gridSpacing) {
      canvas.drawLine(
        Offset(bounds.left, y),
        Offset(bounds.right, y),
        paint,
      );
    }

    // Draw origin axes
    final axisPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 2.0;

    if (bounds.contains(Offset.zero)) {
      canvas.drawLine(
        Offset(0, bounds.top),
        Offset(0, bounds.bottom),
        axisPaint,
      );
      canvas.drawLine(
        Offset(bounds.left, 0),
        Offset(bounds.right, 0),
        axisPaint,
      );
    }
  }

  void _drawZone(Canvas canvas, StickerZone zone, bool isSelected) {
    final paint = Paint()
      ..color = zone.color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = zone.color.withValues(alpha: isSelected ? 0.8 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.5
      ..strokeDashArray = [10, 5];

    canvas.drawCircle(zone.center, zone.radius, paint);
    canvas.drawCircle(zone.center, zone.radius, borderPaint);

    // Draw zone label
    final textPainter = TextPainter(
      text: TextSpan(
        text: zone.name,
        style: TextStyle(
          color: zone.color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        zone.center.dx - textPainter.width / 2,
        zone.center.dy - zone.radius - textPainter.height - 10,
      ),
    );
  }

  void _drawSticker(Canvas canvas, PlacedSticker sticker, bool isSelected) {
    if (isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(sticker.position, 35, selectionPaint);
    }

    // For now, draw emoji as text (in real implementation, you'd load image)
    final textPainter = TextPainter(
      text: TextSpan(
        text: sticker.sticker.emoji,
        style: TextStyle(
          fontSize: 32 * sticker.scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    canvas.save();
    canvas.translate(sticker.position.dx, sticker.position.dy);
    canvas.rotate(sticker.rotation);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  void _drawText(Canvas canvas, CanvasText text, bool isSelected) {
    if (isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(
          center: text.position,
          width: text.text.length * text.fontSize * 0.6,
          height: text.fontSize + 10,
        ),
        selectionPaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text.text,
        style: TextStyle(
          color: text.color,
          fontSize: text.fontSize,
          fontFamily: text.fontFamily,
          fontWeight: text.fontWeight,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    canvas.save();
    canvas.translate(text.position.dx, text.position.dy);
    canvas.rotate(text.rotation);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  void _drawStroke(Canvas canvas, DrawingStroke drawing) {
    if (drawing.points.length > 1) {
      final path = Path();
      path.moveTo(drawing.points.first.dx, drawing.points.first.dy);
      
      for (int i = 1; i < drawing.points.length; i++) {
        path.lineTo(drawing.points[i].dx, drawing.points[i].dy);
      }
      
      canvas.drawPath(path, drawing.paintStyle);
    }
  }

  void _drawCurrentStroke(Canvas canvas) {
    final paint = Paint()
      ..color = selectedColor
      ..strokeWidth = selectedBrushSize
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
    
    for (int i = 1; i < currentStroke.length; i++) {
      path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawZoneCreationPreview(Canvas canvas) {
    if (zoneStartPoint == null) return;
    
    final paint = Paint()
      ..color = Colors.purple.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeDashArray = [5, 5];

    // Draw circle preview (assuming we'll implement mouse position tracking)
    canvas.drawCircle(zoneStartPoint!, 100, paint);
  }

  void _drawCenterIndicator(Canvas canvas, Size size) {
    final centerPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Draw a small dot at the origin if visible
    if (viewport.bounds.contains(Offset.zero)) {
      canvas.drawCircle(Offset.zero, 3, centerPaint);
    }
  }

  bool _isDrawingVisible(DrawingStroke drawing) {
    return drawing.points.any((point) => viewport.bounds.contains(point));
  }

  @override
  bool shouldRepaint(InfiniteCanvasPainter oldDelegate) {
    return canvas != oldDelegate.canvas ||
           viewport != oldDelegate.viewport ||
           selectedSticker != oldDelegate.selectedSticker ||
           selectedText != oldDelegate.selectedText ||
           selectedZone != oldDelegate.selectedZone ||
           currentStroke != oldDelegate.currentStroke ||
           isDrawing != oldDelegate.isDrawing ||
           isCreatingZone != oldDelegate.isCreatingZone ||
           zoneStartPoint != oldDelegate.zoneStartPoint;
  }
}

/// Minimap painter
class MinimapPainter extends CustomPainter {
  final CreativeCanvas canvas;
  final CanvasViewport viewport;
  final Size screenSize;
  final Size minimapSize;

  MinimapPainter({
    required this.canvas,
    required this.viewport,
    required this.screenSize,
    required this.minimapSize,
  });

  @override
  void paint(Canvas paintCanvas, Size size) {
    final contentBounds = canvas.contentBounds ?? const Rect.fromLTWH(-500, -500, 1000, 1000);
    
    // Draw content area
    final contentPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.fill;
    paintCanvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), contentPaint);

    // Draw stickers as dots
    final stickerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (final sticker in canvas.stickers) {
      final minimapPos = _canvasToMinimapPosition(sticker.position, contentBounds, size);
      paintCanvas.drawCircle(minimapPos, 2, stickerPaint);
    }

    // Draw zones
    final zonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final zone in canvas.zones) {
      zonePaint.color = zone.color;
      final center = _canvasToMinimapPosition(zone.center, contentBounds, size);
      final radius = (zone.radius / contentBounds.width) * size.width;
      paintCanvas.drawCircle(center, radius, zonePaint);
    }

    // Draw current viewport
    final viewportPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final viewportRect = _viewportToMinimapRect(viewport.bounds, contentBounds, size);
    paintCanvas.drawRect(viewportRect, viewportPaint);
  }

  Offset _canvasToMinimapPosition(Offset canvasPos, Rect contentBounds, Size minimapSize) {
    final normalizedX = (canvasPos.dx - contentBounds.left) / contentBounds.width;
    final normalizedY = (canvasPos.dy - contentBounds.top) / contentBounds.height;
    return Offset(normalizedX * minimapSize.width, normalizedY * minimapSize.height);
  }

  Rect _viewportToMinimapRect(Rect viewportBounds, Rect contentBounds, Size minimapSize) {
    final topLeft = _canvasToMinimapPosition(viewportBounds.topLeft, contentBounds, minimapSize);
    final bottomRight = _canvasToMinimapPosition(viewportBounds.bottomRight, contentBounds, minimapSize);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  @override
  bool shouldRepaint(MinimapPainter oldDelegate) {
    return canvas != oldDelegate.canvas || viewport != oldDelegate.viewport;
  }
}

/// Dialog for creating zones
class _ZoneCreationDialog extends StatefulWidget {
  final Function(String name, String theme, Color color) onZoneCreated;

  const _ZoneCreationDialog({required this.onZoneCreated});

  @override
  State<_ZoneCreationDialog> createState() => _ZoneCreationDialogState();
}

class _ZoneCreationDialogState extends State<_ZoneCreationDialog> {
  final _nameController = TextEditingController();
  String _selectedTheme = 'zoo';
  Color _selectedColor = Colors.green;

  final _themes = [
    'zoo', 'city', 'underwater', 'forest', 'space', 'farm', 'playground', 'kitchen'
  ];

  final _colors = [
    Colors.green, Colors.blue, Colors.purple, Colors.orange,
    Colors.red, Colors.teal, Colors.pink, Colors.amber
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Zone'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Zone Name',
              hintText: 'My Zoo Area',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTheme,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: _themes.map((theme) => DropdownMenuItem(
              value: theme,
              child: Text(theme.replaceFirst(theme[0], theme[0].toUpperCase())),
            )).toList(),
            onChanged: (value) => setState(() => _selectedTheme = value!),
          ),
          const SizedBox(height: 16),
          const Text('Color:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((color) => GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _selectedColor == color ? Colors.black : Colors.grey,
                    width: _selectedColor == color ? 3 : 1,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onZoneCreated(_nameController.text, _selectedTheme, _selectedColor);
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Dialog for finding stickers
class _StickerFinderDialog extends StatelessWidget {
  final List<PlacedSticker> stickers;
  final Function(PlacedSticker) onStickerSelected;

  const _StickerFinderDialog({
    required this.stickers,
    required this.onStickerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Find Stickers'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: ListView.builder(
          itemCount: stickers.length,
          itemBuilder: (context, index) {
            final sticker = stickers[index];
            return ListTile(
              leading: Text(sticker.sticker.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(sticker.sticker.name),
              subtitle: Text('at (${sticker.position.dx.toInt()}, ${sticker.position.dy.toInt()})'),
              onTap: () => onStickerSelected(sticker),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Dialog for navigating between zones
class _ZoneNavigatorDialog extends StatelessWidget {
  final List<StickerZone> zones;
  final Function(StickerZone) onZoneSelected;

  const _ZoneNavigatorDialog({
    required this.zones,
    required this.onZoneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Navigate to Zone'),
      content: SizedBox(
        width: 300,
        height: 300,
        child: ListView.builder(
          itemCount: zones.length,
          itemBuilder: (context, index) {
            final zone = zones[index];
            return ListTile(
              leading: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: zone.color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(zone.name),
              subtitle: Text('${zone.theme} • ${zone.stickerIds.length} stickers'),
              onTap: () => onZoneSelected(zone),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Extension for dash array support
extension DashPath on Paint {
  set strokeDashArray(List<double> dashArray) {
    // This is a simplified version - in real implementation you'd use a proper dash path
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import '../models/sticker_models.dart';

/// Interactive creative canvas for sticker placement, drawing, and text
class CreativeCanvasWidget extends StatefulWidget {
  final CreativeCanvas canvas;
  final List<Sticker> availableStickers;
  final CanvasTool selectedTool;
  final Color selectedColor;
  final double selectedBrushSize;
  final BrushType selectedBrushType;
  final Function(CreativeCanvas) onCanvasChanged;
  final VoidCallback? onToolRequest;

  const CreativeCanvasWidget({
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
  State<CreativeCanvasWidget> createState() => _CreativeCanvasState();
}

class _CreativeCanvasState extends State<CreativeCanvasWidget>
    with TickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  
  // Selection and transformation
  PlacedSticker? _selectedSticker;
  CanvasText? _selectedText;
  
  // Drawing state
  final ValueNotifier<List<Offset>> _currentStrokeNotifier = ValueNotifier([]);
  bool _isDrawing = false;
  
  // Text editing
  TextEditingController? _textController;
  bool _isEditingText = false;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  
  @override
  void initState() {
    super.initState();
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
    _currentStrokeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _canvasKey,
      width: widget.canvas.canvasSize.width,
      height: widget.canvas.canvasSize.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
        child: Stack(
          children: [
            // Background
            _buildBackground(),
            
            // Canvas content area
            Positioned.fill(
              child: GestureDetector(
                onTapDown: _handleTapDown,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                // Enable better touch handling for drawing
                behavior: HitTestBehavior.opaque,
                // Reduce pan distance threshold for more responsive drawing
                dragStartBehavior: DragStartBehavior.down,
                child: RepaintBoundary(
                  child: ValueListenableBuilder<List<Offset>>(
                    valueListenable: _currentStrokeNotifier,
                    builder: (context, currentStroke, child) {
                      return CustomPaint(
                        painter: CanvasPainter(
                          canvas: widget.canvas,
                          selectedSticker: _selectedSticker,
                          selectedText: _selectedText,
                          currentStroke: currentStroke,
                          selectedColor: widget.selectedColor,
                          selectedBrushSize: widget.selectedBrushSize,
                          isDrawing: _isDrawing,
                        ),
                        child: Container(),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Placed stickers with interaction
            ..._buildPlacedStickers(),
            
            // Placed texts with interaction
            ..._buildPlacedTexts(),
            
            // Text input overlay
            if (_isEditingText) _buildTextInput(),
            
            // Tool cursor/guide
            if (widget.selectedTool != CanvasTool.select) _buildToolCursor(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final background = widget.canvas.background;
    
    if (background.gradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: background.gradient!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }
    
    if (background.imagePath != null) {
      return Image.asset(
        background.imagePath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: background.backgroundColor ?? Colors.white,
          );
        },
      );
    }
    
    if (background.imageUrl != null) {
      return Image.network(
        background.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: background.backgroundColor ?? Colors.white,
          );
        },
      );
    }
    
    return Container(
      color: background.backgroundColor ?? Colors.white,
    );
  }

  List<Widget> _buildPlacedStickers() {
    return widget.canvas.stickers.map((sticker) {
      final isSelected = _selectedSticker?.id == sticker.id;
      
      return Positioned(
        left: sticker.position.dx - 30, // Half size for centering
        top: sticker.position.dy - 30,
        child: GestureDetector(
          onTap: () => _selectSticker(sticker),
          onPanStart: (details) => _startStickerMove(sticker, details),
          onPanUpdate: (details) => _updateStickerMove(details),
          onPanEnd: (details) => _endStickerMove(),
          child: Transform.rotate(
            angle: sticker.rotation,
            child: Transform.scale(
              scale: sticker.scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(
                    color: Colors.blue,
                    width: 2,
                  ) : null,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _buildStickerContent(sticker.sticker),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStickerContent(Sticker sticker) {
    if (sticker.imagePath != null) {
      return Image.asset(
        sticker.imagePath!,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildEmojiSticker(sticker),
      );
    }
    
    if (sticker.imageUrl != null) {
      return Image.network(
        sticker.imageUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildEmojiSticker(sticker),
      );
    }
    
    return _buildEmojiSticker(sticker);
  }

  Widget _buildEmojiSticker(Sticker sticker) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: sticker.backgroundColor?.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          sticker.emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  List<Widget> _buildPlacedTexts() {
    return widget.canvas.texts.map((text) {
      final isSelected = _selectedText?.id == text.id;
      
      return Positioned(
        left: text.position.dx,
        top: text.position.dy,
        child: GestureDetector(
          onTap: () => _selectText(text),
          onDoubleTap: () => _editText(text),
          onPanStart: (details) => _startTextMove(text, details),
          onPanUpdate: (details) => _updateTextMove(details),
          onPanEnd: (details) => _endTextMove(),
          child: Transform.rotate(
            angle: text.rotation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(4),
                border: isSelected ? Border.all(
                  color: Colors.blue,
                  width: 1,
                ) : null,
              ),
              child: Text(
                text.text,
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
            ),
          ),
        ),
      );
    }).toList();
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

  Widget _buildToolCursor() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.selectedColor.withValues(alpha: 0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              _getToolIcon(),
              color: widget.selectedColor.withValues(alpha: 0.7),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getToolIcon() {
    switch (widget.selectedTool) {
      case CanvasTool.sticker:
        return Icons.auto_awesome;
      case CanvasTool.draw:
        return Icons.brush;
      case CanvasTool.text:
        return Icons.text_fields;
      case CanvasTool.eraser:
        return Icons.cleaning_services;
      case CanvasTool.select:
        return Icons.pan_tool;
    }
  }

  // Event handlers
  void _handleTapDown(TapDownDetails details) {
    final position = details.localPosition;
    
    switch (widget.selectedTool) {
      case CanvasTool.select:
        _clearSelection();
        break;
      case CanvasTool.sticker:
        _requestStickerSelection(position);
        break;
      case CanvasTool.text:
        _startTextInput(position);
        break;
      case CanvasTool.draw:
        // Don't start drawing on tap down for draw tool, let pan handle it
        break;
      case CanvasTool.eraser:
        _eraseAtPosition(position);
        break;
    }
  }

  void _handlePanStart(DragStartDetails details) {
    final position = details.localPosition;
    
    if (widget.selectedTool == CanvasTool.draw) {
      _startDrawing(position);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;
    
    if (widget.selectedTool == CanvasTool.draw && _isDrawing) {
      _continueDrawing(position);
    } else if (widget.selectedTool == CanvasTool.eraser) {
      _eraseAtPosition(position);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.selectedTool == CanvasTool.draw && _isDrawing) {
      _finishDrawing();
    }
  }

  // Sticker operations
  void _requestStickerSelection(Offset position) {
    widget.onToolRequest?.call();
    
    // For now, show a simple dialog to select sticker
    _showStickerPicker(position);
  }

  void _showStickerPicker(Offset position) {
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
                  _addSticker(sticker, position);
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
      lastModified: DateTime.now(),
    );

    widget.onCanvasChanged(updatedCanvas);
    _playHapticFeedback();
    _bounceController.forward().then((_) => _bounceController.reverse());
  }

  void _selectSticker(PlacedSticker sticker) {
    setState(() {
      _selectedSticker = sticker;
      _selectedText = null;
    });
  }

  void _startStickerMove(PlacedSticker sticker, DragStartDetails details) {
    _selectSticker(sticker);
  }

  void _updateStickerMove(DragUpdateDetails details) {
    if (_selectedSticker == null) return;

    final newPosition = _selectedSticker!.position + details.delta;
    final updatedSticker = _selectedSticker!.copyWith(position: newPosition);
    
    final updatedStickers = widget.canvas.stickers.map((s) {
      return s.id == updatedSticker.id ? updatedSticker : s;
    }).toList();

    final updatedCanvas = widget.canvas.copyWith(
      stickers: updatedStickers,
      lastModified: DateTime.now(),
    );

    widget.onCanvasChanged(updatedCanvas);
    setState(() {
      _selectedSticker = updatedSticker;
    });
  }

  void _endStickerMove() {
    _playHapticFeedback();
  }

  // Text operations
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
        position: const Offset(100, 100), // Center position for now
        color: widget.selectedColor,
        createdAt: DateTime.now(),
      );

      final updatedCanvas = widget.canvas.copyWith(
        texts: [...widget.canvas.texts, text],
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

  void _selectText(CanvasText text) {
    setState(() {
      _selectedText = text;
      _selectedSticker = null;
    });
  }

  void _editText(CanvasText text) {
    _textController = TextEditingController(text: text.text);
    setState(() {
      _isEditingText = true;
      _selectedText = text;
    });
  }

  void _startTextMove(CanvasText text, DragStartDetails details) {
    _selectText(text);
  }

  void _updateTextMove(DragUpdateDetails details) {
    if (_selectedText == null) return;

    final newPosition = _selectedText!.position + details.delta;
    final updatedText = _selectedText!.copyWith(position: newPosition);
    
    final updatedTexts = widget.canvas.texts.map((t) {
      return t.id == updatedText.id ? updatedText : t;
    }).toList();

    final updatedCanvas = widget.canvas.copyWith(
      texts: updatedTexts,
      lastModified: DateTime.now(),
    );

    widget.onCanvasChanged(updatedCanvas);
    setState(() {
      _selectedText = updatedText;
    });
  }

  void _endTextMove() {
    _playHapticFeedback();
  }

  // Drawing operations
  void _startDrawing(Offset position) {
    _isDrawing = true;
    _currentStrokeNotifier.value = [position];
  }

  void _continueDrawing(Offset position) {
    if (!_isDrawing) return;
    
    final currentStroke = _currentStrokeNotifier.value;
    
    // Add some basic stroke smoothing by avoiding duplicate points that are too close
    if (currentStroke.isNotEmpty) {
      final lastPoint = currentStroke.last;
      final distance = (position - lastPoint).distance;
      // Only add point if it's moved at least 1 pixel to reduce noise but maintain responsiveness
      if (distance < 1.0) return;
    }
    
    // Immediately update the stroke and trigger repaint - this is much more efficient
    // than setState as it only rebuilds the CustomPaint widget
    _currentStrokeNotifier.value = [...currentStroke, position];
  }

  void _finishDrawing() {
    final currentStroke = _currentStrokeNotifier.value;
    if (!_isDrawing || currentStroke.isEmpty) return;

    final stroke = DrawingStroke(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: List.from(currentStroke),
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
      lastModified: DateTime.now(),
    );

    widget.onCanvasChanged(updatedCanvas);

    _isDrawing = false;
    _currentStrokeNotifier.value = [];
    
    _playHapticFeedback();
  }

  // Eraser operations
  void _eraseAtPosition(Offset position) {
    const eraseRadius = 20.0;
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
        lastModified: DateTime.now(),
      );

      widget.onCanvasChanged(updatedCanvas);
      _playHapticFeedback();
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedSticker = null;
      _selectedText = null;
    });
  }

  void _playHapticFeedback() {
    HapticFeedback.lightImpact();
  }
}

/// Custom painter for drawing strokes and canvas elements
class CanvasPainter extends CustomPainter {
  final CreativeCanvas canvas;
  final PlacedSticker? selectedSticker;
  final CanvasText? selectedText;
  final List<Offset> currentStroke;
  final Color selectedColor;
  final double selectedBrushSize;
  final bool isDrawing;

  CanvasPainter({
    required this.canvas,
    this.selectedSticker,
    this.selectedText,
    this.currentStroke = const [],
    required this.selectedColor,
    required this.selectedBrushSize,
    this.isDrawing = false,
  });

  @override
  void paint(Canvas paintCanvas, Size size) {
    // Draw existing strokes
    for (final drawing in canvas.drawings) {
      if (drawing.points.length > 1) {
        final path = Path();
        path.moveTo(drawing.points.first.dx, drawing.points.first.dy);
        
        for (int i = 1; i < drawing.points.length; i++) {
          path.lineTo(drawing.points[i].dx, drawing.points[i].dy);
        }
        
        paintCanvas.drawPath(path, drawing.paintStyle);
      }
    }

    // Draw current stroke while drawing (including single points)
    if (isDrawing && currentStroke.isNotEmpty) {
      final paint = Paint()
        ..color = selectedColor
        ..strokeWidth = selectedBrushSize
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (currentStroke.length == 1) {
        // Draw a single point as a small circle
        paintCanvas.drawCircle(currentStroke.first, selectedBrushSize / 2, paint..style = PaintingStyle.fill);
      } else if (currentStroke.length == 2) {
        // Draw a line for two points
        paintCanvas.drawLine(currentStroke[0], currentStroke[1], paint);
      } else {
        // Draw smoothed path for multiple points using quadratic curves for better performance
        final path = Path();
        path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
        
        for (int i = 1; i < currentStroke.length - 1; i++) {
          final current = currentStroke[i];
          final next = currentStroke[i + 1];
          final controlPoint = Offset(
            (current.dx + next.dx) / 2,
            (current.dy + next.dy) / 2,
          );
          path.quadraticBezierTo(current.dx, current.dy, controlPoint.dx, controlPoint.dy);
        }
        
        // Connect to the last point
        if (currentStroke.length > 2) {
          path.lineTo(currentStroke.last.dx, currentStroke.last.dy);
        }
        
        paint.style = PaintingStyle.stroke;
        paintCanvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    // Optimize shouldRepaint to avoid unnecessary repaints
    // Most sensitive to stroke changes during drawing for smooth performance
    if (isDrawing || oldDelegate.isDrawing) {
      return currentStroke != oldDelegate.currentStroke ||
             isDrawing != oldDelegate.isDrawing ||
             selectedColor != oldDelegate.selectedColor ||
             selectedBrushSize != oldDelegate.selectedBrushSize;
    }
    
    return canvas != oldDelegate.canvas ||
           selectedSticker != oldDelegate.selectedSticker ||
           selectedText != oldDelegate.selectedText;
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/games/game_plugin.dart';
import '../../core/theme/app_colors.dart';
import '../../models/child_profile.dart';
import 'sticker_book_plugin.dart';
import 'models/sticker_models.dart';
import 'widgets/creative_canvas.dart';
import 'widgets/infinite_canvas.dart';
import 'data/sticker_library.dart';

/// Enhanced Sticker Book Creator Game
class StickerBookGame extends ConsumerStatefulWidget {
  final ChildProfile child;
  final GameSession session;
  final StickerBookPlugin plugin;

  const StickerBookGame({
    super.key,
    required this.child,
    required this.session,
    required this.plugin,
  });

  @override
  ConsumerState<StickerBookGame> createState() => _StickerBookGameState();
}

class _StickerBookGameState extends ConsumerState<StickerBookGame>
    with TickerProviderStateMixin {
  late StickerBookGameState gameState;
  late AnimationController _toolbarController;
  late AnimationController _sidebarController;
  
  // UI State
  final bool _showToolbar = true;
  bool _showStickerPacks = false;
  bool _showBackgrounds = false;
  bool _isPlaying = false; // For flip book mode
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
    _setupAnimations();
  }

  void _initializeGame() {
    final stickerPacks = StickerLibrary.getAllStickerPacks();
    final backgrounds = StickerLibrary.getAllBackgrounds();
    
    // Create default infinite canvas
    final defaultCanvas = CreativeCanvas.infinite(
      id: 'default',
      name: 'My Creation',
      background: backgrounds.first,
      viewport: CanvasViewport(
        screenSize: const Size(800, 600),
        center: Offset.zero,
        zoom: 1.0,
      ),
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
    
    final defaultProject = StickerBookProject(
      id: 'default',
      name: 'My First Creation',
      mode: CreationMode.infiniteCanvas,
      infiniteCanvas: defaultCanvas,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    gameState = StickerBookGameState(
      projects: [defaultProject],
      stickerPacks: stickerPacks,
      currentProjectId: defaultProject.id,
    );
  }

  void _setupAnimations() {
    _toolbarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _toolbarController.forward();
  }

  @override
  void dispose() {
    _toolbarController.dispose();
    _sidebarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kidBackgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Main canvas area
            _buildMainCanvas(),
            
            // Top toolbar
            _buildTopToolbar(),
            
            // Tool sidebar
            if (_showToolbar) _buildToolSidebar(),
            
            // Sticker packs sidebar
            if (_showStickerPacks) _buildStickerPacksSidebar(),
            
            // Backgrounds sidebar
            if (_showBackgrounds) _buildBackgroundsSidebar(),
            
            // Flip book controls (when in flip book mode)
            if (_isFlipBookMode()) _buildFlipBookControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCanvas() {
    final project = gameState.currentProject;
    if (project == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final canvas = project.mode == CreationMode.infiniteCanvas
        ? project.infiniteCanvas!
        : project.flipBook!.currentPage!;

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(
          top: 80,
          left: _showToolbar ? 80 : 16,
          right: (_showStickerPacks || _showBackgrounds) ? 320 : 16,
          bottom: _isFlipBookMode() ? 120 : 16,
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: canvas.isInfinite
                ? InfiniteCanvasWidget(
                    canvas: canvas,
                    availableStickers: gameState.availableStickers,
                    selectedTool: gameState.selectedTool,
                    selectedColor: gameState.selectedColor,
                    selectedBrushSize: gameState.selectedBrushSize,
                    selectedBrushType: gameState.selectedBrushType,
                    onCanvasChanged: _onCanvasChanged,
                    onToolRequest: _handleToolRequest,
                  )
                : CreativeCanvasWidget(
                    canvas: canvas,
                    availableStickers: gameState.availableStickers,
                    selectedTool: gameState.selectedTool,
                    selectedColor: gameState.selectedColor,
                    selectedBrushSize: gameState.selectedBrushSize,
                    selectedBrushType: gameState.selectedBrushType,
                    onCanvasChanged: _onCanvasChanged,
                    onToolRequest: _handleToolRequest,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _toolbarController.drive(
          Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ),
        ),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple[400]!,
                Colors.pink[400]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              
              // Project name
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gameState.currentProject?.name ?? 'Sticker Creator',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getModeDisplayText(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Mode toggle
              IconButton(
                onPressed: _toggleCreationMode,
                icon: Icon(
                  _isFlipBookMode() ? Icons.auto_stories : Icons.crop_landscape,
                  color: Colors.white,
                ),
                tooltip: _isFlipBookMode() ? 'Switch to Canvas' : 'Switch to Flip Book',
              ),
              
              // Infinite canvas toggle (only show if in canvas mode)
              if (!_isFlipBookMode())
                IconButton(
                  onPressed: _toggleInfiniteCanvas,
                  icon: Icon(
                    _isInfiniteCanvasMode() ? Icons.all_out : Icons.crop_square,
                    color: Colors.white,
                  ),
                  tooltip: _isInfiniteCanvasMode() ? 'Switch to Standard Canvas' : 'Switch to Infinite Canvas',
                ),
              
              // Save button
              IconButton(
                onPressed: _saveProject,
                icon: const Icon(Icons.save, color: Colors.white),
                tooltip: 'Save Project',
              ),
              
              // Share button
              IconButton(
                onPressed: _shareProject,
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Share Creation',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolSidebar() {
    return Positioned(
      left: 0,
      top: 70,
      bottom: 0,
      child: SlideTransition(
        position: _sidebarController.drive(
          Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ),
        ),
        child: Container(
          width: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              
              // Tool buttons
              _buildToolButton(
                CanvasTool.select,
                Icons.pan_tool,
                'Select',
              ),
              _buildToolButton(
                CanvasTool.sticker,
                Icons.auto_awesome,
                'Stickers',
              ),
              _buildToolButton(
                CanvasTool.draw,
                Icons.brush,
                'Draw',
              ),
              _buildToolButton(
                CanvasTool.text,
                Icons.text_fields,
                'Text',
              ),
              _buildToolButton(
                CanvasTool.eraser,
                Icons.cleaning_services,
                'Eraser',
              ),
              
              const Spacer(),
              
              // Color picker
              _buildColorPicker(),
              
              // Brush size if drawing tool selected
              if (gameState.selectedTool == CanvasTool.draw)
                _buildBrushSizeSelector(),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton(CanvasTool tool, IconData icon, String tooltip) {
    final isSelected = gameState.selectedTool == tool;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: GestureDetector(
        onTap: () => _selectTool(tool),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey[600],
            size: 24,
          ),
        ),
      ).animate(target: isSelected ? 1 : 0)
       .scale(
         begin: const Offset(1.0, 1.0),
         end: const Offset(1.1, 1.1),
         duration: 200.ms,
       ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: colors.map((color) {
          final isSelected = gameState.selectedColor == color;
          return GestureDetector(
            onTap: () => _selectColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.grey[800]! : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBrushSizeSelector() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Text(
            'Size',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 80,
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: gameState.selectedBrushSize,
                min: 2,
                max: 20,
                divisions: 18,
                onChanged: _selectBrushSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerPacksSidebar() {
    return Positioned(
      right: 0,
      top: 70,
      bottom: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sidebarController,
          curve: Curves.easeInOut,
        )),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Sticker Packs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _showStickerPacks = false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Sticker packs list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gameState.stickerPacks.length,
                  itemBuilder: (context, index) {
                    final pack = gameState.stickerPacks[index];
                    return _buildStickerPackCard(pack);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickerPackCard(StickerPack pack) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(pack.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(pack.category),
            color: _getCategoryColor(pack.category),
          ),
        ),
        title: Text(
          pack.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(pack.description),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: pack.stickers.length,
              itemBuilder: (context, stickerIndex) {
                final sticker = pack.stickers[stickerIndex];
                return _buildStickerItem(sticker, stickerIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerItem(Sticker sticker, int stickerIndex) {
    return GestureDetector(
      onTap: () => _addStickerToCanvas(sticker),
      child: Container(
        decoration: BoxDecoration(
          color: sticker.backgroundColor?.withValues(alpha: 0.1) ?? Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            sticker.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ).animate()
       .scale(
         delay: Duration(milliseconds: stickerIndex * 50),
         duration: 300.ms,
         curve: Curves.elasticOut,
       ),
    );
  }

  Widget _buildBackgroundsSidebar() {
    final backgrounds = StickerLibrary.getAllBackgrounds();
    
    return Positioned(
      right: 0,
      top: 70,
      bottom: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sidebarController,
          curve: Curves.easeInOut,
        )),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.palette, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Backgrounds',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _showBackgrounds = false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Backgrounds grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: backgrounds.length,
                  itemBuilder: (context, index) {
                    final background = backgrounds[index];
                    return _buildBackgroundItem(background);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundItem(CanvasBackground background) {
    final currentBackground = gameState.currentProject?.mode == CreationMode.infiniteCanvas
        ? gameState.currentProject!.infiniteCanvas!.background
        : gameState.currentProject!.flipBook!.currentPage!.background;
    
    final isSelected = currentBackground.id == background.id;
    
    return GestureDetector(
      onTap: () => _selectBackground(background),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Background preview
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: _getBackgroundDecoration(background),
              ),
              
              // Name label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                  child: Text(
                    background.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlipBookControls() {
    final flipBook = gameState.currentProject?.flipBook;
    if (flipBook == null) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Previous page
            IconButton(
              onPressed: flipBook.currentPageIndex > 0 ? _previousPage : null,
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 32,
            ),
            
            // Pages indicator
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Add page button
                  IconButton(
                    onPressed: _addPage,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 28,
                  ),
                  
                  // Page indicators
                  ...List.generate(flipBook.pages.length, (index) {
                    final isCurrentPage = index == flipBook.currentPageIndex;
                    return GestureDetector(
                      onTap: () => _goToPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isCurrentPage ? 40 : 20,
                        height: isCurrentPage ? 30 : 20,
                        decoration: BoxDecoration(
                          color: isCurrentPage ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrentPage ? Colors.white : Colors.grey[600],
                              fontSize: isCurrentPage ? 14 : 12,
                              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  // Play button for animation
                  IconButton(
                    onPressed: flipBook.pages.length > 1 ? _playFlipBook : null,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 28,
                  ),
                ],
              ),
            ),
            
            // Next page
            IconButton(
              onPressed: flipBook.currentPageIndex < flipBook.pages.length - 1 ? _nextPage : null,
              icon: const Icon(Icons.arrow_forward_ios),
              iconSize: 32,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getModeDisplayText() {
    final project = gameState.currentProject;
    if (project?.mode == CreationMode.infiniteCanvas) {
      final isInfinite = project?.infiniteCanvas?.isInfinite ?? false;
      return isInfinite ? 'Infinite Canvas' : 'Standard Canvas';
    }
    return 'Flip Book';
  }

  bool _isFlipBookMode() {
    return gameState.currentProject?.mode == CreationMode.flipBook;
  }
  
  bool _isInfiniteCanvasMode() {
    final project = gameState.currentProject;
    return project?.mode == CreationMode.infiniteCanvas && 
           (project?.infiniteCanvas?.isInfinite ?? false);
  }

  Color _getCategoryColor(StickerCategory category) {
    switch (category) {
      case StickerCategory.animals:
        return Colors.green;
      case StickerCategory.shapes:
        return Colors.blue;
      case StickerCategory.letters:
        return Colors.purple;
      case StickerCategory.numbers:
        return Colors.orange;
      case StickerCategory.vehicles:
        return Colors.red;
      case StickerCategory.nature:
        return Colors.teal;
      case StickerCategory.food:
        return Colors.amber;
      case StickerCategory.emotions:
        return Colors.pink;
      case StickerCategory.seasonal:
        return Colors.indigo;
      case StickerCategory.custom:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(StickerCategory category) {
    switch (category) {
      case StickerCategory.animals:
        return Icons.pets;
      case StickerCategory.shapes:
        return Icons.category;
      case StickerCategory.letters:
        return Icons.text_fields;
      case StickerCategory.numbers:
        return Icons.pin;
      case StickerCategory.vehicles:
        return Icons.directions_car;
      case StickerCategory.nature:
        return Icons.nature;
      case StickerCategory.food:
        return Icons.restaurant;
      case StickerCategory.emotions:
        return Icons.sentiment_satisfied;
      case StickerCategory.seasonal:
        return Icons.celebration;
      case StickerCategory.custom:
        return Icons.star;
    }
  }

  BoxDecoration _getBackgroundDecoration(CanvasBackground background) {
    if (background.gradient != null) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: background.gradient!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    
    return BoxDecoration(
      color: background.backgroundColor ?? Colors.white,
      image: background.imagePath != null || background.imageUrl != null
          ? DecorationImage(
              image: background.imagePath != null
                  ? AssetImage(background.imagePath!) as ImageProvider
                  : NetworkImage(background.imageUrl!),
              fit: BoxFit.cover,
            )
          : null,
    );
  }

  // Event handlers
  void _selectTool(CanvasTool tool) {
    setState(() {
      gameState = gameState.copyWith(selectedTool: tool);
    });
    
    // Auto-show relevant sidebars
    if (tool == CanvasTool.sticker) {
      _showStickerPacks = true;
      _showBackgrounds = false;
    } else {
      _showStickerPacks = false;
      _showBackgrounds = false;
    }
    
    _sidebarController.forward();
  }

  void _selectColor(Color color) {
    setState(() {
      gameState = gameState.copyWith(selectedColor: color);
    });
  }

  void _selectBrushSize(double size) {
    setState(() {
      gameState = gameState.copyWith(selectedBrushSize: size);
    });
  }

  void _handleToolRequest() {
    setState(() {
      _showStickerPacks = gameState.selectedTool == CanvasTool.sticker;
      _showBackgrounds = false;
    });
    
    if (_showStickerPacks) {
      _sidebarController.forward();
    }
  }

  void _onCanvasChanged(CreativeCanvas canvas) {
    final project = gameState.currentProject;
    if (project == null) return;

    final updatedProject = project.mode == CreationMode.infiniteCanvas
        ? project.copyWith(
            infiniteCanvas: canvas,
            lastModified: DateTime.now(),
          )
        : project.copyWith(
            flipBook: project.flipBook!.copyWith(
              pages: project.flipBook!.pages.map((page) {
                return page.id == canvas.id ? canvas : page;
              }).toList(),
              lastModified: DateTime.now(),
            ),
            lastModified: DateTime.now(),
          );

    final updatedProjects = gameState.projects.map((p) {
      return p.id == updatedProject.id ? updatedProject : p;
    }).toList();

    setState(() {
      gameState = gameState.copyWith(
        projects: updatedProjects,
        totalCreations: gameState.totalCreations + 1,
      );
    });
  }

  void _addStickerToCanvas(Sticker sticker) {
    // This will be handled by the canvas widget when user taps
    setState(() {
      gameState = gameState.copyWith(selectedTool: CanvasTool.sticker);
    });
  }

  void _selectBackground(CanvasBackground background) {
    final project = gameState.currentProject;
    if (project == null) return;

    if (project.mode == CreationMode.infiniteCanvas) {
      final updatedCanvas = project.infiniteCanvas!.copyWith(
        background: background,
        lastModified: DateTime.now(),
      );
      _onCanvasChanged(updatedCanvas);
    } else {
      final currentPage = project.flipBook!.currentPage;
      if (currentPage != null) {
        final updatedPage = currentPage.copyWith(
          background: background,
          lastModified: DateTime.now(),
        );
        _onCanvasChanged(updatedPage);
      }
    }
  }

  void _toggleCreationMode() {
    final project = gameState.currentProject;
    if (project == null) return;

    final newMode = project.mode == CreationMode.infiniteCanvas
        ? CreationMode.flipBook
        : CreationMode.infiniteCanvas;

    StickerBookProject updatedProject;
    
    if (newMode == CreationMode.flipBook) {
      // Convert canvas to flip book
      final flipBook = FlipBook(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${project.name} - Flip Book',
        pages: [project.infiniteCanvas!],
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );
      
      updatedProject = project.copyWith(
        mode: newMode,
        flipBook: flipBook,
        lastModified: DateTime.now(),
      );
    } else {
      // Convert flip book to canvas (use current page)
      final canvas = project.flipBook!.currentPage ?? project.flipBook!.pages.first;
      
      updatedProject = project.copyWith(
        mode: newMode,
        infiniteCanvas: canvas,
        lastModified: DateTime.now(),
      );
    }

    final updatedProjects = gameState.projects.map((p) {
      return p.id == updatedProject.id ? updatedProject : p;
    }).toList();

    setState(() {
      gameState = gameState.copyWith(projects: updatedProjects);
    });
  }

  void _toggleInfiniteCanvas() {
    final project = gameState.currentProject;
    if (project?.mode != CreationMode.infiniteCanvas || project?.infiniteCanvas == null) return;

    final currentCanvas = project!.infiniteCanvas!;
    final newCanvas = currentCanvas.isInfinite 
        ? currentCanvas.copyWith(isInfinite: false) // Convert to standard canvas
        : CreativeCanvas.infinite( // Convert to infinite canvas
            id: currentCanvas.id,
            name: currentCanvas.name,
            background: currentCanvas.background,
            stickers: currentCanvas.stickers,
            drawings: currentCanvas.drawings,
            texts: currentCanvas.texts,
            zones: currentCanvas.zones,
            createdAt: currentCanvas.createdAt,
            lastModified: DateTime.now(),
            viewport: CanvasViewport(
              screenSize: MediaQuery.of(context).size,
              center: Offset.zero,
              zoom: 1.0,
            ),
          );

    final updatedProject = project.copyWith(
      infiniteCanvas: newCanvas,
      lastModified: DateTime.now(),
    );

    final updatedProjects = gameState.projects.map((p) {
      return p.id == updatedProject.id ? updatedProject : p;
    }).toList();

    setState(() {
      gameState = gameState.copyWith(projects: updatedProjects);
    });

    // Show helpful message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newCanvas.isInfinite 
              ? 'Switched to Infinite Canvas! Pan and zoom to explore.'
              : 'Switched to Standard Canvas.',
        ),
        backgroundColor: newCanvas.isInfinite ? Colors.blue : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _addPage() {
    final project = gameState.currentProject;
    if (project?.flipBook == null) return;

    final newPage = CreativeCanvas(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Page ${project!.flipBook!.pages.length + 1}',
      background: project.flipBook!.currentPage?.background ?? StickerLibrary.getAllBackgrounds().first,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    final updatedFlipBook = project.flipBook!.copyWith(
      pages: [...project.flipBook!.pages, newPage],
      currentPageIndex: project.flipBook!.pages.length,
      lastModified: DateTime.now(),
    );

    final updatedProject = project.copyWith(
      flipBook: updatedFlipBook,
      lastModified: DateTime.now(),
    );

    final updatedProjects = gameState.projects.map((p) {
      return p.id == updatedProject.id ? updatedProject : p;
    }).toList();

    setState(() {
      gameState = gameState.copyWith(projects: updatedProjects);
    });
  }

  void _previousPage() {
    final project = gameState.currentProject;
    if (project?.flipBook == null) return;

    final newIndex = (project!.flipBook!.currentPageIndex - 1).clamp(0, project.flipBook!.pages.length - 1);
    _goToPage(newIndex);
  }

  void _nextPage() {
    final project = gameState.currentProject;
    if (project?.flipBook == null) return;

    final newIndex = (project!.flipBook!.currentPageIndex + 1).clamp(0, project.flipBook!.pages.length - 1);
    _goToPage(newIndex);
  }

  void _goToPage(int index) {
    final project = gameState.currentProject;
    if (project?.flipBook == null) return;

    final updatedFlipBook = project!.flipBook!.copyWith(
      currentPageIndex: index,
    );

    final updatedProject = project.copyWith(
      flipBook: updatedFlipBook,
      lastModified: DateTime.now(),
    );

    final updatedProjects = gameState.projects.map((p) {
      return p.id == updatedProject.id ? updatedProject : p;
    }).toList();

    setState(() {
      gameState = gameState.copyWith(projects: updatedProjects);
    });
  }

  void _playFlipBook() {
    // TODO: Implement flip book animation playback
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _saveProject() {
    // TODO: Implement project saving to local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareProject() {
    // TODO: Implement project sharing/export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/sticker_models.dart';
import '../services/saved_projects_service.dart';

/// Gallery screen for viewing and loading saved sticker book projects
class ProjectsGalleryScreen extends StatefulWidget {
  final AgeMode ageMode;
  final Function(SavedProject) onLoadProject;
  final VoidCallback? onCreateNew;
  
  const ProjectsGalleryScreen({
    super.key,
    required this.ageMode,
    required this.onLoadProject,
    this.onCreateNew,
  });
  
  @override
  State<ProjectsGalleryScreen> createState() => _ProjectsGalleryScreenState();
}

class _ProjectsGalleryScreenState extends State<ProjectsGalleryScreen> {
  final SavedProjectsService _projectsService = SavedProjectsService();
  List<SavedProject> _savedProjects = [];
  bool _isLoading = true;
  bool _isLittleKid = false;
  
  @override
  void initState() {
    super.initState();
    _isLittleKid = widget.ageMode == AgeMode.littleKid;
    _loadSavedProjects();
  }
  
  Future<void> _loadSavedProjects() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _projectsService.initialize();
      final projects = await _projectsService.getSavedProjects();
      
      // Filter by age mode for better organization
      final filteredProjects = projects.where((project) {
        return project.ageMode == widget.ageMode;
      }).toList();
      
      setState(() {
        _savedProjects = filteredProjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteProject(SavedProject project) async {
    final shouldDelete = await _showDeleteConfirmation(project);
    if (shouldDelete) {
      final success = await _projectsService.deleteProject(project.id);
      if (success) {
        setState(() {
          _savedProjects.removeWhere((p) => p.id == project.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isLittleKid 
                    ? '${project.name} was deleted!' 
                    : 'Project "${project.name}" deleted',
              ),
              backgroundColor: Colors.orange[600],
              duration: Duration(seconds: _isLittleKid ? 3 : 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _renameProject(SavedProject project) async {
    final newName = await _showRenameDialog(project);
    if (newName != null && newName.trim().isNotEmpty && newName.trim() != project.name) {
      final success = await _projectsService.renameProject(project.id, newName.trim());
      if (success) {
        // Reload the projects to get the updated data
        await _loadSavedProjects();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isLittleKid 
                    ? 'Renamed to "$newName"!' 
                    : 'Project renamed to "$newName"',
              ),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: _isLittleKid ? 3 : 2),
            ),
          );
        }
      }
    }
  }
  
  Future<bool> _showDeleteConfirmation(SavedProject project) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isLittleKid ? 20 : 16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.red[600],
              size: _isLittleKid ? 28 : 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isLittleKid ? 'Delete Art?' : 'Delete Project?',
                style: TextStyle(
                  fontSize: _isLittleKid ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _isLittleKid 
              ? 'Do you want to delete "${project.name}"? You can\'t get it back!'
              : 'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
          style: TextStyle(
            fontSize: _isLittleKid ? 16 : 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _isLittleKid ? 'Keep It' : 'Cancel',
              style: TextStyle(
                fontSize: _isLittleKid ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              _isLittleKid ? 'Delete It' : 'Delete',
              style: TextStyle(
                fontSize: _isLittleKid ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<String?> _showRenameDialog(SavedProject project) async {
    final TextEditingController controller = TextEditingController(text: project.name);
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isLittleKid ? 20 : 16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: _isLittleKid ? Colors.purple[600] : Colors.blue[600],
              size: _isLittleKid ? 28 : 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isLittleKid ? 'Rename Art' : 'Rename Project',
                style: TextStyle(
                  fontSize: _isLittleKid ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isLittleKid 
                  ? 'What should we call this art?'
                  : 'Enter a new name for this project:',
              style: TextStyle(
                fontSize: _isLittleKid ? 16 : 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: _isLittleKid ? 'My Amazing Art' : 'Project name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_isLittleKid ? 12 : 8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_isLittleKid ? 12 : 8),
                  borderSide: BorderSide(
                    color: _isLittleKid ? Colors.purple[600]! : Colors.blue[600]!,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                fontSize: _isLittleKid ? 16 : 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              _isLittleKid ? 'Cancel' : 'Cancel',
              style: TextStyle(
                fontSize: _isLittleKid ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLittleKid ? Colors.purple[600] : Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              _isLittleKid ? 'Save Name' : 'Rename',
              style: TextStyle(
                fontSize: _isLittleKid ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isLittleKid ? AppColors.kidBackgroundLight : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _isLittleKid ? Colors.purple[400] : Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: _isLittleKid ? 4 : 2,
        title: Row(
          children: [
            Icon(
              Icons.photo_library,
              size: _isLittleKid ? 28 : 24,
            ),
            const SizedBox(width: 12),
            Text(
              _isLittleKid ? 'My Art Gallery' : 'My Creations',
              style: TextStyle(
                fontSize: _isLittleKid ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onCreateNew != null)
            IconButton(
              onPressed: widget.onCreateNew,
              icon: Icon(
                Icons.add_circle_outline,
                size: _isLittleKid ? 28 : 24,
              ),
              tooltip: _isLittleKid ? 'Make New Art' : 'Create New',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _savedProjects.isEmpty
              ? _buildEmptyScreen()
              : _buildGalleryGrid(),
    );
  }
  
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: _isLittleKid ? 4 : 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              _isLittleKid ? Colors.purple[400]! : Colors.blue[600]!,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isLittleKid ? 'Finding your art...' : 'Loading projects...',
            style: TextStyle(
              fontSize: _isLittleKid ? 18 : 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _isLittleKid ? 120 : 100,
              height: _isLittleKid ? 120 : 100,
              decoration: BoxDecoration(
                color: (_isLittleKid ? Colors.purple[100] : Colors.blue[100]),
                borderRadius: BorderRadius.circular(_isLittleKid ? 24 : 20),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: _isLittleKid ? 60 : 50,
                color: (_isLittleKid ? Colors.purple[400] : Colors.blue[600]),
              ),
            ).animate()
             .scale(duration: 600.ms, curve: Curves.elasticOut)
             .shimmer(delay: 800.ms, duration: 1500.ms),
             
            SizedBox(height: _isLittleKid ? 32 : 24),
            
            Text(
              _isLittleKid ? 'No Art Yet!' : 'No Projects Yet',
              style: TextStyle(
                fontSize: _isLittleKid ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              _isLittleKid 
                  ? 'Start creating amazing art and they will appear here!'
                  : 'Create your first sticker book project to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _isLittleKid ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: _isLittleKid ? 32 : 24),
            
            if (widget.onCreateNew != null)
              ElevatedButton.icon(
                onPressed: widget.onCreateNew,
                icon: Icon(
                  Icons.add_circle,
                  size: _isLittleKid ? 24 : 20,
                ),
                label: Text(
                  _isLittleKid ? 'Make My First Art!' : 'Create First Project',
                  style: TextStyle(
                    fontSize: _isLittleKid ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLittleKid ? Colors.purple[500] : Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: _isLittleKid ? 24 : 20,
                    vertical: _isLittleKid ? 16 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_isLittleKid ? 16 : 12),
                  ),
                  elevation: _isLittleKid ? 4 : 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGalleryGrid() {
    return RefreshIndicator(
      onRefresh: _loadSavedProjects,
      child: GridView.builder(
        padding: EdgeInsets.all(_isLittleKid ? 20 : 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _isLittleKid ? 2 : 3,
          crossAxisSpacing: _isLittleKid ? 16 : 12,
          mainAxisSpacing: _isLittleKid ? 20 : 16,
          childAspectRatio: _isLittleKid ? 0.8 : 0.75,
        ),
        itemCount: _savedProjects.length,
        itemBuilder: (context, index) {
          return _buildProjectCard(_savedProjects[index], index);
        },
      ),
    );
  }
  
  Widget _buildProjectCard(SavedProject project, int index) {
    return Card(
      elevation: _isLittleKid ? 6 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_isLittleKid ? 20 : 16),
      ),
      child: InkWell(
        onTap: () => widget.onLoadProject(project),
        borderRadius: BorderRadius.circular(_isLittleKid ? 20 : 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isLittleKid ? 20 : 16),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail
              Expanded(
                flex: 3,
                child: Container(
                  margin: EdgeInsets.all(_isLittleKid ? 12 : 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_isLittleKid ? 16 : 12),
                    color: Colors.grey[100],
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: _isLittleKid ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_isLittleKid ? 14 : 11),
                    child: _buildThumbnail(project),
                  ),
                ),
              ),
              
              // Project info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _isLittleKid ? 12 : 8,
                    0,
                    _isLittleKid ? 12 : 8,
                    _isLittleKid ? 12 : 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project name
                      Expanded(
                        child: Text(
                          project.name,
                          style: TextStyle(
                            fontSize: _isLittleKid ? 16 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Date and actions
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDate(project.savedAt),
                              style: TextStyle(
                                fontSize: _isLittleKid ? 12 : 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          
                          // Rename button
                          InkWell(
                            onTap: () => _renameProject(project),
                            borderRadius: BorderRadius.circular(_isLittleKid ? 12 : 8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit,
                                size: _isLittleKid ? 20 : 16,
                                color: _isLittleKid ? Colors.purple[400] : Colors.blue[600],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 4),
                          
                          // Delete button
                          InkWell(
                            onTap: () => _deleteProject(project),
                            borderRadius: BorderRadius.circular(_isLittleKid ? 12 : 8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline,
                                size: _isLittleKid ? 20 : 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
     .fadeIn(duration: 400.ms)
     .slideX(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
  
  Widget _buildThumbnail(SavedProject project) {
    if (project.thumbnailPath != null) {
      final file = File(project.thumbnailPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultThumbnail();
          },
        );
      }
    }
    
    return _buildDefaultThumbnail();
  }
  
  Widget _buildDefaultThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[200]!,
            Colors.purple[200]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          size: _isLittleKid ? 40 : 32,
          color: Colors.white,
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (_isLittleKid) {
      // Simpler date format for little kids
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } else {
      // More detailed format for big kids
      if (difference.inDays == 0) {
        return 'Today ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    }
  }
}
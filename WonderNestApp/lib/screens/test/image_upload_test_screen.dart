import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/image_upload_dialog.dart';
import '../../services/file_upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/timber_wrapper.dart';

/// Test screen to demonstrate image upload with tags
class ImageUploadTestScreen extends ConsumerStatefulWidget {
  const ImageUploadTestScreen({super.key});

  @override
  ConsumerState<ImageUploadTestScreen> createState() => _ImageUploadTestScreenState();
}

class _ImageUploadTestScreenState extends ConsumerState<ImageUploadTestScreen> {
  final List<UploadedImage> _uploadedImages = [];

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => ImageUploadDialog(
        category: FileCategory.content,
        onUploadComplete: (fileId, tags) {
          Timber.i('Image uploaded: $fileId with tags: $tags');
          setState(() {
            _uploadedImages.add(UploadedImage(
              id: fileId,
              tags: tags,
              timestamp: DateTime.now(),
            ));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload with Tags'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image Tagging System',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'When uploading images, you must add at least 2 tags to describe the content. '
                  'These tags help AI understand your images and generate relevant stories.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Example tags: bird, cardinal, red, small, flying, nature',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          
          // Upload button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showUploadDialog,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload Image with Tags'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Uploaded images list
          Expanded(
            child: _uploadedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No images uploaded yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _uploadedImages.length,
                    itemBuilder: (context, index) {
                      final image = _uploadedImages[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryBlue,
                            child: Icon(
                              Icons.image,
                              color: Colors.white,
                            ),
                          ),
                          title: Text('Image ${index + 1}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: image.tags.map((tag) {
                                  return Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    padding: const EdgeInsets.all(4),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Uploaded at ${_formatTime(image.timestamp)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _uploadedImages.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }
}

class UploadedImage {
  final String id;
  final List<String> tags;
  final DateTime timestamp;

  UploadedImage({
    required this.id,
    required this.tags,
    required this.timestamp,
  });
}
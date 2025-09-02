import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wonder_nest/core/services/api_service.dart';
import 'package:wonder_nest/models/uploaded_file.dart';
import 'package:wonder_nest/core/services/timber_wrapper.dart';

/// Service for handling file uploads
class FileUploadService {
  final ApiService _apiService;
  final ImagePicker _imagePicker = ImagePicker();

  FileUploadService(this._apiService);

  /// Pick an image from gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      // Check permissions
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          Timber.i('Camera permission denied');
          return null;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          Timber.i('Photo library permission denied');
          return null;
        }
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      Timber.e('Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple files
  Future<List<File>?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return null;
    } catch (e) {
      Timber.e('Error picking files: $e');
      return null;
    }
  }

  /// Upload a file with tags
  Future<UploadedFile?> uploadFileWithTags({
    required File file,
    required FileCategory category,
    required List<String> tags,
    String? childId,
    bool isPublic = false,
    bool isSystemImage = false,
    Function(double)? onProgress,
  }) async {
    // Validate tags
    if (!isSystemImage && tags.length < 2) {
      Timber.e('At least 2 tags are required for non-system images');
      throw Exception('At least 2 tags are required');
    }
    
    for (final tag in tags) {
      if (tag.isEmpty || tag.length > 50) {
        throw Exception('Invalid tag: $tag');
      }
      if (!RegExp(r'^[a-zA-Z0-9-_]+$').hasMatch(tag)) {
        throw Exception('Tag contains invalid characters: $tag');
      }
    }
    try {
      final fileName = file.path.split('/').last;
      final fileBytes = await file.readAsBytes();
      
      // Determine content type
      final extension = fileName.split('.').last.toLowerCase();
      final contentType = _getContentType(extension);

      // Create form data
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: DioMediaType.parse(contentType),
        ),
      });

      // Add query parameters including tags
      final queryParams = {
        'category': category.name,
        'tags': tags.join(','),
        if (childId != null) 'childId': childId,
        'isPublic': isPublic.toString(),
        'isSystemImage': isSystemImage.toString(),
      };

      final response = await _apiService.uploadFile(
        formData: formData,
        queryParams: queryParams,
        onProgress: onProgress,
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data['data'];
        return UploadedFile.fromJson(data);
      }

      return null;
    } catch (e) {
      Timber.e('Error uploading file: $e');
      return null;
    }
  }

  /// Upload a file (legacy method - requires tags)
  Future<UploadedFile?> uploadFile({
    required File file,
    required FileCategory category,
    String? childId,
    bool isPublic = false,
    Function(double)? onProgress,
  }) async {
    // Default tags for legacy uploads
    final defaultTags = ['uploaded', category.name];
    return uploadFileWithTags(
      file: file,
      category: category,
      tags: defaultTags,
      childId: childId,
      isPublic: isPublic,
      onProgress: onProgress,
    );
  }
  
  /// Upload profile picture with tags
  Future<UploadedFile?> uploadProfilePicture({
    required File image,
    List<String> tags = const ['profile', 'avatar'],
    String? childId,
    Function(double)? onProgress,
  }) async {
    return uploadFileWithTags(
      file: image,
      category: FileCategory.profilePicture,
      tags: tags,
      childId: childId,
      isPublic: true,
      onProgress: onProgress,
    );
  }

  /// Get download URL for a file
  Future<String?> getDownloadUrl(String fileId) async {
    try {
      final response = await _apiService.getFile(fileId);
      if (response.statusCode == 200 && response.data != null) {
        return response.data['data']['url'];
      }
      return null;
    } catch (e) {
      Timber.e('Error getting download URL: $e');
      return null;
    }
  }

  /// Download a file
  Future<File?> downloadFile({
    required String fileId,
    required String savePath,
    Function(double)? onProgress,
  }) async {
    try {
      final response = await _apiService.downloadFile(
        fileId: fileId,
        savePath: savePath,
        onProgress: onProgress,
      );

      if (response.statusCode == 200) {
        return File(savePath);
      }
      return null;
    } catch (e) {
      Timber.e('Error downloading file: $e');
      return null;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(String fileId) async {
    try {
      final response = await _apiService.deleteFile(fileId);
      return response.statusCode == 200;
    } catch (e) {
      Timber.e('Error deleting file: $e');
      return false;
    }
  }

  /// List user's files
  Future<List<UploadedFile>> listFiles({
    FileCategory? category,
    String? childId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        if (category != null) 'category': category.name,
        if (childId != null) 'childId': childId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final response = await _apiService.listUserFiles(queryParams: queryParams);
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => UploadedFile.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      Timber.e('Error listing files: $e');
      return [];
    }
  }

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }
}

/// File categories
enum FileCategory {
  profilePicture,
  content,
  document,
  gameAsset,
  artwork,
}

extension FileCategoryExtension on FileCategory {
  String get name {
    switch (this) {
      case FileCategory.profilePicture:
        return 'profile_picture';
      case FileCategory.content:
        return 'content';
      case FileCategory.document:
        return 'document';
      case FileCategory.gameAsset:
        return 'game_asset';
      case FileCategory.artwork:
        return 'artwork';
    }
  }

  String get displayName {
    switch (this) {
      case FileCategory.profilePicture:
        return 'Profile Picture';
      case FileCategory.content:
        return 'Content';
      case FileCategory.document:
        return 'Document';
      case FileCategory.gameAsset:
        return 'Game Asset';
      case FileCategory.artwork:
        return 'Artwork';
    }
  }
}
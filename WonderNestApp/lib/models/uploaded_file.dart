import 'package:freezed_annotation/freezed_annotation.dart';

part 'uploaded_file.freezed.dart';
part 'uploaded_file.g.dart';

@freezed
class UploadedFile with _$UploadedFile {
  const factory UploadedFile({
    required String id,
    required String originalName,
    required String mimeType,
    required int fileSize,
    required String category,
    String? url,
    required String uploadedAt,
    Map<String, dynamic>? metadata,
  }) = _UploadedFile;

  factory UploadedFile.fromJson(Map<String, dynamic> json) =>
      _$UploadedFileFromJson(json);
}
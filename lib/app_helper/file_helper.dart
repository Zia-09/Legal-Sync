import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// 🔹 File Helper - Pick files, detect type, validate size
class FileHelper {
  static const int maxFileSize = 50 * 1024 * 1024; // 50 MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB

  /// Pick file from device
  static Future<File?> pickFile({List<String>? allowedExtensions}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        return file;
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Pick multiple files
  static Future<List<File>> pickMultipleFiles({
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.map((f) => File(f.path!)).toList();
      }
      return [];
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }

  /// Pick image from gallery
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        // Check size
        if (!isValidFileSize(file, maxImageSize)) {
          print('Image too large. Max size: 10 MB');
          return null;
        }
        return file;
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Pick PDF file
  static Future<File?> pickPdf() async {
    return pickFile(allowedExtensions: ['pdf']);
  }

  /// Detect file type from extension
  static String detectFileType(File file) {
    final extension = file.path.split('.').last.toLowerCase();

    return switch (extension) {
      'pdf' => 'pdf',
      'jpg' || 'jpeg' => 'image',
      'png' || 'gif' || 'bmp' => 'image',
      'doc' || 'docx' => 'document',
      'xls' || 'xlsx' => 'spreadsheet',
      'ppt' || 'pptx' => 'presentation',
      'txt' => 'text',
      'zip' || 'rar' => 'archive',
      'mp4' || 'avi' || 'mov' => 'video',
      'mp3' || 'wav' => 'audio',
      _ => 'unknown',
    };
  }

  /// Get file extension
  static String getFileExtension(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  /// Get file name without path
  static String getFileName(File file) {
    return file.path.split('/').last;
  }

  /// Get file size in readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Validate file size
  static bool isValidFileSize(File file, int maxBytes) {
    return file.lengthSync() <= maxBytes;
  }

  /// Validate file type
  static bool isValidFileType(File file, List<String> allowedTypes) {
    final fileType = detectFileType(file);
    return allowedTypes.contains(fileType);
  }

  /// Check if file exists
  static bool fileExists(File file) {
    return file.existsSync();
  }

  /// Get file MIME type
  static String getMimeType(String extension) {
    return switch (extension.toLowerCase()) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      'mp4' => 'video/mp4',
      'mp3' => 'audio/mpeg',
      _ => 'application/octet-stream',
    };
  }

  /// Create temporary file
  static Future<File> createTempFile(String fileName, String content) async {
    final tempDir = await FilePicker.platform.getDirectoryPath();
    if (tempDir == null) throw Exception('Could not access temp directory');

    final file = File('$tempDir/$fileName');
    return await file.writeAsString(content);
  }

  /// Delete file
  static Future<void> deleteFile(File file) async {
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

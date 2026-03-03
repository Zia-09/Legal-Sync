import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;
  static const String _bucketName = 'chat_attachments';

  /// 🔹 Upload a file to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({required File file, required String path}) async {
    try {
      final fileName = file.path.split('/').last;
      final fullPath = '$path/$fileName';

      // Upload file to Supabase Bucket
      await _supabase.storage
          .from(_bucketName)
          .upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final String publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fullPath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file to Supabase: $e');
    }
  }

  /// 🔹 Delete a file from Supabase Storage
  Future<void> deleteFile(String url) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      // pathSegments usually: ['storage', 'v1', 'object', 'public', 'bucket-name', 'folder', 'file']
      // We need everything after the bucket name
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex == pathSegments.length - 1) return;

      final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _supabase.storage.from(_bucketName).remove([storagePath]);
    } catch (e) {
      print('Warning: Failed to delete file from Supabase: $e');
    }
  }
}

final supabaseService = SupabaseService();

/// Download service for managing GGUF model downloads with checksum verification
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../core/app_config.dart';

/// Download progress callback type
typedef ProgressCallback = void Function(int received, int total);

/// Download error callback type
typedef ErrorCallback = void Function(String error);

/// Download completed callback type
typedef CompleteCallback = void Function(String filePath);

/// Service for downloading and verifying GGUF model files
class DownloadService {
  /// Singleton instance
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// Check if model file exists at the expected path
  Future<bool> modelExists() async {
    final file = await getModelFile();
    return await file.exists();
  }

  /// Get the GGUF model file (public method for external access)
  Future<File> getModelFile() async {
    final appDir = await getAppSupportDir();
    final modelDir = Directory('${appDir.path}/models');
    
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    
    return File('${modelDir.path}/${AppConfig.modelFileName}');
  }

  /// Get the absolute path to the GGUF model file
  Future<String> getModelFilePath() async {
    final file = await getModelFile();
    return file.path;
  }

  /// Get application support directory (cross-platform)
  Future<Directory> getAppSupportDir() async {
    // Use the path from AppUtils for now
    // In a real implementation with path_provider, this would use getApplicationSupportDirectory()
    final dir = Directory.systemTemp; // Fallback for web/non-flutter
    if (await dir.exists()) {
      return dir;
    }
    await dir.create(recursive: true);
    return dir;
  }

  /// Calculate SHA256 checksum of a file
  Future<String> calculateFileChecksum(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final chunks = <int>[];
    final raf = file.openRead();
    
    await for (final chunk in raf) {
      chunks.addAll(chunk);
    }

    final bytes = Uint8List.fromList(chunks);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify file checksum against expected value
  Future<bool> verifyChecksum(String filePath) async {
    try {
      final actualChecksum = await calculateFileChecksum(filePath);
      final expectedChecksum = AppConfig.modelChecksum;
      
      // If checksum is still a placeholder, consider it unverified
      if (expectedChecksum.startsWith('placeholder') || 
          expectedChecksum.isEmpty || 
          expectedChecksum.length != 64) {
        return false;
      }
      
      return actualChecksum.toLowerCase() == expectedChecksum.toLowerCase();
    } catch (e) {
      return false;
    }
  }

  /// Download model from configured URL with progress callback
  Future<String?> downloadModel({
    ProgressCallback? onProgress,
    ErrorCallback? onError,
    CompleteCallback? onComplete,
  }) async {
    try {
      final url = Uri.parse(AppConfig.getModelDownloadUrl());
      
      // Final check for valid URL
      if (!url.toString().startsWith('http')) {
        onError?.call('Invalid download URL: ${url.toString()}');
        return null;
      }

      // Get the target file
      final file = await getModelFile();
      
      // Create HTTP request with timeout
      final client = http.Client();
      final request = http.Request('GET', url);
      
      // Send request with timeout
      final response = await client.send(request).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode != 200) {
        client.close();
        onError?.call('Download failed with status: ${response.statusCode}');
        return null;
      }

      // Get total expected size
      final contentLength = response.contentLength ?? AppConfig.modelFileSize;
      var downloaded = 0;

      // Open file for writing
      final sink = file.openWrite();

      // Download in chunks
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        
        onProgress?.call(downloaded, contentLength);
      }

      await sink.close();
      client.close();

      // Verify download completed
      if (!await file.exists()) {
        onError?.call('Download failed: file was not created');
        return null;
      }

      // Verify checksum
      final isValid = await verifyChecksum(file.path);
      if (!isValid && !AppConfig.modelChecksum.startsWith('placeholder')) {
        // If checksum is not placeholder and verification failed, delete file
        await file.delete();
        onError?.call('Checksum verification failed');
        return null;
      }

      onComplete?.call(file.path);
      return file.path;

    } catch (e) {
      onError?.call('Download error: ${e.toString()}');
      return null;
    }
  }

  /// Download model with simplified interface for unit testing
  static Future<String> downloadModelWithDefaults() async {
    final service = DownloadService();
    String? result;
    
    await service.downloadModel(
      onProgress: (received, total) {
        // Simple progress logging
        final percent = (received / total * 100).toStringAsFixed(1);
        print('Download progress: $percent% ($received / $total bytes)');
      },
      onError: (error) {
        print('Download error: $error');
      },
      onComplete: (filePath) {
        result = filePath;
        print('Download completed: $filePath');
      },
    );
    
    return result ?? '';
  }
}

/// Extension for easier checksum handling
extension ChecksumHelper on String {
  /// Check if this string looks like a valid SHA256 hash
  bool get isValidSha256 {
    if (length != 64) return false;
    final hexChars = RegExp(r'^[0-9a-fA-F]+$');
    return hexChars.hasMatch(this);
  }
}
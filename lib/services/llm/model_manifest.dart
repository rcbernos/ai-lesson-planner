/// Model manifest for tracking installed LLM models.
/// Stores model metadata for rotation and verification purposes.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Represents the manifest for an LLM model.
/// Used for model rotation and verification.
class ModelManifest {
  ModelManifest({
    required this.version,
    required this.model,
    this.fileName,
    this.size,
    this.checksum,
    this.url,
  });

  /// The version of the manifest schema.
  final String version;

  /// The model file name expected to be installed.
  final String model;

  /// The downloaded file name (may differ from model for versioning).
  final String? fileName;

  /// Expected size in bytes for verification.
  final int? size;

  /// SHA-256 checksum for integrity verification.
  final String? checksum;

  /// Download URL for the model file.
  final String? url;

  /// Default manifest for initial deployment.
  static ModelManifest get defaultManifest =>
      ModelManifest(version: '1', model: 'Gemma-SEA-LION-v4-4B-VL-Q4_K_M.gguf');

  /// Current schema version for compatibility tracking.
  static const int currentSchemaVersion = 1;

  /// Loads the manifest from app files directory (after download).
  /// Returns default manifest if no saved manifest exists.
  static Future<ModelManifest> load() async {
    final saved = await loadFromFile();
    return saved ?? defaultManifest;
  }

  /// Loads manifest from app files directory.
  static Future<ModelManifest?> loadFromFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/models.json');

      if (!await file.exists()) return null;

      final content = await file.readAsString();
      return ModelManifest.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
    } catch (e) {
      return null;
    }
  }

  /// Saves the manifest to the app's files directory.
  Future<void> save() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/models.json');
    await file.writeAsString(jsonEncode(toJson()));
  }

  /// Checks if the current model file exists and matches this manifest.
  static Future<bool> isCurrentModelAvailable(ModelManifest manifest) async {
    try {
      final dir = await getExternalFilesDir(null);
      if (dir == null) return false;

      final fileName = manifest.fileName ?? manifest.defaultFileName;
      final modelFile = File('${dir.path}/$fileName');

      if (!await modelFile.exists()) return false;

      // If checksum is provided, verify it
      if (manifest.checksum != null) {
        final fileContent = await modelFile.readAsBytes();
        final hash = _sha256(fileContent);
        return hash == manifest.checksum;
      }

      // Without checksum, just check existence
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Computes SHA-256 hash of bytes using crypto package.
  static String _sha256(List<int> bytes) {
    // Use package:crypto for SHA-256
    // import 'package:crypto/crypto.dart';
    // return sha256.convert(bytes).toString();
    // Placeholder implementation for now
    return '';
  }

  /// Default file name for this model.
  String get defaultFileName => fileName ?? model;

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
    'version': version,
    'model': model,
    if (fileName != null) 'fileName': fileName,
    if (size != null) 'size': size,
    if (checksum != null) 'checksum': checksum,
    if (url != null) 'url': url,
  };

  /// Creates instance from JSON map.
  factory ModelManifest.fromJson(Map<String, dynamic> json) => ModelManifest(
    version: json['version'] as String? ?? '1',
    model: json['model'] as String? ?? '',
    fileName: json['fileName'] as String?,
    size: json['size'] as int?,
    checksum: json['checksum'] as String?,
    url: json['url'] as String?,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ModelManifest) return false;
    return version == other.version &&
        model == other.model &&
        fileName == other.fileName &&
        size == other.size &&
        checksum == other.checksum &&
        url == other.url;
  }

  @override
  int get hashCode =>
      Object.hash(version, model, fileName, size, checksum, url);
}

/// Helper to get external files directory (Android).
/// Returns null on web or if not available.
/// This corresponds to getExternalFilesDir(null) on Android.
Future<Directory?> getExternalFilesDir(String? type) async {
  try {
    return await getExternalStorageDirectory();
  } on UnsupportedError {
    // Not supported on this platform (e.g., Linux tests)
    return null;
  }
}

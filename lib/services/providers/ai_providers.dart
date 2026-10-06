/// Riverpod providers for AI services
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ai_service.dart';
import '../../services/downloads.dart';

/// Provider for the AI Service singleton
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

/// Provider for the Download Service singleton
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
});

/// State for model download progress
class DownloadProgress {
  final int received;
  final int total;

  const DownloadProgress({required this.received, required this.total});

  double get progress => total > 0 ? received / total : 0.0;

  @override
  String toString() => 'DownloadProgress($received/$total)';
}

/// State for AI service
class AIServiceState {
  final bool isInitialized;
  final String? modelPath;
  final bool isDownloading;
  final DownloadProgress? downloadProgress;
  final String? error;

  const AIServiceState({
    this.isInitialized = false,
    this.modelPath,
    this.isDownloading = false,
    this.downloadProgress,
    this.error,
  });

  AIServiceState copyWith({
    bool? isInitialized,
    String? modelPath,
    bool? isDownloading,
    DownloadProgress? downloadProgress,
    String? error,
  }) {
    return AIServiceState(
      isInitialized: isInitialized ?? this.isInitialized,
      modelPath: modelPath ?? this.modelPath,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error ?? this.error,
    );
  }

  @override
  String toString() => 'AIServiceState('
      'isInitialized: $isInitialized, '
      'modelPath: $modelPath, '
      'isDownloading: $isDownloading, '
      'downloadProgress: $downloadProgress, '
      'error: $error'
      ')';
}

/// StateNotifier for AI Service
class AIServiceNotifier extends StateNotifier<AIServiceState> {
  final AIService _aiService;

  AIServiceNotifier(this._aiService) : super(const AIServiceState()) {
    initialize();
  }

  Future<void> initialize() async {
    state = state.copyWith(isInitialized: false);
    
    try {
      await _aiService.ensureModelAvailable(
        onProgress: (received, total) {
          state = state.copyWith(
            isDownloading: true,
            downloadProgress: DownloadProgress(received: received, total: total),
          );
        },
        onError: (error) {
          state = state.copyWith(error: error);
        },
      );
      
      final path = await _aiService.getModelPath();
      state = state.copyWith(
        isInitialized: true,
        modelPath: path,
        isDownloading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        isDownloading: false,
        error: e.toString(),
      );
    }
  }

  /// Generate a lesson plan
  Future<String> generateLessonPlan(Map<String, dynamic> params) async {
    try {
      return await _aiService.generateLessonPlan(params);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Force download of model
  Future<void> downloadModel() async {
    await _aiService.ensureModelAvailable(
      onProgress: (received, total) {
        state = state.copyWith(
          isDownloading: true,
          downloadProgress: DownloadProgress(received: received, total: total),
        );
      },
      onError: (error) {
        state = state.copyWith(error: error, isDownloading: false);
      },
    );
    
    state = state.copyWith(
      isDownloading: false,
      modelPath: await _aiService.getModelPath(),
    );
  }

  /// Verify model checksum
  Future<bool> verifyModel() async {
    return await _aiService.verifyCurrentModel();
  }

  /// Cleanup model
  Future<void> cleanup() async {
    await _aiService.cleanup();
    state = state.copyWith(
      isInitialized: false,
      modelPath: null,
    );
  }
}

/// Provider for AI Service State
final aiServiceStateProvider = StateNotifierProvider<AIServiceNotifier, AIServiceState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return AIServiceNotifier(aiService);
});

/// Convenience provider for checking if model is available
final isModelAvailableProvider = Provider<bool>((ref) {
  final state = ref.watch(aiServiceStateProvider);
  return state.isInitialized && state.modelPath != null;
});

/// Convenience provider for download progress
final downloadProgressProvider = Provider<DownloadProgress?>((ref) {
  final state = ref.watch(aiServiceStateProvider);
  return state.downloadProgress;
});

/// Convenience provider for AI service error
final aiServiceErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(aiServiceStateProvider);
  return state.error;
});
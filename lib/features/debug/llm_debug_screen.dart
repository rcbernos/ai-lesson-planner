/// Debug screen for testing LLM engine on device.
/// Only available in debug builds (kDebugMode guard).
library;

import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'package:ai_lesson_planner/core/llm/llm_engine.dart';
import 'package:ai_lesson_planner/core/llm/local_llama_engine.dart';
import 'package:ai_lesson_planner/core/llm/model_paths.dart';
import 'package:ai_lesson_planner/features/debug/download_dialog.dart';
import 'package:ai_lesson_planner/services/llm/model_downloader.dart';

/// Debug screen for testing LLM generation on device.
class LlmDebugScreen extends StatefulWidget {
  const LlmDebugScreen({super.key});

  @override
  State<LlmDebugScreen> createState() => _LlmDebugScreenState();
}

class _LlmDebugScreenState extends State<LlmDebugScreen> {
  final LocalLlamaEngine _engine = LocalLlamaEngine();
  final TextEditingController _promptController = TextEditingController(
    text:
        'Ano ang kahalahuhang nilalaman ng araling ito? Magbigay ng '
        'hindi pampostmodernong sagot na maaaring gamitin ng guro sa pagtuturo.',
  );

  String _output = '';
  bool _isLoading = false;
  bool _isModelLoaded = false;
  bool _isGenerating = false;
  String? _modelPath;
  String? _modelSize;
  double _tokensPerSecond = 0;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  @override
  void dispose() {
    _engine.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _checkModelStatus() async {
    final path = await ModelPaths.checkModelInstalled();
    final size = await ModelPaths.getModelFileSize();
    if (!mounted) return;
    setState(() {
      _modelPath = path;
      _modelSize = size == null ? null : ModelPaths.formatFileSize(size);
    });
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
      _isModelLoaded = false;
    });
    try {
      final expectedPath = await ModelPaths.getExpectedModelPath();
      await _engine.load(
        ModelSpec(path: expectedPath, contextSize: 2048, threads: 4),
      );
      if (!mounted) return;
      setState(() => _isModelLoaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model loaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load model: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (!_isModelLoaded || _isGenerating || prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _output = '';
      _tokensPerSecond = 0;
    });

    final stopwatch = Stopwatch()..start();
    var tokenCount = 0;
    try {
      await for (final token in _engine.complete([
        ChatMsg(role: 'user', content: prompt),
      ], GenParams(temperature: 0.3, maxTokens: 512))) {
        if (!mounted) break;
        tokenCount++;
        setState(() => _output += token);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Generation failed: $e')));
    } finally {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _tokensPerSecond =
              tokenCount / max(1, stopwatch.elapsedMilliseconds / 1000);
        });
      }
    }
  }

  Future<void> _cancelGeneration() => _engine.cancel();

  Future<void> _downloadModel() async {
    final downloader = ModelDownloader();
    final progressStream = downloader.download();

    // Show the download dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        progressStream: progressStream,
        onCancel: () {
          downloader.cancel();
          Navigator.of(context).pop();
        },
      ),
    );

    // Wait for download to complete
    await for (final progress in progressStream) {
      if (progress.isComplete) {
        if (!mounted) break;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model downloaded successfully')),
        );

        // Check model status
        await _checkModelStatus();
        if (!mounted) break;
        Navigator.of(context).pop();
        break;
      }

      if (progress.error != null) {
        if (!mounted) break;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${progress.error}')),
        );
        Navigator.of(context).pop();
        break;
      }
    }
  }

  /// Imports a GGUF model file selected by the user via file picker.
  Future<void> _importModel() async {
    // Allow only .gguf files
    const allowedExtensions = ['gguf'];

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (!mounted || result.isEmpty) {
      // User cancelled the picker
      return;
    }

    final selectedFile = result.first;
    final selectedPath = selectedFile.path;

    if (selectedPath == null || selectedPath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access file path')),
      );
      return;
    }

    final file = File(selectedPath);

    // Check file size (must be at least 100 MB)
    try {
      final fileSize = await file.length();
      const minSize = 100 * 1024 * 1024; // 100 MB

      if (fileSize < minSize) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File too small. Model file must be at least 100 MB.',
            ),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read file: $e')));
      return;
    }

    // Get destination path
    final destPath = await ModelPaths.getExpectedModelPath();
    if (!mounted) return;

    // Show loading indicator during copy
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Importing model file...'),
            ],
          ),
        ),
      ),
    );

    try {
      if (_isModelLoaded) {
        await _engine.unload();
        if (!mounted) return;
        setState(() => _isModelLoaded = false);
      }
      await file.copy(destPath);

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model imported successfully')),
      );

      // Check model status
      await _checkModelStatus();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading dialog

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(
          child: Text('This screen is only available in debug mode'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Debug'),
        actions: [
          if (_isGenerating)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancel generation',
              onPressed: _cancelGeneration,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isModelLoaded
                          ? Icons.check_circle
                          : Icons.report_problem,
                      color: _isModelLoaded ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isModelLoaded
                                ? 'Model Loaded'
                                : _modelPath != null
                                ? 'Model installed. Click Load Model.'
                                : 'No model found. Import via file_picker.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_modelPath != null)
                            SelectableText(
                              'Path: $_modelPath',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (_modelSize != null) Text('Size: $_modelSize'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prompt Input
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Filipino Test Prompt',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _checkModelStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Model'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _downloadModel,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Model'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        (_isLoading || _isGenerating || _modelPath == null)
                        ? null
                        : _loadModel,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Load Model'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_isLoading || _isGenerating)
                        ? null
                        : _importModel,
                    icon: const Icon(Icons.file_copy),
                    label: const Text('Import Model File'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isModelLoaded && !_isGenerating && !_isLoading)
                        ? _generate
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Generate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Output Display
            const Text(
              'Output:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.isEmpty ? 'Waiting for generation...' : _output,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Display
            if (_tokensPerSecond > 0)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Tokens/second: ${_tokensPerSecond.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

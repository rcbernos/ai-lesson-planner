/// Download progress dialog for model downloads.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ai_lesson_planner/services/llm/model_downloader.dart';

/// A dialog that shows download progress.
class DownloadProgressDialog extends StatefulWidget {
  const DownloadProgressDialog({
    super.key,
    required this.progressStream,
    this.onCancel,
  });

  /// Stream of download progress updates.
  final Stream<DownloadProgress> progressStream;

  /// Callback when user cancels.
  final VoidCallback? onCancel;

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  StreamSubscription<DownloadProgress>? _subscription;
  DownloadProgress _currentProgress = DownloadProgress(
    bytesReceived: 0,
    totalBytes: 0,
    isComplete: false,
  );

  @override
  void initState() {
    super.initState();
    _listenToProgress();
  }

  void _listenToProgress() {
    _subscription = widget.progressStream.listen(
      (progress) {
        if (!mounted) return;
        setState(() {
          _currentProgress = progress;
        });

        if (progress.isComplete) {
          Navigator.of(context).pop();
        }
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _currentProgress = DownloadProgress(
            bytesReceived: _currentProgress.bytesReceived,
            totalBytes: _currentProgress.totalBytes,
            isComplete: false,
            error: e.toString(),
          );
        });
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$bytes bytes';
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _currentProgress.error != null;

    return AlertDialog(
      title: const Text('Downloading Model'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _currentProgress.percentage,
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.surface,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            hasError
                ? 'Error: ${_currentProgress.error}'
                : '${_formatBytes(_currentProgress.bytesReceived)} / '
                      '${_currentProgress.totalBytes != null ? _formatBytes(_currentProgress.totalBytes!) : '?'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            (_currentProgress.percentage * 100) < 1
                ? 'Preparing download...'
                : hasError
                ? 'Download failed'
                : 'Downloading model file... This may take several minutes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        if (!hasError)
          TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        if (hasError)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

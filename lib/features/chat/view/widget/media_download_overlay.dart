import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/services/chat_media_storage_service.dart';

/// WhatsApp-style download states for media messages.
enum MediaDownloadState { notDownloaded, downloading, downloaded }

/// A reusable overlay that shows a blurred preview with a download button
/// for received media messages. Once downloaded, tapping opens the file
/// from the device gallery/file manager.
///
/// Wrap any media widget (image, video thumbnail, audio, document) with this.
class MediaDownloadOverlay extends StatefulWidget {
  /// The media URL to download.
  final String url;

  /// Message type: "image", "video", "audio", "document".
  final String messageType;

  /// Optional file name for saving.
  final String? fileName;

  /// The child widget to show underneath (image, video thumbnail, etc.).
  final Widget child;

  /// Widget dimensions.
  final double? width;
  final double? height;

  /// Border radius for clipping.
  final double borderRadius;

  /// File size text to display (e.g. "2.3 MB").
  final String? fileSizeText;

  /// Whether this is a received message (only received msgs need download).
  final bool isReceived;

  /// Callback when download completes. Passes the local file path.
  final void Function(String localPath)? onDownloaded;

  /// Whether to open file on tap after download.
  final bool openOnTap;

  const MediaDownloadOverlay({
    super.key,
    required this.url,
    required this.messageType,
    required this.child,
    this.fileName,
    this.width,
    this.height,
    this.borderRadius = 10,
    this.fileSizeText,
    this.isReceived = true,
    this.onDownloaded,
    this.openOnTap = true,
  });

  @override
  State<MediaDownloadOverlay> createState() => _MediaDownloadOverlayState();
}

class _MediaDownloadOverlayState extends State<MediaDownloadOverlay> {
  MediaDownloadState _state = MediaDownloadState.notDownloaded;
  double _progress = 0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyDownloaded();
  }

  Future<void> _checkIfAlreadyDownloaded() async {
    if (!widget.isReceived || widget.url.isEmpty) {
      setState(() => _state = MediaDownloadState.downloaded);
      return;
    }
    final existing = await ChatMediaStorageService.findExistingFile(
      url: widget.url,
      messageType: widget.messageType,
      fileName: widget.fileName,
    );
    if (existing != null && mounted) {
      setState(() {
        _state = MediaDownloadState.downloaded;
        _localPath = existing.path;
      });
    }
  }

  Future<void> _startDownload() async {
    if (_state == MediaDownloadState.downloading) return;
    setState(() {
      _state = MediaDownloadState.downloading;
      _progress = 0;
    });

    final file = await ChatMediaStorageService.downloadAndSave(
      url: widget.url,
      messageType: widget.messageType,
      fileName: widget.fileName,
      onProgress: (received, total) {
        if (total > 0 && mounted) {
          setState(() => _progress = received / total);
        }
      },
    );

    if (!mounted) return;

    if (file != null) {
      setState(() {
        _state = MediaDownloadState.downloaded;
        _localPath = file.path;
      });
      widget.onDownloaded?.call(file.path);
    } else {
      setState(() => _state = MediaDownloadState.notDownloaded);
    }
  }

  void _openFile() {
    if (_localPath == null) return;
    try {
      OpenFile.open(_localPath!);
    } catch (e) {
      debugPrint('Could not open file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If sent by me or already downloaded, show normal media
    if (!widget.isReceived || _state == MediaDownloadState.downloaded) {
      // When openOnTap is true and file is available, open it on tap.
      // Otherwise, return child directly so the parent's onTap works.
      if (widget.openOnTap && _localPath != null) {
        return GestureDetector(
          onTap: _openFile,
          child: widget.child,
        );
      }
      return widget.child;
    }

    // Not downloaded or downloading — show blurred overlay
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred child underneath
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: widget.child,
            ),
          ),

          // Dark scrim
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

          // Download button / progress
          Center(
            child: _state == MediaDownloadState.downloading
                ? _buildProgressIndicator()
                : _buildDownloadButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: _startDownload,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text(
              widget.fileSizeText ?? _typeLabel(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final percent = (_progress * 100).toInt();
    return GestureDetector(
      onTap: () {
        // Cancel not supported for now — just show progress
      },
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: _progress > 0 ? _progress : null,
                strokeWidth: 3,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            // Percentage text
            Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel() {
    switch (widget.messageType.toLowerCase()) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'document':
        return 'Document';
      default:
        return 'Download';
    }
  }
}

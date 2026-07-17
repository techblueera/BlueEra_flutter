import 'dart:io';

import 'package:BlueEra/core/services/chat_media_storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a symbol's photo from the local `Symbols/` folder once it has been
/// cached; otherwise streams it over the network and saves a copy into
/// `Symbols/` in the background so the next open renders straight from disk
/// (WhatsApp-style local media).
class SymbolCachedImage extends StatefulWidget {
  /// The symbol media URL (http/https) or, already, a local file path.
  final String url;

  /// Symbol id — used to build the stable on-disk filename.
  final String id;

  final BoxFit fit;
  final double? width;
  final double? height;

  const SymbolCachedImage({
    super.key,
    required this.url,
    required this.id,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  State<SymbolCachedImage> createState() => _SymbolCachedImageState();
}

class _SymbolCachedImageState extends State<SymbolCachedImage> {
  File? _localFile;

  bool get _isRemote => widget.url.isNotEmpty && widget.url.startsWith('http');

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant SymbolCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.id != widget.id) {
      _localFile = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    if (!_isRemote) return; // already a local path or empty
    final existing = await ChatMediaStorageService.findExistingSymbol(
      url: widget.url,
      id: widget.id,
    );
    if (existing != null) {
      if (mounted) setState(() => _localFile = existing);
      return;
    }
    // Not cached yet — the network branch renders now; download in the
    // background and swap to the local file when it lands.
    final saved = await ChatMediaStorageService.downloadAndSaveSymbol(
      url: widget.url,
      id: widget.id,
    );
    if (saved != null && mounted) setState(() => _localFile = saved);
  }

  @override
  Widget build(BuildContext context) {
    // Caller already passed a local file path.
    if (!_isRemote && widget.url.isNotEmpty) {
      final f = File(widget.url);
      if (f.existsSync()) {
        return Image.file(f,
            fit: widget.fit, width: widget.width, height: widget.height);
      }
    }

    if (_localFile != null) {
      return Image.file(
        _localFile!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (_, __, ___) => _network(),
      );
    }
    return _network();
  }

  Widget _network() {
    if (widget.url.isEmpty) return const SizedBox.shrink();
    return CachedNetworkImage(
      imageUrl: widget.url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) =>
          const Icon(Icons.broken_image, color: Colors.white54),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:video_compress/video_compress.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_media_storage_service.dart';
import '../../../../core/services/local_strorage_helper.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/model/messageMediaUrl.dart';
import '../widget/chat_cached_image.dart';
import '../widget/media_message_full_view.dart';

/// WhatsApp-style "Media, Links and Docs" page for a conversation.
class ConversationMediaPage extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final int initialTab;

  const ConversationMediaPage({
    super.key,
    required this.conversationId,
    required this.contactName,
    this.initialTab = 0,
  });

  @override
  State<ConversationMediaPage> createState() => _ConversationMediaPageState();
}

class _ConversationMediaPageState extends State<ConversationMediaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = LocalStorageHelper();

  List<Messages> _mediaMessages = [];
  List<Messages> _docMessages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    final all = await _storage.getMediaMessagesByConversationId(
        widget.conversationId);

    for (final msg in all) {
      if (msg.url == null) continue;
      for (final media in msg.url!) {
        final url = media.url;
        if (url == null || !url.contains('http')) continue;
        final local = await ChatMediaStorageService.findExistingFile(
          url: url,
          messageType: msg.messageType ?? 'image',
          fileName: media.name,
        );
        if (local != null) media.url = local.path;
      }
    }

    final media = <Messages>[];
    final docs = <Messages>[];
    for (final m in all) {
      if (m.messageType == 'image' || m.messageType == 'video') {
        media.add(m);
      } else {
        docs.add(m);
      }
    }
    media.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    docs.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    if (mounted) {
      setState(() {
        _mediaMessages = media;
        _docMessages = docs;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              widget.contactName,
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            CustomText(
              AppStrings.mediaDocs.tr,
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.black45,
          indicatorColor: AppColors.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: 'Media (${_mediaMessages.length})'),
            Tab(text: 'Docs (${_docMessages.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMediaGrid(),
                _buildDocsList(),
              ],
            ),
    );
  }

  // ─── Media Grid ────────────────────────────────────────────────────────────

  Widget _buildMediaGrid() {
    if (_mediaMessages.isEmpty) {
      return _emptyState(Icons.photo_library_outlined, AppStrings.noMediaSharedYet.tr);
    }

    final items = <_MediaItem>[];
    for (final msg in _mediaMessages) {
      if (msg.url == null) continue;
      for (int i = 0; i < msg.url!.length; i++) {
        items.add(_MediaItem(
          media: msg.url![i],
          message: msg,
          indexInMessage: i,
        ));
      }
    }

    final flatMediaList = items.map((e) => e.media).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final url = item.media.url ?? '';
        final isVideo = item.message.messageType == 'video' || _isVideoUrl(url);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullImagePreviewPage(
                  images: flatMediaList,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: isVideo
              ? _VideoThumbnailTile(videoPath: url)
              : ChatCachedImage(url: url, fit: BoxFit.cover),
        );
      },
    );
  }

  // ─── Documents List ────────────────────────────────────────────────────────

  Widget _buildDocsList() {
    if (_docMessages.isEmpty) {
      return _emptyState(Icons.insert_drive_file_outlined, AppStrings.noDocumentsSharedYet.tr);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _docMessages.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 72,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final msg = _docMessages[index];
        final media = msg.url?.firstOrNull;
        final url = media?.url ?? '';
        final name = media?.name ?? 'Document';
        final isAudio = msg.messageType == 'audio';
        final isPdf = name.toLowerCase().endsWith('.pdf');
        final date = _formatDate(msg.createdAt);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isAudio
                  ? _audioIcon()
                  : isPdf && !url.contains('http') && url.isNotEmpty
                      ? _PdfThumbnailTile(pdfPath: url)
                      : _docIcon(),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            date,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          trailing: Icon(
            url.contains('http') ? Icons.download_rounded : Icons.open_in_new_rounded,
            size: 20,
            color: Colors.black38,
          ),
          onTap: () {
            if (!url.contains('http') && url.isNotEmpty) {
              try { OpenFile.open(url); } catch (_) {}
            }
          },
        );
      },
    );
  }

  Widget _audioIcon() {
    return Container(
      color: Colors.purple.shade50,
      child: Icon(Icons.audiotrack_rounded, color: Colors.purple.shade400, size: 26),
    );
  }

  Widget _docIcon() {
    return Container(
      color: Colors.red.shade50,
      child: Icon(Icons.insert_drive_file_rounded, color: Colors.red.shade400, size: 26),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') ||
        lower.endsWith('.avi') || lower.endsWith('.mkv');
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─── Video Thumbnail Tile ──────────────────────────────────────────────────

class _VideoThumbnailTile extends StatefulWidget {
  final String videoPath;
  const _VideoThumbnailTile({required this.videoPath});

  @override
  State<_VideoThumbnailTile> createState() => _VideoThumbnailTileState();
}

class _VideoThumbnailTileState extends State<_VideoThumbnailTile> {
  File? _thumbnail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final path = widget.videoPath;

    // VideoCompress only works on local files — for network URLs (or empty
    // paths) fall straight through to the "Not playable" state.
    if (path.isEmpty || path.contains('http')) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final source = File(path);
      if (!await source.exists()) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final thumb = await VideoCompress.getFileThumbnail(
        path,
        quality: 30,
        position: -1,
      ).timeout(const Duration(seconds: 5));
      if (await thumb.exists() && await thumb.length() > 0) {
        if (mounted) setState(() { _thumbnail = thumb; _loading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Widget _videoPlaceholder() {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Icon(
        Icons.videocam_rounded,
        color: Colors.white.withValues(alpha: 0.35),
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasThumb = _thumbnail != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasThumb)
          Image.file(
            _thumbnail!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _videoPlaceholder(),
          )
        else if (_loading)
          Container(
            color: Colors.black87,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white38),
            ),
          )
        else
          _videoPlaceholder(),
        // Play icon overlay — always shown so the tile reads as a tappable video
        Center(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

// ─── PDF Thumbnail Tile ────────────────────────────────────────────────────

class _PdfThumbnailTile extends StatefulWidget {
  final String pdfPath;
  const _PdfThumbnailTile({required this.pdfPath});

  @override
  State<_PdfThumbnailTile> createState() => _PdfThumbnailTileState();
}

class _PdfThumbnailTileState extends State<_PdfThumbnailTile> {
  Uint8List? _imageBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    try {
      final doc = await pdfx.PdfDocument.openFile(widget.pdfPath);
      final page = await doc.getPage(1);
      final image = await page.render(
        width: page.width * 0.5,
        height: page.height * 0.5,
        format: pdfx.PdfPageImageFormat.png,
      );
      await page.close();
      await doc.close();
      if (mounted && image != null) {
        setState(() { _imageBytes = image.bytes; _loading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.red.shade50,
      child: _loading
          ? Center(child: SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red.shade300)))
          : Icon(Icons.insert_drive_file_rounded, color: Colors.red.shade400, size: 26),
    );
  }
}

// ─── Data class ────────────────────────────────────────────────────────────

class _MediaItem {
  final MessageMediaUrl media;
  final Messages message;
  final int indexInMessage;
  const _MediaItem({required this.media, required this.message, required this.indexInMessage});
}

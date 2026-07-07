import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../auth/controller/bookmark_controller.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/model/bookmarked_media.dart';
import '../../auth/model/messageMediaUrl.dart';
import '../forward_screen/chat_forward_screen.dart';

class FullImagePreviewPage extends StatefulWidget {
  final List<MessageMediaUrl> images;
  final int initialIndex;
  final bool? isFromComment;

  /// Optional per-image captions, parallel to [images]. When a caption exists
  /// for the current media, it is shown WhatsApp-style over a bottom gradient
  /// (white text, 2 lines collapsed + a "Read more" toggle).
  final List<String?>? captions;

  /// Optional per-image parent messages, parallel to [images]. When provided,
  /// a YouTube-Shorts-style like/reply/forward action rail is shown on the
  /// right for the current media.
  final List<Messages?>? messages;

  /// Conversation context used when bookmarking a photo so the Bookmarks
  /// screen can group it under the right person.
  final String? conversationId;
  final String? personName;
  final String? personImage;

  const FullImagePreviewPage({
    super.key,
    required this.images,
    required this.initialIndex,
    this.isFromComment,
    this.captions,
    this.messages,
    this.conversationId,
    this.personName,
    this.personImage,
  });

  @override
  State<FullImagePreviewPage> createState() => _FullImagePreviewPageState();
}

class _FullImagePreviewPageState extends State<FullImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = true;

  /// Whether the current image's caption is expanded past its 2-line preview.
  bool _captionExpanded = false;

  /// Caption font size — slightly larger for readability in full screen.
  static const double _captionFontSize = 16;
  static const Color _captionLinkColor = Color(0xFF4FC3F7);

  /// Tap recognizers for clickable caption links; disposed with the state.
  final List<TapGestureRecognizer> _linkRecognizers = [];

  Messages? _messageAt(int index) {
    final msgs = widget.messages;
    if (msgs == null || index < 0 || index >= msgs.length) return null;
    return msgs[index];
  }

  /// Optimistically toggles the like on [msg] and fires the API. The Messages
  /// object is shared with the chat list, so the update stays consistent.
  void _toggleLike(Messages msg) {
    final wasLiked = msg.is_liked ?? false;
    final current = int.tryParse(msg.likes_count ?? '0') ?? 0;
    setState(() {
      msg.is_liked = !wasLiked;
      msg.likes_count = (wasLiked ? (current - 1) : (current + 1))
          .clamp(0, 1 << 31)
          .toString();
    });
    final data = {
      ApiKeys.message_id: msg.id ?? '',
      ApiKeys.type: "Code1",
    };
    Get.find<ChatViewController>()
        .likeAndUnlikeMessage(data, msg.senderId ?? '', msg.conversationId ?? '');
  }

  /// Sets the reply target and returns to the chat so the user can compose.
  void _reply(Messages msg) {
    Get.find<ChatViewController>().setReplyMessage(msg);
    Navigator.pop(context);
  }

  /// Activates selection for [msg] and opens the forward screen.
  void _forward(Messages msg) {
    Get.find<ChatThemeController>().activateSelection(msg);
    Navigator.pop(context);
    Get.to(() => ChatForwardScreen());
  }

  String? _captionAt(int index) {
    final caps = widget.captions;
    if (caps == null || index < 0 || index >= caps.length) return null;
    final c = caps[index];
    return (c != null && c.trim().isNotEmpty) ? c : null;
  }

  /// True when [caption] wouldn't fit in 2 lines at the current width, so a
  /// "Read more" toggle is warranted.
  bool _captionOverflows(String caption) {
    final tp = TextPainter(
      text: TextSpan(
        text: caption,
        style: const TextStyle(fontSize: _captionFontSize, height: 1.35),
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 32);
    return tp.didExceedMaxLines;
  }

  bool isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv');
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final r in _linkRecognizers) {
      r.dispose();
    }
    super.dispose();
  }

  /// Opens a tapped caption link in the device's default browser / the
  /// respective app that handles the URL, instead of an in-app web view.
  void _openLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  /// Builds the caption text with any http(s) links rendered in blue and made
  /// tappable. When [maxLines] is set the text is clamped with an ellipsis.
  Widget _linkifiedCaption(String caption, {int? maxLines}) {
    const baseStyle = TextStyle(
      color: Colors.white,
      fontSize: _captionFontSize,
      height: 1.35,
    );
    final urlRegex = RegExp(r'https?:\/\/[^\s]+');
    final matches = urlRegex.allMatches(caption).toList();

    final overflow =
        maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip;

    if (matches.isEmpty) {
      return Text(caption,
          maxLines: maxLines, overflow: overflow, style: baseStyle);
    }

    // Rebuild recognizers each frame; dispose the previous set first.
    for (final r in _linkRecognizers) {
      r.dispose();
    }
    _linkRecognizers.clear();

    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: caption.substring(cursor, m.start)));
      }
      final url = m.group(0)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _openLink(url);
      _linkRecognizers.add(recognizer);
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          color: _captionLinkColor,
          decoration: TextDecoration.underline,
          decorationColor: _captionLinkColor,
        ),
        recognizer: recognizer,
      ));
      cursor = m.end;
    }
    if (cursor < caption.length) {
      spans.add(TextSpan(text: caption.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        child: Stack(
          children: [
            // Media PageView
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() {
                _currentIndex = index;
                _captionExpanded = false;
              }),
              itemBuilder: (context, index) {
                final media = widget.images[index];
                final url = media.url ?? '';
                if (isVideo(url)) {
                  return _FullScreenVideoPlayer(videoUrl: url);
                }
                return _FullScreenImageViewer(imageUrl: url);
              },
            ),

            // Top bar
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showOverlay,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          if (widget.images.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / ${widget.images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // YouTube-Shorts-style action rail — like / reply / forward on the
            // right edge, with glossy shadowed circular buttons.
            Builder(builder: (context) {
              final msg = _messageAt(_currentIndex);
              if (msg == null) return const SizedBox.shrink();
              return Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _showOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showOverlay,
                    child: Center(
                      child: _buildActionRail(msg),
                    ),
                  ),
                ),
              );
            }),

            // Caption overlay (WhatsApp-style) — bottom gradient + white text,
            // 2 lines collapsed with a "Read more"/"Read less" toggle.
            Builder(builder: (context) {
              final caption = _captionAt(_currentIndex);
              if (caption == null) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedOpacity(
                  opacity: _showOverlay ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showOverlay,
                    child: _buildCaptionOverlay(caption),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionOverlay(String caption) {
    final overflows = _captionOverflows(caption);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _captionExpanded
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: SingleChildScrollView(
                      child: _linkifiedCaption(caption),
                    ),
                  )
                : _linkifiedCaption(caption, maxLines: 2),
            if (overflows)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    setState(() => _captionExpanded = !_captionExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _captionExpanded ? 'Read less' : 'Read more',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Vertical like / reply / forward rail (YouTube-Shorts style).
  Widget _buildActionRail(Messages msg) {
    final isLiked = msg.is_liked ?? false;
    final likeCount = int.tryParse(msg.likes_count ?? '0') ?? 0;
    final replyCount = int.tryParse(msg.replies_count ?? '0') ?? 0;
    final forwardCount = int.tryParse(msg.forwards_count ?? '0') ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _glossyActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: isLiked ? const Color(0xFFFF3040) : Colors.white,
          label: likeCount > 0 ? _shortCount(likeCount) : 'Like',
          onTap: () => _toggleLike(msg),
        ),
        const SizedBox(height: 18),
        _glossyActionButton(
          icon: Icons.reply,
          label: replyCount > 0 ? _shortCount(replyCount) : 'Reply',
          onTap: () => _reply(msg),
        ),
        const SizedBox(height: 18),
        _glossyActionButton(
          icon: Icons.forward,
          label: forwardCount > 0 ? _shortCount(forwardCount) : 'Forward',
          onTap: () => _forward(msg),
        ),
        const SizedBox(height: 18),
        // Local bookmark — reacts live to the saved state.
        Obx(() {
          final url = _currentUrl;
          final saved = url != null && BookmarkController.to.isBookmarked(url);
          return _glossyActionButton(
            icon: saved ? Icons.bookmark : Icons.bookmark_border,
            iconColor: saved ? const Color(0xFFFFC107) : Colors.white,
            label: saved ? 'Saved' : 'Save',
            onTap: () => _toggleBookmark(msg),
          );
        }),
      ],
    );
  }

  String? get _currentUrl =>
      (_currentIndex >= 0 && _currentIndex < widget.images.length)
          ? widget.images[_currentIndex].url
          : null;

  /// Adds/removes the current photo from local bookmarks, grouped under the
  /// conversation's person on the Bookmarks screen.
  Future<void> _toggleBookmark(Messages? msg) async {
    final idx = _currentIndex;
    if (idx < 0 || idx >= widget.images.length) return;
    final media = widget.images[idx];
    final url = media.url;
    if (url == null || url.isEmpty) return;
    final bm = BookmarkedMedia(
      url: url,
      name: media.name,
      conversationId: widget.conversationId ?? msg?.conversationId ?? '',
      personName: widget.personName,
      personImage: widget.personImage,
      messageId: msg?.id,
      caption: _captionAt(idx),
      savedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final added = await BookmarkController.to.toggle(bm);
    commonSnackBar(
        message: added ? 'Added to bookmarks' : 'Removed from bookmarks');
  }

  /// A glossy, shadowed circular action button with a label beneath it.
  Widget _glossyActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  /// Compact count formatting (1.2K, 3.4M) for the rail labels.
  String _shortCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

/// Full-screen image viewer with pinch-to-zoom
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isNetwork = imageUrl.contains('http');
    return Center(
      child: InteractiveViewer(
        maxScale: 5.0,
        minScale: 0.5,
        child: isNetwork
            ? Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  final percent = progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null;
                  return Center(
                    child: CircularProgressIndicator(
                      value: percent,
                      color: Colors.white70,
                      strokeWidth: 2.5,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            size: 48, color: Colors.white38),
                        SizedBox(height: 12),
                        Text('Failed to load image',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  );
                },
              )
            : Image.file(
                File(imageUrl),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            size: 48, color: Colors.white38),
                        SizedBox(height: 12),
                        Text('Failed to load image',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Full-screen video player with controls
class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _FullScreenVideoPlayer({required this.videoUrl});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.contains('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoUrl));
    }

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _hasError = true;
      });
    });

    _controller.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white38),
            SizedBox(height: 12),
            Text('Video unavailable',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }

    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white70,
          strokeWidth: 2.5,
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // Play/Pause button
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: GestureDetector(
                onTap: () {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),

          // Bottom progress bar
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          colors: const VideoProgressColors(
                            playedColor: Colors.white,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

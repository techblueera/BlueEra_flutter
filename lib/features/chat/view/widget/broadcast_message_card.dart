import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/messageMediaUrl.dart';
import 'package:BlueEra/features/chat/view/widget/chat_cached_image.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/features/chat/view/widget/media_message_full_view.dart';
import 'package:BlueEra/features/common/reel/widget/auto_video_playback_manager.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Full-width broadcast card for the BlueEra / Admin conversation — renders a
/// single [Messages] as a news-channel post (edge-to-edge image, larger body
/// font, tappable in-text links, a link-preview chip and a reactions/forward
/// footer) so a broadcast thread reads like the reference Telegram channel
/// post. Used ONLY for broadcast (Admin) messages; normal chat messages keep
/// the standard [MessageCard] bubble.
class BroadcastMessageCard extends StatefulWidget {
  final Messages message;

  const BroadcastMessageCard({super.key, required this.message});

  @override
  State<BroadcastMessageCard> createState() => _BroadcastMessageCardState();
}

class _BroadcastMessageCardState extends State<BroadcastMessageCard> {
  /// Number of lines a long broadcast body is clamped to before the
  /// "Read more" toggle is shown — mirrors the WhatsApp-channel look.
  static const int _collapsedMaxLines = 8;

  /// Matches http(s) URLs in the body so they can be rendered as tappable
  /// blue links (like the "https://dainik.bhaskar.com/…" link in the
  /// reference post).
  static final RegExp _urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');

  /// Whether the user has expanded a clamped body via "Read more".
  bool _expanded = false;

  /// Tap recognizers for the in-text links. Rebuilt every build and disposed
  /// here + in [dispose] so we never leak gesture recognizers.
  final List<TapGestureRecognizer> _recognizers = [];

  Messages get message => widget.message;

  ChatThemeController get _theme => Get.find<ChatThemeController>();

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  /// Image/video media URLs attached to the broadcast, in order. Audio / docs
  /// are excluded — the broadcast card only lays out photos & video thumbs.
  List<String> get _mediaUrls => (message.url ?? [])
      .where((m) => (m.url ?? '').isNotEmpty && _isImageOrVideo(m))
      .map((m) => m.url!)
      .toList();

  bool _isImageOrVideo(MessageMediaUrl m) {
    final type = (m.type ?? '').toLowerCase();
    if (type == 'image' || type == 'video') return true;
    // Fall back to the extension when the type field is missing.
    return !_isAudioUrl(m.url ?? '');
  }

  bool _isAudioUrl(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.mp3') ||
        path.endsWith('.m4a') ||
        path.endsWith('.wav') ||
        path.endsWith('.aac') ||
        path.endsWith('.ogg');
  }

  /// First http(s) link found in the body, used for the link-preview chip.
  String? get _firstBodyLink {
    final match = _urlRegExp.firstMatch(message.message ?? '');
    return match?.group(0);
  }

  /// Bare domain (no scheme / "www." / path) of [url] for the preview chip.
  String _domainOf(String url) {
    try {
      var host = Uri.parse(url).host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host.isNotEmpty ? host : url;
    } catch (_) {
      return url;
    }
  }

  Future<void> _openLink(String url) async {
    try {
      await launchURL(url);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final body = (message.message ?? '').trim();
    final images = _mediaUrls;
    final time = formatChatTime(message.createdAt ?? '');
    final link = _firstBodyLink;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Obx(
        () => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildImages(context, images, body),
                ),
              if (body.isNotEmpty) _buildBody(body),
              if (link != null) ...[
                const SizedBox(height: 8),
                _buildLinkPreview(link),
              ],
              const SizedBox(height: 6),
              _buildFooter(time),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the broadcast body as a news-channel post: the first line is a
  /// bold headline and the rest is a normal-weight grey description — both at
  /// the SAME font size. The description keeps the "Read more" clamp for long
  /// text; in-text http(s) links stay tappable blue in either part.
  Widget _buildBody(String body) {
    _disposeRecognizers();
    // Match the normal chat message font size (no broadcast up-scale) so a
    // broadcast reads at the same size as a regular bubble.
    final fontSize = _theme.chatFontSize.value;

    // Split into headline (first line) + description (the remainder).
    final newlineIdx = body.indexOf('\n');
    final title =
        (newlineIdx == -1 ? body : body.substring(0, newlineIdx)).trim();
    final description =
        newlineIdx == -1 ? '' : body.substring(newlineIdx + 1).trim();

    final titleStyle = _theme.chatTextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      isMyMessage: false,
    );
    final descStyle = _theme
        .chatTextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          isMyMessage: false,
        )
        .copyWith(color: AppColors.secondaryTextColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty)
          Text.rich(
            TextSpan(style: titleStyle, children: _linkifiedSpans(title, titleStyle)),
          ),
        if (title.isNotEmpty && description.isNotEmpty)
          const SizedBox(height: 3),
        if (description.isNotEmpty)
          _buildDescription(_linkifiedSpans(description, descStyle), descStyle),
      ],
    );
  }

  /// The grey description with the collapsed-line clamp + "Read more" toggle.
  /// Spans are precomputed by [_buildBody] so link recognizers aren't rebuilt
  /// on every LayoutBuilder relayout.
  Widget _buildDescription(List<InlineSpan> spans, TextStyle style) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure the full text against the collapsed line cap to decide
        // whether a "Read more" affordance is even needed.
        final painter = TextPainter(
          text: TextSpan(style: style, children: spans),
          maxLines: _collapsedMaxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        if (!painter.didExceedMaxLines) {
          return Text.rich(TextSpan(style: style, children: spans));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(style: style, children: spans),
              maxLines: _expanded ? null : _collapsedMaxLines,
              overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: CustomText(
                  _expanded ? 'Read less' : 'Read more',
                  fontSize: _theme.chatFontSize.value,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Splits [body] into plain-text runs and tappable blue link runs.
  List<InlineSpan> _linkifiedSpans(String body, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    int start = 0;
    for (final match in _urlRegExp.allMatches(body)) {
      if (match.start > start) {
        spans.add(TextSpan(text: body.substring(start, match.start)));
      }
      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _openLink(url);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: url,
        style: baseStyle.copyWith(
          color: const Color(0xFF1B7DED),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFF1B7DED),
        ),
        recognizer: recognizer,
      ));
      start = match.end;
    }
    if (start < body.length) {
      spans.add(TextSpan(text: body.substring(start)));
    }
    return spans;
  }

  /// Rich link preview — the SAME card used by normal chat messages
  /// (see MessageBubble.buildLinkPreview): a cover image with the page title,
  /// description and domain, tappable to open the URL.
  Widget _buildLinkPreview(String url) {
    final domain = _domainOf(url);
    return GestureDetector(
      onTap: () => _openLink(url),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: AnyLinkPreview.builder(
            link: url,
            cache: const Duration(days: 7),
            placeholderWidget: Container(
              height: 200,
              color: Colors.grey.shade100,
              child: const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryColor),
              ),
            ),
            errorWidget: const SizedBox.shrink(),
            itemBuilder: (context, metadata, imageProvider, svgImage) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageProvider != null)
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image(image: imageProvider, fit: BoxFit.cover),
                    )
                  else if (svgImage != null)
                    SizedBox(
                        height: 140, width: double.infinity, child: svgImage),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (metadata.title != null &&
                            metadata.title!.isNotEmpty)
                          CustomText(
                            metadata.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        if (metadata.desc != null &&
                            metadata.desc!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          CustomText(
                            metadata.desc!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            fontSize: 11,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ],
                        const SizedBox(height: 6),
                        CustomText(
                          domain,
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Bottom row: reaction pill (emoji cluster + like count) and forward pill
  /// on the left, timestamp pinned to the right — mirroring the reference
  /// channel post. Each pill only shows when its count is non-zero.
  Widget _buildFooter(String time) {
    final likes = int.tryParse(message.likes_count ?? '') ?? 0;
    final forwards = int.tryParse(message.forwards_count ?? '') ?? 0;

    return Row(
      children: [
        if (likes > 0) ...[
          _reactionPill(likes),
          const SizedBox(width: 8),
        ],
        if (forwards > 0) ...[
          _forwardPill(forwards),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        CustomText(
          time,
          fontSize: 11.5,
          color: _theme.chatTimeColor.value,
        ),
      ],
    );
  }

  Widget _reactionPill(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😂👍😮🙏', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          CustomText(
            '$count',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5B6472),
          ),
        ],
      ),
    );
  }

  Widget _forwardPill(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shortcut_rounded, size: 15, color: Color(0xFF5B6472)),
          const SizedBox(width: 5),
          CustomText(
            '$count',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5B6472),
          ),
        ],
      ),
    );
  }

  /// Whether [url]'s extension marks it as a video (vs an image).
  bool _isVideoUrl(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.webm') ||
        path.endsWith('.mkv');
  }

  Widget _mediaThumb(String url, {double? width, double? height}) {
    if (_isVideoUrl(url)) {
      return Container(
        width: width,
        height: height,
        color: Colors.black87,
        alignment: Alignment.center,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 32),
        ),
      );
    }
    return ChatCachedImage(
      url: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  /// Single full-width item, or a 2-column grid (max 4, with a "+N" overlay)
  /// for multiples — mirrors the notification-screen broadcast layout. Tapping
  /// opens the shared full-screen viewer with the body as caption.
  Widget _buildImages(BuildContext context, List<String> images, String body) {
    // Full-width card: screen width minus the outer margins (6*2) and the
    // bubble's inner horizontal padding (10*2).
    final width = MediaQuery.of(context).size.width - 32;

    if (images.length == 1) {
      final url = images.first;
      // A single video autoplays while it's the most-visible one on screen
      // (scroll-driven, one at a time); tapping still opens the full viewer.
      if (_isVideoUrl(url)) {
        return _BroadcastAutoPlayVideo(
          videoId: url,
          url: url,
          width: width,
          height: width * 0.72,
          onTap: () => _openImages(images, body, 0),
        );
      }
      return GestureDetector(
        onTap: () => _openImages(images, body, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _mediaThumb(url, width: width, height: width * 0.72),
        ),
      );
    }

    final displayCount = images.length > 4 ? 4 : images.length;
    return SizedBox(
      width: width,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final showOverlay = images.length > 4 && index == 3;
          return GestureDetector(
            onTap: () => _openImages(images, body, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _mediaThumb(images[index]),
                  if (showOverlay)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      alignment: Alignment.center,
                      child: Text(
                        '+${images.length - 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openImages(List<String> images, String body, int index) {
    final caption = body.trim().isNotEmpty ? body.trim() : null;
    Get.to(() => FullImagePreviewPage(
          images: images.map((u) => MessageMediaUrl(url: u)).toList(),
          initialIndex: index,
          captions: List<String?>.filled(images.length, caption),
        ));
  }
}

/// Inline broadcast video that auto-plays only while it is the most-visible
/// video on screen, coordinated by the shared [SimplePriorityVideoManager] so
/// exactly one video plays at a time as the user scrolls (same engine the feed
/// uses). Shows a play glyph over a dark backdrop until it becomes current;
/// tapping opens the full-screen viewer.
class _BroadcastAutoPlayVideo extends StatefulWidget {
  final String videoId;
  final String url;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _BroadcastAutoPlayVideo({
    required this.videoId,
    required this.url,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  State<_BroadcastAutoPlayVideo> createState() =>
      _BroadcastAutoPlayVideoState();
}

class _BroadcastAutoPlayVideoState extends State<_BroadcastAutoPlayVideo> {
  final SimplePriorityVideoManager _videoManager =
      Get.isRegistered<SimplePriorityVideoManager>()
          ? Get.find<SimplePriorityVideoManager>()
          : Get.put(SimplePriorityVideoManager());

  @override
  void dispose() {
    // Drop this video from the visibility pool so scrolling away (or leaving
    // the thread) hands playback back to the next visible video / pauses.
    _videoManager.removeVideo(widget.videoId);
    super.dispose();
  }

  void _onVisibility(VisibilityInfo info) {
    _videoManager.updateVideoVisibility(
        widget.videoId, widget.url, info.visibleFraction);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('bcast_vid_${widget.videoId}'),
      onVisibilityChanged: _onVisibility,
      child: GetBuilder<SimplePriorityVideoManager>(
        builder: (vm) {
          final controller = vm.controller;
          final isCurrent = vm.currentIndex.value == widget.videoId.hashCode;
          final showVideo = isCurrent &&
              controller != null &&
              controller.value.isInitialized &&
              controller.value.size.width > 0 &&
              controller.value.size.height > 0;

          return GestureDetector(
            onTap: widget.onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.black87),
                    if (showVideo)
                      FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    if (!showVideo)
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 34),
                        ),
                      ),
                    if (showVideo)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _videoManager.toggleMute,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _videoManager.isMuted,
                              builder: (_, muted, __) => Icon(
                                muted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
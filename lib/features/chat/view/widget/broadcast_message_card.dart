import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/messageMediaUrl.dart';
import 'package:BlueEra/features/chat/view/widget/chat_cached_image.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/features/chat/view/widget/media_message_full_view.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-width broadcast card for the BlueEra / Admin conversation — renders a
/// single [Messages] with the SAME design as [BlueEraNotificationScreen]'s
/// bubble (edge-to-edge card, larger font, image grid) so a broadcast thread
/// opened from the chat list looks identical to the one opened from a
/// notification tap. Used ONLY for broadcast (Admin) messages; normal chat
/// messages keep the standard [MessageCard] bubble.
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

  /// Whether the user has expanded a clamped body via "Read more".
  bool _expanded = false;

  Messages get message => widget.message;

  ChatThemeController get _theme => Get.find<ChatThemeController>();

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

  @override
  Widget build(BuildContext context) {
    final body = (message.message ?? '').trim();
    final images = _mediaUrls;
    final time = formatChatTime(message.createdAt ?? '');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Obx(
        () => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildImages(context, images, body),
                ),
              if (body.isNotEmpty)
                _buildBody(
                  body,
                  _theme.chatTextStyle(
                    fontSize: _theme.chatFontSize.value + 3,
                    fontWeight: FontWeight.w500,
                    isMyMessage: false,
                  ),
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: CustomText(
                  time,
                  fontSize: 11.5,
                  color: _theme.chatTimeColor.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the broadcast body like a WhatsApp-channel post: short text shows
  /// in full, while a long message is clamped to [_collapsedMaxLines] with an
  /// ellipsis and a "Read more" toggle that expands / collapses it in place.
  Widget _buildBody(String body, TextStyle style) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure the full text against the collapsed line cap to decide
        // whether a "Read more" affordance is even needed.
        final painter = TextPainter(
          text: TextSpan(text: body, style: style),
          maxLines: _collapsedMaxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        if (!painter.didExceedMaxLines) {
          return Text(body, style: style);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              body,
              style: style,
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
      return GestureDetector(
        onTap: () => _openImages(images, body, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _mediaThumb(images.first, width: width, height: width * 0.72),
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

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/model/messageMediaUrl.dart';
import 'package:BlueEra/features/chat/notification_chat/controller/blueera_notification_controller.dart';
import 'package:BlueEra/features/chat/view/widget/chat_cached_image.dart';
import 'package:BlueEra/features/chat/view/widget/media_message_full_view.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Read-only conversation that renders every stored broadcast / system
/// notification (profile updates, admin announcements, etc.) as incoming chat
/// bubbles — styled exactly like [PersonalChatScreen]/[MessageBubble] received
/// messages, over the same chat background, but with no input bar and no
/// "Read more" truncation (the full notification text is always shown).
/// Opened by tapping the pinned "BlueEra" row in the personal chat list.
class BlueEraNotificationScreen extends StatefulWidget {
  const BlueEraNotificationScreen({super.key});

  @override
  State<BlueEraNotificationScreen> createState() =>
      _BlueEraNotificationScreenState();
}

class _BlueEraNotificationScreenState extends State<BlueEraNotificationScreen> {
  final controller = BlueEraNotificationController.to;
  // Self-register so the background + bubble colors match the rest of the chat
  // surfaces regardless of entry path (mirrors PersonalChatScreen).
  final chatThemeController = getOrPut(() => ChatThemeController());

  @override
  void initState() {
    super.initState();
    // Opening the thread clears the unread badge on the chat-list row.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.markAllRead();
    });
  }

  String _formatTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return DateFormat('h:mm a').format(dt);
    return DateFormat("d MMM, h:mm a").format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fillColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Same chat background as the personal chat screen.
            Obx(() => chatThemeController.chatBackground()),
            Obx(() {
              final items = controller.messages;
              logs("ergerfsd ${items.last.toMap()}");
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: CustomText(
                      "You're all caught up. Broadcast and system "
                      "notifications from BlueEra will appear here.",
                      textAlign: TextAlign.center,
                      color: AppColors.secondaryTextColor,
                      fontSize: 14,
                      maxLines: 4,
                    ),
                  ),
                );
              }
              // `messages` is newest-first; reverse:true renders index 0 at the
              // bottom, so the newest notification sits at the bottom and the
              // list opens scrolled to it — just like a chat thread.
              return ListView.builder(
                reverse: true,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                itemCount: items.length,
                itemBuilder: (context, index) => _bubble(items[index]),
              );
            }),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              AppImageAssets.app_logo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.notifications, color: AppColors.primaryColor),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                "BlueEra",
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              CustomText(
                "Notifications",
                fontSize: 12,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A full-width broadcast card — the BlueEra conversation spans the whole
  /// screen (edge to edge, left and right) instead of the usual 85%-width
  /// received bubble, so long-form announcements read like the reference
  /// broadcast layout. Text is rendered a step larger than the standard chat
  /// font. Always renders the FULL notification text (no "Read more" cap).
  Widget _bubble(BlueEraNotificationItem item) {
    final hasTitle = item.title.trim().isNotEmpty &&
        item.title.trim().toLowerCase() != 'blueera';
    final body = item.body.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Obx(
        () => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: chatThemeController.receiveMessageBgColor.value,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos attached to the broadcast — rendered like a chat
              // image message, tappable to open the full-screen viewer.
              if (item.hasImages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildImages(item),
                ),
              if (hasTitle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: CustomText(
                    item.title.trim(),
                    fontSize: chatThemeController.chatFontSize.value + 4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                    maxLines: 4,
                  ),
                ),
              if (body.isNotEmpty)
                // Full text — no truncation / Read more.
                Text(
                  body,
                  style: chatThemeController.chatTextStyle(
                    fontSize: chatThemeController.chatFontSize.value + 3,
                    fontWeight: FontWeight.w500,
                    isMyMessage: false,
                  ),
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: CustomText(
                  _formatTime(item.timeMillis),
                  fontSize: 11.5,
                  color: chatThemeController.chatTimeColor.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether [url]'s file extension marks it as a video (vs an image), so the
  /// same broadcast media list can carry both and each renders correctly.
  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    // Strip any query string before checking the extension.
    final path = lower.split('?').first;
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.webm') ||
        path.endsWith('.mkv');
  }

  /// The visual for a single media URL — a video thumbnail (dark backdrop +
  /// play icon) when the extension is a video, otherwise the cached image.
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

  /// Renders the broadcast's media inside the bubble — a single full-width
  /// item, or a 2-column grid (max 4, with a "+N" overlay) for multiples —
  /// matching the chat image/video-message look. Each URL is shown as an
  /// image or a video thumbnail based on its extension. Tapping opens the
  /// shared full-screen viewer (which plays videos) with the body as caption.
  Widget _buildImages(BlueEraNotificationItem item) {
    final images = item.images;
    // Full-width bubble: screen width minus the outer margins (6*2) and the
    // bubble's inner horizontal padding (14*2).
    final width = MediaQuery.of(context).size.width - 40;

    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _openImages(item, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _mediaThumb(
            images.first,
            width: width,
            height: width * 0.72,
          ),
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
            onTap: () => _openImages(item, index),
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

  void _openImages(BlueEraNotificationItem item, int index) {
    final caption = item.body.trim().isNotEmpty ? item.body.trim() : null;
    Get.to(() => FullImagePreviewPage(
          images: item.images
              .map((u) => MessageMediaUrl(url: u))
              .toList(),
          initialIndex: index,
          captions: List<String?>.filled(item.images.length, caption),
        ));
  }
}

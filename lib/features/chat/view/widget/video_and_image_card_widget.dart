import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/widget/video_type_message_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_theme_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetListOfMessageData.dart';
import '../../auth/model/messageMediaUrl.dart';
import 'component_widgets.dart';
import 'custom_video_player.dart';
import 'chat_cached_image.dart';
import 'media_download_overlay.dart';
import 'media_message_full_view.dart';
class VideoAndImageCardWidget extends StatefulWidget {
  const VideoAndImageCardWidget({super.key, required this.name,required this.conversationId,required this.userId, this.profileImage, required this.isInitialMessage, this.contactNo, required this.message, required this.time, required this.isReceive, required this.theme, this.conversationName, this.conversationProfileImage,});
  final String conversationId;
  final String userId;
  final String? profileImage;
  final String? name;
  /// Conversation partner (chat person) name/image — used for bookmark
  /// grouping so a saved photo is filed under the OTHER person, not the sender.
  final String? conversationName;
  final String? conversationProfileImage;
  final bool isInitialMessage;
  final String? contactNo;
 final Messages message;
 final     String time;
 final bool isReceive;
 final     ThemeData theme;
  @override
  State<VideoAndImageCardWidget> createState() => _VideoAndImageCardWidgetState();
}

class _VideoAndImageCardWidgetState extends State<VideoAndImageCardWidget> {

  final chatThemeController = Get.find<ChatThemeController>();

  /// Tap recognizers for clickable caption links; disposed with the state.
  final List<TapGestureRecognizer> _linkRecognizers = [];

  @override
  void dispose() {
    for (final r in _linkRecognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return  buildImageMessage(widget.message,widget.time,widget.isReceive,widget.theme,widget.userId,widget.conversationId);
  }
  Widget buildImageMessage(Messages message, String time, bool isReceive,
      ThemeData theme, String userId, String conversation) {
    if (message.sendLoadingFile != null &&
        message.sendLoadingFile!.isNotEmpty) {
      return _buildUploadingSingleMedia(
          message.sendLoadingFile??[], time, isReceive, theme, userId,
          conversation,message);
    } else if (message.url?.length == 1) {

      return _buildSingleMedia(
          message.url?.first ?? MessageMediaUrl(), time, isReceive, theme,
          message);
    } else {
      return _buildMediaGrid(message.url ?? [], time, isReceive, theme,message);
    }
  }
  Widget _buildUploadingSingleMedia(List<File> path, String time, bool isReceiveMsg,
      ThemeData theme, String userId, String conversation, Messages message) {
    final chatViewController = Get.find<ChatViewController>();
    final int displayCount = path.length > 4 ? 4 : path.length;

    return Align(
      alignment: isReceiveMsg ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: 254,
        height: 252,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isReceiveMsg
              ? chatThemeController.receiveMessageBgColor.value
              : chatThemeController.myMessageBgColor.value,
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          children: [
            Expanded(
              child: (path.length == 1)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildUploadingMediaItem(
                        file: path[0],
                        chatViewController: chatViewController,
                      ),
                    )
                  : GridView.builder(
                      itemCount: displayCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisExtent: path.length == 2 ? 220 : 110,
                        crossAxisCount: 2,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1.5,
                      ),
                      itemBuilder: (context, index) {
                        final showOverlay = path.length > 4 && index == 3;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _buildUploadingMediaItem(
                                file: path[index],
                                chatViewController: chatViewController,
                              ),
                            ),
                            if (showOverlay)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${path.length - 4}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                timeAndReadInfoWidget(
                  message: message,
                  isMyMessage: message.myMessage ?? false,
                  time: time,
                  timeColor: (!isReceiveMsg) ? Colors.white : Colors.black54,
                  indicateColor: message.messageRead == 1 ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single uploading media item — shows thumbnail with blur overlay + progress.
  /// For videos: shows first frame thumbnail (via Image.file) with blur + progress.
  /// For images: shows the image with blur + progress.
  Widget _buildUploadingMediaItem({
    required File file,
    required ChatViewController chatViewController,
  }) {
    final isVideo = file.path.toLowerCase().endsWith('.mp4');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail: for images show the file directly, for videos show a dark placeholder
        if (isVideo)
          Container(color: Colors.black87)
        else
          Image.file(file, fit: BoxFit.cover),

        // Blur overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: isVideo ? 0.6 : 0.45),
          ),
        ),

        // Upload progress indicator
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Video icon for video files
              if (isVideo)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Icon(Icons.videocam_rounded, color: Colors.white70, size: 32),
                ),

              // Circular progress with percentage
              Obx(() {
                final progressStr = chatViewController.VideoUploadProgress.value;
                final progressVal = double.tryParse(progressStr) ?? 0;
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progressVal > 0 ? progressVal / 100 : null,
                        strokeWidth: 3,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      Center(
                        child: Text(
                          progressVal > 0 ? '${progressVal.toInt()}%' : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),
              const Text(
                'Sending...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens the full-screen viewer seeded with EVERY image/video in the
  /// conversation (chronological order) so the user can swipe between them,
  /// starting at [tappedUrl]. Each media carries its message's caption so the
  /// caption overlay follows as you swipe.
  void _openFullScreen(String tappedUrl) {
    FocusScope.of(context).unfocus();
    if (chatThemeController.isMessageSelectionActive.value) {
      chatThemeController.selectMoreMessage(
          widget.message.forwardId == null ? widget.message.id : widget.message.forwardId);
      return;
    }

    final messages = Get.find<ChatViewController>().getListOfMessageData ?? [];
    final List<MessageMediaUrl> allMedia = [];
    final List<String?> captions = [];
    final List<Messages?> mediaMessages = [];
    for (final m in messages) {
      if (m.messageType != 'image' && m.messageType != 'video') continue;
      final urls = m.url;
      if (urls == null || urls.isEmpty) continue;
      final caption =
          (m.message != null && m.message!.trim().isNotEmpty) ? m.message : null;
      for (final u in urls) {
        allMedia.add(u);
        captions.add(caption);
        mediaMessages.add(m);
      }
    }

    int startIndex = allMedia.indexWhere((e) => e.url == tappedUrl);

    // Fallback: if the aggregated list is empty or the tapped media wasn't
    // found (e.g. list not yet populated), show just this message's media.
    if (allMedia.isEmpty || startIndex < 0) {
      final own = widget.message.url ?? [];
      final ownCaption = (widget.message.message != null &&
              widget.message.message!.trim().isNotEmpty)
          ? widget.message.message
          : null;
      allMedia
        ..clear()
        ..addAll(own);
      captions
        ..clear()
        ..addAll(List.filled(own.length, ownCaption));
      mediaMessages
        ..clear()
        ..addAll(List.filled(own.length, widget.message));
      startIndex = own.indexWhere((e) => e.url == tappedUrl);
      if (startIndex < 0) startIndex = 0;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullImagePreviewPage(
          images: allMedia,
          initialIndex: startIndex,
          captions: captions,
          messages: mediaMessages,
          conversationId: widget.conversationId,
          // Prefer the conversation partner's identity (falls back to the
          // per-message name/image if the partner wasn't supplied).
          personName: widget.conversationName ?? widget.name,
          personImage: widget.conversationProfileImage ?? widget.profileImage,
        ),
      ),
    );
  }

  Widget _buildSingleMedia(MessageMediaUrl path, String time, bool isReceiveMsg,
      ThemeData theme, Messages message)
  {
    final isVideo = path.url?.toLowerCase().endsWith('.mp4');
    if (isVideo ?? false) {
      // Video: wrap with download overlay for received messages
      return GestureDetector(
        onTap: () => _openFullScreen(path.url ?? ''),
        child: MediaDownloadOverlay(
          url: path.url ?? '',
          messageType: 'video',
          fileName: path.name,
          width: 256,
          height: 280,
          isReceived: isReceiveMsg,
          openOnTap: false,
          child: ChatVideoMessage(
            message: message,
            userId: widget.userId.toString(),
            conversation: widget.conversationId.toString(),
            videoUrl: path,
            time: time,
            views: 0,
            likes: 0,
            comments: 0,
            isReceiveMsg: isReceiveMsg,
          ),
        ),
      );
    }

    // Image
    final imageWidget = ChatCachedImage(
        url: path.url ?? '',
        height: 250, width: 252, fit: BoxFit.cover);

    // A payment screenshot is flagged by the backend's top-level `is_payment`
    // (see image-is-payment-flutter-integration-guide.md); the legacy
    // metadata flag is kept for backward compatibility with older messages.
    final bool isPaymentShot = message.isPayment == true ||
        message.metadata?.isPaymentScreenshot == true;

    final bool hasCaption =
        message.message != null && message.message != '';

    final bubbleColor = isReceiveMsg
        ? chatThemeController.receiveMessageBgColor.value
        : chatThemeController.myMessageBgColor.value;
    // Caption text is always black (per design), with links rendered in blue
    // and made tappable to open.
    const textColor = Colors.black;
    const linkColor = Color(0xFF1976D2);

    final imageBubble = GestureDetector(
      onTap: () => _openFullScreen(path.url ?? ''),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: bubbleColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  MediaDownloadOverlay(
                    url: path.url ?? '',
                    messageType: 'image',
                    fileName: path.name,
                    width: 252,
                    height: 250,
                    isReceived: isReceiveMsg,
                    openOnTap: false,
                    child: imageWidget,
                  ),
                  if (!hasCaption)
                    Positioned(
                      bottom: 6,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(time,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
              // WhatsApp-style caption: media + text, with the time and
              // read-receipt tucked at the bottom-right of the caption.
              if (hasCaption)
                Container(
                  width: 252,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLinkifiedText(
                        message.message ?? '',
                        textColor: textColor,
                        linkColor: linkColor,
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: timeAndReadInfoWidget(
                          message: message,
                          isMyMessage: message.myMessage ?? false,
                          time: time,
                          timeColor: Colors.black54,
                          indicateColor:
                              message.messageRead == 1 ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Align(
      alignment: isReceiveMsg ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isReceiveMsg ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          imageBubble,
          if (isPaymentShot) _buildApprovalFooter(message, isReceiveMsg),
        ],
      ),
    );
  }

  Widget _buildLinkifiedText(
    String text, {
    required Color textColor,
    required Color linkColor,
  }) {
    final baseStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final urlRegex = RegExp(r'https?:\/\/[^\s]+');
    final matches = urlRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }
    // Dispose recognizers built in a previous frame before rebuilding them.
    for (final r in _linkRecognizers) {
      r.dispose();
    }
    _linkRecognizers.clear();
    final spans = <TextSpan>[];
    int cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      final url = m.group(0)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _openLink(url);
      _linkRecognizers.add(recognizer);
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
        recognizer: recognizer,
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return RichText(text: TextSpan(style: baseStyle, children: spans));
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

  /// Footer shown under a payment-screenshot image bubble.
  /// - Sender (buyer): a "Waiting for approval" / Approved / Rejected tag.
  /// - Receiver (shop owner): Approve / Reject buttons while pending, then the
  ///   resulting status tag.
  Widget _buildApprovalFooter(Messages message, bool isReceiveMsg) {
    // Backend lifecycle: 'pending' | 'success' | 'failed'.
    final status = message.paymentStatus ?? 'pending';

    // Only the receiver (owner) can confirm/reject, and only while pending.
    if (isReceiveMsg && status == 'pending') {
      return Container(
        width: 256,
        margin: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: _approvalActionButton(
                label: 'Reject',
                icon: Icons.close_rounded,
                color: AppColors.red00,
                filled: false,
                onTap: () => _handleApproval(message, 'failed'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _approvalActionButton(
                label: 'Approve',
                icon: Icons.check_rounded,
                color: AppColors.green1A,
                filled: true,
                onTap: () => _handleApproval(message, 'success'),
              ),
            ),
          ],
        ),
      );
    }

    return _buildStatusTag(status);
  }

  Widget _buildStatusTag(String status) {
    late final Color color;
    late final IconData icon;
    late final String label;
    switch (status) {
      case 'success':
        color = AppColors.green1A;
        icon = Icons.check_circle_rounded;
        label = 'Payment accepted';
        break;
      case 'failed':
        color = AppColors.red00;
        icon = Icons.cancel_rounded;
        label = 'Payment rejected';
        break;
      default:
        color = AppColors.orange;
        icon = Icons.hourglass_top_rounded;
        label = 'Waiting for approval';
    }
    return Container(
      width: 256,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          CustomText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _approvalActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
            CustomText(
              label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : color,
            ),
          ],
        ),
      ),
    );
  }

  /// Owner decision via PUT /chat/payment-status. [status] is the backend
  /// value: 'success' (approve) or 'failed' (reject). The optimistic local
  /// patch + `paymentStatusUpdate` socket re-render both sides.
  Future<void> _handleApproval(Messages message, String status) async {
    await Get.find<ChatViewController>()
        .updatePaymentStatus(messageId: message.id ?? '', status: status);
    if (mounted) setState(() {});
  }

  Widget _buildMediaGrid(List<MessageMediaUrl> paths, String time,
      bool isReceiveMsg, ThemeData theme,Messages message)
  {
    int displayCount = paths.length > 4 ? 4 : paths.length;
    return Center(
      child: Container(
        child: Align(
          alignment: isReceiveMsg ? Alignment.centerLeft : Alignment.centerRight,
          child: Column(
            crossAxisAlignment:
            isReceiveMsg ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Container(
                width: 254,
                height: 256,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isReceiveMsg
                      ? chatThemeController.receiveMessageBgColor.value
                      : chatThemeController.myMessageBgColor.value,
                ),
                padding: EdgeInsets.all(3),
                child: Column(
                  children: [
                    GridView.builder(
                      itemCount: displayCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisExtent: paths.length == 2 ? 220 : 110,
                        crossAxisCount: 2,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1.5,
                      ),
                      itemBuilder: (context, index) {
                        final isVideo =
                        paths[index].url?.toLowerCase().endsWith('.mp4');
                        final showOverlay = paths.length > 4 && index == 3;
                        return GestureDetector(
                          onTap: () => _openFullScreen(paths[index].url ?? ''),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: isVideo ?? false
                                    ? ChatCustomVideoPlayer(
                                  key: ValueKey('vp_${paths[index].url ?? ''}'),
                                  videoUrl: paths[index].url ?? '',
                                )
                                    : ChatCachedImage(
                                    url: paths[index].url ?? '',
                                    fit: BoxFit.cover),
                              ),
                              if (showOverlay)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${paths.length - 4}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        timeAndReadInfoWidget(message: message,isMyMessage: message.myMessage??false,time: time,timeColor: (!isReceiveMsg) ? Colors.white : Colors.black54,indicateColor:message.messageRead==1?Colors.blue:Colors.grey),
                        const SizedBox(
                          width: 11,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

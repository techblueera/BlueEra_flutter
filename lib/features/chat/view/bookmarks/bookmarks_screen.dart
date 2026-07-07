import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/cached_avatar_widget.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/bookmark_controller.dart';
import '../../auth/model/bookmarked_media.dart';
import '../../auth/model/messageMediaUrl.dart';
import '../widget/chat_cached_image.dart';
import '../widget/media_message_full_view.dart';

/// Level 1 — lists every person/conversation that has bookmarked media.
/// Tapping a person opens a gridview of just their saved photos.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BookmarkController.to;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(title: 'Bookmarks'),
      body: Obx(() {
        if (controller.bookmarks.isEmpty) {
          return _emptyState();
        }
        final entries = controller.groupedByConversation.entries.toList();
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(
              height: 1, thickness: 0.5, indent: 76, color: Color(0xFFEDEDED)),
          itemBuilder: (context, i) {
            final items = entries[i].value;
            return _personTile(context, entries[i].key, items);
          },
        );
      }),
    );
  }

  Widget _personTile(
      BuildContext context, String conversationId, List<BookmarkedMedia> items) {
    final first = items.first;
    final name = (first.personName?.trim().isNotEmpty ?? false)
        ? first.personName!
        : 'Chat';
    return InkWell(
      onTap: () => Get.to(() => BookmarkPersonMediaScreen(
            conversationId: conversationId,
            personName: name,
          )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Preview stack: avatar with a small photo peek behind it.
            CachedAvatarWidget(
              imageUrl: first.personImage,
              size: 46,
              borderRadius: 23,
              showProfileOnFullScreen: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    name,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    fontSize: 12.5,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_border_rounded,
              size: 64, color: Colors.black26),
          const SizedBox(height: 12),
          CustomText(
            'No bookmarks yet',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
          const SizedBox(height: 4),
          CustomText(
            'Tap the bookmark icon on any chat photo\nto save it here.',
            fontSize: 13,
            color: Colors.black38,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

/// Level 2 — a gridview of one person's bookmarked images. Reactive to
/// removals, so unbookmarking a photo drops it live (and pops when empty).
class BookmarkPersonMediaScreen extends StatelessWidget {
  final String conversationId;
  final String personName;

  const BookmarkPersonMediaScreen({
    super.key,
    required this.conversationId,
    required this.personName,
  });

  @override
  Widget build(BuildContext context) {
    final controller = BookmarkController.to;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(title: personName),
      body: Obx(() {
        final items = controller.bookmarks
            .where((b) => b.conversationId == conversationId)
            .toList();
        if (items.isEmpty) {
          return Center(
            child: CustomText(
              'No bookmarks for $personName',
              fontSize: 14,
              color: Colors.black45,
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) =>
              _mediaTile(context, controller, items, index),
        );
      }),
    );
  }

  Widget _mediaTile(
    BuildContext context,
    BookmarkController controller,
    List<BookmarkedMedia> items,
    int index,
  ) {
    final media = items[index];
    return GestureDetector(
      onTap: () => Get.to(() => FullImagePreviewPage(
            images: items
                .map((b) => MessageMediaUrl(url: b.url, name: b.name))
                .toList(),
            initialIndex: index,
            captions: items.map((b) => b.caption).toList(),
          )),
      onLongPress: () => _confirmRemove(context, controller, media),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.isVideo)
              Container(
                color: Colors.black87,
                alignment: Alignment.center,
                child: const Icon(Icons.play_circle_outline,
                    color: Colors.white, size: 30),
              )
            else
              ChatCachedImage(url: media.url, fit: BoxFit.cover),
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.bookmark, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    BookmarkController controller,
    BookmarkedMedia media,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const CustomText('Remove bookmark',
            fontSize: 17, fontWeight: FontWeight.bold),
        content: const CustomText(
          'Remove this photo from your bookmarks?',
          fontSize: 14,
          color: Colors.black87,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const CustomText('Cancel',
                color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () {
              controller.remove(media.url);
              Navigator.pop(ctx);
            },
            child: const CustomText('Remove',
                color: AppColors.red00, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

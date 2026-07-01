import 'dart:math' as math;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:BlueEra/features/common/home/view/widget/symbol_fullscreen_viewer.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// WhatsApp-status-style list of everyone who has an active symbol — the same
/// people shown with the multi-colour ring around their avatar in the chat
/// lists. An "Add Symbol" row sits on top; each user row below opens that
/// user's symbols in the fullscreen viewer. Backed by the shared
/// [SymbolFeedController.userGroups], so it stays in sync with the story row.
class SymbolChatListScreen extends StatelessWidget {
  const SymbolChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SymbolFeedController>()
        ? Get.find<SymbolFeedController>()
        : Get.put(SymbolFeedController());
    // Refresh so the list reflects any symbols posted/expired since the feed
    // was last fetched.
    controller.fetchSymbolFeed();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(title: AppStrings.symbols.tr),
      body: Obx(() {
        final groups = controller.userGroups
            .where((g) => g.symbols.isNotEmpty)
            .toList();

        return RefreshIndicator(
          onRefresh: () => controller.fetchSymbolFeed(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildAddSymbolTile(controller),
              const Divider(height: 1),
              if (groups.isEmpty && controller.isLoading.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
              else if (groups.isEmpty)
                _buildEmptyState()
              else
                for (int i = 0; i < groups.length; i++)
                  _buildSymbolUserTile(
                    context: context,
                    group: groups[i],
                    onTap: () => _openViewer(context, groups, i),
                  ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAddSymbolTile(SymbolFeedController controller) {
    return InkWell(
      onTap: () async {
        await Get.to(() => AddChatSymbolScreen());
        controller.fetchSymbolFeed();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.addSymbolMenu.tr,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 2),
                CustomText(
                  "Share a photo, video or text symbol",
                  fontSize: 12.5,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolUserTile({
    required BuildContext context,
    required SymbolUserGroup group,
    required VoidCallback onTap,
  }) {
    final bool isSelf = group.user?.id == userId;
    final String name =
        isSelf ? "My Symbol" : (group.user?.name ?? AppStrings.userFallback.tr);
    final String? profileImage = group.user?.profileImage;
    final int count = group.symbols.length;
    final List<bool> seenFlags =
        group.symbols.map((s) => s.hasSeen == true).toList(growable: false);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CustomPaint(
                painter: _SymbolRingPainter(seenFlags: seenFlags),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: (profileImage != null && profileImage.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: profileImage,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const _AvatarFallback(),
                            errorWidget: (_, __, ___) => const _AvatarFallback(),
                          )
                        : const _AvatarFallback(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    name,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    count > 1 ? "$count symbols" : "$count symbol",
                    fontSize: 12.5,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.web_stories_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            CustomText(
              AppStrings.noSymbolsYet.tr,
              fontSize: 15,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(
      BuildContext context, List<SymbolUserGroup> groups, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => SymbolFullscreenViewer(
          groups: groups,
          initialGroupIndex: index,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.person, color: Colors.grey[400], size: 24),
    );
  }
}

/// Segmented ring around the avatar — one arc per symbol, green when unseen and
/// light grey once seen (mirrors the story-row ring so the two surfaces read
/// the same).
class _SymbolRingPainter extends CustomPainter {
  final List<bool> seenFlags;

  static const Color _unseenColor = AppColors.symbolBorderGreen;
  static final Color _seenColor = Colors.grey.shade400;
  static const double _strokeWidth = 2.4;

  const _SymbolRingPainter({required this.seenFlags});

  @override
  void paint(Canvas canvas, Size size) {
    final int count = seenFlags.length;
    if (count == 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (math.min(size.width, size.height) - _strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    if (count == 1) {
      paint.color = seenFlags.first ? _seenColor : _unseenColor;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final double gapDeg = count > 12 ? 2.0 : (count > 6 ? 3.0 : 4.0);
    final double gapRad = gapDeg * math.pi / 180.0;
    final double totalGap = gapRad * count;
    final double segmentSweep = (2 * math.pi - totalGap) / count;

    double startAngle = -math.pi / 2 + gapRad / 2;
    for (int i = 0; i < count; i++) {
      paint.color = seenFlags[i] ? _seenColor : _unseenColor;
      canvas.drawArc(rect, startAngle, segmentSweep, false, paint);
      startAngle += segmentSweep + gapRad;
    }
  }

  @override
  bool shouldRepaint(covariant _SymbolRingPainter old) {
    if (old.seenFlags.length != seenFlags.length) return true;
    for (int i = 0; i < seenFlags.length; i++) {
      if (old.seenFlags[i] != seenFlags[i]) return true;
    }
    return false;
  }
}
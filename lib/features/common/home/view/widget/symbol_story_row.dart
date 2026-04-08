import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:BlueEra/features/common/home/view/widget/symbol_fullscreen_viewer.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SymbolStoryRow extends StatelessWidget {
  const SymbolStoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SymbolFeedController>()
        ? Get.find<SymbolFeedController>()
        : Get.put(SymbolFeedController());

    return Obx(() {
      if (controller.isLoading.value && controller.symbols.isEmpty) {
        return const SizedBox.shrink();
      }
      if (controller.symbols.isEmpty) return const SizedBox.shrink();

      /// Collect embeddedUrl stories for link preview
      final linkStories = controller.symbols
          .where((s) =>
              s.type == 'embeddedUrl' &&
              s.content != null &&
              s.content!.isNotEmpty)
          .toList();

      return Column(
        children: [
          /// Story circles row
          Container(
            margin: EdgeInsets.only(top: 10, right: 10, left: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: controller.symbols.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _SymbolStoryItem(
                  symbol: controller.symbols[index],
                  onTap: () =>
                      _openFullscreen(context, controller.symbols, index),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  void _openFullscreen(
      BuildContext context, List<SymbolFeedItem> symbols, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => SymbolFullscreenViewer(
          symbols: symbols,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

/// Link preview card shown outside the story row
class _SymbolStoryItem extends StatelessWidget {
  final SymbolFeedItem symbol;
  final VoidCallback onTap;

  const _SymbolStoryItem({required this.symbol, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasSeen = symbol.hasSeen ?? false;
    final String? profileImage = symbol.user?.profileImage;
    final String name = symbol.user?.name ?? 'User';
    final String displayName =
        name.length > 10 ? '${name.substring(0, 10)}.' : name;
    final bool isLink = symbol.type == 'embeddedUrl';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      startAngle: 0.0,
                      endAngle: 6.28319,
                      colors: [
                        AppColors.symbolBorderRed,
                        AppColors.symbolBorderBlue,
                        AppColors.symbolBorderYellow,
                        AppColors.symbolBorderGreen,
                        AppColors.symbolBorderRed,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: (profileImage != null && profileImage.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: profileImage,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.person,
                                    color: Colors.grey[400], size: 28),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.person,
                                    color: Colors.grey[400], size: 28),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.person,
                                  color: Colors.grey[400], size: 28),
                            ),
                    ),
                  ),
                ),

                /// Link badge on story circle
                if (isLink)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child:
                          const Icon(Icons.link, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            CustomText(
              displayName,
              fontSize: SizeConfig.extraSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              color: AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

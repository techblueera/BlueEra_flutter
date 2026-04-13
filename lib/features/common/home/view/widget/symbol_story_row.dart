import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:BlueEra/features/common/home/view/widget/symbol_fullscreen_viewer.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SymbolStoryRow extends StatelessWidget {
  const SymbolStoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SymbolFeedController>()
        ? Get.find<SymbolFeedController>()
        : Get.put(SymbolFeedController());

    return Obx(() {
      if (controller.isLoading.value && controller.userGroups.isEmpty) {
        return const SizedBox.shrink();
      }
      if (controller.userGroups.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 10, right: 10, left: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        height: 106,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: controller.userGroups.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final group = controller.userGroups[index];
            return _SymbolUserCircle(
              group: group,
              onTap: () => _openFullscreen(
                  context, controller.userGroups, index),
            );
          },
        ),
      );
    });
  }

  void _openFullscreen(
      BuildContext context, List<SymbolUserGroup> groups, int initialGroupIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => SymbolFullscreenViewer(
          groups: groups,
          initialGroupIndex: initialGroupIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _SymbolUserCircle extends StatelessWidget {
  final SymbolUserGroup group;
  final VoidCallback onTap;

  const _SymbolUserCircle({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasUnseen = group.hasUnseen;
    final String? profileImage = group.user?.profileImage;
    final String name = group.user?.name ?? AppStrings.userFallback.tr;
    final String displayName =
        name.length > 10 ? '${name.substring(0, 10)}.' : name;
    final int symbolCount = group.symbols.length;

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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasUnseen
                        ? const SweepGradient(
                            startAngle: 0.0,
                            endAngle: 6.28319,
                            colors: [
                              AppColors.symbolBorderRed,
                              AppColors.symbolBorderBlue,
                              AppColors.symbolBorderYellow,
                              AppColors.symbolBorderGreen,
                              AppColors.symbolBorderRed,
                            ],
                          )
                        : null,
                    border: hasUnseen
                        ? null
                        : Border.all(color: Colors.grey.shade300, width: 2),
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

                /// Symbol count badge
                if (symbolCount > 1)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$symbolCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
              color: hasUnseen
                  ? AppColors.mainTextColor
                  : AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

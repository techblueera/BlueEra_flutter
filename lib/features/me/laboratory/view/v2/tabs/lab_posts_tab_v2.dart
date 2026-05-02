import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Posts tab — embeds the global FeedScreen filtered to the current
/// user and exposes the same Create-Post dialog used elsewhere in the
/// "me" stack (Lekha / Symbol / Poll / Job for business accounts).
class LabPostsTabV2 extends StatelessWidget {
  const LabPostsTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showCreatePostDialog(context),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: CustomText(
                'Create Post',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size12),
        FeedScreen(
          key: const ValueKey('lab_v2_my_posts'),
          postFilterType: PostType.myPosts,
          id: userId,
          isInParentScroll: true,
          horizontalPaddingChannel: SizeConfig.size12,
        ),
      ],
    );
  }

  Future<void> _showCreatePostDialog(BuildContext context) async {
    final isBusiness = isBusinessUser();
    final entries = <_PostMenuEntry>[
      _PostMenuEntry(
        type: PostCreationMenu.message,
        label: AppStrings.lekha.tr,
        iconAsset: AppIconAssets.message_post,
      ),
      _PostMenuEntry(
        type: PostCreationMenu.symbol,
        label: AppStrings.symbol.tr,
        iconAsset: 'assets/icons/add_symbol_color.png',
      ),
      _PostMenuEntry(
        type: PostCreationMenu.poll,
        label: AppStrings.poll.tr,
        iconAsset: AppIconAssets.qa_ask_questionOutlinedIcon,
      ),
      if (isBusiness)
        _PostMenuEntry(
          type: PostCreationMenu.jobPost,
          label: AppStrings.jobPost.tr,
          iconAsset: AppIconAssets.uilSuitcaseOutlinedIcon,
        ),
    ];

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Create Post',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size12),
              for (var i = 0; i < entries.length; i++) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _handlePostMenu(entries[i].type);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.size10,
                      horizontal: SizeConfig.size4,
                    ),
                    child: Row(
                      children: [
                        LocalAssets(
                          imagePath: entries[i].iconAsset,
                          height: 24,
                          width: 24,
                        ),
                        SizedBox(width: SizeConfig.size12),
                        CustomText(
                          entries[i].label,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
                if (i != entries.length - 1)
                  Divider(height: 1, color: Colors.grey.shade200),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handlePostMenu(PostCreationMenu type) {
    switch (type) {
      case PostCreationMenu.message:
      case PostCreationMenu.poll:
        postVia(Get.context!, type);
        break;
      case PostCreationMenu.jobPost:
        Get.toNamed(RouteHelper.getCreateJobPostScreenRoute(), arguments: {
          'isEditMode': false,
          'jobId': '',
          'createJobVia': 'laboratory',
        });
        break;
      case PostCreationMenu.symbol:
        Get.to(() => AddChatSymbolScreen());
        break;
    }
  }
}

class _PostMenuEntry {
  final PostCreationMenu type;
  final String label;
  final String iconAsset;

  const _PostMenuEntry({
    required this.type,
    required this.label,
    required this.iconAsset,
  });
}

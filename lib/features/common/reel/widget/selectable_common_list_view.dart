import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/controller/tag_people_controller.dart';
import 'package:BlueEra/features/common/reel/models/get_all_users.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_check_box.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectableCommonListView extends StatelessWidget {
  final ScrollController scrollController;
  final List<UsersData> allItems;
  final Set<String> selectedIndexes; // IDs only
  final Function(String userId, String username, bool isSelected) onSelectionChanged;
  final bool showSubTitle;
  final bool isScrollable;

  const SelectableCommonListView({
    super.key,
    required this.scrollController,
    required this.allItems,
    required this.selectedIndexes,
    required this.onSelectionChanged,
    this.showSubTitle = false,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final itemCount = allItems.length + (Get.find<TagPeopleController>().isLoadingMore.value ? 1 : 0);

      return ListView.separated(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: itemCount,
        shrinkWrap: true,
        physics: !isScrollable
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          /// ✅ Show loader at the end
          if (index == allItems.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            );
          }

          final item = allItems[index];
          final isIndividual =
              item.accountType.toUpperCase() == AppConstants.individual;

          final profileImage = isIndividual ? item.profileImage : item.logo;
          final userId = item.id;

          /// ✅ Name logic
          final name = isIndividual
              ? (item.username?.isNotEmpty == true
              ? "${item.username} (${item.name ?? ''})"
              : item.name ?? '')
              : (item.businessName ?? '');

          /// ✅ Subtitle logic
          final subtitle = isIndividual
              ? (item.designation ?? '')
              : (item.categoryOfBusiness?.name ?? '');

          final isSelected = selectedIndexes.contains(userId);

          return ListTile(
            leading: CachedAvatarWidget(
              imageUrl: profileImage,
              size: SizeConfig.size42,
              borderRadius: SizeConfig.size25,
            ),
            title: CustomText(
              name,
              fontSize: SizeConfig.medium,
              color: AppColors.mainTextColor,
            ),
            subtitle: showSubTitle && subtitle.isNotEmpty
                ? CustomText(
              subtitle,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            )
                : null,
            trailing: CustomCheckBox(
              isChecked: isSelected,
              onChanged: () => onSelectionChanged(userId, name, isSelected),
              size: SizeConfig.size25,
              activeColor: AppColors.primaryColor,
              borderColor: AppColors.secondaryTextColor,
            ),
          );
        },
        separatorBuilder: (context, index) {
          // ✅ Avoid adding divider after the loader
          if (index >= allItems.length - 1) return SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
            child: CommonHorizontalDivider(),
          );
        },
      );
    });
  }
}

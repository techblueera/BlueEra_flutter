import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/models/get_all_users.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_check_box.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class SelectableCommonListView extends StatelessWidget {
  final List<UsersData> allItems;
  final Set<String> selectedIndexes; // IDs only
  final Function(String userId, String username, bool isSelected) onSelectionChanged;
  final bool showSubTitle;
  final bool isScrollable;

  const SelectableCommonListView({
    super.key,
    required this.allItems,
    required this.selectedIndexes,
    required this.onSelectionChanged,
    this.showSubTitle = false,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: allItems.length,
      shrinkWrap: true,
      physics: !isScrollable
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final item = allItems[index];
        final profileImage = item.accountType.toUpperCase() == AppConstants.individual
            ? item.profileImage
            : item.logo;
        final userId = item.id;
        final name = item.accountType.toUpperCase() == AppConstants.individual
            ? item.name
            : item.businessName; /// should be business owner username/name here
        final designation = item.accountType.toUpperCase() == AppConstants.individual
            ? item.designation  /// should be designation here
            : item.categoryOfBusiness?.name??'';
        final isSelected = selectedIndexes.contains(userId);

        return ListTile(
          leading: CachedAvatarWidget(
            imageUrl: profileImage,
            size: SizeConfig.size42,
          ),
          title: CustomText(
             name,
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
          ),
          subtitle: showSubTitle
              ? CustomText(
            designation,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          )
              : null,
          trailing: CustomCheckBox(
            isChecked: isSelected,
            onChanged: () => onSelectionChanged(userId, name??'', isSelected),
            size: SizeConfig.size25,
            activeColor: AppColors.primaryColor,
            borderColor: AppColors.secondaryTextColor,
          ),
        );
      },
      separatorBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
        child: CommonHorizontalDivider(),
      ),
    );
  }
}

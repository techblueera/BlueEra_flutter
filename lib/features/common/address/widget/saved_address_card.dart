import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/address/model/user_address_model.dart';
import 'package:BlueEra/features/common/address/model/address_ui_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// One saved address in the list: selectable, with edit + delete actions.
class SavedAddressCard extends StatelessWidget {
  const SavedAddressCard({
    super.key,
    required this.address,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final UserAddress address;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        padding: EdgeInsets.all(SizeConfig.paddingS),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.whiteDB,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: SizeConfig.size2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: SizeConfig.size20,
                color: isSelected ? AppColors.primaryColor : AppColors.greyAF,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tag(
                    label: address.typeLabel,
                    bgColor: AppColors.skyBlueFF,
                    textColor: AppColors.primaryColor,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  CustomText(
                    address.formattedAddress,
                    fontSize: SizeConfig.small,
                    color: AppColors.black28,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Row(
                    children: [
                      _Action(
                        icon: Icons.edit_outlined,
                        label: AppStrings.edit,
                        color: AppColors.primaryColor,
                        onTap: onEdit,
                      ),
                      SizedBox(width: SizeConfig.size20),
                      _Action(
                        icon: Icons.delete_outline,
                        label: AppStrings.delete,
                        color: AppColors.red00,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SizeConfig.size12),
      ),
      child: CustomText(
        label,
        fontSize: SizeConfig.extraSmall,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: SizeConfig.size18, color: color),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            label,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }
}

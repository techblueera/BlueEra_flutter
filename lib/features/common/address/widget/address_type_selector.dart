import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/address/model/address_ui_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Home / Office / Other chips for the address form.
///
/// "Other" is the only option that carries a label of its own — the caller
/// renders its input field, this widget just reports the selection.
class AddressTypeSelector extends StatelessWidget {
  const AddressTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final String selectedType;
  final ValueChanged<String> onTypeSelected;

  static const Map<String, IconData> _icons = {
    AddressTypeOption.home: Icons.home_outlined,
    AddressTypeOption.office: Icons.business_center_outlined,
    AddressTypeOption.other: Icons.location_on_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SizeConfig.size10,
      runSpacing: SizeConfig.size10,
      children: AddressTypeOption.selectable.map((type) {
        final isSelected = selectedType == type;
        return InkWell(
          borderRadius: BorderRadius.circular(SizeConfig.size20),
          onTap: () => onTypeSelected(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.paddingS,
              vertical: SizeConfig.size8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.skyBlueFF : AppColors.white,
              borderRadius: BorderRadius.circular(SizeConfig.size20),
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : AppColors.borderGray,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icons[type],
                  size: SizeConfig.size18,
                  color: isSelected ? AppColors.primaryColor : AppColors.grey7E,
                ),
                SizedBox(width: SizeConfig.size6),
                CustomText(
                  type,
                  fontSize: SizeConfig.small,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryColor : AppColors.grey7E,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

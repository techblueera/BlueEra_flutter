import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/widgets/color_picker_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class ColorSelectionTile extends StatelessWidget {
  final AddProductViaAiController controller;
  final Function(Color, String) onSelectedColor;

  const ColorSelectionTile({Key? key, required this.controller, required this.onSelectedColor}) : super(key: key);

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ColorPickerWidget(
        onColorSelected: (color, colorName) {
          onSelectedColor.call(color, colorName);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorPicker(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [AppShadows.textFieldShadow],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.colorTemplateIcon),
            SizedBox(width: SizeConfig.size8),
            CustomText(
              'Select Color',
              color: AppColors.grey9A,
              fontWeight: FontWeight.w400,
              fontSize: SizeConfig.large,
            ),
            Spacer(),
            LocalAssets(
              imagePath: AppIconAssets.addBlueIcon,
              imgColor: AppColors.grey9A,
            ),
          ],
        ),
      ),
    );
  }
}

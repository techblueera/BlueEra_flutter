import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';

class AddToCartButton extends StatelessWidget {
  final bool isAdded;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final double? width;

  const AddToCartButton({
    super.key,
    required this.isAdded,
    required this.onAdd,
    required this.onRemove,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBtn(
      height: SizeConfig.size36,
      width: width ?? SizeConfig.size70,
      onTap: isAdded ? onRemove : onAdd,
      title: isAdded ? 'Added' : 'Add',
      textColor: isAdded ? AppColors.white : AppColors.primaryColor,
      bgColor: isAdded ? AppColors.primaryColor : AppColors.white,
      radius: 6.0,
      borderColor: AppColors.primaryColor,
    );
  }
}
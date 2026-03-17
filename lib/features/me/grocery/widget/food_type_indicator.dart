import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class FoodTypeIndicator extends StatelessWidget {
  final bool isVegetarian;
  final double size;

  const FoodTypeIndicator({
    super.key,
    required this.isVegetarian,
    this.size = 7.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor = isVegetarian
        ? AppColors.green00
        : AppColors.red00;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: indicatorColor, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      padding: const EdgeInsets.all(3.5),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size),
          color: indicatorColor,
        ),
      ),
    );
  }
}
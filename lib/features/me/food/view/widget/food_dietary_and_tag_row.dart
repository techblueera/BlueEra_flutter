import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/me/food/view/widget/food_tag_widget.dart'; // Adjust path
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class FoodDietaryAndTagRow extends StatelessWidget {
  final String? dietaryType;
  final List<String>? cookingMethods;

  const FoodDietaryAndTagRow({
    super.key,
    this.dietaryType,
    this.cookingMethods,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the color for the dietary icon
    final bool isNonVeg = dietaryType?.toLowerCase() == "non-veg";
    final Color dietaryColor = isNonVeg ? AppColors.red00 : const Color(0xff008000);

    // Join the tags into a single string
    final String tagLabel = (cookingMethods ?? []).join(', ');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dietary Icon (Veg/Non-Veg)
        LocalAssets(
          imagePath: AppIconAssets.food_category,
          imgColor: dietaryColor,
        ),

        const SizedBox(width: 5),

        // Cooking Method Tags
        if (tagLabel.isNotEmpty)
          Flexible(
            child: FoodTagWidget(
              label: tagLabel,
            ),
          ),
      ],
    );
  }
}
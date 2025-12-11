import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_image_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class OthersTab extends StatefulWidget {
  const OthersTab({super.key});

  @override
  State<OthersTab> createState() => _OthersTabState();
}

class _OthersTabState extends State<OthersTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------
        // ICE CREAM
        // ---------------------------------------------------------
        _sectionWidget(
          "Ice Cream",
          icons: [
            _iconItem(AppIconCategoryAssets.vanilla, "Vanilla"),
            _iconItem(AppIconCategoryAssets.chocolate, "Chocolate"),
            _iconItem(AppIconCategoryAssets.strawberry, "Strawberry"),
            _iconItem(AppIconCategoryAssets.butterscotch, "Butterscotch"),
            _iconItem(AppIconCategoryAssets.blackCurrant, "Black Currant"),
            _iconItem(AppIconCategoryAssets.mango, "Mango"),
            _iconItem(AppIconCategoryAssets.coffee, "Coffee"),
            _iconItem(AppIconCategoryAssets.nutsCaramel, "Nuts & Caramel"),
          ],
          context: context,
        ),

        // ---------------------------------------------------------
        // STREET FOOD
        // ---------------------------------------------------------
        _sectionWidget(
          "Street Food",
          icons: [
            _iconItem(AppIconCategoryAssets.samosa, "Samosa"),
            _iconItem(AppIconCategoryAssets.kachori, "Kachori"),
            _iconItem(AppIconCategoryAssets.alooChop, "Aloo Chop"),
            _iconItem(AppIconCategoryAssets.breadPakora, "Bread Pakora"),
            _iconItem(AppIconCategoryAssets.paneerPakora, "Paneer Pakora"),
            _iconItem(AppIconCategoryAssets.batataVada, "Batata Vada"),
            _iconItem(AppIconCategoryAssets.vegCutlet, "Veg Cutlet"),
            _iconItem(AppIconCategoryAssets.dalVada, "Dal Vada"),
          ],
          context: context,
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  Widget _sectionWidget(
      String title, {
        required List<Widget> icons,
        required BuildContext context,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              CustomText(
                title,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: icons,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  Widget _iconItem(String img, String label) {
    return SizedBox(
      width: SizeConfig.size80,
      child: Column(
        children: [
          Container(
            height: SizeConfig.size50,
            width: SizeConfig.size50,
            padding: EdgeInsets.all(SizeConfig.size6),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: LocalAssets(imagePath: img),
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            label,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

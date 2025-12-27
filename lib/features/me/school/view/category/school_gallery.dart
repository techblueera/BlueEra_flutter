import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../medical/view/widget/otc_items.dart';
class SchoolGallery extends StatefulWidget {
  const SchoolGallery({super.key});

  @override
  State<SchoolGallery> createState() => _SchoolGalleryState();
}
class _SchoolGalleryState extends State<SchoolGallery> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Gallery",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          Expanded(
              child: CategoryListView()),
          SizedBox(height: SizeConfig.size14),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {

                },
                icon: const Icon(Icons.add_circle_outline, size: 20,color: AppColors.primaryColor),
                label: CustomText(
                    "Add More Course",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size18),
        ],
      ),
    );
  }
}

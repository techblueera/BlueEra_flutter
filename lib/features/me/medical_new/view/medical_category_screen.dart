import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/string_utils.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_subcategory_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/common_back_app_bar.dart';

class MedicalCategoryScreen extends StatefulWidget {
  const MedicalCategoryScreen({super.key});

  @override
  State<MedicalCategoryScreen> createState() => _MedicalCategoryScreenState();
}

class _MedicalCategoryScreenState extends State<MedicalCategoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final _medicalController = getOrPut(() => MedicalController());
  final List<Color> cardColors = const [
    Color(0x1A0085FE),
    Color(0xFFFAF0E7),
    Color(0xFFD8F8DB),
    Color(0xFFF8DCDE),
    Color(0x1AFABC00),
    Color(0x1A0085FE),
  ];

  @override
  void initState() {
    _medicalController.fetchGroceryNestedCategory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.whiteF3,
        appBar: CommonBackAppBar(
            title: 'Add Medical Products',
           ),
        body: SafeArea(
            child: Obx(() => _medicalController
                    .medicalNestedCategoryLoading.value
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount:
                        _medicalController.medicalNestedCategoryList.length,
                    padding: EdgeInsets.only(
                      left: SizeConfig.size8,
                      right: SizeConfig.size8,
                      top: SizeConfig.size15,
                      bottom: SizeConfig.size30,
                    ),
                    itemBuilder: (context, index) {
                      var item1 = _medicalController.medicalNestedCategoryList[index];
                      List<MedicalNestedCategoryModel> level2Category = item1.children ?? [];
                      final Color boxColor = cardColors[index % cardColors.length];

                      return Padding(
                        padding: EdgeInsets.only(bottom: SizeConfig.size10),
                        child: CustomFormCard(
                          color: boxColor,
                          padding: EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                item1.name,
                                color:AppColors.mainTextColor,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.large,
                              ),

                              SizedBox(height: SizeConfig.paddingXSL),

                              MasonryGridView.count(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                primary: false,
                                crossAxisCount: 3,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                padding: EdgeInsets.zero,
                                itemCount: level2Category.length,
                                itemBuilder: (context, index) {
                                  var item2 = level2Category[index];
                                  return _buildCategoryItem(
                                    medicalNestedCategory: item2,
                                    onTap: (c) {
                                      List<MedicalNestedCategoryModel> level3Category = item2.children ?? [];

                                      Get.to(() => MedicalSubCategoryScreen(
                                        arrLevel3Category: level3Category,
                                      ));
                                    },
                                  );

                                },
                              ),


                            ],
                          ),
                        ),
                      );
                    },
                  ))

            ));
  }

  Widget _buildCategoryItem({
    required MedicalNestedCategoryModel? medicalNestedCategory,
    required Function(MedicalNestedCategoryModel item)? onTap,
  }) {
    return InkWell(
      onTap: () {
        if (medicalNestedCategory!=null && onTap != null) onTap(medicalNestedCategory);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: AppColors.greyE5,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: medicalNestedCategory?.image ?? '',
              height: SizeConfig.size60,
              width: SizeConfig.size60,
              fit: BoxFit.contain,
              placeholder: (context, url) => ClipRRect(
                borderRadius: BorderRadius.circular(SizeConfig.size40),
                child: LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    height: SizeConfig.size80,
                    width: SizeConfig.size80,
                ),
              ),
              errorWidget: (context, url, error) =>
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.size40),
                    child: LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        height: SizeConfig.size80,
                        width: SizeConfig.size80,
                    ),
                  ),
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            SizedBox(
              height: 30,
              child: CustomText(
                formatToTwoLines(medicalNestedCategory?.name),
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }


}

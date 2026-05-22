import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/medical_product_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMedicalScreen extends StatefulWidget {
  const AddMedicalScreen({super.key});

  @override
  State<AddMedicalScreen> createState() => _AddMedicalScreenState();
}

class _AddMedicalScreenState extends State<AddMedicalScreen> {
  final controller = getOrPut(() => MedicalController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(),
      bottomNavigationBar: Material(
        elevation: 8.0,
        child: Container(
          color: AppColors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
            child: SafeArea(
              child: CustomBtn(
                onTap: () {
                  Get.toNamed(RouteHelper.getAddMedicalVariantScreenRoute());
                },
                isValidate: true,
                radius: SizeConfig.size8,
                title: '${AppStrings.medicalPostProductsPrefix.tr} ${controller.selectedMedicalProducts.length} ${AppStrings.medicalPostProductsSuffix.tr}',
                // isLoading: authController.isAddBusinessUserLoading.value
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size20,
        ),
        child: Obx(() => GridView.builder(
              itemCount: controller.selectedMedicalProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (_, i) =>
                  medicalCard(controller.selectedMedicalProducts[i], i),
            )),
      ),
    );
  }

  Widget medicalCard(MedicalProductData p, int index) {
    final price = controller.getPriceDetails(p.variants?.firstOrNull?.pricing);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: SizedBox(
                  height: SizeConfig.size150,
                  width: double.infinity,
                  child: (p.images!=null && p.images!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: p.images!.first.url??'',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  )
                      : LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                  top: SizeConfig.size2,
                  right: SizeConfig.size2,
                  child: _groceryPopUpMenu(index))
            ],
          ),
          Expanded(
            child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 9.0, vertical: SizeConfig.size6),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${p.name}",
                  fontSize: SizeConfig.small,
                  maxLines: 1,
                  color: AppColors.mainTextColor,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2)),
                      padding: EdgeInsets.all(3.5),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(width: 0.5, color: AppColors.greyE5)),
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                      child: CustomText(
                        (p.variants?.firstOrNull?.weight != null || p.variants?.firstOrNull?.unit != null)
                            ? '${p.variants?.firstOrNull?.weight ?? '-'} ${p.variants?.firstOrNull?.unit ?? ''}'
                            : AppStrings.medicalWeightNotSet.tr,
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          "${AppStrings.price.tr}: ",
                          fontSize: 10,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(width: SizeConfig.size3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            "${price.sellingRange}",
                            fontSize: 10,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          "${AppStrings.mrp.tr}: ",
                          fontSize: 10,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(width: SizeConfig.size3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            "${price.mrpRange}",
                            fontSize: 10,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomText(
                          "${AppStrings.discount.tr}: ",
                          fontSize: 10,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(width: SizeConfig.size3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            "${price.discountRange}",
                            fontSize: 10,
                            color: AppColors.green00,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _groceryPopUpMenu(int i) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(-6, 36),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        if (value == AppConstants.EDIT) {
          Get.back(result: true);
        } else if (value == AppConstants.REMOVE) {
          controller.selectedMedicalProducts.removeAt(i);
          if (controller.selectedMedicalProducts.length == 0) {
            Get.back(result: true);
          }
        }
      },
      icon: Container(
        padding: EdgeInsets.all(6),
        decoration:
            BoxDecoration(color: AppColors.blackMite, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(
          Icons.more_vert,
          size: SizeConfig.size12,
          color: AppColors.white,
        ),
      ),
      itemBuilder: (context) => PopupMenuBuilders.medicalPopUpMenuItems(),
    );
  }

}

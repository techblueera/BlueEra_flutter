import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/model/my_medical_super_category_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class MyMedicalSuperCategoryScreen extends StatefulWidget {
  const MyMedicalSuperCategoryScreen({super.key});

  @override
  State<MyMedicalSuperCategoryScreen> createState() =>
      _MyMedicalSuperCategoryScreenState();
}

class _MyMedicalSuperCategoryScreenState
    extends State<MyMedicalSuperCategoryScreen> {
  final controller = getOrPut(() => MedicalController());

  @override
  void initState() {
    controller.fetchMyMedicalCategory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.medicalMyProductsTitle.tr),
      body: Obx(() {
        if (controller.myMedicalCategoryLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final categoryList =
            List<MyMedicalSuperCategoryModel>.from(controller.myMedicalCategoryList);

        if (categoryList.isEmpty) {
          return Center(
            child: EmptyStateWidget(
              message: AppStrings.medicalHaveNotPostedProducts.tr,
              actionText: AppStrings.medicalAddProductsNow.tr,
              actionCallback: () =>
                  Get.toNamed(RouteHelper.getMedicalCategoryScreenRoute()),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.fetchMyMedicalCategory(),
          child: GridView.builder(
            padding: EdgeInsets.all(SizeConfig.size12),
            itemCount: categoryList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: SizeConfig.size12,
              mainAxisSpacing: SizeConfig.size12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final item = categoryList[index];
              return _categoryCard(item);
            },
          ),
        );
      }),
    );
  }

  Widget _categoryCard(MyMedicalSuperCategoryModel item) {
    final hasImage = item.image != null && item.image!.isNotEmpty;
    final isNetwork = hasImage && isNetworkImage(item.image!);
    final isSvg = hasImage && item.image!.toLowerCase().endsWith('.svg');

    return InkWell(
      onTap: () {
        Get.toNamed(
          RouteHelper.getMyMedicalProductsScreenRoute(),
          arguments: {
            ApiKeys.argCategoryId: item.sId,
            ApiKeys.argCategoryName: item.name,
          },
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: _buildCategoryImage(
                    hasImage: hasImage,
                    isNetwork: isNetwork,
                    isSvg: isSvg,
                    imagePath: item.image ?? '',
                  ),
                ),
              ),
            ),

            // Name + action section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size10, vertical: SizeConfig.size8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      item.name ?? '',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: AppColors.primaryColor),
                          SizedBox(width: 4),
                          CustomText(
                            AppStrings.medicalViewProducts,
                            fontSize: 11,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage({
    required bool hasImage,
    required bool isNetwork,
    required bool isSvg,
    required String imagePath,
  }) {
    const double size = 56;

    if (!hasImage) {
      return LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        height: size,
        width: size,
        boxFix: BoxFit.contain,
      );
    }

    if (isNetwork && isSvg) {
      return SvgPicture.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            SizedBox(width: size, height: size, child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size, color: Colors.grey),
      );
    }

    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) =>
            SizedBox(width: size, height: size, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        errorWidget: (_, __, ___) => Icon(Icons.broken_image, size: size, color: Colors.grey),
      );
    }

    // Local asset
    return LocalAssets(
      imagePath: imagePath,
      height: size,
      width: size,
      boxFix: BoxFit.contain,
    );
  }
}
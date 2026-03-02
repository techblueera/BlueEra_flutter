import 'dart:developer';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/Discover/widget/generic_left_side_category_list.dart';
import 'package:BlueEra/features/me/medical_new/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_product_model.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class MedicalSubCategoryScreen extends StatefulWidget {
  final List<MedicalNestedCategoryModel> arrLevel3Category;

  MedicalSubCategoryScreen({
    super.key,
    required this.arrLevel3Category,
  });

  @override
  State<MedicalSubCategoryScreen> createState() =>
      _MedicalSubCategoryScreenState();
}

class _MedicalSubCategoryScreenState extends State<MedicalSubCategoryScreen> {
  final controller = getOrPut(() => MedicalController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    scrollController.addListener(_onScrollListener);
    controller.fetchGroceryCategoryProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedMedicalData.value = widget.arrLevel3Category.first;
    });
    super.initState();
  }

  void _onScrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !controller.isMedicalCategoryProductsLoadingMore.value &&
        controller.medicalCategoryProductsHasMore) {
      controller.fetchGroceryCategoryProducts(
        isLoadMore: true,
      );
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: CommonBackAppBar(
              title: controller.selectedMedicalData.value?.name,
              isShadowShow: false,
              buildCustomActionWidget: () => Obx(
                    () => controller.selectedMedicalProducts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 20.0),
                            child: Icon(Icons.search),
                          )
                        : InkWell(
                            onTap: () => Get.toNamed(
                                RouteHelper.getAddMedicalScreenRoute()),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 20.0),
                              child: Stack(clipBehavior: Clip.none, children: [
                                LocalAssets(
                                  imagePath: AppIconAssets.cartIcon,
                                ),
                                Positioned(
                                    top: -5,
                                    right: -5,
                                    child: Container(
                                      height: SizeConfig.size16,
                                      width: SizeConfig.size16,
                                      decoration: BoxDecoration(
                                          color: AppColors.red,
                                          shape: BoxShape.circle),
                                      alignment: Alignment.center,
                                      child: CustomText(
                                        '${controller.selectedMedicalProducts.length}',
                                        color: AppColors.white,
                                      ),
                                    ))
                              ]),
                            ),
                          ),
                  )),
          bottomNavigationBar: Obx(() {
            if (controller.selectedMedicalProducts.isEmpty)
              return SizedBox();
            else
              return Material(
                elevation: 8.0,
                child: Container(
                  color: AppColors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size15,
                        vertical: SizeConfig.size15),
                    child: SafeArea(
                      child: CustomBtn(
                        onTap: () {
                          Get.toNamed(RouteHelper.getAddMedicalScreenRoute());
                        },
                        isValidate: true,
                        radius: SizeConfig.size8,
                        title: AppStrings.next,
                        // isLoading: authController.isAddBusinessUserLoading.value
                      ),
                    ),
                  ),
                ),
              );
          }),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftCategoryList(),
              Expanded(child: rightContent()),
            ],
          ),
        ));
  }

  Widget leftCategoryList() {
    return CommonGenericLeftSideCategoryList<MedicalNestedCategoryModel>(
      items: widget.arrLevel3Category,
      getIcon: (item) => item.image ?? '',
      getLabel: (item) => item.name ?? '',
      isSelected: (item) =>
          controller.selectedMedicalData.value?.sId == item.sId,
      onTap: (item, index) {
        final selected = widget.arrLevel3Category[index];
        log('new selection ${controller.selectedMedicalData.value?.sId}');

        if (controller.selectedMedicalData.value?.sId == selected.sId) {
          return;
        }

        controller.selectedMedicalData.value = selected;

        /// api call
        controller.fetchGroceryCategoryProducts();
      },
    );
  }

  Widget rightContent() {
    return Obx(() => Padding(
          padding: const EdgeInsets.all(8),
          child: controller.isMedicalCategoryProductsLoading.value
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Max Limit Error
                    if (controller.isMaxLimitHit)
                      Container(
                        width: SizeConfig.screenWidth,
                        decoration: BoxDecoration(
                            color: AppColors.redBE,
                            borderRadius: BorderRadius.circular(10.0)),
                        margin: EdgeInsets.only(bottom: SizeConfig.size10),
                        padding: EdgeInsets.symmetric(
                            vertical: SizeConfig.size4,
                            horizontal: SizeConfig.size10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                              LocalAssets(
                                  imagePath: AppIconAssets.warningOutlineIcon,
                                  width: SizeConfig.size20,
                                  height: SizeConfig.size20),
                              SizedBox(width: SizeConfig.size8),
                              CustomText(
                                'You can’t select more than ${controller.maxLimit} products at a time.',
                                color: AppColors.redLite,
                                fontSize: SizeConfig.extraSmall,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // GRID
                    Expanded(
                      child: controller.isMedicalCategoryProductsLoading.value
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(SizeConfig.size20),
                                child: SizedBox(
                                    height: 20.0,
                                    width: 20.0,
                                    child: CircularProgressIndicator()),
                              ),
                            )
                          : controller.arrMedicalCategoryProducts.isNotEmpty
                              ? Builder(builder: (context) {
                                  double screenWidth = Get.width;
                                  double totalHorizontalPadding = 8.0;
                                  double crossAxisSpacing = 10.0;
                                  double gridItemWidth = (screenWidth -
                                          totalHorizontalPadding -
                                          crossAxisSpacing) /
                                      2;
                                  double desiredItemHeight = 370.0;

                                  return GridView.builder(
                                    controller: scrollController,
                                    itemCount: controller
                                            .arrMedicalCategoryProducts.length +
                                        (controller
                                                .isMedicalCategoryProductsLoadingMore
                                                .value
                                            ? 1
                                            : 0),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio:
                                          gridItemWidth / desiredItemHeight,
                                    ),
                                    padding: EdgeInsets.only(
                                        bottom: SizeConfig.size30),
                                    itemBuilder: (_, i) {
                                      if (i ==
                                          controller.arrMedicalCategoryProducts
                                              .length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        );
                                      }

                                      return medicalCard(controller
                                          .arrMedicalCategoryProducts[i]);
                                    },
                                  );
                                })
                              : Padding(
                                  padding: EdgeInsets.all(SizeConfig.size20),
                                  child: EmptyStateWidget(
                                      message:
                                          'No ${widget.arrLevel3Category.first.name?.tr} found.')),
                    )
                  ],
                ),
        ));
  }

  Widget medicalCard(MedicalProductData medicalProductData) {
    final bool isSelected =
        controller.selectedMedicalProducts.contains(medicalProductData);
    final price =
        controller.getPriceDetails(medicalProductData.variants?[0].pricing);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: SizedBox(
              height: SizeConfig.size140,
              width: double.infinity,
              child: (medicalProductData.images?.isNotEmpty ?? false)
                  ? CachedNetworkImage(
                      imageUrl: medicalProductData.images!.first.url ?? '',
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
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 9.0, vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${medicalProductData.name}",
                  fontSize: SizeConfig.small,
                  maxLines: 2,
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
                          border: Border.all(
                              width: 0.5, color: AppColors.greyE5)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                      child: CustomText(
                        '${medicalProductData.variants?[0].weight?.toInt()} ${medicalProductData.variants?[0].unit}',
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
                    SizedBox(height: SizeConfig.size8),
                    CustomBtn(
                      height: SizeConfig.size36,
                      onTap: () =>
                          controller.toggleSelection(medicalProductData),
                      title: isSelected ? 'Added' : 'Add',
                      textColor: isSelected
                          ? AppColors.white
                          : AppColors.primaryColor,
                      bgColor: isSelected
                          ? AppColors.primaryColor
                          : AppColors.white,
                      radius: 6.0,
                      borderColor: AppColors.primaryColor,
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

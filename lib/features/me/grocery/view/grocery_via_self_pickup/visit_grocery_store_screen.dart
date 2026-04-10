import 'dart:developer' as dev;

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/view/all_top_selling_grocery_products_screen.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_self_pickup_cart.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_top_selling_tile.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_colors.dart';

class VisitGroceryStoreScreen extends StatefulWidget {
  final String visitBusinessId;
  final String userId;
  const VisitGroceryStoreScreen({
    super.key,
    required this.visitBusinessId,
    required this.userId});

  @override
  State<VisitGroceryStoreScreen> createState() => _VisitGroceryStoreScreenState();
}

class _VisitGroceryStoreScreenState extends State<VisitGroceryStoreScreen> {
  final controller = getOrPut(() => GroceryController());
  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();
  final groceryCustomerController = getOrPut(() => GrocerySelfPickupConsumerController());
  final storeController = getOrPut(() => NewStoreController());

  @override
  void initState() {
    super.initState();
    viewBusinessDetailsController.viewBusinessProfileById(widget.visitBusinessId);
    controller.fetchAllGroceryData(widget.userId, otherStore: true);
    storeController.trackStoreDetailView(widget.visitBusinessId);
    dev.log(
      '[VisitStore] initState '
      'ctrlHash=${identityHashCode(groceryCustomerController)} '
      'listHash=${identityHashCode(groceryCustomerController.selectedGroceriesVariants)} '
      'len=${groceryCustomerController.selectedGroceriesVariants.length} '
      'ids=${groceryCustomerController.selectedGroceriesVariants.map((v) => v.sId).toList()}',
      name: 'VisitStore',
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8,
              vertical: SizeConfig.size15,
            ),
            child: Column(
              children: [
                // --- 1. Profile Header Section (Independent) ---
                Obx(() {
                  if (viewBusinessDetailsController.isProfileLoading.value) {
                    return buildBusinessHeaderSkeleton();
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  return Column(
                    children: [
                      VisitBusinessCommonHeader(
                        details: details,
                        onRated: () => viewBusinessDetailsController
                            .viewBusinessProfileById(widget.visitBusinessId),
                      ),
                      const SizedBox(height: 10),
                      VisitBusinessStatsCard(details: details),
                    ],
                  );
                }),

                // --- 2. Top Selling Products (Independent) ---
                Obx(() {
                  if (controller.fetchGroceryBusinessProductsResponse.value.status == Status.INITIAL) {
                    return Padding(
                        padding: EdgeInsets.only(top: SizeConfig.paddingXSL),
                        child: buildHorizontalListSkeleton());
                  }
                  return controller.groceryBusinessProductsList.isNotEmpty
                      ? _topSellingProduct()
                      : const SizedBox.shrink();
                }),

                SizedBox(height: SizeConfig.paddingXSL),

                // --- 3. Categories Section (Independent) ---
                Obx(() {
                  if (controller.fetchMyGroceryCategoryResponse.value.status == Status.INITIAL) {
                    return buildCategoryGridSkeleton();
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  return _categoryWithInventoryWidget(details);
                }),

                // --- 4. Live Photos Section ---
                Obx(() {
                  if (viewBusinessDetailsController.isProfileLoading.value) {
                    return const SizedBox(
                      height: 10.0
                    );
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  if (details?.livePhotos != null &&
                      details!.livePhotos!.any((p) => p.trim().isNotEmpty)) {
                    return CustomFormCard(
                      padding: const EdgeInsets.all(10),
                      margin: EdgeInsets.only(top: SizeConfig.paddingXSL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            AppStrings.groceryViewLivePhotos.tr,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: 10),
                          StoreLivePhotoWidget(
                            livePhotos: details.livePhotos!
                                .where((p) => p.trim().isNotEmpty)
                                .toList(),
                            natureOfBusiness:
                                details.subCategoryDetails?.name ??
                                    details.natureOfBusiness ??
                                    'OTHER',
                            onViewFullScreen: ({
                              required int index,
                              required List<String> storeImage,
                              required String natureOfBusiness,
                            }) {
                              navigatePushTo(
                                context,
                                ImageViewScreen(
                                  appBarTitle: details.businessName ?? '',
                                  subTitle: natureOfBusiness,
                                  imageUrls: storeImage,
                                  initialIndex: index,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),


                // --- 5. Contact/Map Section (Depends on Profile) ---
                Obx(() {
                  if (viewBusinessDetailsController.isProfileLoading.value) {
                    return const SizedBox.shrink();
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  return BusinessContactMapCard(
                    businessProfileDetails: details,
                    showEditButton: false,
                  );
                }),

                // --- 6. QR Code ---
                Obx(() {
                  if (viewBusinessDetailsController.isProfileLoading.value) {
                    return const SizedBox.shrink();
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  return BusinessQrCodeWidget(data: details);
                }),

                SizedBox(height: SizeConfig.size100),
              ],
            ),
          ),

          // --- 5. Cart UI (Always Reactive) ---
          GrocerySelfPickupCart(
            controller: groceryCustomerController,
          ),
        ],
      ),
    );
  }

  Widget _topSellingProduct(){
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(top: SizeConfig.paddingXSL),
      color: AppColors.primaryColor.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                    AppStrings.groceryViewTopSellingProduct.tr,
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(
                width: SizeConfig.size8,
              ),
              InkWell(
                onTap: () => Get.to(() => AllTopSellingGroceryProductsScreen(
                      userId: widget.userId,
                      otherStore: true,
                      visitBusinessId: widget.visitBusinessId,
                    )),
                child: CustomText(
                    AppStrings.groceryViewViewAll.tr,
                    fontSize: SizeConfig.medium,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),

          SizedBox(
            height: SizeConfig.paddingXSL,
          ),

          SizedBox(
            height: SizeConfig.size240,
            child: Builder(builder: (context) {

              final previewItems = controller.groceryBusinessProductsList.length >
                      GroceryController.businessProductsPreviewLimit
                  ? controller.groceryBusinessProductsList
                      .take(GroceryController.businessProductsPreviewLimit)
                      .toList()
                  : controller.groceryBusinessProductsList.toList();
              return ListView.builder(
                itemCount: previewItems.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index){
                  var groceryProductData = previewItems[index];

                  return Container(
                    width: SizeConfig.size150,
                    margin: EdgeInsets.only(right: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: SizeConfig.size4),

                        Expanded(
                          child: GroceryTopSellingImage(
                            item: groceryProductData,
                            cartOverlay: Obx(() {
                              var productVariants = groceryProductData.productVariant;

                              final cart = groceryCustomerController.selectedGroceriesVariants;
                              final cartLen = cart.length;
                              final bool isAdded = cart.any((v) => v.sId == productVariants?.sId);
                              dev.log(
                                '[VisitStore] tile Obx variantId=${productVariants?.sId} '
                                'cartLen=$cartLen added=$isAdded '
                                'ctrlHash=${identityHashCode(groceryCustomerController)} '
                                'listHash=${identityHashCode(cart)} '
                                'cartIds=${cart.map((v) => v.sId).toList()}',
                                name: 'VisitStore',
                              );

                              return IconButton(
                                onPressed: () {
                                  if (productVariants == null) {
                                    commonSnackBar(message: AppStrings.groceryViewNoVariantsAvailable.tr);
                                    return;
                                  }

                                  if(!isAdded){
                                    final bDetails = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                                    groceryCustomerController.addToCart(
                                      productVariants,
                                      inventoryId: groceryProductData.sId,
                                      productId: productVariants.sId,
                                      businessId: widget.visitBusinessId,
                                      businessName: bDetails?.businessName,
                                      businessLogo: bDetails?.logo,
                                      businessAddress: bDetails?.address,
                                      productImage: (groceryProductData.product?.images?.isNotEmpty ?? false)
                                          ? groceryProductData.product!.images!.first.url
                                          : null,
                                    );
                                  }else{
                                    groceryCustomerController.removeFromCart(productVariants);
                                  }
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isAdded
                                        ? AppColors.greenShade
                                        : AppColors.blackMite,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    !isAdded ? Icons.add : Icons.check,
                                    size: SizeConfig.size16,
                                    color: AppColors.white,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        GroceryTopSellingInfoSection(item: groceryProductData),
                      ],
                    ),
                  );
                },
              );
            }),
          ),



        ],
      ),
    );
  }

  Widget _categoryWithInventoryWidget(BusinessProfileDetails? details){
    final groceryCategoryList = List<GroceryCategoryWithInventoryModel>.from(controller.groceryCategoryList);

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
          AppStrings.groceryViewCategory.tr,
          fontSize: SizeConfig.large,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w600),

          SizedBox(
            height: SizeConfig.paddingXSL,
          ),

          groceryCategoryList.isNotEmpty ?
          MasonryGridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            padding: EdgeInsets.zero,
            primary: false,
            shrinkWrap: true,
            itemCount: groceryCategoryList.length,
            itemBuilder: (context, index) {
              var categoryItem = groceryCategoryList[index];
              return CommonServiceCard(
                service: categoryItem,
                getName: (_categoryItem) => _categoryItem.name??'',
                getIcon: (_categoryItem) => _categoryItem.image??'',
                iconHeight: SizeConfig.size60,
                boxShadow: [],
                onTap: (_categoryItem) {

                  Get.toNamed(
                    RouteHelper.getVisitGroceryProductsScreenRoute(),
                    arguments: {
                      ApiKeys.userId: details?.userId,
                      ApiKeys.businessId: details?.id,
                      ApiKeys.argArrGroceryCatKey: _categoryItem.key,
                      ApiKeys.argArrGroceryCatName: _categoryItem.name,
                    },
                  );

                  // return Get.toNamed(RouteHelper.getGroceryNestedCategoryWithInventoryScreenRoute(),
                  //   arguments: {
                  //     ApiKeys.userId: details?.userId,
                  //     ApiKeys.argGroceryCategoryWithInventory: groceryCategoryList,
                  //     ApiKeys.argArrGroceryCatKey: _categoryItem.key,
                  //     ApiKeys.argArrGroceryCatName: _categoryItem.name,
                  //   },
                  // );

                },
              );
            },
          )
              : EmptyStateWidget(
            message: AppStrings.groceryViewNoProductsYet.trParams({'name': details?.businessName ?? ''}),
          ),

        ],
      ),
    );
  }


}




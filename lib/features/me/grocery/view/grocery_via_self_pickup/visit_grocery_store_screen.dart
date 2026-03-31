import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/features/me/grocery/widget/self_pickup_common_cart_ui.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visit_business_common_header.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                        padding: EdgeInsets.only(top: SizeConfig.paddingM),
                        child: buildHorizontalProductListSkeleton());
                  }
                  return controller.groceryBusinessProductsList.isNotEmpty
                      ? _topSellingProduct()
                      : const SizedBox.shrink();
                }),

                SizedBox(height: SizeConfig.paddingM),

                // --- 3. Categories Section (Independent) ---
                Obx(() {
                  if (controller.fetchMyGroceryCategoryResponse.value.status == Status.INITIAL) {
                    return buildCategoryGridSkeleton();
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  return _categoryWithInventoryWidget(details);
                }),

                SizedBox(height: SizeConfig.paddingM),

                // --- 4. Live Photos Section ---
                Obx(() {
                  if (viewBusinessDetailsController.isProfileLoading.value) {
                    return const SizedBox.shrink();
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  if (details?.livePhotos != null &&
                      details!.livePhotos!.any((p) => p.trim().isNotEmpty)) {
                    return Padding(
                      padding: EdgeInsets.only(top: SizeConfig.paddingM),
                      child: CustomFormCard(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomText(
                              'Live Photos',
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
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                SizedBox(height: SizeConfig.paddingM),

                // --- 5. Contact/Map Section (Depends on Profile) ---
                Obx(() {
                  if (viewBusinessDetailsController.isProfileLoading.value) {
                    return const SizedBox.shrink();
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  return _buildContactNdMapCard(details);
                }),

                // --- 6. QR Code ---
                Obx(() {
                  if (viewBusinessDetailsController.isProfileLoading.value) {
                    return const SizedBox.shrink();
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  return Padding(
                    padding: EdgeInsets.only(top: SizeConfig.paddingM),
                    child: BusinessQrCodeWidget(data: details),
                  );
                }),

                SizedBox(height: SizeConfig.size100),
              ],
            ),
          ),

          // --- 5. Cart UI (Always Reactive) ---
          SelfPickupCommonCartUi(
            selectedVariants: groceryCustomerController.selectedGroceriesVariants,
          ),
        ],
      ),
    );
  }

  Widget _topSellingProduct(){
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(top: SizeConfig.paddingM),
      color: AppColors.primaryColor.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                    'Top Selling Product',
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(
                width: SizeConfig.size8,
              ),
              CustomText(
                  'View All',
                  fontSize: SizeConfig.medium,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600),
            ],
          ),

          SizedBox(
            height: SizeConfig.paddingXSL,
          ),

          SizedBox(
            height: SizeConfig.size240,
            child: ListView.builder(
                itemCount: controller.groceryBusinessProductsList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index){
                  var groceryProductData = controller.groceryBusinessProductsList[index];

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

                        Stack(
                          children: [
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: SizedBox(
                                    height: SizeConfig.size140,
                                    width: double.infinity,
                                    child: (groceryProductData.product?.images?.isNotEmpty ?? false)
                                        ? CachedNetworkImage(
                                      imageUrl: groceryProductData.product?.images!.first.url??'',
                                      fit: BoxFit.fill,
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
                              ],
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Obx(() {
                                var productVariants = groceryProductData.productVariant;


                                final bool isAdded = groceryCustomerController.selectedGroceriesVariants
                                    .any((v) => v.sId == productVariants?.sId);

                                return IconButton(
                                  onPressed: () {
                                    if (productVariants == null) {
                                      commonSnackBar(message: 'No variants available');
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
                                        // deliveryType: 'SELF',
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
                            )
                          ],
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.0, vertical: SizeConfig.size6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: SizeConfig.size30,
                                child: CustomText(
                                  "${groceryProductData.product?.name}",
                                  fontSize: SizeConfig.small,
                                  maxLines: 2,
                                  color: AppColors.mainTextColor,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: SizeConfig.size6),
                              FittedBox(
                                child: Row(
                                  children: [
                                    if (groceryProductData.productVariant?.isVegetarian != null) ...[
                                      FoodTypeIndicator(isVegetarian: groceryProductData.productVariant?.isVegetarian!??false),
                                      SizedBox(width: SizeConfig.size6),
                                    ],
                                    Container(
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          border:
                                          Border.all(width: 0.5, color: AppColors.greyE5)),
                                      padding:
                                      EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                                      child: CustomText(
                                        '${groceryProductData.productVariant?.variantName}',
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: SizeConfig.size6),
                              PriceRow(
                                sellingPrice:  "₹${groceryProductData.minSellingPrice}",
                                mrp: "₹${groceryProductData.minMrp}",
                                discount:  "${groceryProductData.avgDiscount}% OFF",
                              ),
                              SizedBox(height: SizeConfig.size4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
            ),
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
          'Category',
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
              :
          EmptyStateWidget(
            message: '${details?.businessName} don\'t have an inventory yet.',
          ),

          SizedBox(
            height: SizeConfig.paddingXSL,
          ),

        ],
      ),
    );
  }

  Widget _buildContactNdMapCard(BusinessProfileDetails? businessProfileDetails) {
    final logoUrl = businessProfileDetails?.logo;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
              AppStrings.contactUs.tr,
              fontSize: SizeConfig.large,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w600),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.greyE5),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [AppShadows.textFieldShadow]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      // key: ValueKey(logoUrl),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white, // Background color for placeholder transparency
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
                        image: DecorationImage(
                          image: (logoUrl != null && logoUrl.isNotEmpty)
                              ? NetworkImage(logoUrl) as ImageProvider
                              : AssetImage(AppIconAssets.place_holder_image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomText(
                              businessProfileDetails?.businessName,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          const SizedBox(height: 5),
                          (businessProfileDetails?.businessDescription?.isNotEmpty ??false)
                          ? ExpandableText(
                            text: businessProfileDetails?.businessDescription??'',
                            trimLines: 3,
                            isReadMoreNewLine: false,
                            expandMode: ExpandMode.dialog,
                            style: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppConstants.OpenSans,
                            ),
                          )
                          : CustomText(
                              AppStrings.na,
                            color: AppColors.secondaryTextColor,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppConstants.OpenSans,
                          ),
                        ],
                      ),
                    )
                  ],
                ),

                const Divider(
                    color: AppColors.greyE5,
                    height: 30),

                // Contact List
                if(businessProfileDetails?.websiteUrl?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.website_click,
                      businessProfileDetails?.websiteUrl ?? "",
                      AppColors.primaryColor),

                if(businessProfileDetails?.subCategoryDetails?.name?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.principal,
                      businessProfileDetails?.subCategoryDetails?.name ?? "",
                      AppColors.secondaryTextColor),

                if(businessProfileDetails?.ownerDetails?[0].email?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.email,
                      businessProfileDetails?.ownerDetails?[0].email ?? "",
                      AppColors.secondaryTextColor),

                if(businessProfileDetails?.businessNumber?.officeMobNo?.number?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.phone_outline,
                      businessProfileDetails?.businessNumber?.officeMobNo?.number ?? "",
                      AppColors.secondaryTextColor),

                if(businessProfileDetails?.address?.isNotEmpty ?? false)
                  _contactItem(
                      AppIconAssets.location_new,
                      businessProfileDetails?.address ?? "",
                      AppColors.secondaryTextColor),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          // SizedBox(
          //   width: double.infinity,
          //   height: 180,
          //   child: Stack(
          //     children: [
          //       GoogleMap(
          //         onMapCreated: _onMapCreated,
          //         initialCameraPosition: CameraPosition(
          //           target: LatLng(widget.latitude, widget.longitude),
          //           zoom: 14.0,
          //         ),
          //         markers: _markers,
          //         myLocationEnabled: false,
          //         compassEnabled: false,
          //         // Fix for iOS gesture conflicts
          //         // gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          //         //   Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          //         // },
          //       ),
          //       // ... rest of your UI (Send button)
          //     ],
          //   ),
          // ),

          BusinessLocationMapWidget(
            latitude: businessProfileDetails?.businessLocation?.lat ?? 0.0,
            longitude: businessProfileDetails?.businessLocation?.lon ?? 0.0,
            businessName: businessProfileDetails?.businessName ?? "",
          ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: CustomText(label,
                  fontSize: 15, color: AppColors.mainTextColor)),
        ],
      ),
    );
  }

}




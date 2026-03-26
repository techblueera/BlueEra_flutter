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
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/features/me/grocery/widget/self_pickup_common_cart_ui.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_colors.dart';

class OtherGroceryStoreScreen extends StatefulWidget {
  final String visitBusinessId;
  final String userId;
  const OtherGroceryStoreScreen({
    super.key,
    required this.visitBusinessId,
    required this.userId});

  @override
  State<OtherGroceryStoreScreen> createState() => _OtherGroceryStoreScreenState();
}

class _OtherGroceryStoreScreenState extends State<OtherGroceryStoreScreen> {
  final controller = getOrPut(() => GroceryController());
  final viewBusinessDetailsController =
  Get.find<ViewBusinessDetailsController>();
  final groceryCustomerController = getOrPut(() => GrocerySelfPickupConsumerController());

  @override
  void initState() {
    // groceryCustomerController.resetController();
    viewBusinessDetailsController.viewBusinessProfileById(widget.visitBusinessId);
    controller.fetchAllGroceryData(widget.userId, otherStore: true);
    super.initState();
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
                  return _groceryHeaderWidget(details);
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

                // --- 4. Contact/Map Section (Depends on Profile) ---
                Obx(() {
                  if (viewBusinessDetailsController.isProfileLoading.value) {
                    return const SizedBox.shrink();
                  }
                  final details = viewBusinessDetailsController.visitedBusinessProfileDetails?.data;
                  return _buildContactNdMapCard(details);
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

  Widget _groceryHeaderWidget(BusinessProfileDetails? details){
    return CustomFormCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner + Profile Image
        Container(
          height: 170,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner Image

              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  color: AppColors.greyLite, // Background color for the "empty" state
                  child: (details?.coverimage != null && details!.coverimage!.isNotEmpty)
                      ? Image.network(
                    details.coverimage!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildErrorPlaceholder();
                    },
                  )
                      : _buildErrorPlaceholder(), // Show icon if URL is null/empty
                ),
              ),

              // Profile image overlapping banner bottom
              Positioned(
                left: 20,
                top: 90, // makes it overlap smoothly
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.white,
                    child: details?.logo?.isNotEmpty == true
                        ? ClipOval(
                      child: NetWorkOcToAssets(imgUrl: details?.logo ?? "")
                    )
                        : LocalAssets(imagePath: AppIconAssets.user_out_line),
                  ),
                ),
              ),

              Positioned(
                right: 5,
                bottom: 10,
                child: RatingBar.builder(
                  initialRating: 0,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 15, // Adjust size to match your UI
                  unratedColor: AppColors.secondaryTextColor, // Matches the grey outlines in your image
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => LocalAssets(
                    imagePath: AppIconAssets.star_rounded,
                    imgColor: Colors.amber, // Color when filled
                  ),
                  onRatingUpdate: (rating) {
                    print(rating);
                  },
                ),
              )

            ],
          ),
        ),

        // --- FORM SECTION ---
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              CustomText(details?.businessName,
                  fontSize: 18,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.bold),
              const SizedBox(height: 10),
              ExpandableText(
                text: details?.businessDescription ?? AppStrings.na,
                trimLines: 4,
                isReadMoreNewLine: false,
                expandMode: ExpandMode.dialog,
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w400,
                  fontFamily: AppConstants.OpenSans,
                ),
              ),
              const SizedBox(height: 10),
              CommonRatingRow(
                rating:
                double.tryParse(details?.avg_rating.toString() ?? '0.0') ?? 0.0,
                reviews: details?.total_ratings?.toInt() ?? 0,
                distance: '${calculateDistanceKm(
                  LocationService.lat,
                  LocationService.lng,
                  details?.businessLocation?.lat?.toDouble() ?? 0.0,
                  details?.businessLocation?.lon?.toDouble() ?? 0.0,
                ).toStringAsFixed(2)} Km Away',
              ),

              // const SizedBox(height: 10),
              // CustomText(
              //   "Monday – Friday: 9:00 AM – 6:00 PM",
              //   color: AppColors.secondaryTextColor,
              //   fontSize: SizeConfig.small,
              //   fontWeight: FontWeight.w400,
              // )
            ],
          ),
        ),

        const SizedBox(height: 10),
      ],
    )

    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.cover,
        height: 130,
        width: double.infinity,
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
                    RouteHelper.getOtherGroceryProductsScreenRoute(),
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




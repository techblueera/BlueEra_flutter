import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/widget/grocery_profile_header_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';

class MyGroceryStoreScreen extends StatefulWidget {
  const MyGroceryStoreScreen({super.key});

  @override
  State<MyGroceryStoreScreen> createState() => _MyGroceryStoreScreenState();
}

class _MyGroceryStoreScreenState extends State<MyGroceryStoreScreen> {
  final controller = getOrPut(() => GroceryController());
  final viewBusinessDetailsController =
        Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    // controller.fetchMyGroceryCategoryWithVariants();
    // controller.fetchGroceryBusinessProductsRepo();
    controller.fetchAllGroceryData(userId, otherStore: false);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Obx((){
          if (controller.myGroceryLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          BusinessProfileDetails? businessProfileDetails = viewBusinessDetailsController.businessProfileDetails?.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                CustomFormCard(
                  padding: EdgeInsets.zero,
                  child: GroceryProfileHeader(
                    details: businessProfileDetails,
                    controller: viewBusinessDetailsController,
                  )
                ),
            
                if(controller.groceryBusinessProductsList.isNotEmpty)
                _topSellingProduct(),

                SizedBox(
                  height: SizeConfig.paddingM,
                ),
            
                _categoryWithInventoryWidget(),
            
                SizedBox(
                  height: SizeConfig.paddingM,
                ),
            
                _buildContactNdMapCard(businessProfileDetails),

                SizedBox(
                  height: SizeConfig.size100,
                ),
            
              ],
            ),
          );
        }
        )
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
            height: SizeConfig.size265,
            child: ListView.builder(
                itemCount: controller.groceryBusinessProductsList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index){
                  var productsData = controller.groceryBusinessProductsList[index];
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: SizedBox(
                            height: SizeConfig.size140,
                            width: double.infinity,
                            child: (productsData.product?.images?.isNotEmpty ?? false)
                                ? CachedNetworkImage(
                              imageUrl: productsData.product?.images!.first.url??'',
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
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.0, vertical: SizeConfig.size6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: SizeConfig.size30,
                                child: CustomText(
                                  "${productsData.product?.name}",
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
                                          border:
                                          Border.all(width: 0.5, color: AppColors.greyE5)),
                                      padding:
                                      EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                                      child: CustomText(
                                        '${productsData.productVariant?.variantName}',
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
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
                                          "₹${productsData.minSellingPrice}",
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
                                          "₹${productsData.minMrp}",
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
                                          "${productsData.avgDiscount}% OFF",
                                          fontSize: 10,
                                          color: AppColors.green00,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
          )

        ],
      ),
    );
  }

  Widget _categoryWithInventoryWidget(){
    final groceryCategoryList = List<GroceryCategoryWithInventoryModel>.from(controller.groceryCategoryList);

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                    'Category',
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(
                width: SizeConfig.size8,
              ),
              InkWell(
                onTap: ()=> Get.toNamed(
                    RouteHelper.getGrocerySuperCategoryScreenRoute(),
                    arguments: {
                      ApiKeys.argBulkUpload: false
                    }
                ),
                child: CustomText(
                    'Update Inventory',
                    fontSize: SizeConfig.medium,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),

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
                  return Get.toNamed(RouteHelper.getGroceryNestedCategoryWithInventoryScreenRoute(),
                    arguments: {
                      ApiKeys.userId: userId,
                      ApiKeys.argGroceryCategoryWithInventory: groceryCategoryList,
                      ApiKeys.argArrGroceryCatKey: _categoryItem.key,
                      ApiKeys.argArrGroceryCatName: _categoryItem.name,
                    },
                  );


                //   return Get.toNamed(RouteHelper.getMyGroceryProductsScreenRoute(),
                //   arguments: {
                //     ApiKeys.userId: userId,
                //     ApiKeys.argCategoryId: _categoryItem.sId,
                //     ApiKeys.argCategoryName: _categoryItem.name
                //   },
                // );

                },
              );
            },
          )
              :
          EmptyStateWidget(
            message: 'You don\'t have inventory yet, Want to create one?',
          ),

          SizedBox(
            height: SizeConfig.paddingXSL,
          ),

        ],
      ),
    );
  }

  Widget _buildContactNdMapCard(BusinessProfileDetails? businessProfileDetails) {
    final logoUrl = viewBusinessDetailsController.businessProfileDetails?.data?.logo;

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
                      key: ValueKey(logoUrl),
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

                if(businessProfileDetails?.userContactNo?.isNotEmpty ?? false)
                _contactItem(
                    AppIconAssets.phone_outline,
                    businessProfileDetails?.userContactNo?? "",
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




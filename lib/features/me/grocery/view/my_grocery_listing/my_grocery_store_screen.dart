import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_header_view.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_category_with_inventory_model.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
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

          BusinessProfileDetails? businessProfileDetails = viewBusinessDetailsController.businessProfileDetails.value?.data;

          return RefreshIndicator(
            onRefresh: () async {
              controller.fetchAllGroceryData(userId, otherStore: false);
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 15.0,
              ),
              child: Column(
                children: [
                  CustomFormCard(
                      padding: EdgeInsets.zero,
                      child: BusinessProfileHeaderView(
                        details: businessProfileDetails,
                        controller: viewBusinessDetailsController,
                   ),
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

                  BusinessContactMapCard(
                    businessProfileDetails: businessProfileDetails,
                  ),

                  SizedBox(
                    height: SizeConfig.size100,
                  ),

                ],
              ),
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
            height: SizeConfig.size240,
            child: ListView.builder(
                itemCount: controller.groceryBusinessProductsList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index){
                  var groceryProductData = controller.groceryBusinessProductsList[index];
                  return Container(
                    width: SizeConfig.size160,
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

}




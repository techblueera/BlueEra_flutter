import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_contact_map_card.dart';
import 'package:BlueEra/features/business/widgets/business_profile_header_view.dart';
import 'package:BlueEra/features/business/widgets/business_qrcode_widget.dart';
import 'package:BlueEra/features/business/widgets/business_stats.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/widgets/common_business_live_photo.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/common_methods.dart';
import '../widget/attribute_two_rows.dart';

class ProductHomeScreen extends StatefulWidget {
  const ProductHomeScreen({super.key});

  @override
  State<ProductHomeScreen> createState() => _ProductHomeScreenState();
}

class _ProductHomeScreenState extends State<ProductHomeScreen> {
  final controller = getOrPut(() => InventoryController());
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  BusinessProfileDetails? businessProfileDetails;

  @override
  void initState() {
    businessProfileDetails =
        viewBusinessDetailsController.businessProfileDetails.value?.data;
    controller.fetchAllProductData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          controller.fetchAllProductData();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 15.0,
          ),
          child: Column(
            children: [
              BusinessProfileHeaderView(
                details: businessProfileDetails,
                controller: viewBusinessDetailsController,
              ),

              // --- Business Stats ---
              BusinessStats(details: businessProfileDetails),

              // --- Top Selling Products ---
              Obx(() {
                if (controller.ownDraftAndPublicProductResponse.value.status ==
                    Status.INITIAL) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: buildHorizontalProductListSkeleton(),
                  );
                }

                return controller.allProducts.isNotEmpty
                    ? _topSellingProduct()
                    : const SizedBox.shrink();
              }),

              // --- Category ---
              Obx(() {
                if (controller.fetchProductCategoryResponse.value.status ==
                    Status.INITIAL) {
                  return buildCategoryGridSkeleton();
                }
                return _categoryWithInventoryWidget();
              }),

              // --- Business Live Photos ---
              CommonBusinessLivePhoto(
                controller: viewBusinessDetailsController,
              ),

              // --- Contact & Map ---
              BusinessContactMapCard(
                businessProfileDetails: businessProfileDetails,
              ),

              // --- QR Code ---
              BusinessQrCodeWidget(
                data: businessProfileDetails,
              ),

              SizedBox(
                height: SizeConfig.size100,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topSellingProduct() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(top: 10),
      color: AppColors.primaryColor.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText('Top Selling Product',
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText('View All',
                  fontSize: SizeConfig.medium,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          SizedBox(
            height: SizeConfig.size240,
            child: ListView.builder(
              itemCount: controller.allProducts.length > 10
                  ? 10
                  : controller.allProducts.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                var product = controller.allProducts[index];
                final details = product.product.details;
                final variants =
                    product.product.sellerClassification?.variants ?? [];
                final img = (details?.media.isNotEmpty ?? false)
                    ? details!.media.first
                    : '';

                final Map<String, List<dynamic>> uniqueAttributes = {};
                final firstTwoKeys = <String>[];
                for (var v in variants) {
                  for (var key in v.attributes.keys) {
                    if (!firstTwoKeys.contains(key)) {
                      firstTwoKeys.add(key);
                    }
                    if (firstTwoKeys.length == 1) break;
                  }
                  if (firstTwoKeys.length == 1) break;
                }
                for (var key in firstTwoKeys) {
                  uniqueAttributes[key] = [];
                  for (var v in variants) {
                    final value = v.attributes[key];
                    if (value != null) {
                      if (key == 'color' && value is Map<String, dynamic>) {
                        final colorMap = {
                          "color_name": value["color_name"] ?? "",
                          "color_code": value["color_code"] ?? ""
                        };
                        if (!uniqueAttributes[key]!.any((e) =>
                            e is Map &&
                            e["color_name"] == colorMap["color_name"] &&
                            e["color_code"] == colorMap["color_code"])) {
                          uniqueAttributes[key]!.add(colorMap);
                        }
                      } else {
                        if (!uniqueAttributes[key]!.contains(value)) {
                          uniqueAttributes[key]!.add(value);
                        }
                      }
                    }
                  }
                }

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
                          child: img.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: img,
                                  fit: BoxFit.fill,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      LocalAssets(
                                    imagePath:
                                        AppIconAssets.place_holder_image,
                                    boxFix: BoxFit.cover,
                                  ),
                                )
                              : LocalAssets(
                                  imagePath:
                                      AppIconAssets.place_holder_image,
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
                                details?.name ?? '',
                                fontSize: SizeConfig.small,
                                maxLines: 2,
                                color: AppColors.mainTextColor,
                                overflow: TextOverflow.ellipsis,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: SizeConfig.size6),
                            if (variants.isNotEmpty)
                              PriceRow(
                                sellingPrice: '\u20B9${variants[0].sellingPrice}',
                                mrp: '\u20B9${variants[0].mrp}',
                                discount: "${calculateDiscount('${variants[0].sellingPrice}', '${variants[0].mrp}')}% OFF",
                              ),
                            AttributeRows(attributeMap: uniqueAttributes),
                            SizedBox(height: SizeConfig.size4),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryWithInventoryWidget() {
    final categoryList = controller.productCategoryList;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText('Category',
                    fontSize: SizeConfig.large,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(width: SizeConfig.size8),
              InkWell(
                onTap: () async {
                  await Get.toNamed(
                    RouteHelper.getProductSuperCategoryScreenRoute(),
                    arguments: {ApiKeys.argBulkUpload: false},
                  );
                  if (controller.productDataNeedsRefresh) {
                    controller.productDataNeedsRefresh = false;
                    controller.fetchAllProductData();
                  }
                },
                child: CustomText('Update Inventory',
                    fontSize: SizeConfig.medium,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          categoryList.isNotEmpty
              ? MasonryGridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  padding: EdgeInsets.zero,
                  primary: false,
                  shrinkWrap: true,
                  itemCount: categoryList.length,
                  itemBuilder: (context, index) {
                    var categoryItem = categoryList[index];
                    return CommonServiceCard(
                      service: categoryItem,
                      getName: (_categoryItem) => _categoryItem.name ?? '',
                      getIcon: (_categoryItem) => _categoryItem.image ?? '',
                      iconHeight: SizeConfig.size60,
                      boxShadow: [],
                      onTap: (_categoryItem) {
                        Get.toNamed(
                          RouteHelper
                              .getProductNestedCategoryWithInventoryScreenRoute(),
                          arguments: {
                            ApiKeys.argProductCategoryWithInventory:
                                categoryList.toList(),
                            ApiKeys.argProductCatKey:
                                _categoryItem.key ?? '',
                            ApiKeys.argProductCatName:
                                _categoryItem.name ?? '',
                          },
                        );
                      },
                    );
                  },
                )
              : EmptyStateWidget(
                  message:
                      'You don\'t have product yet, Want to create one?',
                ),
          SizedBox(height: SizeConfig.paddingXSL),
        ],
      ),
    );
  }
}

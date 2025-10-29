import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/common/store/widget/store_km_away_text_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/attribute_two_rows.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreProductCard extends StatelessWidget {
  final ProductStore? productStore;
  const StoreProductCard({Key? key, this.productStore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = productStore;
    int discountProduct = calculateDiscount(
      product?.sellerClassification?.variants[0].sellingPrice.toString() ?? "0",
      product?.sellerClassification?.variants[0].mrp.toString() ?? "0",
    ).toInt();

    final details = product?.details;
    final sellerClassification = product?.sellerClassification;

    if (details == null) {
      return const SizedBox();
    }

    final variants = sellerClassification?.variants ?? [];

    final Map<String, List<dynamic>> uniqueAttributes = {};

    final firstTwoKeys = <String>[];
    for (var v in variants) {
      for (var key in v.attributes.keys) {
        if (!firstTwoKeys.contains(key)) {
          firstTwoKeys.add(key);
        }
        if (firstTwoKeys.length == 2) break;
      }
      if (firstTwoKeys.length == 2) break;
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

    return InkWell(
     onTap: (){
       final owner = product?.sellerClassification?.owner;
       final type = owner?.type ?? ProductServiceProviderType.business.title;

       final providerType = ProductServiceProviderType.values.firstWhere(
             (e) => e.title == type,
         orElse: () => ProductServiceProviderType.business,
       );

       Get.toNamed(
         RouteHelper.getStoreProductPreviewScreenProductRoute(),
         arguments: {
           ApiKeys.argProductData: product,
           ApiKeys.id: owner?.id ?? '',
           ApiKeys.providerType: providerType
         },
       );

     },
      child: Container(
        height: SizeConfig.size200,
        decoration: BoxDecoration(
          color: AppColors.whiteFE,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 1.4,
              offset: const Offset(0, 0.7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Product Image
            CustomImageSlideshow(
              isLoading: false,
              height: SizeConfig.size200,
              width: 140,
              imagePaths: details.media,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(10.0)),
              // fit: BoxFit.cover,
            ),
            const SizedBox(width: 10),

            /// Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 8, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title + 3-dot menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomText(
                            details.name,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2
                          ),
                        ),
                        Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                     SizedBox(height: SizeConfig.size8),

                    /// Price Row
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CustomText(
                            "Price: ",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor
                          ),

                          CustomText(
                              '₹${sellerClassification?.variants[0].sellingPrice}',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor
                          ),
                          const SizedBox(width: 6),
                           if (discountProduct > 0) ...[
                          CustomText(
                            "${discountProduct}% Off",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: Colors.green.shade600
                          ),
                          const SizedBox(width: 6),

                          ],
                          CustomText(
                              ' ₹${sellerClassification?.variants[0].mrp}',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                            decoration: TextDecoration.lineThrough
                          ),
                        ],
                      ),
                    ),
                    // SizedBox(height: SizeConfig.size4),

                    AttributeRows(attributeMap: uniqueAttributes),

                     SizedBox(height: SizeConfig.size8),

                    /// Shop + Location Row
                    InkWell(
                      onTap: (){
                        final owner = product?.sellerClassification?.owner;
                        final ownerId = owner?.id ?? '';
                        final screen = AppConstants.storeFeedScreen;

                        if (owner == null) return;

                        final isBusiness = owner.type == ProductServiceProviderType.business.title;

                        final destination = isBusiness
                            ? VisitBusinessProfileNew(
                          businessId: ownerId,
                          screenName: screen,
                        )
                            : NewVisitProfileScreen(
                          authorId: ownerId,
                          screenFromName: screen,
                        );

                        Get.to(() => destination);

                      },
                      child: Row(
                        children: [
                          CachedAvatarWidget(
                            imageUrl: product?.business_logo,
                            size: SizeConfig.size26,
                            borderRadius: SizeConfig.size13,
                            showProfileOnFullScreen: false,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: CustomText(
                              product?.business_name,
                               fontSize: SizeConfig.small,
                               fontWeight: FontWeight.w600,
                               color: AppColors.mainTextColor,
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: SizeConfig.size10),

                    StoreKmAwayTextWidget(
                      lat: sellerClassification?.businessLocation?.latitude?.toDouble() ?? 0.0,
                      long: sellerClassification?.businessLocation?.longitude?.toDouble() ?? 0.0,
                      isUnderlineShow: false,
                      isPadding: 4.0,
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
}

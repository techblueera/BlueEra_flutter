import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/attribute_two_rows.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessAllProductCard extends StatefulWidget {
  final List<GetProductData> allProducts;

  const BusinessAllProductCard({
    super.key,
    required this.allProducts,
    });

  @override
  State<BusinessAllProductCard> createState() => _BusinessAllProductCardState();
}

class _BusinessAllProductCardState extends State<BusinessAllProductCard> {
  int _currentIndex = 0;

  late final List<GlobalKey> _cardKey;
  late final List<GetProductData> _allProducts;

  @override
  void initState() {
    super.initState();
    _allProducts = widget.allProducts;
    _cardKey = List.generate(_allProducts.length, (_) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final crossAxisCount = 2;
        final crossSpacing = 10.0;
        final mainSpacing = 10.0;

        final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
        final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;

        final approximateItemHeight = SizeConfig.size290;

        final childAspectRatio = itemWidth / approximateItemHeight;

        return GridView.builder(
          // controller: storesScrollController,
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8,
              vertical: SizeConfig.size15
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: mainSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _allProducts.length,
          itemBuilder: (BuildContext context, int index) {
            final productData = _allProducts[index];
            int discountProduct = calculateDiscount(
              productData.product.sellerClassification?.variants[0].sellingPrice.toString() ?? "0",
              productData.product.sellerClassification?.variants[0].mrp.toString() ?? "0",
            ).toInt();

            final details = productData.product.details;
            final sellerClassification = productData.product.sellerClassification;

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

            return RepaintBoundary(
              key: _cardKey[index],
              child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.blueLightShade,
                    boxShadow:  [AppShadows.cardShadow],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.transparent,
                        width: 1.5
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      CustomImageSlideshow(
                        isLoading: false,
                        width: double.infinity,
                        height: SizeConfig.size150,
                        imagePaths: details.media,
                        borderRadius: BorderRadius.circular(10),
                      ),

                      SizedBox(height: SizeConfig.size5),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            CustomText(
                              details.name,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.medium,
                              color: AppColors.mainTextColor,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: SizeConfig.size5),

                            // Price Row
                            // if (variants.isNotEmpty)
                            Row(
                              children: [
                                CustomText(
                                  '₹${variants[0].sellingPrice}',
                                  fontWeight: FontWeight.w700,
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.primaryColor,
                                  fontFamily: AppConstants.OpenSans,
                                ),
                                SizedBox(width: SizeConfig.size6),
                                CustomText(
                                  ' ₹${variants[0].mrp}',
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.lineThrough,
                                  fontFamily: AppConstants.OpenSans,
                                ),
                                if (discountProduct > 0)
                                  Padding(
                                    padding: EdgeInsets.only(left: SizeConfig.size6),
                                    child: CustomText(
                                      "${discountProduct}% ${AppStrings.off.tr}",
                                      fontSize: SizeConfig.small,
                                      color: AppColors.greenShade,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppConstants.OpenSans,
                                    ),
                                  ),
                              ],
                            ),

                            SizedBox(height: SizeConfig.size5),

                            AttributeRows(attributeMap: uniqueAttributes),

                          ],
                        ),
                      ),

                      Spacer(),

                      CommonHorizontalDivider(
                        color: Colors.grey,
                      ),

                      InkWell(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
                        onTap: () async {
                          final currentProduct = widget.allProducts[_currentIndex];
                          await VisitingCardHelper().shareVisitingCard(
                              _cardKey[index],
                              productId: currentProduct.product.details?.id
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size8,
                              vertical: SizeConfig.size8,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                CustomText(
                                    AppStrings.shareCardToSocialMediaGrowBusiness,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: SizeConfig.small,
                                    fontFamily: AppConstants.OpenSans
                                ),
                                SizedBox(width: SizeConfig.size8),
                                LocalAssets(
                                    imagePath: AppIconAssets.share_bold,
                                    imgColor: AppColors.primaryColor
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),


              ),
            );
          },

        );

      },

    );
  }



}

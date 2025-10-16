import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DiwaliOfferCard extends StatelessWidget {
  final GlobalKey cardKey;
  final GetProductData ownProductData;
  final String backgroundAsset;

  const DiwaliOfferCard({
    super.key,
    required this.cardKey,
    required this.ownProductData,
    required this.backgroundAsset,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate card size - 1:1 aspect ratio
    const double maxCardSize = 400.0;
    final double cardSize = screenWidth > maxCardSize ? maxCardSize : screenWidth * 0.9;

    // Scale factor based on card size
    final double scaleFactor = cardSize / maxCardSize;

    String getProductImageUrl() {
      try {
        final media = ownProductData.product.details?.media;
        if (media != null && media.isNotEmpty) {
          return media.first;
        }
        return '';
      } catch (e) {
        debugPrint('Error getting product image: $e');
        return '';
      }
    }

    final String productImageUrl = getProductImageUrl();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: RepaintBoundary(
          key: cardKey,
          child: Container(
            height: cardSize,
            width: cardSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              image: DecorationImage(
                image: AssetImage(backgroundAsset),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Product Image and Details Section
                Positioned(
                  top: cardSize * 0.2,
                  left: cardSize * 0.09,
                  right: cardSize * 0.05,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Container(
                        width: cardSize * 0.35,
                        height: cardSize * 0.48,
                        margin: EdgeInsets.only(right: 8 * scaleFactor),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8 * scaleFactor),
                          child: productImageUrl.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: productImageUrl,
                            width: cardSize * 0.35,
                            height: cardSize * 0.48,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ClipRRect(
                              borderRadius: BorderRadius.circular(8.0 * scaleFactor),
                              child: LocalAssets(
                                imagePath:
                                AppIconAssets.place_holder_image,
                                boxFix: BoxFit.fill,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: LocalAssets(
                                    imagePath:
                                    AppIconAssets.place_holder_image,
                                    boxFix: BoxFit.fill,
                                  ),
                                ),
                          ) : LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.fill,
                          ),
                        ),
                      ),

                      // Product Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              ownProductData.product.details?.name,
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.w600,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              fontSize: 16 * scaleFactor,
                              height: 1.2,
                            ),
                            SizedBox(height: 4 * scaleFactor),
                            CustomText(
                              "${ownProductData.product.details?.description ?? ''}",
                              color: AppColors.grayText,
                              fontWeight: FontWeight.w400,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              fontSize: 11 * scaleFactor,
                              height: 1.2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Price Section(MRP)
                Positioned(
                  top: cardSize * 0.49,
                  left: cardSize * 0.5,
                  right: cardSize * 0.05,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      CustomText(
                        "MRP: ",
                        color: AppColors.secondaryTextColor,
                        fontSize: 13 * scaleFactor,
                        fontWeight: FontWeight.w700
                      ),

                      // Original Price
                      CustomText(
                        // "₹ 1000000",
                        "₹ ${ownProductData.product.sellerClassification?.variants[0].mrp}",
                        color: AppColors.secondaryTextColor,
                        fontSize: 13 * scaleFactor,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                        decorationStyle: TextDecorationStyle.solid,
                        decorationColor: AppColors.red,
                      ),
                    ],
                  ),
                ),

                // Price Section(SELLING PRICE)
                Positioned(
                  top: cardSize * 0.6,
                  left: cardSize * 0.49,
                  right: cardSize * 0.05,
                  child: Stack(
                    children: [
                      Text(
                        // '₹ 1000000"',
                        '₹ ${ownProductData.product.sellerClassification?.variants[0].sellingPrice}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18 * scaleFactor,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 1
                            ..color = AppColors.primaryColor,
                        ),
                      ),
                      CustomText(
                        '₹ ${ownProductData.product.sellerClassification?.variants[0].sellingPrice}',
                        color: AppColors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 18 * scaleFactor,
                      ),
                    ],
                  ),
                ),

                // DISCOUNT
                Positioned(
                  top: cardSize * 0.55,
                  left: cardSize * 0.75,
                  right: cardSize * 0.05,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${calculateDiscount(
                          ownProductData.product.sellerClassification?.variants[0].sellingPrice.toString() ?? "0",
                          ownProductData.product.sellerClassification?.variants[0].mrp.toString() ?? "0",
                        ).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryTextColor,
                          fontSize: 13 * scaleFactor,
                        ),
                      ),
                      Text(
                        'OFF',
                        style: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13 * scaleFactor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Store Info Section
                Positioned(
                  top: cardSize * 0.77,
                  left: cardSize * 0.05,
                  right: cardSize * 0.05,
                  child: Row(
                    children: [
                      CachedAvatarWidget(
                        imageUrl: userProfileGlobal,
                        size: 36 * scaleFactor,
                        borderRadius: 17.5 * scaleFactor,
                        borderColor: AppColors.white,
                      ),
                      SizedBox(width: 8 * scaleFactor),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Text(
                                  businessNameGlobal,
                                  style: TextStyle(
                                    fontSize: 20 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 2
                                      ..color = AppColors.yellow,
                                  ),
                                ),
                                Text(
                                  businessNameGlobal,
                                  style: TextStyle(
                                    fontSize: 20 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            CustomText(
                              businessSubCategoryGlobal,
                              color: AppColors.secondaryTextColor,
                              fontSize: 11 * scaleFactor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            CustomText(
                              "$businessOwnerNameGlobal (Owner)",
                              color: AppColors.secondaryTextColor,
                              fontSize: 11 * scaleFactor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Location Footer
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.whiteFade.withValues(alpha: 0.30),
                      gradient: const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          AppColors.purpleOut,
                          AppColors.orangeOut,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    height: cardSize * 0.09,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.darkBrown,
                          size: 14 * scaleFactor,
                        ),
                        SizedBox(width: 4 * scaleFactor),
                        Flexible(
                          child: Text(
                            businessOwnerAddressGlobal,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.darkBrown,
                              fontSize: 12 * scaleFactor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



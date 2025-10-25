import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SharingBusinessServiceCard extends StatelessWidget {
  final GlobalKey cardKey;
  final GetServiceModel serviceData;
  final String backgroundAsset;

  const SharingBusinessServiceCard({
    super.key,
    required this.cardKey,
    required this.serviceData,
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
        final media = serviceData.photos;
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
                  left: cardSize * 0.07,
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
                              serviceData.title,
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.w600,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              fontSize: 16 * scaleFactor,
                              height: 1.2,
                            ),
                            SizedBox(height: 8 * scaleFactor),
                            CustomText(
                              "${serviceData.description ?? ''}",
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

                Positioned(
                  top: cardSize * 0.4,
                  left: cardSize * 0.44,
                  right: cardSize * 0.04,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "${serviceData.facilities?.join(',')}",
                        fontSize: 12 * scaleFactor,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            CustomText(
                              "Open :",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.green39,

                            ),
                            CustomText(
                              "${serviceData.timings?[0].start}",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.grayText,
                              maxLines: 1,
                            ),
                            CustomText(
                              " Close :",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.red,

                              maxLines: 1,
                            ), CustomText(
                              "${serviceData.timings?[0].end}",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.grayText,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Text(
                                  "₹${serviceData.priceRange?.min} -${serviceData.priceRange?.max}",
                                  style: TextStyle(
                                      fontSize: SizeConfig.large,
                                      fontWeight: FontWeight.w900,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 0.5
                                        ..color = AppColors.primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Text(
                                  "₹${serviceData.priceRange?.min} -${serviceData.priceRange?.max}",
                                  style: TextStyle(
                                    fontSize: SizeConfig.large,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.secondaryTextColor
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                            CustomText(
                              "/${serviceData.perUnit}",
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),

                          ],
                        ),
                      ),

                    ],
                  ),
                ),

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
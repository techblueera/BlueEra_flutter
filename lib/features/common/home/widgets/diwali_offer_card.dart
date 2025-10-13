import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_own_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class DiwaliOfferCard extends StatelessWidget {
  final GlobalKey cardKey;
  final OwnProductData ownProductData;
  final String backgroundAsset;
  final int index;
  const DiwaliOfferCard(
      {
        super.key,
        required this.cardKey,
        required this.ownProductData,
        required this.backgroundAsset,
        required this.index
      });


  @override
  Widget build(BuildContext context) {
    // Define relative dimensions for the card based on screen size
    final screenWidth = MediaQuery.of(context).size.width;

    // Set a max width and a proportional height for the card
    // The design is fixed, so we'll cap the card size for larger screens.
    const double maxCardWidth = 400.0;
    const double cardRatio = 1.25; // H/W ratio (approx 5:4)
    final double cardWidth = screenWidth > maxCardWidth ? maxCardWidth : screenWidth * 0.9;
    final double cardHeight = cardWidth * cardRatio;

    // Scale factor for text and minor elements based on card width
    final double scaleFactor = cardWidth / maxCardWidth;
    return Scaffold(
      backgroundColor: AppColors.white, // Light background for contrast
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: RepaintBoundary(
            key: cardKey,
            child: Container(
              height: 420,
              width: SizeConfig.screenWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                image: DecorationImage(
                  image: AssetImage(backgroundAsset),
              fit: BoxFit.cover,          // choose the fit you need
            ),
              ),
              child: Stack(
                clipBehavior: Clip.none, // Allows the '50% Off' badge to overflow
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: cardHeight * 0.15, // Proportional vertical position
                    left: 38 * scaleFactor,
                    right: 20 * scaleFactor,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phone Image Placeholder (mimics mobile.png)
                        Container(
                          width: cardWidth * 0.37,
                          height: cardWidth * 0.52,
                          margin: EdgeInsets.only(right: 10 * scaleFactor),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(
                                    ownProductData.product.details?.media[index]??''
                                )
                            ),
                            borderRadius: BorderRadius.circular(8 * scaleFactor),
                          ),
                          // Mock Camera bump for detail
              
                        ),
              
                        // Price Details Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                ownProductData.product.details?.name,
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.w600,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                fontSize: 17 * scaleFactor,
                                height: 1.3,
                              ),
                              SizedBox(height: 2 * scaleFactor),
                              CustomText(
                                "${ownProductData.product.details?.description??''}",
                                // style: TextStyle(
                                color: AppColors.grayText,
                                fontWeight: FontWeight.w400,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                fontSize: 12 * scaleFactor,
                                height: 1.3,
                                // ),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),


                  Positioned(
                      top: cardHeight * 0.415, // Proportional vertical position
                      left: cardWidth/1.9 * scaleFactor,
                      right: cardWidth/3.3 * scaleFactor,
                      child: CustomText(
                        "₹ ${ownProductData.product.sellerClassification?.variants[0].mrp}",
                        // style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14 * scaleFactor,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                        decorationStyle: TextDecorationStyle.solid,
                        decorationColor: AppColors.red,
                        // ),
                      ),
                  ),

                  Positioned(
                      top: cardHeight * 0.5, // Proportional vertical position
                      left: cardWidth/1.9 * scaleFactor,
                      right: cardWidth/3.3 * scaleFactor,
                      child: Stack(
                        children: [
                          Text(
                            '₹ ${ownProductData.product.sellerClassification?.variants[0].sellingPrice}',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20 * scaleFactor,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 1
                                  ..color = AppColors.primaryColor
                            ),
                          ),
                          CustomText(
                            '₹ ${ownProductData.product.sellerClassification?.variants[0].sellingPrice}',
                            color: AppColors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 20 * scaleFactor,
                          )
                        ],
                      ),
                  ),


                  Positioned(
                    top: cardHeight * 0.47, // Proportional vertical position
                    left: cardWidth/1.18 * scaleFactor,
                    // right: cardWidth/1.1 * scaleFactor,
                    child:  Column(
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
                             fontSize: 14 * scaleFactor
                         ),
                        ),
                        Text(
                          'OFF',
                          style: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14 * scaleFactor
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: cardHeight * 0.65,
                    left: 38 * scaleFactor,
                    right: 16 * scaleFactor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Store Logo and Name Column
                        Row(
                          children: [
                            // Store Logo Placeholder
                            CachedAvatarWidget(
                              imageUrl: userProfileGlobal,
                              size: 40 * scaleFactor,
                              borderRadius: 20 * scaleFactor,
                              borderColor: AppColors.white,
                            ),
                            SizedBox(width: 10 * scaleFactor),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Text(
                                      businessNameGlobal,
                                      style: TextStyle(
                                        fontSize: 24 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 2
                                          ..color = AppColors.yellow, // outline
                                      ),
                                    ),
                                    Text(
                                      businessNameGlobal,
                                      style: TextStyle(
                                        fontSize: 24 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor, // fill
                                      ),
                                    ),
                                  ],
                                ),

                                CustomText(
                                  businessSubCategoryGlobal,
                                  color: AppColors.secondaryTextColor,
                                  fontSize: 12 * scaleFactor,
                                ),
                                SizedBox(height: 1 * scaleFactor),
                                CustomText(
                                  " $businessOwnerNameGlobal (Owner)",
                                  color: AppColors.secondaryTextColor,
                                  fontSize: 12 * scaleFactor,
                                  // fontWeight: FontWeight.w600,
                                ),

                                // SizedBox(
                                //   width: cardWidth * 0.5,
                                //   child: Row(
                                //     children: [
                                //       Expanded(
                                //         child: CustomText(
                                //           businessSubCategoryGlobal,
                                //           color: AppColors.secondaryTextColor,
                                //           fontSize: 12 * scaleFactor,
                                //         ),
                                //       ),
                                //       CustomText(
                                //         " $businessOwnerNameGlobal (Owner)",
                                //         color: AppColors.mainTextColor,
                                //         fontSize: 12 * scaleFactor,
                                //         fontWeight: FontWeight.w600,
                                //       ),
                                //     ],
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              
                  // 6. Location at the bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppColors.whiteFade.withValues(alpha: 0.30),
                          gradient: const LinearGradient(
                            begin: Alignment.centerRight, // start from right
                            end: Alignment.centerLeft, // end to left
                            colors: [
                              AppColors.purpleOut, // Example purple
                              AppColors.orangeOut, // Example blue
                            ],
                          ),
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10))
                      ),
                      height: 35,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: AppColors.darkBrown, size: 16),
                          SizedBox(width: 5 * scaleFactor),
                          Text(
                            businessOwnerAddressGlobal,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkBrown,
                              fontSize: 14 * scaleFactor,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}



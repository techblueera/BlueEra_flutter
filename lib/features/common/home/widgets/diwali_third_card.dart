import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_own_product_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class DiwaliOfferThirdCard extends StatelessWidget {
  final GlobalKey cardKey;
  final OwnProductData ownProductData;
  final int index;
  const DiwaliOfferThirdCard({super.key, required this.cardKey, required this.ownProductData, required this.index});

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
            child: Stack(
              clipBehavior: Clip.none, // Allows the '50% Off' badge to overflow
              alignment: Alignment.topCenter,
              children: [
                Image.asset('assets/diwali_card/cardbg3.png'),
                Positioned(
                  top: cardHeight * 0.15, // Proportional vertical position
                  left: 20 * scaleFactor,
                  right: 20 * scaleFactor,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phone Image Placeholder (mimics mobile.png)
                      Container(
                        width: cardWidth * 0.35,
                        height: cardWidth * 0.42,
                        margin: EdgeInsets.only(right: 10 * scaleFactor),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(
                                  ownProductData.product.details?.media[index]??''
                              )
                          ),
                          borderRadius: BorderRadius.circular(15 * scaleFactor),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.black.withOpacity(0.3),
                          //     blurRadius: 8 * scaleFactor,
                          //     offset: const Offset(0, 4),
                          //   ),
                          // ],
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
                              // style: TextStyle(
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.w600,
                              fontSize: 17 * scaleFactor,
                              height: 1.3,
                              // ),
                            ),
                            SizedBox(height: 2 * scaleFactor),
                            CustomText(
                              ownProductData.product.details?.description,
                              // style: TextStyle(
                              color: AppColors.grayText,
                              fontWeight: FontWeight.w400,
                              fontSize: 12 * scaleFactor,
                              height: 1.3,
                              // ),
                            ),
                            SizedBox(height: 6 * scaleFactor),

                            Row(mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10 * scaleFactor,
                                      horizontal: 10 * scaleFactor),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,

                                  ),

                                  child: Column(
                                    children: [
                                      CustomText(
                                        "MRP : ${ownProductData.product.sellerClassification?.variants[0].mrp.toString() ?? "0"} ",
                                        // style: TextStyle(
                                        color: AppColors.blackFade,
                                        fontSize: 12 * scaleFactor,
                                        fontWeight: FontWeight.w400,
                                        decoration: TextDecoration.lineThrough,
                                        decorationStyle: TextDecorationStyle.solid,
                                        decorationColor: Colors.white,
                                        // ),
                                      ),
                                      const SizedBox(height: 4,),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          gradient: const LinearGradient(
                                            begin: Alignment.centerRight, // start from right
                                            end: Alignment.centerLeft, // end to left
                                            colors: [
                                              AppColors.purpleOut, // Example purple
                                              AppColors.orangeOut, // Example blue
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CustomText(
                                              "Only :",
                                              // style: TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 14 * scaleFactor,
                                              // ),
                                            ),
                                            SizedBox(width: 8 * scaleFactor),
                                            CustomText(
                                              ownProductData.product.sellerClassification?.variants[0].sellingPrice.toString() ?? "0",
                                              // style: TextStyle(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16 * scaleFactor,
                                              // ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Discount Badge: "50% Off" (Positioned to overlap)
                Positioned(
                  top: cardHeight * 0.33, // Adjust to overlap the product and price
                  left: cardWidth * 0.32,
                  child: Stack(
                    children: [
                      Image.asset('assets/diwali_card/flower.png',
                      height: 100,width: 120,),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4 * scaleFactor,
                          vertical: 8 * scaleFactor,
                        ),
                        width: 122,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 20 * scaleFactor),
                            Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: Text(
                                    'BIGGEST',
                                    style: TextStyle(
                                      fontFamily: "Vector",
                                      color: const Color(0xFFFF6B00), // AppColors.darkOrange
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9 * scaleFactor,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2,),
                            Text(
                              'DIWALI SALE',
                              style: TextStyle(
                                color: AppColors.black, // AppColors.darkOrange
                                fontWeight: FontWeight.w900,
                                fontSize: 6.5 * scaleFactor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2,),
                            Text(
                              '${calculateDiscount(
                            ownProductData.product.sellerClassification?.variants[0].sellingPrice.toString() ?? "0",
                            ownProductData.product.sellerClassification?.variants[0].mrp.toString() ?? "0",
                            ).toStringAsFixed(2)}%OFF',
                              style: TextStyle(
                                fontFamily: "Vector",
                                color: AppColors.darkBrown, // AppColors.darkOrange
                                fontWeight: FontWeight.w900,
                                fontSize: 14 * scaleFactor,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 Inner Shadow Overlay

                    ],
                  ),
                ),

                // 4. App Promotion Section: "Only On - BlueEra Super App"
                Positioned(
                  top: cardHeight * 0.48,
                  left: 0,
                  right: 0,
                  child:
                ClipRRect(
                    borderRadius: BorderRadius.circular(10 * scaleFactor),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // blur intensity
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 10 * scaleFactor,
                  horizontal: 8 * scaleFactor,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: 12 * scaleFactor,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10 * scaleFactor),
                  color: Colors.white.withOpacity(0.55), // translucent white

                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 6 * scaleFactor,
                      spreadRadius: 1 * scaleFactor,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      "Only On -",
                      color: AppColors.grayText,
                      fontSize: 14 * scaleFactor,
                      fontWeight: FontWeight.w800,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 25 * scaleFactor,
                          height: 25 * scaleFactor,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20 * scaleFactor),
                            image: const DecorationImage(
                              image: AssetImage("assets/diwali_card/blueera.png"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        CustomText(
                          "BlueEra",
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 17 * scaleFactor,
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: CustomText(
                            "Super App",
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12 * scaleFactor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Image.asset("assets/diwali_card/playstore.png"),
                        const SizedBox(width: 12),
                        Image.asset("assets/diwali_card/appstore.png"),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          ,
                ),

                // 5. Store/Owner Info and CTA (combined row)
                Positioned(
                  top: cardHeight * 0.582,
                  left: 16 * scaleFactor,
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
                              CustomText(
                                businessNameGlobal,
                                // style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15 * scaleFactor,
                                // ),
                              ),
                              SizedBox(height: 2 * scaleFactor),
                              CustomText(
                                "$businessOwnerNameGlobal (Owner)",
                                // style: TextStyle(
                                color: AppColors.grayText,
                                fontSize: 12 * scaleFactor,
                                // ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // CTA Button: "Visit My Store Via Link Below"
                      Container(
                        padding:
                        EdgeInsets.symmetric(vertical: 8 * scaleFactor, horizontal: 12 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10 * scaleFactor),
                          border: Border.all(color: Colors.blueAccent, width: 2 * scaleFactor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2 * scaleFactor,
                            ),
                          ],
                        ),
                        child: Text(
                          "Visit My Store\nVia Link Below",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13 * scaleFactor,
                            height: 1.2,
                          ),
                        ),
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
                      color: AppColors.whiteFade.withOpacity(0.30),
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
                    height: 45,
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
    );
  }
}

// A simple main function to allow testing this class

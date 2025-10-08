import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';



class DiwaliOfferSecondCardScreen extends StatelessWidget {
  const DiwaliOfferSecondCardScreen({super.key});

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
      backgroundColor: const Color(0xFFF0F0F0), // Light background for contrast
      body: Center(
        child: Stack(
          clipBehavior: Clip.none, // Allows the '50% Off' badge to overflow
          alignment: Alignment.topCenter,
          children: [
            Image.asset('assets/diwali_card/cardbg2.png'),
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
                    height: cardWidth * 0.35,
                    margin: EdgeInsets.only(right: 10 * scaleFactor),
                    decoration: BoxDecoration(
                      // color: _kPhoneColor,
                      image: DecorationImage(image: AssetImage("assets/diwali_card/mobile.png")),
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
                          "iPhone 16 128 GB: 5G Mobile Phone with Camera Control",
                          // style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w600,
                          fontSize: 17 * scaleFactor,
                          height: 1.3,
                          // ),
                        ),
                        SizedBox(height: 2 * scaleFactor),

                        // MRP
                        Row(mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomText(
                              "MRP :  ₹2,40,000 ",
                              // style: TextStyle(
                              color: AppColors.blackFade,
                              fontSize: 12 * scaleFactor,
                              fontWeight: FontWeight.w400,
                              // decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white,
                              // ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8 * scaleFactor),

                        // Our Price Box
                        Row(mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 3 * scaleFactor,
                                  horizontal: 12 * scaleFactor),
                              decoration: BoxDecoration(
                                color: AppColors.whiteFade.withOpacity(0.30),
                                borderRadius: BorderRadius.circular(10 * scaleFactor),
                                border: Border.all(color: AppColors.redBorder, width: 1 * scaleFactor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 4 * scaleFactor,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    "Our \nPrice",
                                    // style: TextStyle(
                                    color: AppColors.greyOut,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12 * scaleFactor,
                                    // ),
                                  ),
                                  SizedBox(width: 5 * scaleFactor),
                                  // Vertical Separator (mimicked with a SizedBox and color)
                                  Container(
                                    width: 1,
                                    height: 15 * scaleFactor,
                                    color: AppColors.greyOut,
                                  ),
                                  SizedBox(width: 5 * scaleFactor),
                                  CustomText(
                                    "₹1,20,000",
                                    // style: TextStyle(
                                    color: AppColors.blackFade,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16 * scaleFactor,
                                    // ),
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
              top: cardHeight * 0.30, // Adjust to overlap the product and price
              left: cardWidth * 0.32,
              child: Stack(
                children: [
                  // 🔹 Background Container
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4 * scaleFactor,
                      vertical: 8 * scaleFactor,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(8 * scaleFactor),
                      border: Border.all(color:  AppColors.redBorder, width: 1.3 * scaleFactor),
                      boxShadow: [
                        // Outer shadow (still looks raised)
                        BoxShadow(
                          color:  AppColors.redBorder.withOpacity(0.2),
                          blurRadius: 10 * scaleFactor,
                          offset: Offset(2 * scaleFactor, 2 * scaleFactor),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "50",
                              style: TextStyle(
                                color: const Color(0xFFFF6B00), // AppColors.darkOrange
                                fontWeight: FontWeight.w900,
                                fontSize: 32 * scaleFactor,
                                height: 1,
                              ),
                            ),
                            SizedBox(width: 2 * scaleFactor),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "%",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18 * scaleFactor,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  "Off",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18 * scaleFactor,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 🔹 Inner Shadow Overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8 * scaleFactor),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.redBorder.withOpacity(0.1),
                              Colors.transparent,
                              Colors.transparent,
                              AppColors.redBorder.withOpacity(0.1),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. App Promotion Section: "Only On - BlueEra Super App"
            Positioned(
              top: cardHeight * 0.45,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: 6 * scaleFactor,
                    horizontal: 8 * scaleFactor),
                margin: EdgeInsets.symmetric(
                    vertical: 3 * scaleFactor,
                    horizontal: 20 * scaleFactor),
                decoration: BoxDecoration(
                  color: AppColors.whiteFade.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(10 * scaleFactor),
                  border: Border.all(color:  AppColors.redBorder, width: 1 * scaleFactor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 4 * scaleFactor,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                        "Only On -",
                        // style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * scaleFactor,
                        fontWeight: FontWeight.w500
                      // ),
                    ),
                    SizedBox(width: 6 * scaleFactor),
                    // BlueEra Logo Placeholder (mimics blueera.png)


                    Row(crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 25 * scaleFactor,
                          height: 25 * scaleFactor,
                          decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(20 * scaleFactor),
                              image: DecorationImage(image: AssetImage("assets/diwali_card/blueera.png"))
                          ),
                        ),
                        const SizedBox(width: 6,),
                        CustomText(
                          "BlueEra",
                          // style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 17 * scaleFactor,
                          // ),
                        ),
                        const SizedBox(width: 4,),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: CustomText(
                            "Super App",
                            // style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12 * scaleFactor,
                            // ),
                          ),
                        ),
                      ],
                    ),
                    // SizedBox(width: 8 * scaleFactor),
                    Row(
                      children: [
                        Image.asset("assets/diwali_card/playstore.png"),
                        SizedBox(width: 8,),
                        Image.asset("assets/diwali_card/appstore.png"),
                        SizedBox(width: 4,)
                      ],
                    ),
                    // _buildStoreIcon(Icons.play_arrow), // Play Store Icon
                    // SizedBox(width: 4 * scaleFactor),
                    // _buildStoreIcon(Icons.apple), // App Store Icon
                  ],
                ),
              ),
            ),

            // 5. Store/Owner Info and CTA (combined row)
            Positioned(
              top: cardHeight * 0.555,
              left: 20 * scaleFactor,
              right: 20 * scaleFactor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Store Logo and Name Column
                  Row(
                    children: [
                      // Store Logo Placeholder
                      Container(
                        width: 40 * scaleFactor,
                        height: 40 * scaleFactor,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2 * scaleFactor),
                        ),
                        child: Center(
                          child: CustomText("PS",
                              // style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor
                            // )
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * scaleFactor),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            "Pervez Mobile Shop",
                            // style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15 * scaleFactor,
                            // ),
                          ),
                          SizedBox(height: 2 * scaleFactor),
                          CustomText(
                            "Ramesh Kumar (Owner)",
                            // style: TextStyle(
                            color: Colors.black.withOpacity(0.8),
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
                color: AppColors.whiteFade.withOpacity(0.30),
                height: 45,
                margin: EdgeInsets.symmetric(
                    vertical: 3 * scaleFactor,
                    horizontal: 8 * scaleFactor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: AppColors.darkBrown, size: 16),
                    SizedBox(width: 5 * scaleFactor),
                    Text(
                      "Durgapur, West Bengal - Industrial Area",
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
    );
  }
}

// A simple main function to allow testing this class

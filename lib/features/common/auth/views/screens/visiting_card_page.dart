import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class VisitingCard extends StatelessWidget {
  GlobalKey cardKey = GlobalKey();
  VisitingCard({super.key, required this.cardKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: RepaintBoundary(
          key: cardKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = constraints.maxWidth * 0.9;

              // Dynamic font size scaling
              double baseFont = cardWidth * 0.035; // scales with width
              if (baseFont > 22) baseFont = 22; // cap max
              if (baseFont < 12) baseFont = 12; // cap min

              return Container(
                width: cardWidth,
                margin: const EdgeInsets.all(2),
                // 👇 height removed, wraps content
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage(AppImageAssets.visitingCardBg), // local asset
                    fit: BoxFit.cover,
                  ),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: AppColors.white,
                  //     blurRadius: 4
                  //   )
                  // ]
                ),
                padding: EdgeInsets.all(baseFont * 0.6),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 👈 makes card height fit content
                  children: [
                    /// Top Row (Profile + Name + Right Box)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// LEFT SIDE (Profile + Text + Quote Box)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CachedAvatarWidget(
                                    imageUrl: userProfileGlobal,
                                    size: baseFont * 1.8 * 2,
                                    borderRadius: baseFont * 1.8,
                                    borderColor: AppColors.white,
                                  ),
                                  SizedBox(width: baseFont * 0.6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (accountTypeGlobal.toUpperCase() == AppConstants.individual) ? userNameGlobal : businessOwnerNameGlobal,
                                        style: TextStyle(
                                          fontSize: baseFont + 6,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.mainTextColor,
                                        ),
                                      ),
                                      Text(
                                        (accountTypeGlobal.toUpperCase() == AppConstants.individual) ? userProfessionGlobal : businessNameGlobal,
                                        style: TextStyle(
                                          fontSize: baseFont,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: baseFont * 0.8),

                              /// Quote Box
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: baseFont * 0.8,
                                    vertical: baseFont * 0.6,
                                 ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.grey5B,
                                      width: 1.5
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: baseFont,
                                      color: AppColors.black,
                                      height: 1.4,
                                    ),
                                    children: [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.top,
                                        child: LocalAssets(
                                            imagePath: AppImageAssets.leftQuotation,
                                            height: baseFont * 0.8,
                                            width: baseFont * 0.8
                                        ),
                                      ),

                                      const TextSpan(text: " दोस्तों,\n"),
                                      const TextSpan(
                                          text: "मैंने स्वदेशी सोशल मीडिया ऐप "),
                                      TextSpan(
                                        text: "BlueEra ",
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(
                                          text:
                                          "जॉइन किया है और मैं आपका वहाँ पर इंतज़ार और स्वागत करता हूँ – जय भारत\n",
                                      ),
                                      WidgetSpan(
                                        child: SizedBox(height: baseFont * 1.8), // adjust spacing as needed
                                      ),
                                      const TextSpan(text: "अभी "),
                                      TextSpan(
                                        text: "Download ",
                                        style: TextStyle(color: AppColors.primaryColor),
                                      ),
                                      const TextSpan(text: "करें "),
                                      TextSpan(
                                        text: "Play Store ",
                                        style: TextStyle(color: AppColors.primaryColor),
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: LocalAssets(
                                          imagePath: AppImageAssets.playStore,
                                          height: baseFont * 1.1,
                                          width: baseFont * 1.1
                                        ),
                                      ),
                                      const TextSpan(text: " या "),
                                      TextSpan(
                                        text: "App Store ",
                                        style: TextStyle(color: AppColors.primaryColor),
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: LocalAssets(
                                            imagePath: AppImageAssets.appStore,
                                            height: baseFont * 1.1,
                                            width: baseFont * 1.1
                                        ),
                                      ),
                                      const TextSpan(text: " या नीचे दिए गए "),
                                      TextSpan(
                                        text: "Link ",
                                        style: TextStyle(color: AppColors.primaryColor),
                                      ),
                                      const TextSpan(text: "से "),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.bottom,
                                        child: LocalAssets(
                                            imagePath: AppImageAssets.rightQuotation,
                                            height: baseFont * 0.8,
                                            width: baseFont * 0.8
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: baseFont * 0.6),

                        /// RIGHT SIDE (Gradient Box)
                        Expanded(
                          flex: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 15.0, // horizontal blur strength
                                sigmaY: 15.0, // vertical blur strength
                              ),
                              child: Container(
                                padding: EdgeInsets.all(baseFont * 0.6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF742F),
                                      Color(0xFFFFDAC7),
                                      Color(0xFFFFEADF),
                                      Color(0xFFFFF5F0),
                                      Color(0xFFFFFFFF),
                                      Color(0xFFD9F2DA),
                                      Color(0xFFBAE8BC),
                                      Color(0xFF8ED992),
                                      Color(0xFF00A908),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min, // 👈 keeps box compact
                                  children: [
                                    const Text("🇮🇳", style: TextStyle(fontSize: 32)),
                                    SizedBox(height: baseFont * 0.5),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "Jai Bharat",
                                        style: TextStyle(
                                          fontSize: baseFont + 2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: baseFont * 0.6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Stack(
                                        children: [
                                          // White border text
                                          Text(
                                            "ये देश मेरा, ",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: baseFont,
                                              fontWeight: FontWeight.w600,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = baseFont * 0.15   // thickness of border
                                                ..color = Colors.white, // border color
                                            ),
                                          ),
                                          // Fill text
                                          Text(
                                            "ये देश मेरा, ",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: baseFont,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.deepOrange, // main text color
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Stack(
                                        children: [
                                          // White border text
                                          Text(
                                            "कंटेंट और पोस्ट मेरा,",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: baseFont,
                                              fontWeight: FontWeight.w600,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = baseFont * 0.15   // thickness of border
                                                ..color = Colors.white, // border color
                                            ),
                                          ),
                                          // Fill text
                                          Text(
                                            "कंटेंट और पोस्ट मेरा,",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: baseFont,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.deepOrange, // main text color
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: baseFont * 0.5),


                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Stack(
                                        children: [
                                          Text(
                                            "देखने वाले लोग मेरे,",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: baseFont,
                                              fontWeight: FontWeight.w600,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = baseFont * 0.18   // thickness of border
                                                ..color = Colors.white, // border color
                                            ),
                                          ),
                                          Text(
                                            "देखने वाले लोग मेरे,",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: baseFont,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0025F9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Stack(
                                        children: [
                                          Text(
                                            "तो अब ऐप भी मेरा –",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: baseFont,
                                              fontWeight: FontWeight.w600,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = baseFont * 0.15 // thickness of border
                                                ..color = AppColors.white,
                                            ),
                                          ),
                                          Text(
                                            "तो अब ऐप भी मेरा –",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: baseFont,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: baseFont * 0.2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Stack(
                                        children: [
                                          Text(
                                            "BlueEra",
                                            style: TextStyle(
                                              fontSize: baseFont + 2,
                                              fontWeight: FontWeight.bold,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = baseFont * 0.15   // thickness of border
                                                ..color = Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "BlueEra",
                                            style: TextStyle(
                                              fontSize: baseFont + 2,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: baseFont * 0.2),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: baseFont * 0.6),

                    /// Footer Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "👇Click on Download Link",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: baseFont,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "स्वदेशी अपनाओ",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: baseFont + 6,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiscoverBannerSlider extends StatefulWidget {
  final ScrollController parentScrollController;
  final GlobalKey targetKey;

  const DiscoverBannerSlider({
    super.key,
    required this.parentScrollController,
    required this.targetKey,
  });

  @override
  State<DiscoverBannerSlider> createState() => _DiscoverBannerSliderState();
}

class _DiscoverBannerSliderState extends State<DiscoverBannerSlider> {
  int currentPage = 0;

  // final List<Map<String, String>> sliderData = const [
  //   {"slugId": "FRANCHISE", "image": "https://img.freepik.com/premium-photo/modern-technology-digital-marketing-colorful-abstract-background-with-icons-lines_1355276-4857.jpg?semt=ais_hybrid&w=740&q=80"},
  //   {"slugId": "FRANCHISE", "image": "https://img.freepik.com/free-photo/corporate-management-strategy-solution-branding-concept_53876-167088.jpg?semt=ais_hybrid&w=740&q=80"},
  // ];

  final List<Map<String, String>> sliderData = [
    {"slugId": "FRANCHISE", "image": "assets/images/ban3.jpeg"},
    {"slugId": "BDM", "image": "assets/images/ban2.jpeg"},
    {"slugId": "QR", "image":"assets/images/ban1.jpeg"},
  ];
  // "assets/images/ban1.jpeg"
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Carousel — full bleed, auto-scroll, covers status bar + notch
        CarouselSlider.builder(
          itemCount: sliderData.length,
          options: CarouselOptions(
            aspectRatio: 4 / 3,
            viewportFraction: 1.0,
            autoPlay: true,

            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
            enableInfiniteScroll: sliderData.length > 1,
            scrollPhysics: sliderData.length > 1
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onPageChanged: (index, reason) {
              setState(() {
                currentPage = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final data = sliderData[index];
            return InkWell(
              onTap: () => _handleOnTap(data['slugId']!),
              child: LocalAssets(
                imagePath:data["image"]!,
                // imagePath:"assets/images/ban1.jpeg",
                boxFix: BoxFit.contain,
              ),
            );

            return InkWell(
              onTap: () => _handleOnTap(data['slugId']!),
              child: NetWorkOcToAssets(
                imgUrl: data["image"]!,
                boxFit: BoxFit.cover,
              ),
            );
          },
        ),

       /* /// DOT INDICATOR overlaid at bottom of banner
        if (sliderData.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                sliderData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: currentPage == index ? 20 : 6,
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),*/
      ],
    );
  }

  void _handleOnTap(String slugId) {
    switch (slugId) {
      case 'FRANCHISE':
        Get.to(() => const FranchiseHome());
        break;
      case 'BDM':
        Get.to(() => const ReferralPage());
        break;
      case 'QR':
        Scrollable.ensureVisible(
          widget.targetKey.currentContext!,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
        break;
    }
  }
}

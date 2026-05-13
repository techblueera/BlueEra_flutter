import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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

  final List<Map<String, String>> sliderData = [
    {"slugId": "FRANCHISE", "image": "assets/images/ban3.jpeg"},
    {"slugId": "BDM", "image": "assets/images/ban2.jpeg"},
    {"slugId": "QR", "image":"assets/images/ban1.jpeg"},
  ];
  @override
  Widget build(BuildContext context) {
    final double bannerHeight = (MediaQuery.of(context).size.width * 3 / 4);
    return Container(
      color: AppColors.blue5CAF.withValues(alpha: 0.1),
      child: Stack(
        children: [
          /// Carousel — full bleed, auto-scroll, covers status bar + notch
          CarouselSlider.builder(
            itemCount: sliderData.length,
            options: CarouselOptions(
              height: bannerHeight,
              viewportFraction: 1.0,
              // autoPlay: false,
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
                child: SizedBox(
                  width: double.infinity,
                  height: bannerHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.0)),
                    child: LocalAssets(
                      imagePath: data["image"]!,
                      boxFix: BoxFit.cover,
                    ),
                  ),
                ),
              );

            },
          ),

        ],
      ),
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

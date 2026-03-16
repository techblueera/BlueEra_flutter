import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiscoverBannerPage extends StatefulWidget {
  final GlobalKey targetKey;

  const DiscoverBannerPage({
    super.key,
    required this.targetKey,
  });

  @override
  State<DiscoverBannerPage> createState() => _DiscoverBannerPageState();
}

class _DiscoverBannerPageState extends State<DiscoverBannerPage> {
  int currentPage = 0;

  final List<Map<String, String>> sliderData = const [
    {"slugId": "FRANCHISE", "image": AppImageAssets.franchiseBanner},
    {"slugId": "BDM", "image": AppImageAssets.bdmBanner},
    {"slugId": "QR", "image": AppImageAssets.qrBanner},
  ];

  // Inside _DiscoverBannerPageState
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth * 0.9;
        final double sidePadding = (constraints.maxWidth - cardWidth) / 2;

        return CustomFormCard(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // This is important
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    setState(() {
                      currentPage = (notification.metrics.pixels / cardWidth).round();
                    });
                  }
                  return true;
                },
                // ADD THIS BOX: It prevents the 'Infinite Size' error in Slivers
                child: SizedBox(
                  height: 200, // Or calculate based on width: constraints.maxWidth * 0.5
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const PageScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: sidePadding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Makes items fill the 200 height
                      children: sliderData.map((data) {
                        return GestureDetector(
                          onTap: () => _handleOnTap(data['slugId']!),
                          child: Container(
                            width: cardWidth,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: LocalAssets(
                                imagePath: data["image"]!,
                                width: cardWidth,
                                boxFix: BoxFit.cover, // Use cover to fill the sized box
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildIndicator(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndicator(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        sliderData.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? AppColors.primaryColor
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
        final context = widget.targetKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
        break;
    }
  }
}
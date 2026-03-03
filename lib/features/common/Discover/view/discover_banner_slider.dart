import 'dart:async';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiscoverBannerSlider extends StatefulWidget {
  const DiscoverBannerSlider({super.key});

  @override
  State<DiscoverBannerSlider> createState() => _DiscoverBannerSliderState();
}

class _DiscoverBannerSliderState extends State<DiscoverBannerSlider> {
  final PageController _controller = PageController(viewportFraction: 1.0);
  int currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> sliderData = [
    {"slugId": "FRANCHISE", "image": AppImageAssets.franchiseBanner},
    {"slugId": "BDM", "image": AppImageAssets.franchiseBanner},
    {"slugId": "QR", "image": AppImageAssets.qrBanner},
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel(); // Clear existing timer
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_controller.hasClients) {
        int nextPage = (currentPage + 1) % sliderData.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          /// SLIDER
          SizedBox(
            height: 180,
            child: GestureDetector(
              // 2. Pause timer on touch down, restart on touch up
              onPanDown: (_) => _timer?.cancel(),
              onPanEnd: (_) => _startAutoScroll(),
              onPanCancel: () => _startAutoScroll(),
              child: PageView.builder(
                controller: _controller,
                itemCount: sliderData.length,
                onPageChanged: (index) {
                  setState(() => currentPage = index);
                },
                itemBuilder: (context, index) {
                  // 3. Horizontal padding creates space between slides
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildSlide(sliderData[index]),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// DOT INDICATOR
          Row(
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
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, String> data) {
    return InkWell(
      onTap: () {
        switch (data['slugId']) {
          case 'FRANCHISE':
            Get.to(() => const FranchiseHome());
            break;
          case 'BDM':
            Get.to(() => const ReferralPage());
            break;
          case 'QR':
            commonSnackBar(message: 'Coming soon..');
            break;
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: LocalAssets(
          imagePath: data["image"]!,
          boxFix: BoxFit.cover,
        ),
      ),
    );
  }
}
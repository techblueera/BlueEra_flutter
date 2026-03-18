import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
import 'package:BlueEra/features/common/referral/view/referral_page.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
  late PageController _controller;

  int currentPage = 0;

  final List<Map<String, String>> sliderData = const [
    {"slugId": "FRANCHISE", "image": AppImageAssets.franchiseBanner},
    {"slugId": "BDM", "image": AppImageAssets.bdmBanner},
    {"slugId": "QR", "image": AppImageAssets.qrBanner},
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Controller without auto-scroll logic
    final PageController _controller = PageController(viewportFraction: 0.9);

    return CustomFormCard(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          /// SLIDER
          AspectRatio(
            aspectRatio: 16 / 7, // Adjust this ratio to match your image design
            child: PageView.builder(
              controller: _controller,
              itemCount: sliderData.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildSlide(context, sliderData[index]);
              },
            ),
          ),

          const SizedBox(height: 12),

          /// SIMPLIFIED INDICATOR
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

  Widget _buildSlide(BuildContext context, Map<String, String> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Adds space between cards
      child: InkWell(
        onTap: () => _handleOnTap(data['slugId']!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: LocalAssets(
            imagePath: data["image"]!,
            width: double.infinity,
            boxFix: BoxFit.cover,
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
        Scrollable.ensureVisible(
          widget.targetKey.currentContext!,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
        break;
    }
  }
}

// class DiscoverBannerSlider extends StatefulWidget {
//   final ScrollController parentScrollController; // Add this
//   final GlobalKey targetKey; // Add this to identify where to scroll to
//   const DiscoverBannerSlider({
//     super.key,
//     required this.parentScrollController,
//     required this.targetKey,
//   });
//
//   @override
//   State<DiscoverBannerSlider> createState() => _DiscoverBannerSliderState();
// }
//
// class _DiscoverBannerSliderState extends State<DiscoverBannerSlider> {
//   // 1. Changed viewportFraction to 0.9 to make padding/peek effect visible
//   final PageController _controller = PageController(viewportFraction: 0.9);
//   int currentPage = 0;
//   Timer? _timer;
//
//   final List<Map<String, String>> sliderData = [
//     {"slugId": "FRANCHISE", "image": AppImageAssets.franchiseBanner},
//     {"slugId": "BDM", "image": AppImageAssets.bdmBanner},
//     {"slugId": "QR", "image": AppImageAssets.qrBanner},
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _startAutoScroll();
//   }
//
//   void _startAutoScroll() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
//       if (_controller.hasClients) {
//         // Use +1 and check bounds to avoid jumping back from index 2 to 0 instantly
//         int nextPage = currentPage + 1;
//         if (nextPage >= sliderData.length) nextPage = 0;
//
//         _controller.animateToPage(
//           nextPage,
//           duration: const Duration(milliseconds: 800),
//           curve: Curves.easeInOutQuart,
//         );
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomFormCard(
//       padding: const EdgeInsets.symmetric(vertical: 10.0),
//       child: Column(
//         children: [
//           /// SLIDER
//           SizedBox(
//             height: SizeConfig.screenHeight * 0.22,
//             child: Listener(
//               // 2. Use PointerDownEvent to kill the timer immediately
//               onPointerDown: (_) => _timer?.cancel(),
//               // 3. Restart timer only when user stops touching
//               onPointerUp: (_) => _startAutoScroll(),
//               child: PageView.builder(
//                 controller: _controller,
//                 itemCount: sliderData.length,
//                 // Allow the user to swipe naturally
//                 physics: const BouncingScrollPhysics(),
//                 onPageChanged: (index) {
//                   setState(() => currentPage = index);
//                 },
//                 itemBuilder: (context, index) {
//                   return _buildSlide(sliderData[index]);
//                 },
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 12),
//
//           /// DOT INDICATOR
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(
//               sliderData.length,
//                   (index) => AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 margin: const EdgeInsets.symmetric(horizontal: 4),
//                 height: 8,
//                 width: currentPage == index ? 24 : 8,
//                 decoration: BoxDecoration(
//                   color: currentPage == index
//                       ? AppColors.primaryColor
//                       : Colors.grey.shade400,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSlide(Map<String, String> data) {
//     return InkWell(
//       onTap: () {
//         switch (data['slugId']) {
//           case 'FRANCHISE':
//             Get.to(() => const FranchiseHome());
//             break;
//           case 'BDM':
//             Get.to(() => const ReferralPage());
//             break;
//           case 'QR':
//             commonSnackBar(message: 'Coming soon..');
//             break;
//         }
//       },
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12.0),
//         child: LocalAssets(
//           imagePath: data["image"]!,
//           width: double.maxFinite,
//           boxFix: BoxFit.cover,
//         ),
//       ),
//     );
//   }
// }
/*

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
}*/

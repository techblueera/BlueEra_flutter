import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class OtherServicesSlider extends StatefulWidget {
  final List<ServiceSliderModel> items;

  const OtherServicesSlider({
    super.key,
    required this.items,
  });

  @override
  State<OtherServicesSlider> createState() => _OtherServicesSliderState();
}

class _OtherServicesSliderState extends State<OtherServicesSlider> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// SLIDER
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _SliderCard(item: item);
            },
          ),
        ),

        const SizedBox(height: 12),

        /// DOT INDICATOR
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.items.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: currentIndex == index ? 20 : 6,
              decoration: BoxDecoration(
                color: currentIndex == index
                    ? Colors.blue
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
class _SliderCard extends StatelessWidget {
  final ServiceSliderModel item;

  const _SliderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          /// IMAGE
          Positioned.fill(
            child: Image.network(
              item.image,
              fit: BoxFit.cover,
            ),
          ),

          /// DARK OVERLAY
          // Positioned.fill(
          //   child: Container(
          //     decoration: BoxDecoration(
          //       gradient: LinearGradient(
          //         colors: [
          //           Colors.black.withOpacity(0.6),
          //           Colors.black.withOpacity(0.00),
          //         ],
          //         begin: Alignment.bottomCenter,
          //         end: Alignment.topCenter,
          //       ),
          //     ),
          //   ),
          // ),

          /// CONTENT
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(10),bottomLeft: Radius.circular(10)),
                color: AppColors.black.withOpacity(0.5)
              ),
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(item.icon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      CustomText(
                        item.title,
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
              
                    ],
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    "Gorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet...",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                      color: Colors.white70,
                      fontSize: 13,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class ServiceSliderModel {
  final String image;
  final String title;
  final String description;
  final IconData icon;

  ServiceSliderModel({
    required this.image,
    required this.title,
    required this.description,
    required this.icon,
  });
}

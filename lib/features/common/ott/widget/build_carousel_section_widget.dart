// --- Widget Builders ---
import 'package:BlueEra/features/common/ott/controller/ott_home_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BuildCarouselSectionWidget extends StatelessWidget {
  BuildCarouselSectionWidget({super.key});

  final ottHomeController = Get.find<OttHomeController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const SizedBox(height: 8),

          CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              autoPlay: true,
              viewportFraction: 0.9,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                ottHomeController.updateIndex(index);
              },
            ),
            items: ottHomeController.carouselImages.map((imageUrl) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Dots Indicator
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    ottHomeController.carouselImages.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ottHomeController.currentCarouselIndex.value ==
                              entry.key
                          ? Colors.black
                          : Colors.black.withValues(alpha: 0.5),
                      // color: (Theme.of(Get.context!).primaryColor).withOpacity(controller.currentCarouselIndex.value == entry.key ? 0.9 : 0.4),
                    ),
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }
}

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/me/hotel/controller/room_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/create_room_details_sccreen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoomListingScreen extends StatelessWidget {
  final controller = Get.put(RoomDetailController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Standard Room",
      ),
      bottomNavigationBar: SafeArea(child: _buildAddMoreButton()),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive padding: wider screens get more horizontal margin
            double horizontalPadding =
                constraints.maxWidth > 600 ? constraints.maxWidth * 0.2 : 16;

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 16),
                    itemCount: controller.roomList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRoomCard(controller.roomList[index]),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final List<String> images = List<String>.from(room['images']);
    final RxInt currentImageIndex = 0.obs;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 220,
                    viewportFraction: 1.0,
                    // Disable infinite scroll if there's only 1 image
                    enableInfiniteScroll: images.length > 1,
                    // Disable physics (scrolling) if there's only 1 image
                    scrollPhysics: images.length > 1
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onPageChanged: (index, reason) =>
                        currentImageIndex.value = index,
                  ),
                  items: images
                      .map((url) => Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image,
                                  size: 50, color: Colors.grey),
                            ),
                          ))
                      .toList(),
                ),
              ),

              // Indicators
              if (images.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          return Container(
                            width: 7.0,
                            height: 7.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(
                                  currentImageIndex.value == entry.key
                                      ? 1.0
                                      : 0.4),
                            ),
                          );
                        }).toList(),
                      )),
                ),
              // Menu Button
              // Positioned(
              //   top: 12,
              //   right: 12,
              //   child: CircleAvatar(
              //     backgroundColor: Colors.black.withOpacity(0.3),
              //     radius: 18,
              //     child: const Icon(Icons.more_vert,
              //         color: Colors.white, size: 20),
              //   ),
              // ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomText(
                        room['name'],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.percent_rounded,
                        color: AppColors.primaryColor, size: 22),
                  ],
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: "₹${formatNumber(int.parse(room['price']))}",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    const TextSpan(
                        text: "/day",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  width: Get.width,
                  child: Row(
                    children: [
                      Expanded(
                          child: _amenityIcon(Icons.bed_outlined, room['bed'])),
                      const SizedBox(width: 20),
                      Expanded(
                          child: _amenityIcon(
                              Icons.people_outline, room['occupancy'])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenityIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Flexible(
          child: CustomText(
            label,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
      width: double.infinity,
      color: Colors.white,
      child: OutlinedButton.icon(
        onPressed: () {
          Get.to(RoomDesignScreen());
        },
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: const CustomText("Add more", fontWeight: FontWeight.w600),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          side: const BorderSide(color: AppColors.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

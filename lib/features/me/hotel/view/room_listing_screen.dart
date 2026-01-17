import 'package:BlueEra/core/api/model/hotel_room_listing_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hotel/controller/room_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/create_room_details_sccreen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoomListingScreen extends StatefulWidget {
  final String roomType;
  final String roomName;

  RoomListingScreen(
      {super.key, required this.roomType, required this.roomName});

  @override
  State<RoomListingScreen> createState() => _RoomListingScreenState();
}

class _RoomListingScreenState extends State<RoomListingScreen> {
  final controller = Get.put(RoomDetailController());

  @override
  void initState() {
    // TODO: implement initState
    controller.getHotelRoomDetails(roomTYPE: widget.roomType);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.roomName,
      ),
      bottomNavigationBar: SafeArea(child: _buildAddMoreButton()),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive padding: wider screens get more horizontal margin
            double horizontalPadding =
                constraints.maxWidth > 600 ? constraints.maxWidth * 0.2 : 16;

            return Obx(() {
              if (controller.hotelRoomDataList.isNotEmpty) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding, vertical: 16),
                        itemCount: controller.hotelRoomDataList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildRoomCard(
                                controller.hotelRoomDataList[index]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return Center(
                  child: CustomText("No Rooms found please create room"));
            });
          },
        ),
      ),
    );
  }

  Widget _buildRoomCard(HotelRoomData room) {
    final List<String> images =
        List<String>.from(room.images?.exteriorImages ?? []);
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
              InkWell(
                onTap: () {
                  navigatePushTo(
                    context,
                    ImageViewScreen(
                      subTitle: room.name,
                      appBarTitle: AppStrings.imageViewer,
                      imageUrls: images,
                      initialIndex: currentImageIndex.value,
                    ),
                  );
                },
                child: ClipRRect(
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
              Positioned(
                top: 12,
                right: 12,
                child: PopupMenuButton<String>(
                  // Callback when a menu item is selected
                  onSelected: (value) async {
                    if (value == 'edit') {
                      // Pass the index and the specific list to the picker
                      // controller.pickImage(ImageSource.gallery, imageList, index: index);
                    } else if (value == 'delete') {
                      await showCommonDialog(
                          context: context,
                          text:
                              'Are you sure you want to delete this hotel room?',
                          confirmCallback: () async {
                            await controller.deleteHotelRoomController(
                                hotelRoomId: room.id ?? "",
                                hotelRoomType: room.type ?? "");
                          },
                          cancelCallback: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          confirmText: AppStrings.yes,
                          cancelText: AppStrings.no);
                    }
                  },
                  // The visual trigger for the menu
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    radius: 16,
                    child: const Icon(Icons.more_vert,
                        color: Colors.white, size: 18),
                  ),
                  itemBuilder: (BuildContext context) => [
                    // const PopupMenuItem(
                    //   value: 'edit',
                    //   child: Row(
                    //     children: [
                    //       Icon(Icons.edit, size: 20, color: Colors.blue),
                    //       SizedBox(width: 10),
                    //       Text("Edit"),
                    //     ],
                    //   ),
                    // ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 10),
                          CustomText("Delete"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                        room.name,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // const Icon(Icons.percent_rounded,
                    //     color: AppColors.primaryColor, size: 22),
                  ],
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text:
                            "₹${formatNumber(int.parse(room.pricePerDay.toString()))}",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    const TextSpan(
                        text: "/day",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ]),
                ),
                const SizedBox(height: 10),
                Container(
                  width: Get.width,
                  child: Row(
                    children: [
                      Flexible(
                          child: _amenityIcon(
                              AppIconAssets.bad, room.bedType ?? "")),
                      const SizedBox(width: 20),
                      Flexible(
                          child: _amenityIcon(AppIconAssets.occupancy,
                              room.maxOccupancy.toString())),
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

  Widget _amenityIcon(String icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalAssets(imagePath: icon),
        const SizedBox(width: 8),
        Flexible(
          child: CustomText(
            label,
            color: AppColors.secondaryTextColor,
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
          Get.to(RoomDesignScreen(
            roomType: widget.roomType,
            roomName: widget.roomName,
          ));
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

import 'package:BlueEra/core/api/model/ai_hotel_res_model.dart';
import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/room_detils_screen.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_header_view.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_home_gallery_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelHomeDetailScreen extends StatelessWidget {
  final controller = Get.put(HotelDetailController());

// Helper to clean up API strings (e.g., "standardRoom" -> "Standard Room")
  String _formatTypeName(String type) {
    if (type.isEmpty) return "";
    String result = type.replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');
    return result[0].toUpperCase() + result.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        final profile = controller.hotelData.value?.profile;
        final rooms = controller.hotelData.value?.rooms ?? [];

        return CustomScrollView(
          slivers: [
            // 1. Header Image
            SliverAppBar(
              expandedHeight: Get.height * 0.35,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.appBackgroundColor,
                  child: HotelHeaderView(
                    schoolAboutUsController: controller,
                  ),
                ),
                collapseMode: CollapseMode.parallax,
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonCardWidget(
                      padding: 10,
                      cardMargin: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText("Choose Room",
                              fontSize: 18, fontWeight: FontWeight.bold),
                          const SizedBox(height: 12),

                          // Dynamic Category Chips
                          Obx(() {
                            final types = controller.dynamicRoomTypes;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: types.map((type) {
                                  bool isSelected =
                                      controller.selectedRoomType.value == type;
                                  return GestureDetector(
                                    onTap: () => controller
                                        .selectedRoomType.value = type,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : AppColors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        // Pill shape
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryColor
                                              : AppColors.secondaryTextColor,
                                        ),
                                      ),
                                      child: CustomText(
                                        _formatTypeName(type),
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          // Dynamic Room List
                          Obx(() => SizedBox(
                                height: 310,
                                child: controller.filteredRooms.isEmpty
                                    ? const Center(
                                        child: CustomText("No rooms available"))
                                    : ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            controller.filteredRooms.length,
                                        itemBuilder: (context, index) =>
                                            _buildRoomCard(controller
                                                .filteredRooms[index]),
                                      ),
                              )),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => Get.to(RoomSelectionScreen()),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CustomText(
                                  "View All ",
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                Icon(
                                  Icons.arrow_right_alt,
                                  color: AppColors.primaryColor,
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),

                    // 3. Gallery Section
                    SizedBox(height: 24),

                    HotelHomeGalleryWidget(photos: profile?.photos),

                    // 4. Amenities Section
                    SizedBox(height: 24),
                    CommonCardWidget(
                      padding: 10,
                      cardMargin: 0,
                      child: SizedBox(
                        width: Get.width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText("Hotel Amenities",
                                fontSize: 18, fontWeight: FontWeight.bold),
                            SizedBox(height: 15),
                            _buildAmenities(profile?.amenities),
                          ],
                        ),
                      ),
                    ),

                    // 5. Contact Section
                    SizedBox(height: 24),
                    _buildContactCard(profile),
                    SizedBox(height: 24),

                    CommonCardWidget(
                      padding: 5,
                      child: BusinessLocationWidget(
                          locationText: profile?.locationHotel?.name,
                          latitude: double.parse(
                              profile?.locationHotel?.latitude?.toString() ??
                                  "0.0"),
                          longitude: double.parse(
                              profile?.locationHotel?.longitude?.toString() ??
                                  "0.0"),
                          businessName: profile?.name ?? "",
                          padding: 0,
                          isTitleShow: true),
                    ),

                    SizedBox(height: kBottomNavigationBarHeight + 30),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildContactCard(Profile? profile) {
    return CommonCardWidget(
      padding: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText("Contact Us",
              fontSize: 24, fontWeight: FontWeight.bold),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and Hotel Name
                if (profile?.photos?.isNotEmpty ?? false)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      // color: Colors.white,
                      shape: BoxShape.circle,
                      // border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                      image: DecorationImage(
                          image: NetworkImage(
                              profile?.photos?.first.imageReferences?.first ??
                                  ''),
                          fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 10),
                CustomText(profile?.name,
                    fontSize: 20, fontWeight: FontWeight.bold),

                const SizedBox(height: 5),
                CustomText(
                  profile?.description,
                  color: Colors.grey,
                  fontSize: 14,
                ),
                const Divider(height: 30),

                // Contact List
                _contactItem(AppIconAssets.website_click,
                    profile?.website ?? "", Colors.blue),
                _contactItem(
                    AppIconAssets.principal, "Reception", Colors.grey[700]!),
                _contactItem(
                    AppIconAssets.email,
                    profile?.contacts?.firstOrNull?.email ?? "",
                    AppColors.secondaryTextColor),
                _contactItem(
                    AppIconAssets.phone_outline,
                    profile?.contacts?.firstOrNull?.phone ?? "",
                    AppColors.secondaryTextColor),
                _contactItem(AppIconAssets.location_new,
                    profile?.locationHotel?.name ?? "", Colors.grey[700]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(
            imagePath: icon,
            imgColor: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: CustomText(label, fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Rooms room) {
    return Container(
      width: 236,
      height: 303,
      // Increased width to match the aspect ratio of your image
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Softer rounded corners
      ),
      child: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                room.images?.exteriorImages?.firstOrNull ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.hotel, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),

          // 2. Bottom Gradient Overlay (to make text readable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Favorite Icon
          // Positioned(
          //   top: 12,
          //   right: 12,
          //   child: CircleAvatar(
          //     backgroundColor: Colors.white,
          //     radius: 18,
          //     child: Icon(Icons.favorite, color: Colors.red[400], size: 20),
          //   ),
          // ),

          // 4. Content Overlay
          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title and Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomText(
                        room.name ?? "Room Name",
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                      ),
                    ),
                    // Row(
                    //   children: List.generate(
                    //     5,
                    //         (index) => const Icon(Icons.star, color: Colors.amber, size: 14),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 4),

                // Price
                CustomText(
                  "₹${room.pricePerDay}/day",
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 12),

                // Bed Type Info
                Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.bad,
                      imgColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    CustomText(
                      room.bedType ?? "",
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Occupancy Info
                Row(
                  children: [
                    LocalAssets(
                      imagePath: AppIconAssets.occupancy,
                      imgColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    CustomText(
                      room.maxOccupancy ?? "",
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(Amenities? amen) {
    if (amen == null) return SizedBox();
    return Wrap(
      spacing: 20,
      children: [
        // if (amen.swimmingPool ?? false) _amenityIcon(Icons.pool, "Pool"),
        if (amen.freeWifi ?? true) _amenityIcon(Icons.wifi, "Wifi"),
        if (amen.airConditioning ?? true) _amenityIcon(Icons.ac_unit, "AC"),
      ],
    );
  }

  Widget _amenityIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor),
        CustomText(label, fontSize: 12),
      ],
    );
  }

  Widget _buildContactInfo(Profile? profile) {
    final contact = profile?.contacts?.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
                leading: Icon(Icons.email),
                title: CustomText(contact?.email ?? "")),
            ListTile(
                leading: Icon(Icons.phone),
                title: CustomText(contact?.phone ?? "")),
            ListTile(
                leading: Icon(Icons.location_on),
                title: CustomText(contact?.address ?? "")),
          ],
        ),
      ),
    );
  }
}

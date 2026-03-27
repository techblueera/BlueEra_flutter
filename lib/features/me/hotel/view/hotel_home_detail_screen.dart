import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_amenities_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_contact_us/hotel_contact_us.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_photos_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_screen.dart';
import 'package:BlueEra/features/me/hotel/view/room_amenities_screen.dart';
import 'package:BlueEra/features/me/hotel/view/room_detils_screen.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_header_view.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_home_gallery_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelHomeDetailScreen extends StatefulWidget {
  @override
  State<HotelHomeDetailScreen> createState() => _HotelHomeDetailScreenState();
}

class _HotelHomeDetailScreenState extends State<HotelHomeDetailScreen> {
  final controller = getOrPut(() => HotelDetailController());

  String _formatTypeName(String type) {
    if (type.isEmpty) return "";
    String result = type.replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');
    return result[0].toUpperCase() + result.substring(1);
  }

  @override
  void initState() {
    controller.loadHotelData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = controller.hotelData.value?.profile;

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
                    // 2. Room Section
                    CommonCardWidget(
                      padding: 10,
                      cardMargin: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            "Choose Room",
                            onAdd: () => Get.to(RoomSelectionScreen()),
                            onEdit: () => Get.to(RoomAmenitiesScreen()),
                          ),
                          const SizedBox(height: 12),

                          // Category Chips
                          Obx(() {
                            final types = controller.dynamicRoomTypes;
                            if (types.isEmpty) return const SizedBox.shrink();
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: types.map((type) {
                                  bool isSelected =
                                      controller.selectedRoomType.value == type;
                                  return GestureDetector(
                                    onTap: () =>
                                        controller.selectedRoomType.value =
                                            type,
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : AppColors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
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

                          // Room List or Placeholder
                          Obx(() {
                            final allRooms =
                                controller.hotelData.value?.rooms ?? [];
                            if (allRooms.isEmpty) {
                              return _buildEmptyPlaceholder(
                                "No rooms added yet",
                                icon: Icons.hotel_outlined,
                                onAdd: () => Get.to(RoomSelectionScreen()),
                              );
                            }
                            if (controller.filteredRooms.isEmpty) {
                              return const SizedBox(
                                height: 80,
                                child: Center(
                                  child: CustomText("No rooms for this type"),
                                ),
                              );
                            }
                            return SizedBox(
                              height: 310,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: controller.filteredRooms.length,
                                itemBuilder: (context, index) => _buildRoomCard(
                                    controller.filteredRooms[index]),
                              ),
                            );
                          }),

                          const SizedBox(height: 16),
                          Obx(() {
                            final hasRooms =
                                controller.hotelData.value?.rooms?.isNotEmpty ??
                                    false;
                            if (!hasRooms) return const SizedBox.shrink();
                            return InkWell(
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
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),

                    // 3. Gallery Section
                    const SizedBox(height: 16),
                    CommonCardWidget(
                      padding: 10,
                      cardMargin: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            "Gallery",
                            onAdd: () => Get.to(PropertyPhotoScreen()),
                          ),
                          const SizedBox(height: 12),
                          profile?.photos?.isNotEmpty == true
                              ? HotelHomeGalleryWidget(photos: profile?.photos)
                              : _buildEmptyPlaceholder(
                                  "No photos added yet",
                                  icon: Icons.photo_library_outlined,
                                  onAdd: () => Get.to(PropertyPhotoScreen()),
                                ),
                        ],
                      ),
                    ),

                    // 4. Amenities Section
                    const SizedBox(height: 16),
                    CommonCardWidget(
                      padding: 10,
                      cardMargin: 0,
                      child: SizedBox(
                        width: Get.width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              "Hotel Amenities",
                              onEdit: () => Get.to(HotelAmenitiesScreen()),
                            ),
                            const SizedBox(height: 15),
                            profile?.amenities != null
                                ? _buildAmenities(profile?.amenities)
                                : _buildEmptyPlaceholder(
                                    "No amenities added yet",
                                    icon: Icons.spa_outlined,
                                    onAdd: () =>
                                        Get.to(HotelAmenitiesScreen()),
                                  ),
                          ],
                        ),
                      ),
                    ),

                    // 5. Policies Section
                    const SizedBox(height: 16),
                    CommonCardWidget(
                      padding: 10,
                      cardMargin: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            "Hotel Policies",
                            onEdit: () => Get.to(HotelPoliciesScreen()),
                          ),
                          const SizedBox(height: 10),
                          profile?.policy != null
                              ? _buildPolicySummary(profile!.policy!)
                              : _buildEmptyPlaceholder(
                                  "No policies added yet",
                                  icon: Icons.policy_outlined,
                                  onAdd: () =>
                                      Get.to(HotelPoliciesScreen()),
                                ),
                        ],
                      ),
                    ),

                    // 6. Contact Section
                    const SizedBox(height: 16),
                    _buildContactCard(profile),
                    const SizedBox(height: 20),

                    BusinessLocationWidget(
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

  // ─── Section Header with Edit / Add icons ──────────────────────────────────
  Widget _buildSectionHeader(
    String title, {
    VoidCallback? onAdd,
    VoidCallback? onEdit,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ServiceHomeTitleWidget(title: title),
        Row(
          children: [
            if (onEdit != null)
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primaryColor),
                ),
              ),
            if (onEdit != null && onAdd != null) const SizedBox(width: 8),
            if (onAdd != null)
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add,
                      size: 18, color: AppColors.primaryColor),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ─── Empty Placeholder ─────────────────────────────────────────────────────
  Widget _buildEmptyPlaceholder(
    String message, {
    IconData icon = Icons.info_outline,
    VoidCallback? onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 44, color: AppColors.primaryColor.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 12),
          CustomText(
            message,
            color: AppColors.secondaryTextColor,
            fontSize: 13,
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    CustomText("Add Now",
                        color: Colors.white, fontSize: 13),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Policy Summary Chips ──────────────────────────────────────────────────
  Widget _buildPolicySummary(Policy policy) {
    final items = <String>[];
    if (policy.checkInTime != null)
      items.add("Check-in: ${policy.checkInTime}");
    if (policy.checkOutTime != null)
      items.add("Check-out: ${policy.checkOutTime}");
    if (policy.earlyCheckInAllowed == true)
      items.add("Early check-in allowed");
    if (policy.lateCheckOutAllowed == true)
      items.add("Late check-out allowed");
    if (policy.freeCancellation == true) items.add("Free cancellation");
    if (policy.localIdAllowed == true) items.add("Local ID accepted");
    if (policy.marriedCoupleAllowed == true)
      items.add("Married couples allowed");
    if (policy.bachelorStudentAllowed == true)
      items.add("Bachelors/students allowed");

    if (items.isEmpty) {
      return _buildEmptyPlaceholder(
        "No policies added yet",
        icon: Icons.policy_outlined,
        onAdd: () => Get.to(HotelPoliciesScreen()),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.2)),
                ),
                child: CustomText(item,
                    fontSize: 12, color: AppColors.mainTextColor),
              ))
          .toList(),
    );
  }

  // ─── Contact Card ──────────────────────────────────────────────────────────
  Widget _buildContactCard(Profile? profile) {
    return CommonCardWidget(
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "Contact Us",
            onEdit: () => Get.to(const HotelContactUs()),
          ),
          const SizedBox(height: 20),
          if (profile?.contacts?.isEmpty ?? true)
            _buildEmptyPlaceholder(
              "No contact details added yet",
              icon: Icons.contact_phone_outlined,
              onAdd: () => Get.to(const HotelContactUs()),
            )
          else
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
                  if (profile?.photos?.isNotEmpty ?? false) ...[
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12, blurRadius: 10)
                        ],
                        image: DecorationImage(
                            image: NetworkImage(
                                profile?.photos?.first.imageReferences
                                        ?.first ??
                                    ''),
                            fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  CustomText(profile?.name,
                      fontSize: 18, fontWeight: FontWeight.bold),
                  const SizedBox(height: 5),
                  CustomText(
                    profile?.description,
                    color: AppColors.secondaryTextColor,
                    fontSize: 12,
                  ),
                  const Divider(height: 30),

                  // Contact List
                  _contactItem(AppIconAssets.website_click,
                      profile?.website ?? "", AppColors.primaryColor),
                  _contactItem(AppIconAssets.principal, "Reception",
                      Colors.grey[700]!),
                  _contactItem(
                      AppIconAssets.email,
                      profile?.contacts?.firstOrNull?.email ?? "N/A",
                      AppColors.secondaryTextColor),
                  _contactItem(
                      AppIconAssets.phone_outline,
                      profile?.contacts?.firstOrNull?.phone ?? "N/A",
                      AppColors.secondaryTextColor),
                  _contactItem(
                      AppIconAssets.location_new,
                      profile?.locationHotel?.name ?? "N/A",
                      Colors.grey[700]!),
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
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
              child:
                  CustomText(label, color: AppColors.mainTextColor)),
        ],
      ),
    );
  }

  // ─── Room Card ─────────────────────────────────────────────────────────────
  Widget _buildRoomCard(Rooms room) {
    return Container(
      width: 236,
      height: 303,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
                  child:
                      const Icon(Icons.hotel, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),

          // 2. Bottom Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Content Overlay
          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  ],
                ),
                const SizedBox(height: 4),

                CustomText(
                  "₹${room.pricePerDay}/day",
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: 12),

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

  // ─── Amenities Grid ────────────────────────────────────────────────────────
  Widget _buildAmenities(Amenities? amen) {
    if (amen == null) return const SizedBox();
    return Wrap(
      spacing: 20,
      children: [
        if (amen.freeWifi ?? false) _amenityIcon(Icons.wifi, "Wifi"),
        if (amen.airConditioning ?? false) _amenityIcon(Icons.ac_unit, "AC"),
        if (amen.television ?? false) _amenityIcon(Icons.tv, "TV"),
        if (amen.roomService ?? false)
          _amenityIcon(Icons.room_service, "Room Service"),
        if (amen.powerBackup ?? false)
          _amenityIcon(
              Icons.battery_charging_full_sharp, "Power Bank"),
        if (amen.balcony ?? false) _amenityIcon(Icons.balcony, "Balcony"),
        if (amen.attachedBathroom ?? false)
          _amenityIcon(Icons.bathroom, "Bathroom"),
        if (amen.wardrobe ?? false)
          _amenityIcon(Icons.devices_other, "Wardrobe"),
        if (amen.deskChair ?? false)
          _amenityIcon(Icons.chair, "Desk Chair"),
        if (amen.roomRefrigerators ?? false)
          _amenityIcon(Icons.cabin_sharp, "Room Refrigerators"),
        if (amen.electricKettle ?? false)
          _amenityIcon(Icons.electric_bolt, "Electric Kettle"),
      ],
    );
  }

  Widget _amenityIcon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          CustomText(label, fontSize: 12),
        ],
      ),
    );
  }
}

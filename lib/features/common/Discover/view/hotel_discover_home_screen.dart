import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_home_gallery_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_header_title_widget.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelDiscoverHomeScreen extends StatefulWidget {
  final HotelServiceData data;

  HotelDiscoverHomeScreen({super.key, required this.data});

  @override
  State<HotelDiscoverHomeScreen> createState() =>
      _HotelDiscoverHomeScreenState();
}

class _HotelDiscoverHomeScreenState extends State<HotelDiscoverHomeScreen> {
  var selectedRoomType = "";

// Helper to clean up API strings (e.g., "standardRoom" -> "Standard Room")
  String _formatTypeName(String type) {
    if (type.isEmpty) return "";
    String result = type.replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');
    return result[0].toUpperCase() + result.substring(1);
  }

  List<Rooms> get filteredRooms {
    return widget.data.rooms
            ?.where((room) => room.type == selectedRoomType)
            .toList() ??
        [];
  }

  // Get unique types dynamically from the data
  List<String> get dynamicRoomTypes {
    final rooms = widget.data.rooms ?? [];
    // Extract types, remove nulls/empty, and get unique values
    return rooms
        .map((e) => e.type ?? "")
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> types = [];
  Profile? profile;

  @override
  void initState() {
    // TODO: implement initState
    profile = widget.data.profile;
    types = dynamicRoomTypes;
    selectedRoomType = types.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: profile?.name,
      ),
      bottomNavigationBar: profile?.businessId != userId
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 12.0, right: 12, bottom: 15, top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: PositiveCustomBtn(
                          onTap: () async {
                            final chatViewController =
                                Get.find<ChatViewController>();
                            chatViewController.checkChatConnectionAndOpenChat(
                              userId: profile?.businessId ?? '',
                            );
                          },
                          title: AppStrings.chat),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: PositiveCustomBtn(
                          onTap: () {
                            commonSnackBar(message: 'Coming Soon....');
                          },
                          title: AppStrings.bookInquiry),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // 1. Header Image
          SliverAppBar(
            expandedHeight: Get.height * 0.35,
            leading: SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.appBackgroundColor,
                child: HotelHeaderViewDiscover(
                  data: widget.data,
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
                        ServiceHomeTitleWidget(
                          title: AppStrings.chooseRoom,
                        ),
                        const SizedBox(height: 12),

                        // Dynamic Category Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: types.map((type) {
                              bool isSelected = selectedRoomType == type;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedRoomType = type;
                                  });
                                },
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
                        ),

                        const SizedBox(height: 16),
                        // Dynamic Room List
                        SizedBox(
                          height: 310,
                          child: filteredRooms.isEmpty
                              ? const Center(
                                  child: CustomText(AppStrings.noRoomsAvailable))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: filteredRooms.length,
                                  itemBuilder: (context, index) {
                                    Rooms data = filteredRooms[index];
                                    return _buildRoomCard(data);
                                  },
                                ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),

                  // 3. Gallery Section
                  SizedBox(height: 24),

                  HotelHomeGalleryWidget(photos: profile?.photos),
                  SizedBox(height: 24),

                  // 4. Amenities Section
                  CommonCardWidget(
                    padding: 10,
                    cardMargin: 0,
                    child: SizedBox(
                      width: Get.width,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(AppStrings.hotelAmenities,
                              fontSize: 18, fontWeight: FontWeight.bold),
                          SizedBox(height: 15),
                          _buildAmenities(profile?.amenities),
                        ],
                      ),
                    ),
                  ),

                  // 5. Contact Section
                  SizedBox(height: 20),
                  _buildContactCard(profile),
                  SizedBox(height: 20),

                  BusinessLocationWidget(
                      locationText: widget.data.profile?.location?.name,
                      latitude: double.parse(widget
                          .data.profile?.location?.coordinates?[0]
                          .toString() ??
                          "0.0"),
                      longitude: double.parse(widget
                          .data.profile?.location?.coordinates?[1]
                          .toString() ??
                          "0.0"),
                      businessName: profile?.name ?? "",
                      padding: 0,
                      isTitleShow: true),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Profile? profile) {
    return CommonCardWidget(
      // padding: 15,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(
            title:AppStrings.contactUs
          ),
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
                if (profile?.photos?.isNotEmpty ?? false) ...[
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
                _contactItem(
                    AppIconAssets.principal, AppStrings.reception.tr, Colors.grey[700]!),
                _contactItem(
                    AppIconAssets.email,
                    profile?.contacts?.firstOrNull?.email ?? "N/A",
                    AppColors.secondaryTextColor),
                _contactItem(
                    AppIconAssets.phone_outline,
                    profile?.contacts?.firstOrNull?.phone ?? "N/A",
                    AppColors.secondaryTextColor),
                _contactItem(AppIconAssets.location_new,
                    profile?.location?.name ?? "N/A", Colors.grey[700]!),
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
          Expanded(child: CustomText(label, color: AppColors.mainTextColor)),
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
          Positioned(
            // bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 10.0, right: 10, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title and Stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomText(
                              room.name ?? "N/A",
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              maxLines: 1,
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 4),

                      // Price
                      CustomText(
                        "₹${room.pricePerDay}/day",
                        color: Colors.white,
                        fontSize: 16,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 5),

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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
        if (amen.freeWifi ?? true) _amenityIcon(Icons.wifi, "Wifi"),
        if (amen.airConditioning ?? true) _amenityIcon(Icons.ac_unit, "AC"),
        if (amen.television ?? true) _amenityIcon(Icons.tv, "TV"),
        if (amen.roomService ?? true)
          _amenityIcon(Icons.room_service, "Room Service"),
        if (amen.powerBackup ?? true)
          _amenityIcon(Icons.battery_charging_full_sharp, "Power Bank"),
        if (amen.balcony ?? true) _amenityIcon(Icons.balcony, "Balcony"),
        if (amen.attachedBathroom ?? true)
          _amenityIcon(Icons.bathroom, "Bathroom"),
        if (amen.wardrobe ?? true)
          _amenityIcon(Icons.devices_other, "wardrobe"),
        if (amen.deskChair ?? true) _amenityIcon(Icons.chair, "Desk Chair"),
        if (amen.roomRefrigerators ?? true)
          _amenityIcon(Icons.cabin_sharp, "Room Refrigerators"),
        if (amen.electricKettle ?? true)
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

class HotelHeaderViewDiscover extends StatefulWidget {
  final HotelServiceData data;

  const HotelHeaderViewDiscover({
    super.key,
    required this.data,
  });

  @override
  State<HotelHeaderViewDiscover> createState() => _HotelHeaderViewState();
}

class _HotelHeaderViewState extends State<HotelHeaderViewDiscover> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return CommonCardWidget(
      padding: 0,
      cardMargin: 10,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // --- HEADER SECTION (Banner & Logo) ---
          SizedBox(
            height: size.height * 0.21,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image
                if (widget.data.profile?.photos?.isNotEmpty ?? false)
                  GestureDetector(
                    onTap: () => null,
                    // onTap: () => _pickImage(true),
                    child: Container(
                      width: double.infinity,
                      height: size.height * 0.17,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[100],
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        image: DecorationImage(
                            image: NetworkImage(
                                (widget.data.profile?.coverUrl ?? "")),
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),

                // Logo Image
                Positioned(
                  bottom: 0,
                  left: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                      image: DecorationImage(
                          image: NetworkImage(
                              (widget.data.profile?.logoUrl ?? "")),
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- FORM SECTION ---
          ServiceHomeHeaderTitleWidget(
            title: widget.data.profile?.name ?? "",
            description: widget.data.profile?.description ?? "",
          ),
        ],
      ),
    );
  }
}

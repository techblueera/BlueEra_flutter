import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_home_gallery_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelsDetailsWidget extends StatelessWidget {
  final HotelServiceData hotelServiceData;
  HotelsDetailsWidget({super.key, required this.hotelServiceData});

final discoverController = Get.find<DiscoverController>();


  @override
  Widget build(BuildContext context) {
    Profile? profile = hotelServiceData.profile;
    List<Rooms>? rooms = hotelServiceData.rooms;

    final distance = calculateDistance(
        profile?.location?.coordinates?[1].toDouble() ?? 0.0,
        profile?.location?.coordinates?[0].toDouble() ?? 0.0);

    // Helper to clean up API strings (e.g., "standardRoom" -> "Standard Room")
    String _formatTypeName(String type) {
      if (type.isEmpty) return "";
      String result = type.replaceAllMapped(
          RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');
      return result[0].toUpperCase() + result.substring(1);
    }

    return Column(
      children: [

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
                color: AppColors.greyE5,
                width: 0.5),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  // Navigate to details
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    (profile!=null && (profile.coverUrl?.isNotEmpty ?? false))
                        ? CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: SizeConfig.size150,
                      imagePaths: [profile.coverUrl!],
                      borderRadius: BorderRadius.circular(10),
                    ) : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        height: SizeConfig.size150,
                        width: double.infinity,
                      ),
                    ),
                    Positioned(
                        left: 20,
                        bottom: -(SizeConfig.size34),
                        child: Container(
                          padding: EdgeInsets.all(3.0),
                          decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle
                          ),
                          child: (profile!=null && (profile.logoUrl?.isNotEmpty ?? false))
                              ? CachedAvatarWidget(
                            imageUrl: profile.logoUrl!,
                            size: SizeConfig.size65,
                            borderColor: Colors.white,
                            borderRadius: SizeConfig.size40,
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(SizeConfig.size40),
                            child: LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              height: SizeConfig.size65,
                              width: SizeConfig.size65,
                            ),
                          ),
                        )
                    )

                  ],
                ),
              ),

              SizedBox(
                height: SizeConfig.size60,
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: CustomText(
                          profile?.name ?? 'Unknown User',
                          fontSize: SizeConfig.large,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w700
                      ),
                    ),
                    SizedBox(
                      width: SizeConfig.size8,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size3,
                        horizontal: SizeConfig.size10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppColors.secondaryTextColor, width: 0.5),
                      ),
                      child: CustomText(
                          '5 Star',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: SizeConfig.size8,
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.size3,
                      horizontal: SizeConfig.size10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.secondaryTextColor, width: 0.5),
                    ),
                    child: CustomText(
                        '5 Star',
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400
                    ),
                  ),
                  SizedBox(
                    width: SizeConfig.size5,
                  ),
                  CommonRatingRow(
                    rating: double.tryParse(profile?.rating.toString()??'0.0') ?? 0.0,
                    reviews: profile?.reviews ?? 0,
                    distance: '${distance?.toStringAsFixed(2)} KM',
                  )
                ],
              ),

              SizedBox(
                height: SizeConfig.size12,
              ),

              ExpandableText(
                text: profile?.description ?? AppStrings.na,
                trimLines: 3,
                expandMode: ExpandMode.dialog,
                style: TextStyle(
                  color: AppColors.mainTextColor,
                  fontFamily: AppConstants.OpenSans,
                  fontWeight: FontWeight.w400,
                  fontSize: SizeConfig.medium,
                ),
              ),

              SizedBox(
                height: SizeConfig.size10,
              ),

            ],
          ),
        ),

        SizedBox(height: SizeConfig.size15),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
                color: AppColors.greyE5,
                width: 0.5),
          ),
          child: Column(
            children: [
              CustomFormCard(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [



                    CustomText("Choose Room",
                        fontSize: 18, fontWeight: FontWeight.bold),
                    const SizedBox(height: 12),

                    // Dynamic Category Chips
                    Obx(() {
                      final types = discoverController.getDynamicRoomTypes(hotelServiceData);
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: types.map((type) {
                            bool isSelected = discoverController.selectedRoomType.value == type;
                            return GestureDetector(
                              onTap: () => discoverController.selectedRoomType.value = type,
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
                    SizedBox(
                      height: 310,
                      child: (rooms?.isEmpty ?? false)
                          ? const Center(
                          child: CustomText("No rooms available"))
                          : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: rooms!.length,
                        itemBuilder: (context, index) =>
                            _buildRoomCard(rooms[index]),
                      ),
                    ),
                    // const SizedBox(height: 16),
                    // InkWell(
                    //   onTap: () => Get.to(RoomSelectionScreen()),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.end,
                    //     children: [
                    //       CustomText(
                    //         "View All ",
                    //         color: AppColors.primaryColor,
                    //         fontWeight: FontWeight.w600,
                    //         fontSize: 16,
                    //       ),
                    //       Icon(
                    //         Icons.arrow_right_alt,
                    //         color: AppColors.primaryColor,
                    //       )
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),

              // 3. Gallery Section
              SizedBox(height: 24),

              HotelHomeGalleryWidget(photos: profile?.photos),


              // 4. Amenities Section
              SizedBox(height: 24),
              CustomFormCard(
                padding: EdgeInsets.all(10),
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

              CustomFormCard(
                padding: EdgeInsets.all(10),
                child: BusinessLocationWidget(
                    locationText: profile?.location?.name,
                    latitude: double.parse(
                        profile?.location?.coordinates?[1].toString() ??
                            "0.0"),
                    longitude: double.parse(
                        profile?.location?.coordinates?[0].toString() ??
                            "0.0"),
                    businessName: profile?.name ?? "",
                    padding: 0,
                    isTitleShow: true),
              ),

              SizedBox(height: kBottomNavigationBarHeight + 30),

            ],
          ),
        ),

        SizedBox(height: SizeConfig.paddingL),

        CustomBtn(
          onTap: () {},
          isValidate: true,
          radius: SizeConfig.size10,
          title: 'Book Now',
          // isLoading: authController.isAddBusinessUserLoading.value
        ),
      ],
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
                    profile?.location?.name ?? "", Colors.grey[700]!),
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
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
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
}

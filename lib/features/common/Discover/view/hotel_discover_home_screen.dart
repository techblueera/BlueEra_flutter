import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
import 'package:BlueEra/features/me/hotel/view/widget/hotel_home_gallery_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/visit_business_stats_card.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:BlueEra/widgets/website_preview_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class HotelDiscoverHomeScreen extends StatefulWidget {
  final HotelServiceData data;

  const HotelDiscoverHomeScreen({super.key, required this.data});

  @override
  State<HotelDiscoverHomeScreen> createState() =>
      _HotelDiscoverHomeScreenState();
}

class _HotelDiscoverHomeScreenState extends State<HotelDiscoverHomeScreen> {
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final storeController = getOrPut(() => NewStoreController());
  var selectedRoomType = "";

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

  List<String> get dynamicRoomTypes {
    final rooms = widget.data.rooms ?? [];
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
    profile = widget.data.profile;
    types = dynamicRoomTypes;
    selectedRoomType = types.isNotEmpty ? types.first : '';
    super.initState();
    final id = profile?.businessId ?? '';
    if (id.isNotEmpty) {
      viewBusinessDetailsController.viewBusinessProfileById(id);
      storeController.trackStoreDetailView(id);
    }
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
                padding: EdgeInsets.only(
                  left: SizeConfig.paddingS,
                  right: SizeConfig.paddingS,
                  bottom: 15,
                  top: 10,
                ),
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
                        title: AppStrings.chat,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PositiveCustomBtn(
                        onTap: () {
                          commonSnackBar(
                              message: AppStrings.comingSoonLabel.tr);
                        },
                        title: AppStrings.bookInquiry,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            _buildHeader(),
            SizedBox(height: SizeConfig.size16),

            Obx(() {
              viewBusinessDetailsController.profileVersion.value;
              return VisitBusinessStatsCard(
                details: viewBusinessDetailsController
                    .visitedBusinessProfileDetails
                    ?.data,
              );
            }),

            // --- Choose Room ---
            SizedBox(height: SizeConfig.size16),
            _buildChooseRoom(),

            // --- Gallery ---
            SizedBox(height: SizeConfig.size16),
            _buildGallerySection(),

            // --- Amenities ---
            SizedBox(height: SizeConfig.size16),
            _buildAmenitiesSection(),

            // --- Contact Us ---
            SizedBox(height: SizeConfig.size16),
            _buildContactCard(),
            SizedBox(height: SizeConfig.size16),

            /// WEBSITE PREVIEW
            WebsitePreviewCard(
              url: profile?.website ?? '',
            ),

            // --- Location Map ---
            SizedBox(height: SizeConfig.size16),
            _buildLocationSection(),

            SizedBox(height: kBottomNavigationBarHeight + 30),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final size = MediaQuery.of(context).size;

    return CommonCardWidget(
      padding: 0,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner + Logo
          SizedBox(
            height: size.height * 0.21,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner
                Container(
                  width: double.infinity,
                  height: size.height * 0.17,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: (profile?.coverUrl?.isNotEmpty ?? false)
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: profile?.coverUrl ?? "",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: size.height * 0.17,
                            placeholder: (ctx, _) =>
                                Container(color: Colors.blueGrey[100]),
                            errorWidget: (ctx, _, __) => Container(
                              color: Colors.blueGrey[100],
                              child: Icon(Icons.image_outlined,
                                  color: Colors.blueGrey[300], size: 40),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.image_outlined,
                              color: Colors.blueGrey[300], size: 40),
                        ),
                ),

                // Logo
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
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                    ),
                    child: ClipOval(
                      child: (profile?.logoUrl?.isNotEmpty ?? false)
                          ? CachedNetworkImage(
                              imageUrl: profile?.logoUrl ?? "",
                              fit: BoxFit.cover,
                              placeholder: (ctx, _) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                              errorWidget: (ctx, _, __) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                            )
                          : LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Name & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  profile?.name ?? "",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile?.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  ExpandableText(
                    text: profile?.description ?? "",
                    trimLines: 2,
                    expandMode: ExpandMode.dialog,
                  ),
                ],
              ],
            ),
          ),

          // Rating, Reviews & Distance
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: _buildRatingDistanceRow(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistanceRow() {
    final coords = profile?.location?.coordinates;
    String? distanceText;

    if (coords != null &&
        coords.length >= 2 &&
        LocationService.lat != 0.0 &&
        LocationService.lng != 0.0) {
      final hotelLat = coords[1].toDouble();
      final hotelLng = coords[0].toDouble();
      if (hotelLat != 0.0 && hotelLng != 0.0) {
        final km = calculateDistanceKm(
          LocationService.lat,
          LocationService.lng,
          hotelLat,
          hotelLng,
        );
        distanceText = '${km.toStringAsFixed(1)} ${AppStrings.kmAwayLabel.tr}';
      }
    }

    return CommonRatingRow(
      rating: double.tryParse(profile?.rating?.toString() ?? '0') ?? 0.0,
      reviews: profile?.reviews ?? 0,
      distance: distanceText,
    );
  }

  // ─── CHOOSE ROOM ───────────────────────────────────────────────────

  Widget _buildChooseRoom() {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.chooseRoom),
          const SizedBox(height: 12),
          if (types.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noRoomsAvailable.tr,
                imageSize: 60,
              ),
            )
          else ...[
            // Room type chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: types.map((type) {
                  bool isSelected = selectedRoomType == type;
                  return GestureDetector(
                    onTap: () => setState(() => selectedRoomType = type),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.secondaryTextColor,
                        ),
                      ),
                      child: CustomText(
                        _formatTypeName(type),
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.normal,
                        fontSize: SizeConfig.medium,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Room cards
            SizedBox(
              height: 310,
              child: filteredRooms.isEmpty
                  ? const Center(child: CustomText(AppStrings.noRoomsAvailable))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        return _buildRoomCard(filteredRooms[index]);
                      },
                    ),
            ),
          ],
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Rooms room) {
    final imageUrl = room.images?.exteriorImages?.firstOrNull ?? '';
    return Container(
      width: 236,
      height: 303,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, _) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (ctx, _, __) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.hotel,
                            size: 50, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.hotel, size: 50, color: Colors.grey),
                    ),
            ),
          ),

          // Bottom overlay
          Positioned(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
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
                      CustomText(
                        room.name ?? "N/A",
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        "\u20B9${room.pricePerDay ?? 0}/day",
                        color: Colors.white,
                        fontSize: 16,
                        maxLines: 1,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 5),
                      if (room.bedType?.isNotEmpty ?? false)
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
                              fontSize: SizeConfig.small,
                            ),
                          ],
                        ),
                      if (room.maxOccupancy?.isNotEmpty ?? false) ...[
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: SizeConfig.small,
                            ),
                          ],
                        ),
                      ],
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

  // ─── GALLERY ────────────────────────────────────────────────────────

  Widget _buildGallerySection() {
    final allImages = profile?.photos
            ?.expand((p) => p.imageReferences ?? <String>[])
            .toList() ??
        [];

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.gallery),
          const SizedBox(height: 12),
          if (allImages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noPhotosAvailableMsg.tr,
                imageSize: 60,
              ),
            )
          else
            HotelHomeGalleryWidget(photos: profile?.photos),
        ],
      ),
    );
  }

  // ─── AMENITIES ──────────────────────────────────────────────────────

  Widget _buildAmenitiesSection() {
    final amen = profile?.amenities;
    final chips = <_AmenityItem>[];
    if (amen?.freeWifi == true)
      chips.add(_AmenityItem(Icons.wifi, AppStrings.amenityWifi.tr));
    if (amen?.airConditioning == true)
      chips.add(_AmenityItem(Icons.ac_unit, AppStrings.amenityAC.tr));
    if (amen?.television == true)
      chips.add(_AmenityItem(Icons.tv, AppStrings.amenityTV.tr));
    if (amen?.roomService == true)
      chips.add(
          _AmenityItem(Icons.room_service, AppStrings.amenityRoomService.tr));
    if (amen?.powerBackup == true)
      chips.add(_AmenityItem(
          Icons.battery_charging_full_sharp, AppStrings.amenityPowerBackup.tr));
    if (amen?.balcony == true)
      chips.add(_AmenityItem(Icons.balcony, AppStrings.amenityBalcony.tr));
    if (amen?.attachedBathroom == true)
      chips.add(_AmenityItem(Icons.bathroom, AppStrings.amenityBathroom.tr));
    if (amen?.wardrobe == true)
      chips.add(
          _AmenityItem(Icons.devices_other, AppStrings.amenityWardrobe.tr));
    if (amen?.deskChair == true)
      chips.add(_AmenityItem(Icons.chair, AppStrings.amenityDeskChair.tr));
    if (amen?.roomRefrigerators == true)
      chips.add(_AmenityItem(Icons.kitchen, AppStrings.amenityRefrigerator.tr));
    if (amen?.electricKettle == true)
      chips.add(_AmenityItem(
          Icons.electric_bolt, AppStrings.amenityElectricKettle.tr));

    final displayChips = chips.length > 5 ? chips.sublist(0, 5) : chips;
    final hasMore = chips.length > 5;

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.hotelAmenities),
          SizedBox(height: SizeConfig.size12),
          if (chips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noAmenitiesListed.tr,
                imageSize: 60,
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                ...displayChips.map((a) => _amenityChip(a.icon, a.label)),
                if (hasMore)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: CustomText(
                            AppStrings.hotelAmenities.tr,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          content: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: chips
                                .map((a) => _amenityChip(a.icon, a.label))
                                .toList(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: CustomText(AppStrings.close,
                                  color: AppColors.primaryColor),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xffEAF2FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.1)),
                      ),
                      child: CustomText(
                        '+${chips.length - 5} ${AppStrings.viewMoreLabel.tr}',
                        fontSize: SizeConfig.small,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _amenityChip(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 22),
        ),
        const SizedBox(height: 4),
        CustomText(label, fontSize: 11, textAlign: TextAlign.center),
      ],
    );
  }

  // ─── CONTACT US (clickable) ─────────────────────────────────────────

  Widget _buildContactCard() {
    final contact = profile?.contacts?.firstOrNull;
    final hasContact = (contact?.email?.isNotEmpty ?? false) ||
        (contact?.phone?.isNotEmpty ?? false) ||
        (profile?.website?.isNotEmpty ?? false) ||
        (profile?.location?.name?.isNotEmpty ?? false);

    final firstImageUrl = profile?.photos
        ?.expand((p) => p.imageReferences ?? <String>[])
        .firstOrNull;

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.contactUs),
          const SizedBox(height: 12),
          if (!hasContact && (profile?.name?.isEmpty ?? true))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: AppStrings.noContactDetailsMsg.tr,
                imageSize: 60,
              ),
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
                  // Logo & Name
                  Row(
                    children: [
                      if (firstImageUrl?.isNotEmpty ?? false)
                        Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: firstImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (ctx, _) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                              errorWidget: (ctx, _, __) => LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: CustomText(
                          profile?.name ?? '',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (profile?.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    ExpandableText(text: profile?.description ?? ""),
                  ],
                  const Divider(height: 20),

                  // Clickable contact items
                  if (profile?.website?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.website_click,
                      label: profile?.website ?? "",
                      iconColor: AppColors.primaryColor,
                      onTap: () => _launchUrl(profile?.website ?? ""),
                    ),
                  if (contact?.email?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.email,
                      label: contact?.email ?? "",
                      iconColor: AppColors.secondaryTextColor,
                      onTap: () => _launchEmail(contact?.email ?? ""),
                    ),
                  if (contact?.phone?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.phone_outline,
                      label: contact?.phone ?? "",
                      iconColor: AppColors.secondaryTextColor,
                      onTap: () => _launchCaller(contact?.phone ?? ""),
                    ),
                  if (profile?.location?.name?.isNotEmpty ?? false)
                    _contactItemClickable(
                      icon: AppIconAssets.location_new,
                      label: profile?.location?.name ?? "",
                      iconColor: Colors.grey[700]!,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _contactItemClickable({
    required String icon,
    required String label,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              LocalAssets(
                imagePath: icon,
                imgColor: iconColor,
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  label,
                  color: onTap != null
                      ? AppColors.primaryColor
                      : AppColors.mainTextColor,
                  fontSize: SizeConfig.medium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LOCATION ───────────────────────────────────────────────────────

  Widget _buildLocationSection() {
    final coords = profile?.location?.coordinates;
    if (coords == null ||
        coords.length < 2 ||
        (coords[0] == 0.0 && coords[1] == 0.0)) {
      return const SizedBox.shrink();
    }

    return BusinessLocationWidget(
      locationText: profile?.location?.name,
      latitude: coords[1].toDouble(),
      longitude: coords[0].toDouble(),
      businessName: profile?.name ?? "",
      padding: 0,
      isTitleShow: true,
    );
  }

  // ─── LAUNCHERS ──────────────────────────────────────────────────────

  void _launchCaller(String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'\s+\b|\b\s+'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenDialer.tr);
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }

  void _launchEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenEmail.tr);
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
    }
  }

  void _launchUrl(String url) async {
    try {
      String finalUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        finalUrl = 'https://$url';
      }
      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        commonSnackBar(message: AppStrings.couldNotOpenLink.tr);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }
}

class _AmenityItem {
  final IconData icon;
  final String label;
  _AmenityItem(this.icon, this.label);
}

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/Discover/view/hotel_discover_home_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_via_blueera_partner_banner.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_map_widgets.dart';
import 'package:BlueEra/features/common/Discover/widget/home_stay_details_widget.dart';
import 'package:BlueEra/features/common/Discover/widget/hotel_stay_details_widget.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/Discover/widget/vehicle_details_widget.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/local_assets.dart';

class AllStayServiceScreen extends StatefulWidget {
  final List<OnboardingCategoryModel> stayCategories;
  final OnboardingCategoryModel? selectedStayCategory;

  const AllStayServiceScreen(
      {super.key, required this.stayCategories, this.selectedStayCategory});

  @override
  State<AllStayServiceScreen> createState() => _AllStayServiceScreenState();
}

class _AllStayServiceScreenState extends State<AllStayServiceScreen> {
  final controller = getOrPut(() => DiscoverController());
  ScrollController scrollController = ScrollController();
  late List<OnboardingCategoryModel> _stayCategories;
  late String _category;

  @override
  initState() {
    super.initState();
    _stayCategories = widget.stayCategories;
    controller.selectedStayCategory.value = widget.selectedStayCategory;
    _category = controller.selectedStayCategory.value!.slugId;

    if (controller.selectedStayCategory.value != null) {
      if (controller.selectedStayCategory.value?.accountType.toUpperCase() ==
          AppConstants.individual) {
        var serviceType = _category.toRentalServiceType();
        controller.fetchRentalServices(
          rentalServiceType: serviceType,
        );

        // Listener for Pagination
        scrollController.addListener(() {
          if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent) {
            controller.fetchRentalServices(
                rentalServiceType: serviceType, isLoadMore: true);
          }
        });
      } else {
        // handle business rental api call
        controller.fetchHotelServices(category: _category);

        // Listener for Pagination
        scrollController.addListener(() {
          if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent) {
            controller.fetchHotelServices(
                category: _category, isLoadMore: true);
          }
        });
      }
    }
  }

  /// Opens the dedicated full-screen cluster map for the active stay
  /// category. Routes to the rental fetch for individual hosts and to
  /// the hotel fetch for businesses, then hands the resulting list to
  /// [_StayMapScreen].
  void _openStayMapScreen() {
    final cat = controller.selectedStayCategory.value;
    if (cat == null) return;
    final isIndividual =
        cat.accountType.toUpperCase() == AppConstants.individual;

    if (isIndividual) {
      final serviceType = _category.toRentalServiceType();
      controller.fetchAllRentalsForMap(rentalServiceType: serviceType);
    } else {
      controller.fetchAllHotelsForMap(category: _category);
    }
    Get.to(
      () => _StayMapScreen(isIndividual: isIndividual),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Tab-aware "Add ___" CTA. Reactive to `selectedStayCategory` so
        // the label/icon/route flip as the user moves between sticky
        // tabs. Only shown for individual rental categories — hotel /
        // business tabs (HOTELS_RESORT, HOSTELS_PAYING_GUEST, etc.) get
        // no FAB because the listing-add routes don't apply to them.
        floatingActionButton: Obx(() {
          final spec = _addRentalSpec(controller.selectedStayCategory.value);
          if (spec == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => Get.toNamed(spec.route),
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.white,
            icon: Icon(spec.icon),
            label: CustomText(
              spec.label,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: SizeConfig.medium,
            ),
          );
        }),
        body: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: DiscoverMapPreview(
                    statusBarHeight: statusBarHeight,
                    onTap: _openStayMapScreen,
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyCategoryHeaderDelegate(
                    topPadding: statusBarHeight,
                    categories: _stayCategories
                        .map((c) => StickyCategory(
                              id: c.slugId,
                              name: c.name,
                              imageUrl: c.icon,
                            ))
                        .toList(),
                    selectedId: controller.selectedStayCategory.value?.slugId,
                    onCategoryTap: (item) {
                      final cat = _stayCategories
                          .firstWhere((c) => c.slugId == item.id);
                      controller.selectedStayCategory.value = cat;
                      controller.selectedTabIndex.value =
                          _stayCategories.indexOf(cat);
                      _category = cat.slugId;
                      if (cat.accountType == AppConstants.individual) {
                        final serviceType = _category.toRentalServiceType();
                        controller.fetchRentalServices(
                            rentalServiceType: serviceType);
                      } else {
                        controller.fetchHotelServices(category: _category);
                      }
                      setState(() {});
                    },
                    onBack: () => Navigator.pop(context),
                    expandedLabelColor: AppColors.white,
                    backgroundGradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.blue5CAF.withValues(alpha: 0.1),
                        AppColors.blue5CAF.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: BookViaBlueEraPartnerBanner(onTap: () {}),
                ),
                _buildListSliver(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ({String label, String route, IconData icon})? _addRentalSpec(
      OnboardingCategoryModel? cat) {
    if (cat == null) return null;
    if (cat.accountType.toUpperCase() != AppConstants.individual) {
      return null;
    }
    switch (cat.slugId) {
      case AppConstants.flat:
        return (
          label: AppStrings.addHouse.tr,
          route: RouteHelper.getAddFlatRoomRentalServiceScreenRoute(),
          icon: Icons.house_rounded,
        );
      case AppConstants.vehicle:
        return (
          label: AppStrings.addVehicleLabel.tr,
          route: RouteHelper.getVehicleRentalServiceRoute(),
          icon: Icons.directions_car_rounded,
        );
      case AppConstants.property:
        return (
          label: AppStrings.addOther.tr,
          route: RouteHelper.getHomeStayRentalServiceRoute(),
          icon: Icons.add_home_rounded,
        );
    }
    return null;
  }

  Widget _buildListSliver() {
    return Obx(() {
      final isIndividual = controller.selectedStayCategory.value?.accountType ==
          AppConstants.individual;

      if (isIndividual) {
        if (controller.isRentalServiceLoading.value &&
            controller.rentalServices.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.rentalServices.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _NoHotelsFound(
              title: AppStrings.noStaysAvailable.tr,
              subtitle: AppStrings.noStaysAvailableHint.tr,
              onRetry: () {
                final serviceType = _category.toRentalServiceType();
                controller.fetchRentalServices(rentalServiceType: serviceType);
              },
            ),
          );
        }

        final list = controller.rentalServices;
        final showMoreLoader = controller.isRentalServiceLoadingMore.value;
        final rows = buildNativeAdRows(list.length);

        return SliverPadding(
          padding: EdgeInsets.only(
            left: SizeConfig.size8,
            right: SizeConfig.size8,
            bottom: SizeConfig.paddingL,
          ),
          sliver: SliverList.builder(
            itemCount: rows.length + (showMoreLoader ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == rows.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final row = rows[index];
              if (row.isAd) {
                return NativeAdSlot(
                  adOrdinal: row.adOrdinal,
                  keyPrefix: 'stay_service_native_ad',
                );
              }
              return rentalServiceCard(list[row.contentIndex]);
            },
          ),
        );
      }

      // Business (hotel) branch
      if (controller.isRentalServiceLoading.value &&
          controller.hotelServices.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.hotelServices.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _NoHotelsFound(
            title: AppStrings.noHotelsRoomsAvailable.tr,
            subtitle: AppStrings.noHotelsRoomsAvailableHint.tr,
            onRetry: () => controller.fetchHotelServices(category: _category),
          ),
        );
      }

      final list = controller.hotelServices;
      final showMoreLoader = controller.isRentalServiceLoadingMore.value;
      final rows = buildNativeAdRows(list.length);

      return SliverPadding(
        padding: EdgeInsets.only(
          left: SizeConfig.size8,
          right: SizeConfig.size8,
          bottom: SizeConfig.paddingL,
        ),
        sliver: SliverList.builder(
          itemCount: rows.length + (showMoreLoader ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == rows.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final row = rows[index];
            if (row.isAd) {
              return NativeAdSlot(
                adOrdinal: row.adOrdinal,
                keyPrefix: 'stay_service_native_ad',
              );
            }
            return hotelServiceCard(list[row.contentIndex]);
          },
        ),
      );
    });
  }

  /// Discover rental listing card — mirrors the showroom reference
  /// design (image slider → title → description → spec strip → price →
  /// Chat / Book Now). Works for both vehicle and property/flat rentals,
  /// swapping the spec cells to suit the [RentalServiceData.type].
  Widget rentalServiceCard(RentalServiceData service) {
    final rentalCoords = service.location?.coordinates;
    final distanceData = (rentalCoords != null && rentalCoords.length >= 2)
        ? calculateDistance(
            rentalCoords[1].toDouble(), rentalCoords[0].toDouble())
        : null;

    final images = service.images ?? const <String>[];
    final rating = double.tryParse(service.rating?.toString() ?? '') ?? 0.0;

    void openDetails() {
      (service.type == AppConstants.property ||
              service.type == AppConstants.flat)
          ? Get.to(HomeStayDetailsWidget(service: service))
          : Get.to(VehicleDetailsWidget(service: service));
    }

    return GestureDetector(
      onTap: openDetails,
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size10),
        decoration: BoxDecoration(
          color: Colors.white,
          // color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF4)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14001120), blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rentalImageHeader(images, rating),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    service.name ?? AppStrings.unknownUser.tr,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((service.highlights?.isNotEmpty ?? false) ||
                      (service.description?.trim().isNotEmpty ?? false)) ...[
                    SizedBox(height: SizeConfig.size6),
                    CustomText(
                      (service.highlights?.isNotEmpty ?? false)
                          ? service.highlights!.join(", ")
                          : service.description!.trim(),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (_rentalSpecs(service).isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size12),
                    _rentalSpecStrip(service),
                  ],
                  SizedBox(height: SizeConfig.size12),
                  _rentalPriceRow(service, distanceData),
                  SizedBox(height: SizeConfig.size12),
                  _rentalActions(service, openDetails),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Image header (slider + overlays) ────────────────────────────
  Widget _rentalImageHeader(List<String> images, double rating) {
    return Stack(
      children: [
        CustomImageSlideshow(
          isLoading: false,
          imagePaths: images,
          width: double.infinity,
          height: 190,
          boxFit: BoxFit.cover,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        if (rating > 0)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 6)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  SizedBox(width: SizeConfig.size2),
                  CustomText(
                    rating.toStringAsFixed(1),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          right: 10,
          top: 10,
          child: Column(
            children: [
              _circleAction(Icons.share_outlined),
              SizedBox(height: SizeConfig.size8),
              _circleAction(Icons.favorite_border_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleAction(IconData icon) {
    return GestureDetector(
      onTap: () => commonSnackBar(message: "Coming soon...."),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6)],
        ),
        child: Icon(icon, size: 18, color: AppColors.mainTextColor),
      ),
    );
  }

  // ─── Spec strip ───────────────────────────────────────────────────
  /// (icon, label) cells driven by the rental type — only the specs the
  /// listing actually carries are emitted, capped at three.
  List<MapEntry<IconData, String>> _rentalSpecs(RentalServiceData service) {
    final specs = <MapEntry<IconData, String>>[];
    if (service.type == AppConstants.vehicle) {
      final v = service.vehicleDetails;
      if ((v?.fuelType ?? '').trim().isNotEmpty) {
        specs.add(
            MapEntry(Icons.local_gas_station_outlined, v!.fuelType!.trim()));
      }
      if (v?.seatingCapacity != null) {
        specs.add(MapEntry(
          Icons.event_seat_outlined,
          '${v!.seatingCapacity} ${AppStrings.seats.tr}',
        ));
      }
      if (v?.yearOfManufacture != null) {
        specs.add(
            MapEntry(Icons.calendar_today_outlined, '${v!.yearOfManufacture}'));
      } else if ((v?.vehicleType ?? '').trim().isNotEmpty) {
        specs.add(
            MapEntry(Icons.directions_car_outlined, v!.vehicleType!.trim()));
      }
    } else {
      final p = service.propertyDetails;
      if ((p?.bhk ?? '').trim().isNotEmpty) {
        specs.add(MapEntry(Icons.home_outlined, p!.bhk!.trim()));
      }
      if (p?.beds != null) {
        specs.add(MapEntry(Icons.bed_outlined, '${p!.beds}'));
      }
      if ((p?.propertyType ?? '').trim().isNotEmpty) {
        specs.add(MapEntry(Icons.apartment_outlined, p!.propertyType!.trim()));
      }
    }
    return specs.take(3).toList();
  }

  Widget _rentalSpecStrip(RentalServiceData service) {
    final specs = _rentalSpecs(service);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEFF4)),
      ),
      child: Row(
        children: List.generate(specs.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Container(
                width: 1, height: 34, color: const Color(0xFFE0E6EE));
          }
          final spec = specs[i ~/ 2];
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(spec.key, size: 18, color: AppColors.primaryColor),
                SizedBox(height: SizeConfig.size4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CustomText(
                    spec.value,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Price + distance ─────────────────────────────────────────────
  Widget _rentalPriceRow(RentalServiceData service, double? distanceData) {
    final hasPrice = service.price != null && service.priceUnit != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasPrice)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.price.tr,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    '₹${service.price}/${service.priceUnit}',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          )
        else
          const Spacer(),
        if (distanceData != null) ...[
          SizedBox(width: SizeConfig.size8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.near_me_outlined,
                  size: SizeConfig.size16, color: AppColors.secondaryTextColor),
              SizedBox(width: SizeConfig.size2),
              CustomText(
                '$distanceData KM',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────
  Widget _rentalActions(RentalServiceData service, VoidCallback onBook) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _openRentalChat(service),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 16, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    AppStrings.chat.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: onBook,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    AppStrings.bookNow.tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Opens a chat with the hotel/business owner from the hotel card's chat
  /// option. Mirrors the hospital/business discover cards: records a
  /// chat-click against the businessId, then opens the discover chat lane.
  Future<void> _openHotelChat(HotelServiceData service) async {
    final businessId = service.businessId ?? service.profile?.businessId ?? '';
    if (businessId.isEmpty) {
      Get.snackbar(
        AppStrings.na.tr,
        AppStrings.businessNotAvailableForChat.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    ChatClickTracker.track(
      userId: businessId,
      source: ChatClickSource.searchResult,
    );
    final chatViewController = Get.find<ChatViewController>();
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: businessId,
      name: service.profile?.name,
      profile: service.profile?.logoUrl,
      route: AppConstants.route_discover,
    );
  }

  Future<void> _openRentalChat(RentalServiceData service) async {
    final ownerId = service.userId;
    if (ownerId == null || ownerId.isEmpty) {
      Get.snackbar(
        AppStrings.na.tr,
        AppStrings.businessNotAvailableForChat.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final chatViewController = Get.find<ChatViewController>();
    await chatViewController.checkChatConnectionAndOpenChat(
      userId: ownerId,
      route: AppConstants.route_discover,
    );
  }

  Widget hotelServiceCard(HotelServiceData service) {
    final coords = service.profile?.location?.coordinates;
    final distance = (coords != null && coords.length >= 2)
        ? calculateDistanceInt(coords[1].toDouble(), coords[0].toDouble())
        : 0;
    List<String> allImages = service.profile?.photos
            ?.expand((photo) =>
                photo.imageReferences ?? []) // Flatten all image lists
            .map((url) => url.toString()) // Ensure they are strings
            .take(5) // Stop after 5 items
            .toList() ??
        []; // Fallback to empty list

    // "Starting From" → cheapest room across the listing.
    final roomPrices = (service.rooms ?? [])
        .map((r) => r.pricePerDay)
        .whereType<int>()
        .toList()
      ..sort();
    final startingPrice = roomPrices.isNotEmpty ? roomPrices.first : null;

    void openDetails() => Get.to(() => HotelDiscoverHomeScreen(data: service));

    return InkWell(
      onTap: openDetails,
      child: PropertyCard(
        imageUrls: allImages,
        logoUrl: service.profile?.logoUrl ?? '',
        hotelName: service.profile?.name ?? "N/A",
        businessId: service.businessId ?? service.profile?.businessId,
        address: [
          service.profile?.address?.street,
          service.profile?.address?.city,
          service.profile?.address?.state,
        ].where((e) => e != null && e.isNotEmpty).join(', '),
        distance: distance.toString(),
        rent: startingPrice?.toString() ?? '',
        rating: (service.profile?.rating ?? 0).toDouble(),
        reviews: service.profile?.reviews ?? 0,
        checkInTime: service.profile?.policy?.checkInTime ?? '',
        checkOutTime: service.profile?.policy?.checkOutTime ?? '',
        amenities: _hotelAmenities(service.profile?.amenities),
        // Tapping "Inquiry" navigates to the detail screen; the customer
        // starts the actual enquiry-first flow from the detail screen's
        // own Inquiry button (which opens the enquiry sheet + primes the
        // room cache used by the eventual booking sheet).
        onInquiry: openDetails,
        onChat: () => _openHotelChat(service),
      ),
    );
/*
    return InkWell(
      onTap: () {
        Get.to(HotelDiscoverHomeScreen(
          data: service,
        ));
      },
      child: CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size10),
          margin: EdgeInsets.only(bottom: SizeConfig.size10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (profile?.coverUrl?.isNotEmpty ?? false)
                      ? InkWell(
                          onTap: () {
                            // Navigate to details
                          },
                          child: CachedAvatarWidget(
                            imageUrl: profile?.coverUrl,
                            size: SizeConfig.size40,
                            borderColor: Colors.white,
                            borderRadius: SizeConfig.size20,
                          ),
                        )
                      : ClipRRect(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size20),
                          child: LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            height: SizeConfig.size40,
                            width: SizeConfig.size40,
                          ),
                        ),
                  SizedBox(width: SizeConfig.size6),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(service.profile?.name ?? AppStrings.na,
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                      SizedBox(height: SizeConfig.size6),
                      CommonRatingRow(
                        rating: double.tryParse(
                                profile?.rating.toString() ?? '0.0') ??
                            0.0,
                        reviews: profile?.reviews ?? 0,
                        distance: '${distance?.toStringAsFixed(2)} KM',
                      )
                    ],
                  )),
                  // Icon(Icons.more_vert, color: AppColors.black)
                ],
              ),

              if (profile?.photos?.firstOrNull?.imageReferences?.isNotEmpty ??
                  false) ...[
                SizedBox(height: SizeConfig.size6),
                CustomText(profile?.description ?? "",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400),
              ],

              // SizedBox(height: SizeConfig.size8),
              //
              // if(service.price!=null && service.priceUnit!=null)
              //   CustomText(
              //     '₹${service.price}/${service.priceUnit}',
              //     fontSize: SizeConfig.medium,
              //     fontWeight: FontWeight.w700,
              //     color: AppColors.mainTextColor,
              //   ),
              // SizedBox(height: SizeConfig.size8),
              //
              // if(service.type == AppConstants.property || service.type == AppConstants.flat)
              //   FittedBox(
              //     fit: BoxFit.scaleDown,
              //     child: Row(
              //       children: [
              //         CustomText(
              //           "Check In: ",
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           overflow: TextOverflow.ellipsis,
              //           color: AppColors.green00,
              //         ),
              //         CustomText(
              //           service.checkInTime,
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           overflow: TextOverflow.ellipsis,
              //           color: AppColors.secondaryTextColor,
              //           maxLines: 1,
              //         ),
              //         CustomText(
              //           ' | ',
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           color: AppColors.secondaryTextColor,
              //           overflow: TextOverflow.ellipsis,
              //         ),
              //         CustomText(
              //           "Check Out: ",
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           overflow: TextOverflow.ellipsis,
              //           color: AppColors.redB4,
              //           maxLines: 1,
              //         ),
              //         CustomText(
              //           service.checkOutTime,
              //           fontSize: SizeConfig.small,
              //           fontWeight: FontWeight.w400,
              //           color: AppColors.grayText,
              //           overflow: TextOverflow.ellipsis,
              //           maxLines: 1,
              //         ),
              //       ],
              //     ),
              //   ),
            ],
          )),
    );
*/
  }

  /// Maps the hotel-level boolean amenity flags to (icon, label) pairs for
  /// the card's amenity grid — only enabled amenities are emitted, in a
  /// stable display order matching the design.
  List<MapEntry<IconData, String>> _hotelAmenities(Amenities? a) {
    if (a == null) return const [];
    final list = <MapEntry<IconData, String>>[];
    void add(bool? on, IconData icon, String label) {
      if (on == true) list.add(MapEntry(icon, label));
    }

    add(a.freeParking, Icons.local_parking_rounded, 'Free Parking');
    add(a.restaurant, Icons.restaurant_rounded, 'Restaurant');
    add(a.frontDesk24x7, Icons.support_agent_rounded, '24x7 Front Desk');
    add(a.elevatorLift, Icons.elevator_rounded, 'Elevator/Lift');
    add(a.cctvSurveillance, Icons.videocam_rounded, 'CCTV Surveillance');
    add(a.powerBackup, Icons.bolt_rounded, 'Power Backup');
    add(a.laundryService, Icons.local_laundry_service_rounded,
        'Laundry Service');
    add(a.swimmingPool, Icons.pool_rounded, 'Swimming Pool');
    add(a.airportTransportation, Icons.airport_shuttle_rounded,
        'Airport Transport');
    add(a.bar, Icons.local_bar_rounded, 'Bar');
    add(a.gym, Icons.fitness_center_rounded, 'Gym');
    return list;
  }

  void showFullRentalDetails(
    RentalServiceData service,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
          ),
          builder: (scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                _dragHandle(),
                _header(context),
                const SizedBox(height: 4),
                (service.type == AppConstants.property ||
                        service.type == AppConstants.flat)
                    ? HomeStayDetailsWidget(service: service)
                    : VehicleDetailsWidget(service: service),
                SizedBox(height: SizeConfig.paddingL)
              ],
            );
          },
        );
      },
    );
  }

  void showFullHotelDetails(
    HotelServiceData service,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CommonDraggableBottomSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          backgroundColor: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
          ),
          builder: (scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                _dragHandle(),
                _header(context),
                const SizedBox(height: 4),
                HotelsDetailsWidget(hotelServiceData: service),
                SizedBox(height: SizeConfig.paddingL)
              ],
            );
          },
        );
      },
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 50,
          height: 5,
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: AppColors.secondaryTextColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  Widget _header(BuildContext context) => Row(
        children: [
          Expanded(
            child: CustomText(
              AppStrings.detailsLabel,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      );
}

class PropertyCard extends StatefulWidget {
  final List<String> imageUrls;
  final String logoUrl;
  final String hotelName;
  final String address;
  final String distance;
  final String rent;
  final double rating;
  final int reviews;
  final String checkInTime;
  final String checkOutTime;
  final List<MapEntry<IconData, String>> amenities;
  final String? businessId;

  /// Tapping the pill-shaped "Inquiry" CTA on the card. The list screen
  /// wires this to open the hotel detail screen — customer sees rooms /
  /// amenities / policies there and starts the enquiry-first flow from
  /// the detail screen's own Inquiry button.
  final VoidCallback? onInquiry;
  final VoidCallback? onChat;

  const PropertyCard({
    super.key,
    required this.imageUrls,
    required this.logoUrl,
    required this.hotelName,
    required this.address,
    required this.distance,
    required this.rent,
    required this.rating,
    required this.reviews,
    required this.checkInTime,
    required this.checkOutTime,
    required this.amenities,
    this.businessId,
    this.onInquiry,
    this.onChat,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  // Dummy reviews for the read-only review sheet.
  final List<Map<String, dynamic>> _dummyReviews = const [
    {
      'name': 'Priya Sharma',
      'rating': 5.0,
      'date': '2 days ago',
      'comment':
          'Fantastic stay! The rooms were spotless and the staff was incredibly warm. Breakfast spread was delicious.',
    },
    {
      'name': 'Rahul Verma',
      'rating': 4.0,
      'date': '1 week ago',
      'comment':
          'Great value for money. Clean rooms, good location, though check-in took a little longer than expected.',
    },
    {
      'name': 'Anita Desai',
      'rating': 4.5,
      'date': '3 weeks ago',
      'comment':
          'Loved the view from our room. The pool area is well-maintained and the ambience is peaceful.',
    },
    {
      'name': 'Vikram Rao',
      'rating': 3.5,
      'date': '1 month ago',
      'comment':
          'Decent stay. Rooms could be a little more spacious but the service made up for it.',
    },
  ];

  void _openReviewsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewsBottomSheet(
        hotelName: widget.hotelName,
        rating: widget.rating,
        reviews: _dummyReviews,
      ),
    );
  }

  Future<void> _shareBusiness() async {
    final shareLink = hotelDeepLink(hotelId: widget.businessId);
    final name = widget.hotelName.trim().isNotEmpty
        ? widget.hotelName.trim()
        : 'this stay';

    await ShareService.instance.openShareSheet(
      text: "Check out $name on BlueEra:\n$shareLink",
      subject: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = widget.imageUrls.length > 1;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = (screenWidth - SizeConfig.size32) * 8 / 16;
    const logoSize = 54.0;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14001120), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageHeader(hasMultipleImages, imageHeight),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Row(
                      children: [
                        _logoAvatar(logoSize),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                widget.hotelName,
                                fontWeight: FontWeight.w600,
                                fontSize: SizeConfig.large18,
                                color: AppColors.black22,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Always show the location row — missing
                              // pieces fall back to 'N/A' so the layout
                              // stays consistent across listings.
                              SizedBox(height: SizeConfig.size4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  LocalAssets(
                                    imagePath: AppIconAssets.location_outline,
                                    imgColor: AppColors.primaryColor,
                                  ),
                                  SizedBox(width: SizeConfig.size4),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: (widget.distance.isNotEmpty &&
                                                    widget.distance != '0')
                                                ? '${widget.distance}KM Away'
                                                : 'N/A',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '  |  ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppColors.secondaryTextColor,
                                            ),
                                          ),
                                          TextSpan(
                                            text: widget.address.isNotEmpty
                                                ? widget.address
                                                : 'N/A',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color:
                                                  AppColors.secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.amenities.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size12),
                    Padding(
                      padding: EdgeInsets.fromLTRB(14, 0, 14, 0),
                      child: _amenityGrid(),
                    ),
                  ],
                  SizedBox(height: SizeConfig.size14),
                  _bottomRow(),
                ],
              ),
            ],
          ),
          // // Logo straddling the image / content seam.
          // Positioned(
          //   left: 14,
          //   top: imageHeight - (logoSize / 2),
          //   child: _logoAvatar(logoSize),
          // ),
        ],
      ),
    );
  }

  // ─── Image header (carousel + overlays) ──────────────────────────
  Widget _imageHeader(bool hasMultipleImages, double height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.imageUrls.isEmpty
                ? _brokenImage(height)
                : CarouselSlider(
                    options: CarouselOptions(
                      height: height,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: hasMultipleImages,
                      autoPlay: hasMultipleImages,
                    ),
                    items: widget.imageUrls
                        .map((url) => Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _brokenImage(height),
                            ))
                        .toList(),
                  ),
          ),
          // Bottom scrim for pill/logo legibility.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.30),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          if (widget.rating > 0)
            Positioned(
              left: 10,
              top: 10,
              child: GestureDetector(
                onTap: _openReviewsSheet,
                child: _whitePill(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.yellow),
                      SizedBox(width: SizeConfig.size2),
                      CustomText(
                        widget.rating.toStringAsFixed(1),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Single bookmark affordance top-right — long-press falls back
          // to share so the share entry point isn't lost from the surface.
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _circleIconBtn(AppIconAssets.share_bold,
                    onTap: () => _shareBusiness),
                const SizedBox(height: 8),
                _circleIconBtn(AppIconAssets.star, onTap: () {}),
              ],
            ),
          ),
          // Positioned(
          //   right: 10,
          //   bottom: 10,
          //   child: _circleIconBtn(AppIconAssets.star_rounded, onTap: (){}),
          // ),
          // Two time pills — check-in green, check-out red — with 'N/A'
          // fallback so the card layout stays stable when the listing
          // doesn't ship policy times.
          Positioned(
            right: 10,
            bottom: 10,
            child: _timeRangePill(
              checkIn:
                  widget.checkInTime.isNotEmpty ? widget.checkInTime : "N/A",
              checkOut:
                  widget.checkOutTime.isNotEmpty ? widget.checkOutTime : "N/A",
            ),
          ),
        ],
      ),
    );
  }

  Widget _whitePill({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6)],
        ),
        child: child,
      );

  Widget _timeRangePill({
    required String checkIn,
    required String checkOut,
  }) {
    final checkInLabel = _formatTime12h(checkIn);
    final checkOutLabel = _formatTime12h(checkOut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE2EE),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Check In
          LocalAssets(
            imagePath: AppIconAssets.clock_new,
            imgColor: AppColors.green0B,
            height: 13,
            width: 13,
          ),
          const SizedBox(width: 4),
          CustomText(
            checkInLabel,
            color: AppColors.green0B,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(width: 6),
          CustomText(
            "-",
            color: AppColors.grey7E,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(width: 6),
          // Check Out
          LocalAssets(
            imagePath: AppIconAssets.clock_new,
            imgColor: AppColors.redB4,
            height: 13,
            width: 13,
          ),
          const SizedBox(width: 4),
          CustomText(
            checkOutLabel,
            color: AppColors.redB4,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  /// Backend sends "HH:MM" in 24-hour form (e.g. "09:00", "15:00"). Convert
  /// to "h:mm AM/PM". Idempotent — already-formatted strings and unparseable
  /// values pass through untouched.
  String _formatTime12h(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    final upper = trimmed.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) return trimmed;
    final parts = trimmed.split(':');
    if (parts.length < 2) return trimmed;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return trimmed;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$hour12:$mm $period';
  }
  // Widget _timePill(String time) => Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //       decoration: BoxDecoration(
  //         color: AppColors.greenShade,
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withValues(alpha: 0.15),
  //             blurRadius: 6,
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Icon(Icons.schedule_rounded, size: 13, color: Colors.white),
  //           SizedBox(width: SizeConfig.size4),
  //           CustomText(
  //             time,
  //             fontSize: 11,
  //             fontWeight: FontWeight.w700,
  //             color: Colors.white,
  //           ),
  //         ],
  //       ),
  //     );

  Widget _circleIconBtn(String icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: LocalAssets(
            imagePath: icon,
            imgColor: AppColors.white,
            height: 14,
            width: 8,
          ),
        ),
      ),
    );
  }

  // ─── Amenities grid (3 columns, boxed pills) ─────────────────────
  Widget _amenityGrid() {
    final items = widget.amenities;
    // 5 amenity cells + a "+X More" cell caps the grid at 2 rows × 3
    // columns matching the reference design; overflow collapses into
    // the More chip so the card height stays predictable.
    final showMore = items.length > 6;
    final visible = showMore ? items.take(5).toList() : items.toList();
    final moreCount = items.length - visible.length;

    final cells = <Widget>[
      ...visible.map((e) => _amenityCell(e.key, e.value, isMore: false)),
      if (moreCount > 0)
        _amenityCell(
          Icons.more_horiz_rounded,
          '+$moreCount ${AppStrings.more.tr}',
          isMore: true,
        ),
    ];

    const cols = 3;
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += cols) {
      final slice = cells.sublist(i, (i + cols).clamp(0, cells.length));
      final isLast = i + cols >= cells.length;
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : SizeConfig.size8),
        child: Row(
          children: List.generate(cols, (c) {
            final child = c < slice.length ? slice[c] : const SizedBox.shrink();
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: c < cols - 1 ? SizeConfig.size8 : 0),
                child: child,
              ),
            );
          }),
        ),
      ));
    }
    return Column(children: rows);
  }

  Widget _amenityCell(IconData icon, String label, {required bool isMore}) {
    final iconColor = isMore ? const Color(0xFF66727E) : AppColors.grey7E;
    final textColor = isMore ? const Color(0xFF66727E) : AppColors.grey7E;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFDDE2EE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          SizedBox(width: SizeConfig.size6),
          Flexible(
            child: CustomText(
              label,
              fontSize: 12,
              fontWeight: isMore ? FontWeight.w400 : FontWeight.w400,
              color: textColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Starting price + chat + Book Now ────────────────────────────
  Widget _bottomRow() => Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.geryFC,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Starting From',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size2),
                  widget.rent.isEmpty
                      ? CustomText(
                          'N/A',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          // crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CustomText(
                              '₹${_formatPrice(widget.rent)}',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                            CustomText(
                              '/Day',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryTextColor,
                            ),
                          ],
                        ),
                ],
              ),
            ),
            // if (widget.onChat != null) ...[
            //   GestureDetector(
            //     onTap: widget.onChat,
            //     child: Container(
            //       height: 40,
            //       width: 40,
            //       alignment: Alignment.center,
            //       decoration: BoxDecoration(
            //         color: AppColors.primaryColor.withValues(alpha: 0.1),
            //         borderRadius: BorderRadius.circular(10),
            //         border:
            //             Border.all(color: AppColors.primaryColor, width: 0.6),
            //       ),
            //       child: Icon(Icons.chat_bubble_outline_rounded,
            //           size: 18, color: AppColors.primaryColor),
            //     ),
            //   ),
            //   SizedBox(width: SizeConfig.size10),
            // ],
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: widget.onInquiry,
                child: Container(
                  height: 40,
                  // padding:
                  //     const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        AppStrings.inquiry.tr,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppColors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  String _formatPrice(String raw) {
    final n = int.tryParse(raw);
    if (n == null) return raw;
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _logoAvatar(double size) {
    return ClipOval(
      child: widget.logoUrl.isEmpty
          ? _brokenHotelLogo(size)
          : CachedNetworkImage(
              imageUrl: widget.logoUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: size, height: size, color: AppColors.greyE5),
              errorWidget: (_, __, ___) => _brokenHotelLogo(size),
            ),
    );
  }

  Widget _brokenHotelLogo(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.greyE5,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Icon(
          Icons.broken_image_outlined,
          size: size * 0.4,
          color: AppColors.secondaryTextColor,
        ),
      );

  Widget _brokenImage(double height) => Container(
        width: double.infinity,
        height: height,
        color: AppColors.greyE5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined,
                size: SizeConfig.size40, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size6),
            CustomText(
              AppStrings.imageUnavailable.tr,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      );
}

class _ReviewsBottomSheet extends StatelessWidget {
  final String hotelName;
  final double rating;
  final List<Map<String, dynamic>> reviews;

  const _ReviewsBottomSheet({
    required this.hotelName,
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return CommonDraggableBottomSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      backgroundColor: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      padding: EdgeInsets.only(
        left: SizeConfig.size16,
        right: SizeConfig.size16,
        top: SizeConfig.size10,
      ),
      builder: (scrollController) {
        final avg = reviews.isEmpty
            ? rating
            : reviews
                    .map((r) => (r['rating'] as num).toDouble())
                    .reduce((a, b) => a + b) /
                reviews.length;

        return ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTextColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    hotelName,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size6),
            Row(
              children: [
                Icon(Icons.star_rounded,
                    color: Colors.amber, size: SizeConfig.size22),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  avg.toStringAsFixed(1),
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(width: SizeConfig.size6),
                CustomText(
                  '· ${reviews.length} ${AppStrings.reviewsLowercase.tr}',
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Divider(color: AppColors.greyE5, height: 1),
            SizedBox(height: SizeConfig.size10),
            ...reviews.map(_reviewTile),
            SizedBox(height: SizeConfig.paddingL),
          ],
        );
      },
    );
  }

  Widget _reviewTile(Map<String, dynamic> r) {
    final name = r['name'] as String;
    final rate = (r['rating'] as num).toDouble();
    final date = r['date'] as String;
    final comment = r['comment'] as String;
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: SizeConfig.size16,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.15),
                child: CustomText(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.small,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.medium,
                      color: AppColors.mainTextColor,
                    ),
                    CustomText(
                      date,
                      fontSize: SizeConfig.small,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < rate.floor();
                  final half = !filled && (i < rate);
                  return Icon(
                    half
                        ? Icons.star_half_rounded
                        : (filled
                            ? Icons.star_rounded
                            : Icons.star_border_rounded),
                    size: SizeConfig.size16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            comment,
            fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }
}

class _NoHotelsFound extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _NoHotelsFound({
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final illustrationSize = (screenWidth * 0.35).clamp(
      SizeConfig.size80,
      SizeConfig.size150,
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size24,
          vertical: SizeConfig.size16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: illustrationSize,
              height: illustrationSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor.withValues(alpha: 0.12),
                    AppColors.primaryColor.withValues(alpha: 0.04),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.hotel_outlined,
                size: illustrationSize * 0.5,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              title,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              subtitle,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: SizeConfig.size16),
              InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size20,
                    vertical: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        color: AppColors.white,
                        size: SizeConfig.size18,
                      ),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        'retry'.tr,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       final isCompact = constraints.maxHeight < 200;
  //
  //       final illustrationSize =
  //       isCompact
  //           ? SizeConfig.size80
  //           : (constraints.maxWidth * 0.35).clamp(
  //         SizeConfig.size80,
  //         SizeConfig.size150,
  //       );
  //
  //       return Center(
  //         child: SingleChildScrollView(
  //           padding: EdgeInsets.symmetric(
  //             horizontal: SizeConfig.size24,
  //             vertical: SizeConfig.size16,
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.center,
  //             children: [
  //               Container(
  //                 width: illustrationSize,
  //                 height: illustrationSize,
  //                 decoration: BoxDecoration(
  //                   shape: BoxShape.circle,
  //                   gradient: LinearGradient(
  //                     begin: Alignment.topLeft,
  //                     end: Alignment.bottomRight,
  //                     colors: [
  //                       AppColors.primaryColor.withValues(alpha: 0.12),
  //                       AppColors.primaryColor.withValues(alpha: 0.04),
  //                     ],
  //                   ),
  //                 ),
  //                 alignment: Alignment.center,
  //                 child: Icon(
  //                   Icons.hotel_outlined,
  //                   size: illustrationSize * 0.5,
  //                   color: AppColors.primaryColor,
  //                 ),
  //               ),
  //               SizedBox(height: SizeConfig.size16),
  //               CustomText(
  //                 title,
  //                 fontSize: SizeConfig.large,
  //                 fontWeight: FontWeight.w700,
  //                 color: AppColors.mainTextColor,
  //                 textAlign: TextAlign.center,
  //                 maxLines: 2,
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //               SizedBox(height: SizeConfig.size8),
  //               CustomText(
  //                 subtitle,
  //                 fontSize: SizeConfig.small,
  //                 color: AppColors.secondaryTextColor,
  //                 textAlign: TextAlign.center,
  //                 maxLines: 3,
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //               if (onRetry != null) ...[
  //                 SizedBox(height: SizeConfig.size16),
  //                 InkWell(
  //                   onTap: onRetry,
  //                   borderRadius: BorderRadius.circular(24),
  //                   child: Container(
  //                     padding: EdgeInsets.symmetric(
  //                       horizontal: SizeConfig.size20,
  //                       vertical: SizeConfig.size10,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: AppColors.primaryColor,
  //                       borderRadius: BorderRadius.circular(24),
  //                     ),
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Icon(Icons.refresh, color: AppColors.white, size: SizeConfig.size18),
  //                         SizedBox(width: SizeConfig.size6),
  //                         CustomText(
  //                           'Retry',
  //                           fontSize: SizeConfig.small,
  //                           fontWeight: FontWeight.w600,
  //                           color: AppColors.white,
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}

/// Full-screen cluster map for the stay categories. Mirrors the design
/// of the self-profession map but pulls from `rentalServicesMapList` /
/// `hotelServicesMapList` depending on whether the active category is
/// individual or business. Marker tap opens the same details flow used
/// by the list cards.
class _StayMapScreen extends StatefulWidget {
  final bool isIndividual;

  const _StayMapScreen({required this.isIndividual});

  @override
  State<_StayMapScreen> createState() => _StayMapScreenState();
}

class _StayMapScreenState extends State<_StayMapScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _stayIcon;

  final DiscoverController _ctrl = Get.find<DiscoverController>();
  static const ClusterManagerId _clusterManagerId =
      ClusterManagerId('stay_services');

  @override
  void initState() {
    super.initState();
    DiscoverMarkerIcons.circle(
      icon:
          widget.isIndividual ? Icons.home_work_outlined : Icons.hotel_outlined,
    ).then((d) {
      if (mounted) setState(() => _stayIcon = d);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (widget.isIndividual) {
      for (final s in _ctrl.rentalServicesMapList) {
        final coords = s.location?.coordinates;
        if (coords == null || coords.length < 2) continue;
        final lng = coords[0].toDouble();
        final lat = coords[1].toDouble();
        if (lat == 0 && lng == 0) continue;
        markers.add(
          Marker(
            markerId: MarkerId(s.sId ?? '${s.name}_$lat,$lng'),
            position: LatLng(lat, lng),
            clusterManagerId: _clusterManagerId,
            icon: _stayIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: s.name ?? AppStrings.unknownUser.tr,
              snippet: s.type ?? '',
              onTap: () => _openRentalDetails(s),
            ),
            onTap: () => _openRentalDetails(s),
          ),
        );
      }
    } else {
      for (final s in _ctrl.hotelServicesMapList) {
        final coords = s.profile?.location?.coordinates;
        if (coords == null || coords.length < 2) continue;
        // Hotel API returns coordinates as [lat, lng] (NOT GeoJSON
        // [lng, lat]) — sample payload: [12.9149899, 77.6058263] for
        // Bangalore. Read index 0 as latitude.
        final lat = coords[0].toDouble();
        final lng = coords[1].toDouble();
        if (lat == 0 && lng == 0) continue;
        markers.add(
          Marker(
            markerId: MarkerId(
                s.profile?.businessId ?? '${s.profile?.name}_$lat,$lng'),
            position: LatLng(lat, lng),
            clusterManagerId: _clusterManagerId,
            icon: _stayIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: s.profile?.name ?? AppStrings.na,
              snippet:
                  s.rooms?.firstOrNull?.bedType ?? AppStrings.hotelLabel.tr,
              onTap: () => _openHotelDetails(s),
            ),
            onTap: () => _openHotelDetails(s),
          ),
        );
      }
    }
    return markers;
  }

  void _openRentalDetails(RentalServiceData service) {
    if (service.type == AppConstants.property ||
        service.type == AppConstants.flat) {
      Get.to(HomeStayDetailsWidget(service: service));
    } else {
      Get.to(VehicleDetailsWidget(service: service));
    }
  }

  void _openHotelDetails(HotelServiceData service) {
    Get.to(() => HotelDiscoverHomeScreen(data: service));
  }

  Future<void> _zoomToCluster(Cluster cluster) async {
    if (_mapController == null) return;
    if (cluster.markerIds.length <= 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(cluster.position, 15),
      );
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(cluster.bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLat =
        LocationService.lat != 0.0 ? LocationService.lat : 28.6139;
    final initialLng =
        LocationService.lng != 0.0 ? LocationService.lng : 77.2090;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            // Rebuild markers reactively as the unpaginated lists arrive.
            final _ = widget.isIndividual
                ? _ctrl.rentalServicesMapList.length
                : _ctrl.hotelServicesMapList.length;
            final markers = _buildMarkers();
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(initialLat, initialLng),
                zoom: 12,
              ),
              markers: markers,
              clusterManagers: {
                ClusterManager(
                  clusterManagerId: _clusterManagerId,
                  onClusterTap: _zoomToCluster,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (c) => _mapController = c,
            );
          }),
          Obx(() {
            final isLoading =
                _ctrl.staysMapResponse.value.status == Status.INITIAL;
            if (!isLoading) return const SizedBox.shrink();
            return const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }),
          Positioned(
            top: statusBarHeight + SizeConfig.size4,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                bannerMapCircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(child: bannerMapLocationPill()),
                SizedBox(width: SizeConfig.size8),
                bannerMapCircleIconButton(
                  icon: Icons.my_location,
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(initialLat, initialLng),
                        13,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Obx(() {
              final count = widget.isIndividual
                  ? _ctrl.rentalServicesMapList.where((s) {
                      final c = s.location?.coordinates;
                      return c != null &&
                          c.length >= 2 &&
                          !(c[0] == 0 && c[1] == 0);
                    }).length
                  : _ctrl.hotelServicesMapList.where((s) {
                      final c = s.profile?.location?.coordinates;
                      return c != null &&
                          c.length >= 2 &&
                          !(c[0] == 0 && c[1] == 0);
                    }).length;
              return Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          '$count ${widget.isIndividual ? AppStrings.staysOnMapSuffix.tr : AppStrings.hotelsOnMapSuffix.tr}',
                          fontSize: SizeConfig.small,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Keeps the category slider pinned at the top while scrolling.

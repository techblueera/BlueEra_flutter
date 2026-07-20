import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_confirm_pickup_screen.dart';
import 'package:BlueEra/features/ride_booking/view/ride_destination_search_screen.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Entry screen of the ride-booking flow (screenshot 1).
///
/// Map behind, a pickup pill floating over it, and a draggable sheet holding
/// the "Where do you want to go?" affordance, recent destinations and the
/// Explore vehicle rail.
class RideHomeScreen extends StatefulWidget {
  const RideHomeScreen({super.key});

  @override
  State<RideHomeScreen> createState() => _RideHomeScreenState();
}

class _RideHomeScreenState extends State<RideHomeScreen> {
  late final RideBookingController controller;
  GoogleMapController? _mapController;

  /// Bhopal — a sane frame while the device fix resolves, so the map never
  /// opens on the null island.
  static const LatLng _fallbackCenter = LatLng(23.2599, 77.4126);

  @override
  void initState() {
    super.initState();
    // The whole flow shares one controller instance; later screens reuse it
    // via Get.find(), and it is disposed when the flow is popped.
    controller = Get.put(RideBookingController());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLng get _center {
    final lat = controller.currentLat.value;
    final lng = controller.currentLng.value;
    return (lat == 0 && lng == 0) ? _fallbackCenter : LatLng(lat, lng);
  }

  /// Destination chosen → confirm the pickup point on the map next.
  Future<void> _openDestinationSearch() async {
    final RidePlace? chosen = await Get.to<RidePlace>(
      () => const RideDestinationSearchScreen(),
    );
    if (chosen == null) return;
    controller.setDrop(chosen);
    Get.to(() => const RideConfirmPickupScreen());
  }

  void _selectRecent(RidePlace place) {
    controller.setDrop(place);
    Get.to(() => const RideConfirmPickupScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          _map(),
          _pickupPill(),
          _sheet(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- map

  Widget _map() {
    return Obx(() {
      final center = _center;
      return GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 15.5),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (c) => _mapController = c,
        markers: {
          Marker(
            markerId: const MarkerId('pickup'),
            position: center,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        },
      );
    });
  }

  /// Floating pill showing the current pickup address; tapping it lets the
  /// user re-pick the pickup point before choosing a destination.
  Widget _pickupPill() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Row(
        children: [
          RideCircleButton(icon: Icons.arrow_back, onTap: Get.back),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() {
              final place = controller.pickup.value;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Get.to(() => const RideConfirmPickupScreen()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: RideStyle.floatingShadow,
                  ),
                  child: Row(
                    children: [
                      const RideEndpointDot(color: RideStyle.pickup),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomText(
                          place?.fullAddress.isNotEmpty == true
                              ? place!.fullAddress
                              : 'Locating you…',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RideStyle.ink,
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

  // ------------------------------------------------------------------ sheet

  Widget _sheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(RideStyle.sheetRadius),
            ),
            boxShadow: RideStyle.sheetShadow,
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const RideSheetHandle(),
              _searchField(),
              const SizedBox(height: 8),
              _recentsSection(),
              const SizedBox(height: 18),
              _exploreSection(),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openDestinationSearch,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: RideStyle.hairline),
            boxShadow: RideStyle.floatingShadow,
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: RideStyle.ink, size: 24),
              const SizedBox(width: 12),
              CustomText(
                'Where do you want to go?',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: RideStyle.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentsSection() {
    return Obx(() {
      if (controller.isLoadingRecents.value && controller.recentPlaces.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
        );
      }
      if (controller.recentPlaces.isEmpty) return const SizedBox.shrink();
      return Column(
        children: [
          for (final place in controller.recentPlaces)
            _RecentPlaceTile(
              place: place,
              onTap: () => _selectRecent(place),
              onToggleSave: () => controller.toggleSavedPlace(place),
            ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------- explore

  /// Vehicle categories. Tapping one still routes through destination search —
  /// the choice is carried into the vehicle screen as a pre-selection.
  ///
  /// Uses the app's own transport artwork rather than Material glyphs, so this
  /// rail matches the vehicle imagery already used across the transport
  /// screens.
  static const List<_ExploreItem> _exploreItems = [
    _ExploreItem('Parcel on Bike', 'PARCEL', AppIconAssets.carbon_delivery),
    _ExploreItem('Auto', 'AUTO', AppIconAssets.transport_auto),
    _ExploreItem('Cab Economy', 'CAB_ECONOMY', AppIconAssets.transport_taxi),
    _ExploreItem('Bike', 'BIKE', AppIconAssets.transport_bike),
  ];

  Widget _exploreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Explore',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: RideStyle.ink,
              ),
              GestureDetector(
                onTap: _openDestinationSearch,
                child: Row(
                  children: [
                    CustomText(
                      'View All',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: RideStyle.ink,
                    ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: RideStyle.ink),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in _exploreItems)
                Expanded(
                  child: _ExploreTile(
                    item: item,
                    onTap: _openDestinationSearch,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- sub-widgets

class _RecentPlaceTile extends StatelessWidget {
  const _RecentPlaceTile({
    required this.place,
    required this.onTap,
    required this.onToggleSave,
  });

  final RidePlace place;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history,
                    size: 24, color: RideStyle.inkMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        place.title,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: RideStyle.ink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      CustomText(
                        place.subtitle,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: RideStyle.inkMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleSave,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      place.isSaved ? Icons.favorite : Icons.favorite_border,
                      size: 24,
                      color: place.isSaved
                          ? RideStyle.drop
                          : RideStyle.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Dashed rule between recents, matching the reference design.
            const _DashedDivider(),
          ],
        ),
      ),
    );
  }
}

/// Hairline made of short dashes — Flutter has no dashed border primitive.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const gapWidth = 4.0;
        final count =
            (constraints.maxWidth / (dashWidth + gapWidth)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: gapWidth),
              color: RideStyle.hairline,
            ),
          ),
        );
      },
    );
  }
}

class _ExploreItem {
  const _ExploreItem(this.label, this.code, this.assetPath);
  final String label;
  final String code;

  /// SVG under `assets/svg/` — see [AppIconAssets].
  final String assetPath;
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.item, required this.onTap});

  final _ExploreItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Container(
              height: 74,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RideStyle.surfaceTint,
                borderRadius: BorderRadius.circular(14),
              ),
              // No imgColor — these are full-colour vehicle illustrations, so
              // tinting them would flatten them to a silhouette.
              child: LocalAssets(
                imagePath: item.assetPath,
                boxFix: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            CustomText(
              item.label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: RideStyle.ink,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

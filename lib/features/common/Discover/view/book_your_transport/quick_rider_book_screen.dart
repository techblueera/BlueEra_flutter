import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/api/model/place_prediction.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/get_booking_rider_model.dart';
import 'package:BlueEra/features/common/Discover/model/nearby_discover_models.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/fare_call_queue_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';

/// Quick "book this rider" flow launched when a bike rider is tapped in the
/// "Nearest Stores" rail. Instead of opening a profile, the user picks a DROP
/// location on a full-screen map (pickup is fixed to their current location) and
/// taps "Connect to Rider" — which reuses the standard fare-call booking flow in
/// [DiscoverController] (`rider-service/fare/orders`), targeting only the tapped
/// rider, then lands on the [FareCallQueueScreen].
class QuickRiderBookScreen extends StatefulWidget {
  final NearbyWorkerCard rider;

  const QuickRiderBookScreen({super.key, required this.rider});

  @override
  State<QuickRiderBookScreen> createState() => _QuickRiderBookScreenState();
}

class _QuickRiderBookScreenState extends State<QuickRiderBookScreen> {
  final _discoverController = getOrPut(() => DiscoverController());
  final TextEditingController _searchController = TextEditingController();

  BlueMapController? _mapController;

  // Fixed pickup = the user's current location (read-only).
  LatLng? _pickupLatLng;
  String _pickupAddress = '';

  // Drop = the map centre pin; resolved to an address on every camera idle.
  LatLng? _dropLatLng;
  String? _dropAddress;
  bool _isResolvingDrop = false;
  bool _isPinDragging = false;

  // Places autocomplete.
  List<PlacePrediction> _predictions = [];
  bool _isLoadingPredictions = false;
  bool _showPredictions = false;
  Timer? _debounce;

  bool _isBooking = false;

  /// Lucknow fallback when the device location is still unknown.
  static const LatLng _fallbackLatLng = LatLng(26.7836, 80.9013);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    await LocationService.ensureUsableLocation();
    if (!mounted) return;
    final lat = LocationService.lat;
    final lng = LocationService.lng;
    setState(() {
      _pickupLatLng =
          (lat != 0.0 || lng != 0.0) ? LatLng(lat, lng) : _fallbackLatLng;
      _pickupAddress = LocationService.userCurrentAddress.value.formattedAddress;
    });
  }

  LatLng get _initialCamera => _pickupLatLng ?? _fallbackLatLng;

  // ─── Drop pin resolution ────────────────────────────────────────────────

  Future<void> _resolveDropAddress(LatLng latLng) async {
    setState(() {
      _isResolvingDrop = true;
      _dropAddress = null;
    });
    String resolved;
    try {
      resolved = await LocationService.getAddressUsingLatLng(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
    } catch (e) {
      log('quick-book reverse-geocode failed: $e');
      resolved = '';
    }
    if (!mounted) return;
    final clean = resolved.trim();
    final useless =
        clean.isEmpty || clean.replaceAll(RegExp(r'[\s,]'), '').isEmpty;
    setState(() {
      _dropLatLng = latLng;
      _dropAddress = useless
          ? 'Lat ${latLng.latitude.toStringAsFixed(5)}, '
              'Lng ${latLng.longitude.toStringAsFixed(5)}'
          : clean;
      _isResolvingDrop = false;
    });
  }

  void _recenterOnMyLocation() {
    final p = _pickupLatLng;
    if (p == null) return;
    _mapController?.moveTo(p, zoom: 16);
  }

  // ─── Places search ──────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        setState(() {
          _predictions = [];
          _showPredictions = false;
        });
      } else {
        _fetchPredictions(trimmed);
      }
    });
  }

  Future<void> _fetchPredictions(String query) async {
    setState(() {
      _isLoadingPredictions = true;
      _showPredictions = true;
    });
    try {
      final res = await PlaceRepo().autoCompleteSearch(query: query);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = res.response?.data;
        final json = (data['predictions'] as List?) ?? [];
        setState(() {
          _predictions = PlacePrediction.fromList(json);
          _isLoadingPredictions = false;
        });
      } else {
        setState(() {
          _predictions = [];
          _isLoadingPredictions = false;
        });
      }
    } catch (e) {
      log('quick-book autocomplete error: $e');
      if (mounted) {
        setState(() {
          _predictions = [];
          _isLoadingPredictions = false;
        });
      }
    }
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _showPredictions = false;
      _searchController.text = prediction.description ?? '';
      _isResolvingDrop = true;
      _dropAddress = null;
    });
    try {
      final res = await PlaceRepo()
          .getCompletePlaceDetails(placeId: prediction.placeId ?? '');
      final details = PlaceDetailsResponse.fromJson(res.response?.data);
      final loc = details.result?.geometry?.location;
      final lat = loc?.lat;
      final lng = loc?.lng;
      if (lat == null || lng == null) {
        commonSnackBar(message: 'Could not resolve that place, try another.');
        if (mounted) setState(() => _isResolvingDrop = false);
        return;
      }
      final target = LatLng(lat, lng);
      // Move the map to the picked place; the centre pin now sits on it. Use the
      // prediction's own description as the drop address (richer than a reverse
      // geocode of the point).
      _mapController?.moveTo(target, zoom: 16);
      if (!mounted) return;
      setState(() {
        _dropLatLng = target;
        _dropAddress = prediction.description ?? _dropAddress;
        _isResolvingDrop = false;
      });
    } catch (e) {
      log('quick-book place details error: $e');
      if (mounted) setState(() => _isResolvingDrop = false);
      commonSnackBar(message: 'Could not resolve that place, try another.');
    }
  }

  // ─── Booking ────────────────────────────────────────────────────────────

  bool get _canConnect {
    final drop = _dropLatLng;
    final pickup = _pickupLatLng;
    if (drop == null || pickup == null || _isResolvingDrop || _isBooking) {
      return false;
    }
    // Guard against booking a ride to the pickup itself.
    final meters = Geolocator.distanceBetween(
        pickup.latitude, pickup.longitude, drop.latitude, drop.longitude);
    return meters > 50;
  }

  Future<void> _connectToRider() async {
    if (!_canConnect) return;
    final pickup = _pickupLatLng!;
    final drop = _dropLatLng!;
    setState(() => _isBooking = true);

    final dc = _discoverController;
    // InCity passenger ride.
    dc.selectedHorizontalTab.value = 0;
    dc.selectedFromLat?.value = pickup.latitude;
    dc.selectedFromLong?.value = pickup.longitude;
    dc.selectedFromAddress?.value = _pickupAddress;
    dc.selectedToLat?.value = drop.latitude;
    dc.selectedToLong?.value = drop.longitude;
    dc.selectedToAddress?.value = _dropAddress ?? '';

    // Road distance ≈ straight-line × 1.27 (same fallback the passenger booking
    // screen uses) so the fare quote has a distance to work from.
    final meters = Geolocator.distanceBetween(
        pickup.latitude, pickup.longitude, drop.latitude, drop.longitude);
    dc.roadDistanceKm.value =
        double.parse(((meters / 1000) * 1.27).toStringAsFixed(2));

    try {
      // Fetch the fare quote (populates ridersDetailsList → twoWheelerRider.fare
      // used by makeTransportBookOrderApi).
      await dc.getBookingRidersApi();

      // Target ONLY the tapped rider: a single-element queue + receiverUserId.
      final riderUser = RiderUser(
        riderId: widget.rider.userId,
        name: widget.rider.name,
        profileImage: widget.rider.profileImage,
        distance: widget.rider.distance.toStringAsFixed(2),
      );
      dc.selectedRider.value = riderUser;
      dc.selectedRiders.assignAll([riderUser]);

      // Listeners BEFORE the booking call so no queue event is missed.
      dc.setupFareCallQueueListeners();
      final ok = await dc.makeTransportBookOrderApi();
      if (!mounted) return;
      if (ok) {
        Get.to(() => FareCallQueueScreen(orderId: dc.fareCallOrderId.value));
      }
    } catch (e) {
      log('quick-book booking error: $e');
      commonSnackBar(message: 'Unable to connect to the rider. Try again.');
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildMap(),
            _buildCenterPin(),
            // Back button.
            Positioned(
              top: 12,
              left: 12,
              child: _circleIconButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            // My-location FAB.
            Positioned(
              right: 12,
              bottom: 320,
              child: _circleIconButton(
                icon: Icons.my_location,
                iconColor: AppColors.primaryColor,
                onTap: _recenterOnMyLocation,
              ),
            ),
            _buildSearchPanel(),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Positioned.fill(
      child: BlueMap(
        initialCenter: _initialCamera,
        initialZoom: 16,
        myLocationEnabled: true,
        onMapCreated: (c) {
          _mapController = c;
          c.moveTo(_initialCamera, zoom: 16);
        },
        // BlueMap has no separate "move started" event — the first move after a
        // rest is the start, which is all the flag ever meant.
        onCameraMoved: (centre) {
          _dropLatLng = centre;
          if (!_isPinDragging) {
            setState(() {
              _isPinDragging = true;
              _isResolvingDrop = true;
              _dropAddress = null;
            });
          }
          if (_showPredictions) {
            setState(() => _showPredictions = false);
            FocusScope.of(context).unfocus();
          }
        },
        onCameraIdle: (centre) {
          if (_isPinDragging) setState(() => _isPinDragging = false);
          _resolveDropAddress(centre);
        },
      ),
    );
  }

  Widget _buildCenterPin() {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 60,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 28,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: _isPinDragging ? 16 : 10,
                  height: _isPinDragging ? 6 : 4,
                  decoration: BoxDecoration(
                    color: Colors.black
                        .withValues(alpha: _isPinDragging ? 0.18 : 0.30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                bottom: _isPinDragging ? 48 : 32,
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.red00,
                  size: 44,
                  shadows: [
                    Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Positioned(
      top: 12,
      left: 64,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search drop location',
                prefixIcon: const Icon(Icons.search, color: AppColors.grayText),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _predictions = [];
                            _showPredictions = false;
                          });
                        },
                      ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_showPredictions) _buildPredictionsList(),
        ],
      ),
    );
  }

  Widget _buildPredictionsList() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: _isLoadingPredictions
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : _predictions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CustomText('No results',
                      fontSize: 13, color: AppColors.grayText),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _predictions.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.greyE5),
                  itemBuilder: (_, i) {
                    final p = _predictions[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined,
                          color: AppColors.primaryColor, size: 20),
                      title: CustomText(
                        p.description ?? '',
                        fontSize: 13,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.black,
                      ),
                      onTap: () => _selectPrediction(p),
                    );
                  },
                ),
    );
  }

  Widget _buildBottomCard() {
    return Material(
      color: AppColors.white,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRiderRow(),
              const SizedBox(height: 14),
              // Fixed pickup — your current location (read-only).
              _locationRow(
                dotColor: AppColors.primaryColor,
                label: 'Pickup · Your location',
                value: _pickupAddress.isNotEmpty
                    ? _pickupAddress
                    : 'Fetching your location...',
              ),
              const SizedBox(height: 10),
              // Drop — the map pin.
              _locationRow(
                dotColor: AppColors.red00,
                label: 'Drop',
                value: _isResolvingDrop
                    ? 'Fetching address...'
                    : (_dropAddress?.isNotEmpty ?? false)
                        ? _dropAddress!
                        : 'Move the map or search to set drop',
                loading: _isResolvingDrop,
              ),
              const SizedBox(height: 16),
              _buildConnectButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiderRow() {
    final r = widget.rider;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withValues(alpha: 0.10),
            border: Border.all(color: AppColors.greyE5),
          ),
          child: r.profileImage.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: Uri.encodeFull(r.profileImage),
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.person,
                      color: AppColors.primaryColor),
                )
              : const Icon(Icons.person, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                r.name.isNotEmpty ? r.name : 'Rider',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              CustomText(
                '${r.displayLabel} · ${r.distance.toStringAsFixed(1)} km away',
                fontSize: 12,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (r.live)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CustomText('Live',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00A344)),
          ),
      ],
    );
  }

  Widget _locationRow({
    required Color dotColor,
    required String label,
    required String value,
    bool loading = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: dotColor, width: 3),
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(label,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (loading) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: CustomText(
                      value,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectButton() {
    final enabled = _canConnect;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? _connectToRider : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          disabledBackgroundColor:
              AppColors.primaryColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          elevation: 0,
        ),
        child: _isBooking
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const CustomText(
                'Connect to Rider',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: iconColor ?? AppColors.black),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/repo/favorite_location_repo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/map/blue_map.dart';
import 'package:BlueEra/core/map/lat_lng.dart';

/// Rapido-rider–style address picker.
///
/// Returned via `Get.back(result: {lat, lng, address})` when the user
/// taps the bottom "Select Pickup / Select Drop" button. Returns
/// `null` if the user backs out or taps "Change".
class MapPickAddressScreen extends StatefulWidget {
  final LatLng initialLatLng;
  final bool isPickup;

  /// Optional reference marker (the *other* end of the trip) so the
  /// user keeps their bearings while picking.
  final LatLng? otherEndLatLng;

  const MapPickAddressScreen({
    super.key,
    required this.initialLatLng,
    required this.isPickup,
    this.otherEndLatLng,
  });

  @override
  State<MapPickAddressScreen> createState() => _MapPickAddressScreenState();
}

class _MapPickAddressScreenState extends State<MapPickAddressScreen> {
  BlueMapController? _mapController;

  LatLng? _pickedLatLng;
  String? _pickedAddress;
  bool _isResolving = false;
  bool _isPinDragging = false;
  String? _favoriteSavingTag;

  @override
  void initState() {
    super.initState();
    _pickedLatLng = widget.initialLatLng;
    // Resolve the very first address so the bottom card isn't empty
    // when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAddress(widget.initialLatLng);
    });
  }

  Future<void> _resolveAddress(LatLng latLng) async {
    setState(() {
      _isResolving = true;
      _pickedAddress = null;
    });
    String resolved;
    try {
      resolved = await LocationService.getAddressUsingLatLng(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
    } catch (e) {
      log('reverse-geocode failed: $e');
      resolved = '';
    }
    if (!mounted) return;
    final clean = resolved.trim();
    final isUseless = clean.isEmpty ||
        clean.replaceAll(RegExp(r'[\s,]'), '').isEmpty;
    setState(() {
      _pickedAddress = isUseless
          ? 'Lat ${latLng.latitude.toStringAsFixed(5)}, '
              'Lng ${latLng.longitude.toStringAsFixed(5)}'
          : clean;
      _isResolving = false;
    });
  }

  void _recenterOnMyLocation() {
    final lat = LocationService.lat;
    final lng = LocationService.lng;
    if (lat == 0.0 && lng == 0.0) return;
    _mapController?.moveTo(LatLng(lat, lng), zoom: 16);
  }

  void _openChange() {
    // Returning null tells the caller to keep its inline-search flow
    // open so the user can re-search instead of submitting a pin.
    Navigator.of(context).pop();
  }

  void _onSubmit() {
    final point = _pickedLatLng;
    if (point == null || _isResolving) return;
    Navigator.of(context).pop({
      'lat': point.latitude,
      'lng': point.longitude,
      'address': _pickedAddress ?? '',
    });
  }

  Future<void> _saveFavorite(String tag) async {
    if (_pickedLatLng == null || _isResolving) return;
    final address = _pickedAddress ?? '';
    if (address.isEmpty) {
      commonSnackBar(message: 'Address is still loading, try again.');
      return;
    }
    setState(() => _favoriteSavingTag = tag);
    try {
      final res = await FavoriteLocationRepo().addFavoriteLocation(
        address: address,
        latitude: _pickedLatLng!.latitude,
        longitude: _pickedLatLng!.longitude,
        tag: tag,
      );
      if (!mounted) return;
      if (res.isSuccess) {
        commonSnackBar(message: 'Saved to ${_labelFor(tag)}');
      } else {
        commonSnackBar(
          message: res.message ?? 'Could not save favourite',
        );
      }
    } catch (e) {
      if (!mounted) return;
      commonSnackBar(message: 'Could not save favourite');
      log('addFavoriteLocation error: $e');
    } finally {
      if (mounted) setState(() => _favoriteSavingTag = null);
    }
  }

  String _labelFor(String tag) {
    switch (tag) {
      case 'home':
        return 'Home';
      case 'office':
        return 'Office';
      case 'hostel':
        return 'Hostel';
      default:
        return tag;
    }
  }

  List<BlueMapMarker> _referenceMarkers() {
    if (widget.otherEndLatLng == null) return const [];
    return [
      BlueMapMarker(
        id: widget.isPickup ? 'drop_ref' : 'pickup_ref',
        position: widget.otherEndLatLng!,
        icon: Icons.location_on,
        color: widget.isPickup ? Colors.red : Colors.blue,
        anchor: BlueMarkerAnchor.bottom,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            /// Full-screen map
            Positioned.fill(
              child: BlueMap(
                initialCenter: widget.initialLatLng,
                initialZoom: 16,
                myLocationEnabled: true,
                onMapCreated: (c) {
                  _mapController = c;
                  c.moveTo(widget.initialLatLng, zoom: 16);
                },
                markers: _referenceMarkers(),
                // BlueMap has no separate "move started" event, so the first
                // move after a rest doubles as one — which is exactly what the
                // flag meant anyway.
                onCameraMoved: (centre) {
                  _pickedLatLng = centre;
                  if (!_isPinDragging) {
                    setState(() {
                      _isPinDragging = true;
                      _isResolving = true;
                      _pickedAddress = null;
                    });
                  }
                },
                onCameraIdle: (centre) {
                  if (_isPinDragging) {
                    setState(() => _isPinDragging = false);
                  }
                  _resolveAddress(centre);
                },
              ),
            ),

            /// Centre pin (lifts while panning)
            IgnorePointer(
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
                            color: Colors.black.withValues(
                                alpha: _isPinDragging ? 0.18 : 0.30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        bottom: _isPinDragging ? 48 : 32,
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.greenShade,
                          size: 44,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// Back FAB (top-left over map)
            Positioned(
              top: 12,
              left: 12,
              child: _circleIconButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),

            /// My-location FAB (right, above bottom card)
            Positioned(
              right: 12,
              bottom: _bottomCardHeight() + 12,
              child: _circleIconButton(
                icon: Icons.my_location,
                iconColor: AppColors.primaryColor,
                onTap: _recenterOnMyLocation,
              ),
            ),

            /// Bottom card
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

  /// Used to lift the my-location FAB above the bottom card. Keep
  /// roughly aligned with the card's actual height.
  double _bottomCardHeight() => 290;

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
              Row(
                children: [
                  const Expanded(
                    child: CustomText(
                      'Select your location',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  InkWell(
                    onTap: _openChange,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.grayText.withValues(alpha: 0.4)),
                      ),
                      child: const CustomText(
                        'Change',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAddressTile(),
              const SizedBox(height: 16),
              _buildSaveLocationHeader(),
              const SizedBox(height: 10),
              _buildFavouriteChips(),
              const SizedBox(height: 16),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.greenShade, width: 3),
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _isResolving
                ? Row(
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor),
                        ),
                      ),
                      SizedBox(width: 8),
                      CustomText(
                        'Fetching address...',
                        fontSize: 13,
                        color: AppColors.grayText,
                      ),
                    ],
                  )
                : CustomText(
                    (_pickedAddress?.isNotEmpty ?? false)
                        ? _pickedAddress!
                        : 'Move map to pin the location',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveLocationHeader() {
    return Row(
      children: [
        const CustomText(
          'Save location as',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.greyE5,
          ),
        ),
      ],
    );
  }

  Widget _buildFavouriteChips() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _favouriteChip(
              tag: 'home', label: 'Home', icon: Icons.home_outlined),
          const SizedBox(width: 8),
          _favouriteChip(
              tag: 'office',
              label: 'Office',
              icon: Icons.business_center_outlined),
          const SizedBox(width: 8),
          _favouriteChip(
              tag: 'hostel',
              label: 'Hostel',
              icon: Icons.apartment_outlined),
          const SizedBox(width: 8),
          _addNewChip(),
        ],
      ),
    );
  }

  Widget _favouriteChip({
    required String tag,
    required String label,
    required IconData icon,
  }) {
    final isSaving = _favoriteSavingTag == tag;
    final disabled = _favoriteSavingTag != null ||
        _isResolving ||
        _pickedLatLng == null;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: disabled ? null : () => _saveFavorite(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: AppColors.grayText.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSaving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              )
            else
              Icon(icon, size: 16, color: AppColors.primaryColor),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _addNewChip() {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _promptCustomFavouriteTag,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: AppColors.grayText.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, size: 16, color: AppColors.primaryColor),
            SizedBox(width: 6),
            CustomText(
              'Add New',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptCustomFavouriteTag() async {
    if (_pickedLatLng == null || _isResolving) return;
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const CustomText(
          'Save as',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Mom\'s house',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const CustomText('Cancel',
                color: AppColors.grayText),
          ),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isEmpty) return;
              Navigator.of(ctx).pop(v);
            },
            child: const CustomText('Save',
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    if (tag != null && tag.isNotEmpty) {
      _saveFavorite(tag);
    }
  }

  Widget _buildSubmitButton() {
    final canSubmit = !_isResolving && _pickedLatLng != null;
    final title = widget.isPickup ? 'Select Pickup' : 'Select Drop';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? _onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 0,
        ),
        child: CustomText(
          title,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

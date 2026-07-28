import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/v2/profession_consultant_discover_screen_v2.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_map_widgets.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/map/view/searchLocationScreen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// **Professionals & Consultants — entry (v2).**
///
/// Location-first landing for the consultant discover flow, the exact shape
/// [SelfProfessionDiscoverEntryScreen] uses for home services: a full-bleed map,
/// a "Where you Want?" location selector (device location OR a searched place),
/// and a profession grid.
///
/// Picking a category stamps the chosen location onto [DiscoverController] as a
/// per-flow override (see [DiscoverController.setEarnDiscoverLocation]) — the
/// global [LocationService] is left untouched — then pushes the results list
/// ([ProfessionConsultantDiscoverScreenV2]) scoped to that place, which repeats
/// the same map-backdrop + draggable-sheet shape for continuity.
///
/// Note the consultant search endpoint is not location-scoped server-side, so
/// the picked place drives the map camera, the header pill and the client-side
/// distance/Nearest sort rather than the query itself. See
/// [DiscoverController.fetchAllProfessionalConsForMap].
class ProfessionConsultantDiscoverEntryScreen extends StatefulWidget {
  final List<ProfessionTypeData> professionalConsultantCategories;

  const ProfessionConsultantDiscoverEntryScreen({
    super.key,
    required this.professionalConsultantCategories,
  });

  @override
  State<ProfessionConsultantDiscoverEntryScreen> createState() =>
      _ProfessionConsultantDiscoverEntryScreenState();
}

class _ProfessionConsultantDiscoverEntryScreenState
    extends State<ProfessionConsultantDiscoverEntryScreen> {
  final _controller = getOrPut(() => DiscoverController());

  GoogleMapController? _mapController;

  // The location the search will scope to. Seeded from the device fix; the
  // user can override it with "current location" or a searched place.
  double? _lat;
  double? _lng;
  String _locationLabel = '';

  static const LatLng _fallbackCenter = LatLng(28.6139, 77.2090); // Delhi

  @override
  void initState() {
    super.initState();
    if (LocationService.lat != 0.0 || LocationService.lng != 0.0) {
      _lat = LocationService.lat;
      _lng = LocationService.lng;
    }
    _locationLabel = _deviceAddressLabel();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Best-effort short label for the device address ("SubLocality, City").
  String _deviceAddressLabel() {
    final a = LocationService.userCurrentAddress.value;
    final parts = [a.subLocality, a.city].where((p) => p.trim().isNotEmpty);
    return parts.join(', ');
  }

  LatLng get _mapTarget =>
      (_lat != null && _lng != null && !(_lat == 0 && _lng == 0))
          ? LatLng(_lat!, _lng!)
          : _fallbackCenter;

  void _recenterMap() {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_mapTarget, 13));
  }

  // ── Category tap → stamp location + open results ──────────────────────────
  void _onCategoryTap(ProfessionTypeData c) {
    _controller.setEarnDiscoverLocation(
      lat: _lat,
      lng: _lng,
      label: _locationLabel,
    );
    Get.to(() => ProfessionConsultantDiscoverScreenV2(
          professionalConsultantCategories:
              widget.professionalConsultantCategories,
          selectedProfessionConsultantData: c,
        ));
  }

  // ── Location picker ───────────────────────────────────────────────────────
  // Full-screen search (autofocus field + "Use Current Location" + recent
  // searches) — the app's standard picker. Far more room than a keyboard-
  // cramped bottom sheet, and it handles the current-location + recents flows
  // for us. It reports the pick through [onPlaceSelected] then pops.
  Future<void> _openLocationPicker() async {
    double? pickedLat;
    double? pickedLng;
    String? pickedAddress;
    await Get.to(() => SearchLocationScreen(
          fromScreen: '',
          onPlaceSelected: (lat, lng, address) {
            pickedLat = lat;
            pickedLng = lng;
            pickedAddress = address;
          },
        ));
    if (pickedLat != null && pickedLng != null) {
      _applyPickedLocation(
        lat: pickedLat,
        lng: pickedLng,
        label: (pickedAddress ?? '').trim(),
      );
    }
  }

  void _applyPickedLocation({
    required double? lat,
    required double? lng,
    required String label,
  }) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _locationLabel = label;
    });
    _recenterMap();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative map backdrop (not pannable — the sheet owns gestures).
          Positioned.fill(
            child: AbsorbPointer(
              child: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _mapTarget, zoom: 13),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (c) => _mapController = c,
              ),
            ),
          ),
          // Header: back + "Professionals & Consultants" pill.
          Positioned(
            top: topInset + SizeConfig.size8,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                bannerMapCircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size16,
                      vertical: SizeConfig.size12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F001120),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CustomText(
                      AppStrings.professionalsConsultant.tr,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Draggable content sheet.
          DraggableScrollableSheet(
            initialChildSize: 0.56,
            minChildSize: 0.42,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22001120),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(bottom: SizeConfig.paddingL),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin:
                            EdgeInsets.symmetric(vertical: SizeConfig.size12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    CustomText(
                      'Where you Want ?',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(height: SizeConfig.size12),
                    _locationField(),
                    SizedBox(height: SizeConfig.size20),
                    _categoryGrid(),
                    SizedBox(height: SizeConfig.size12),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _locationField() {
    final label = _locationLabel.trim().isNotEmpty
        ? _locationLabel
        : AppStrings.selectLocationPill.tr;
    return InkWell(
      onTap: _openLocationPicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyE5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.my_location_rounded,
                size: 20, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: CustomText(
                label,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.edit_outlined,
                size: 18, color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    final cats = widget.professionalConsultantCategories;
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: SizeConfig.size16,
          children: cats
              .map((c) => SizedBox(
                    width: itemWidth,
                    child: _categoryTile(c, itemWidth),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _categoryTile(ProfessionTypeData c, double width) {
    final name = c.name ?? '';
    final icon = getIndividualProfessionIcon(c.tagId);
    final iconPath = icon.isNotEmpty ? icon : (c.imageUrl ?? '');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onCategoryTap(c),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: width,
            height: width,
            padding: EdgeInsets.all(width * 0.18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _tileIcon(iconPath),
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            name,
            textAlign: TextAlign.center,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _tileIcon(String iconPath) {
    if (iconPath.isEmpty) return const SizedBox.shrink();
    if (isNetworkImage(iconPath)) {
      return CachedNetworkImage(
        imageUrl: iconPath,
        fit: BoxFit.contain,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.secondaryTextColor,
          size: 20,
        ),
      );
    }
    return LocalAssets(imagePath: iconPath, boxFix: BoxFit.contain);
  }
}

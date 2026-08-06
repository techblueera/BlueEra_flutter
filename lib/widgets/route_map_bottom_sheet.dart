import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

/// The sheet that opens when a location is tapped: which place, how far, the
/// address, its photos, and one button that hands the route to Google Maps.
///
/// ## Why there is no map in here any more
///
/// This used to embed a live [GoogleMap] with a polyline fetched from the
/// Directions API. It was the wrong trade three times over:
///
///  * **It cost money on every open.** One Directions call plus a Maps SDK
///    render per tap, on a sheet that is tapped from every store card in the
///    app. See docs/GOOGLE_MAPS_COST_GUIDE.md.
///  * **It was a picture, not a route.** 200px of non-interactive preview can't
///    reroute, can't say "12 min", and can't be followed while walking. The
///    user's next move after looking at it was always to open Google Maps.
///  * **It delayed the sheet.** The route arrived after the sheet did, so the
///    first thing the user saw was a "Loading route…" chip over an empty map.
///
/// So the sheet now answers what it is actually good at — identity, distance,
/// address, photos — and [openGoogleMapsDirections] draws the real line, in the
/// app that owns navigation, with live traffic and an ETA.
class RouteMapBottomSheet extends StatelessWidget {
  final String destinationName;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final double userLat;
  final double userLng;
  final List<String>? livePhotos;
  final VoidCallback? visitCallback;

  const RouteMapBottomSheet({
    super.key,
    required this.destinationName,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.userLat,
    required this.userLng,
    this.visitCallback,
    this.livePhotos,
  });

  /// Convenience method to show the bottom sheet from anywhere.
  static void show({
    required BuildContext context,
    required String destinationName,
    String destinationAddress = '',
    required double destinationLat,
    required double destinationLng,
    VoidCallback? visitCallback,
    double? userLat,
    double? userLng,
    List<String>? livePhotos,
  }) {
    final uLat = userLat ?? LocationService.lat;
    final uLng = userLng ?? LocationService.lng;

    if (destinationLat == 0.0 && destinationLng == 0.0) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RouteMapBottomSheet(
        destinationName: destinationName,
        destinationAddress: destinationAddress,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        userLat: uLat,
        userLng: uLng,
        livePhotos: livePhotos,
        visitCallback: visitCallback,
      ),
    );
  }

  List<String> get _validPhotos =>
      livePhotos?.where((p) => p.trim().isNotEmpty).toList() ?? [];

  /// Hands the leg to Google Maps on its DIRECTIONS view — the drawn route with
  /// distance and ETA, not turn-by-turn guidance, which would be presumptuous
  /// for someone who has only tapped a shop's address.
  ///
  /// The origin is passed only when the device actually has a fix. Sending
  /// `0,0` would route the user from the Gulf of Guinea; omitting it lets
  /// Google Maps use its own current location, which is the better answer
  /// anyway when ours is stale.
  Future<void> _openDirections(BuildContext context) async {
    final hasOrigin = userLat != 0.0 || userLng != 0.0;
    try {
      await openGoogleMapsDirections(
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        originLat: hasOrigin ? userLat : null,
        originLng: hasOrigin ? userLng : null,
      );
    } catch (_) {
      commonSnackBar(message: 'Could not open Google Maps');
    }
  }

  /// Compact directions affordance — the standard maps glyph, tinted rather
  /// than filled, with a label so it isn't a guess. 40px square keeps it above
  /// the minimum tap target while staying subordinate to the address beside it.
  Widget _directionsButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Get directions',
      child: Tooltip(
        message: 'Get directions',
        child: InkResponse(
          onTap: () => _openDirections(context),
          radius: 28,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.directions_rounded,
              size: 20,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = calculateDistanceKm(
      userLat,
      userLng,
      destinationLat,
      destinationLng,
    ).toStringAsFixed(2);
    final hasPhotos = _validPhotos.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: visitCallback,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            destinationName,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            '$distance Km Away',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Visit Store button
                  if (visitCallback != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).maybePop();
                        visitCallback!();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_rounded,
                                size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            CustomText(
                              AppStrings.view,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(width: 10),

                  // Close button
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.greyE5, width: 0.5),
                    ),
                    child: CloseButton(
                      style: const ButtonStyle(
                        iconSize: WidgetStatePropertyAll(18),
                        padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
                        minimumSize: WidgetStatePropertyAll(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Address, with directions on the end of the same row.
            //
            // This was a full-width filled button under the address. Too loud
            // for what it is: opening Maps is one of several things you can do
            // from here (visit the store, look at the photos), not the sheet's
            // conclusion, and a 46px slab of brand blue claimed otherwise. As
            // an icon at the end of the line it sits with the address it acts
            // on — which is also where the eye already is by the time it wants
            // directions.
            if (destinationAddress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 6.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        color: AppColors.white,
                        border: Border.all(color: AppColors.greyE5),
                      ),
                      child: LocalAssets(
                        imagePath: AppIconAssets.location_outline,
                        imgColor: AppColors.secondaryTextColor,
                        height: 24,
                        width: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        destinationAddress,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _directionsButton(context),
                  ],
                ),
              )
            else
              // No address to hang it off — the action still has to be
              // reachable, so it stands on its own line.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_directionsButton(context)],
                ),
              ),

            const SizedBox(height: 6),

            // Live Photos
            if (hasPhotos) ...[
              Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.store, size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    CustomText(
                      'Store Photos (${_validPhotos.length})',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: StoreLivePhotoWidget(
                  livePhotos: _validPhotos,
                  natureOfBusiness: destinationName,
                  height: 160,
                  onViewFullScreen: ({
                    required int index,
                    required List<String> storeImage,
                    required String natureOfBusiness,
                  }) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewScreen(
                          appBarTitle: destinationName,
                          subTitle: destinationName,
                          imageUrls: storeImage,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

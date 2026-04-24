import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Compact single-line pill: `[📍] 2.4 km · <address>  [→ Directions]`.
///
/// Shared across Discover list cards (grocery, hospital, restaurant, product
/// store, etc.) so the distance + address + directions affordance is
/// consistent and tappable.
class DiscoverAddressPill extends StatelessWidget {
  final double destLat;
  final double destLng;
  final String? address;
  final VoidCallback onTap;
  final String fallbackText;

  /// Hides the "Directions" label when false, keeping only the icon (useful
  /// in tight layouts).
  final bool showDirectionsLabel;

  const DiscoverAddressPill({
    super.key,
    required this.destLat,
    required this.destLng,
    required this.onTap,
    this.address,
    this.fallbackText = 'Address not available',
    this.showDirectionsLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryColor;
    final km = calculateDistanceKm(
      LocationService.lat,
      LocationService.lng,
      destLat,
      destLng,
    );
    final addrText = (address == null || address!.trim().isEmpty)
        ? fallbackText
        : address!.trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.fromLTRB(
              SizeConfig.size6, SizeConfig.size6, SizeConfig.size6, SizeConfig.size6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                accent.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Distance badge — left token, primary-tinted with a compass
              // icon so the reading is immediately recognisable.
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.near_me_rounded,
                        size: SizeConfig.size12, color: accent),
                    SizedBox(width: SizeConfig.size4),
                    CustomText(
                      '${km.toStringAsFixed(1)} km',
                      fontSize: SizeConfig.small,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              // Address — muted middle copy.
              Expanded(
                child: CustomText(
                  addrText,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              // Directions CTA — solid primary gradient so it reads as the
              // action, not a label.
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent,
                      accent.withValues(alpha: 0.82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_rounded,
                        size: SizeConfig.size14, color: Colors.white),
                    if (showDirectionsLabel) ...[
                      SizedBox(width: SizeConfig.size4),
                      CustomText(
                        'Route',
                        fontSize: SizeConfig.extraSmall,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

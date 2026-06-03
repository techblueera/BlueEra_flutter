import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-wide sticky nudge shown just above the bottom navigation bar when the
/// device location is off. Location-based search (nearby stores, services,
/// kitchens) falls back to the profile address, but real GPS gives far better
/// results — so this gently prompts the user to enable it.
///
/// Reactive on [LocationService.isDeviceLocationOn]; collapses to nothing once
/// GPS is granted. The close button hides it for the session (it returns on
/// the next launch), so it reads as dismissible yet persistent.
class LocationPermissionBanner extends StatefulWidget {
  const LocationPermissionBanner({super.key});

  @override
  State<LocationPermissionBanner> createState() =>
      _LocationPermissionBannerState();
}

class _LocationPermissionBannerState extends State<LocationPermissionBanner> {
  // App primary color combination (deep -> bright blue).
  static const Color _c1 = AppColors.blue5CAF; // 0xFF005CAF
  static const Color _c2 = AppColors.primaryColor; // 0xFF0086FF

  // Session-scoped dismissal — the banner reappears on a fresh launch.
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (LocationService.isDeviceLocationOn.value || _dismissed) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_c1, _c2],
            ),
            boxShadow: [
              BoxShadow(
                color: _c1.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.location_off_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Location is off',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      CustomText(
                        'Turn it on for better results near you',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _turnOnButton(),
                const SizedBox(width: 2),
                InkWell(
                  onTap: () => setState(() => _dismissed = true),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.85), size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _turnOnButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => LocationService.fetchLocation(openSettingsOnDeny: true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.my_location_rounded, size: 14, color: _c1),
              const SizedBox(width: 5),
              CustomText(
                'Turn On',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _c1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

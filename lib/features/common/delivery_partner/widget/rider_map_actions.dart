import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The map / navigation controls shared by the rider's order cards.
///
/// The rider flow no longer renders maps itself: there is no in-app polyline
/// preview, no floating mini-map and no PiP hand-off. Every "take me there"
/// on a card opens the phone's own Google Maps, which is what a rider driving
/// actually follows. These widgets are that hand-off, plus the two small tiles
/// that sit beside it, kept in one place so the single-pickup [OrderCard] and
/// the multi-shop card can't drift apart.

/// Slow breathing glow. Wraps the one control a rider on a live job is meant
/// to reach for next, which otherwise sits as a quiet outline among tiles of
/// the same size and weight.
///
/// Honours the platform's "reduce motion" setting by rendering the child flat.
class PulsingHighlight extends StatefulWidget {
  final Widget child;
  final Color color;

  const PulsingHighlight({super.key, required this.child, required this.color});

  @override
  State<PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<PulsingHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.10 + 0.22 * _pulse.value),
                blurRadius: 6 + 10 * _pulse.value,
                spreadRadius: _pulse.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Outlined CTA that hands the rider to the Google Maps app.
///
/// [pulse] is the default because this is normally the next thing to do on a
/// live job. Pass `false` where several of these sit in one list (a multi-shop
/// checklist) and only the current stop should draw the eye — a column of
/// pulsing buttons points at nothing.
class RiderDirectionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool pulse;

  const RiderDirectionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.pulse = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size12,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor, width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: SizeConfig.size18,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size6),
            Flexible(
              child: CustomText(
                label,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    if (!pulse) return button;
    return PulsingHighlight(color: AppColors.primaryColor, child: button);
  }
}

/// Tinted label-over-value tile sitting beside the direction CTA — trip length,
/// stop count. [onTap] is optional; a tile with nothing to open isn't tappable.
class RiderStatBox extends StatelessWidget {
  final String? iconAsset;
  final IconData? icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback? onTap;

  const RiderStatBox({
    super.key,
    this.iconAsset,
    this.icon,
    required this.label,
    required this.value,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size8,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        // Same hairline the outlined direction button beside it has, so the
        // tiles read as one row of boxes rather than a button next to two
        // patches of colour.
        border: Border.all(color: tint.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          if (iconAsset != null)
            LocalAssets(
              imagePath: iconAsset!,
              imgColor: tint,
              height: SizeConfig.size20,
              width: SizeConfig.size20,
            )
          else if (icon != null)
            Icon(icon, size: SizeConfig.size20, color: tint),
          SizedBox(width: SizeConfig.size6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  label,
                  fontSize: SizeConfig.extraSmall,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                CustomText(
                  value,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: tint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return box;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: box);
  }
}

/// Lays [tiles] out as one stretched row — the [ CTA | stat | stat ] strip the
/// ongoing cards carry. A single tile is returned bare, so a row that lost its
/// stats to missing data doesn't render a lone `Expanded`.
Widget riderActionStatsRow(List<Widget> tiles) {
  if (tiles.isEmpty) return const SizedBox.shrink();
  if (tiles.length == 1) return tiles.first;
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(width: SizeConfig.size8),
          Expanded(child: tiles[i]),
        ],
      ],
    ),
  );
}

/// "Call To Customer Care" — a quiet footer link under a hairline, not another
/// bordered card. It's the least-used control on a working card and shouldn't
/// compete with the customer row or the completion control above it.
class RiderCustomerCareRow extends StatelessWidget {
  const RiderCustomerCareRow({super.key});

  /// Dials support when a number is configured; otherwise opens the app's Help
  /// & Support screen, which is where support actually lives today.
  static void call() {
    final number = AppStrings.customerCareNumber.trim();
    if (number.isEmpty) {
      Get.to(() => const HelpAndSupportScreen());
      return;
    }
    openDialer(number);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: AppColors.whiteE5, height: 1),
        InkWell(
          onTap: call,
          child: Padding(
            // Asymmetric: the card already contributes its own bottom padding
            // below this, so an even 12/12 left the footer floating clear of
            // the card edge.
            padding: EdgeInsets.only(
              top: SizeConfig.size12,
              bottom: SizeConfig.size4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.call,
                  imgColor: AppColors.secondaryTextColor,
                  height: SizeConfig.size16,
                  width: SizeConfig.size16,
                ),
                SizedBox(width: SizeConfig.size8),
                CustomText(
                  AppStrings.callToCustomerCare,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Turn-by-turn to a point, in the phone's Google Maps.
///
/// (0, 0) is treated as "no coordinate" rather than a place: it is what a
/// missing location parses to, and opening a map of the Atlantic is worse than
/// saying so.
void openRiderNavigation({required double? latitude, required double? longitude}) {
  if (!hasRiderCoordinates(latitude, longitude)) {
    commonSnackBar(message: AppStrings.locationNotAvailable);
    return;
  }
  openGoogleMapsNavigation(latitude: latitude!, longitude: longitude!);
}

/// The Google Maps directions view — the route drawn between two points, with
/// its distance and ETA. Omit the origin to route from where the rider is.
void openRiderDirections({
  required double? destinationLat,
  required double? destinationLng,
  double? originLat,
  double? originLng,
}) {
  if (!hasRiderCoordinates(destinationLat, destinationLng)) {
    commonSnackBar(message: AppStrings.locationNotAvailable);
    return;
  }
  final hasOrigin = hasRiderCoordinates(originLat, originLng);
  openGoogleMapsDirections(
    destinationLat: destinationLat!,
    destinationLng: destinationLng!,
    originLat: hasOrigin ? originLat : null,
    originLng: hasOrigin ? originLng : null,
  );
}

/// A usable coordinate pair: present and not the (0, 0) a missing location
/// decodes to.
bool hasRiderCoordinates(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  return lat != 0.0 || lng != 0.0;
}

/// The API sends an absent distance as `N/A`, `null` (the string) or empty.
String? riderCleanDistance(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty || value == 'N/A' || value == 'null') return null;
  return value;
}

/// Distance values arrive as bare numbers on some orders and already
/// unit-suffixed on others. Adds the unit only when there isn't one, never
/// "km km".
String riderWithKm(String value) =>
    RegExp(r'[a-zA-Z]').hasMatch(value) ? value : '$value KM';

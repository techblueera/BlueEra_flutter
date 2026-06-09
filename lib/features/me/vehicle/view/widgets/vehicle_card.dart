import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reusable card for both the owner-side dashboard and the public
/// Discover listing.
///
///   * `compact = true`  → fixed-height horizontal-scroll card used on
///                         the Overview tab's "My fleet" rail.
///   * `showOwnerActions` → renders edit + delete trailing actions on
///                         the My-Vehicles tab.
///   * `onTap`            → optional tap handler (Discover wires this
///                         to the detail screen).
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool compact;
  final bool showOwnerActions;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.compact = false,
    this.showOwnerActions = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEFF4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: compact ? _buildCompact() : _buildFull(),
      ),
    );
  }

  // ─── Compact (horizontal rail) layout ───────────────────────────
  Widget _buildCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          width: double.infinity,
          child: _CoverImage(url: vehicle.coverImage ?? _firstImage),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                vehicle.name,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                _subtitleLine(),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size6),
              if (vehicle.price != null)
                CustomText(
                  _priceLabel(),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Full (vertical list) layout ────────────────────────────────
  Widget _buildFull() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: _CoverImage(url: vehicle.coverImage ?? _firstImage),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        vehicle.name,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vehicle.isVerified ?? false)
                      Icon(Icons.verified_rounded,
                          size: 16, color: AppColors.primaryColor),
                  ],
                ),
                SizedBox(height: SizeConfig.size4),
                CustomText(
                  _subtitleLine(),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (vehicle.fuelType != null)
                      _Chip(label: _humanFuel(vehicle.fuelType!)),
                    if (vehicle.transmission != null)
                      _Chip(label: _humanTransmission(vehicle.transmission!)),
                    if (vehicle.seatingCapacity != null)
                      _Chip(
                        label: AppStrings.seatsCountFmt.trParams({
                          'count': '${vehicle.seatingCapacity}',
                        }),
                      ),
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                Row(
                  children: [
                    if (vehicle.price != null)
                      Expanded(
                        child: CustomText(
                          _priceLabel(),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                        ),
                      )
                    else
                      const Spacer(),
                    if (showOwnerActions) ...[
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        color: AppColors.primaryColor,
                        constraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: Colors.red.shade400,
                        constraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? get _firstImage => vehicle.images.isNotEmpty ? vehicle.images.first : null;

  String _subtitleLine() {
    final parts = <String>[];
    if ((vehicle.brand ?? '').isNotEmpty) parts.add(vehicle.brand!);
    if ((vehicle.model ?? '').isNotEmpty) parts.add(vehicle.model!);
    if (vehicle.year != null) parts.add('${vehicle.year}');
    if ((vehicle.location?.city ?? '').isNotEmpty) {
      parts.add('• ${vehicle.location!.city}');
    }
    return parts.join(' ');
  }

  String _priceLabel() {
    final cur = (vehicle.currency ?? 'INR').toUpperCase();
    final symbol = cur == 'INR' ? '₹' : cur;
    return '$symbol ${_compactNumber(vehicle.price!)}';
  }

  String _compactNumber(double v) {
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)} ${AppStrings.compactUnitCr.tr}';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)} ${AppStrings.compactUnitLac.tr}';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}${AppStrings.compactUnitThousand.tr}';
    return v.toStringAsFixed(0);
  }

  String _humanFuel(VehicleFuelType f) {
    switch (f) {
      case VehicleFuelType.petrol:
        return AppStrings.fuelPetrol.tr;
      case VehicleFuelType.diesel:
        return AppStrings.fuelDiesel.tr;
      case VehicleFuelType.electric:
        return AppStrings.fuelElectric.tr;
      case VehicleFuelType.cng:
        return AppStrings.fuelCng.tr;
      case VehicleFuelType.hybrid:
        return AppStrings.fuelHybrid.tr;
      case VehicleFuelType.other:
        return AppStrings.fuelOther.tr;
    }
  }

  String _humanTransmission(VehicleTransmission t) {
    switch (t) {
      case VehicleTransmission.manual:
        return AppStrings.transmissionManual.tr;
      case VehicleTransmission.automatic:
        return AppStrings.transmissionAutomatic.tr;
      case VehicleTransmission.amt:
        return AppStrings.transmissionAmt.tr;
      case VehicleTransmission.cvt:
        return AppStrings.transmissionCvt.tr;
    }
  }
}

class _CoverImage extends StatelessWidget {
  final String? url;
  const _CoverImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFEAF2FB),
        alignment: Alignment.center,
        child: Icon(
          Icons.directions_car_rounded,
          size: 32,
          color: AppColors.primaryColor.withValues(alpha: 0.5),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E6EE)),
      ),
      child: CustomText(
        label,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
      ),
    );
  }
}

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_booking_models.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Whose list this card is rendered in. Drives which actions appear on a
/// `pending` booking: the buyer can cancel; the seller can accept/decline.
enum VehicleBookingRole { buyer, seller }

/// A single booking rendered entirely from its denormalised [snapshot]
/// (no listing re-fetch) plus the request meta (intent, offer, status).
/// Used by both tabs of [VehicleBookingsScreen].
class VehicleBookingCard extends StatelessWidget {
  final VehicleBooking booking;
  final VehicleBookingRole role;
  final bool isActionInFlight;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const VehicleBookingCard({
    super.key,
    required this.booking,
    required this.role,
    this.isActionInFlight = false,
    this.onCancel,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final snap = booking.snapshot;
    final title = (snap?.title ?? '').trim();
    final image = (snap?.image ?? '').trim();
    final priceText = (snap?.priceText ?? '').trim();
    final location = (snap?.location ?? '').trim();
    final condition = (snap?.condition ?? '').trim();

    return CommonCardWidget(
      padding: 0,
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Listing snapshot row ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(SizeConfig.size8),
                  child: _thumb(image),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title.isEmpty ? AppStrings.vehicle.tr : title,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (priceText.isNotEmpty) ...[
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          priceText,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ],
                      SizedBox(height: SizeConfig.size4),
                      Wrap(
                        spacing: SizeConfig.size6,
                        runSpacing: SizeConfig.size4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (condition.isNotEmpty)
                            _miniPill(condition, AppColors.secondaryTextColor),
                          if (location.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.secondaryTextColor),
                                SizedBox(width: SizeConfig.size2),
                                CustomText(
                                  location,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _statusPill(booking.status),
              ],
            ),

            Divider(color: AppColors.greyE5, height: SizeConfig.size20),

            // ── Request meta — intent + optional offer ─────────────
            Row(
              children: [
                Icon(Icons.sell_outlined,
                    size: 14, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size6),
                CustomText(
                  booking.intent.label,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const Spacer(),
                if (booking.offerPrice != null)
                  CustomText(
                    '${AppStrings.bookingOfferLabel.tr}: ₹${_formatAmount(booking.offerPrice!)}',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
              ],
            ),

            // ── Optional note ──────────────────────────────────────
            if ((booking.note ?? '').trim().isNotEmpty) ...[
              SizedBox(height: SizeConfig.size8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(SizeConfig.size8),
                decoration: BoxDecoration(
                  color: AppColors.fillColor,
                  borderRadius: BorderRadius.circular(SizeConfig.size8),
                ),
                child: CustomText(
                  booking.note!.trim(),
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // ── Actions (only while pending) ───────────────────────
            if (booking.status.isPending) _actions(),
          ],
        ),
      ),
    );
  }

  Widget _thumb(String url) {
    const double size = 64;
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: AppColors.greyE5,
        child: Icon(Icons.directions_car_rounded,
            color: AppColors.secondaryTextColor, size: 28),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        width: size,
        height: size,
        color: AppColors.greyE5,
      ),
      errorWidget: (_, __, ___) => Container(
        width: size,
        height: size,
        color: AppColors.greyE5,
        child: Icon(Icons.directions_car_rounded,
            color: AppColors.secondaryTextColor, size: 28),
      ),
    );
  }

  Widget _actions() {
    if (isActionInFlight) {
      return Padding(
        padding: EdgeInsets.only(top: SizeConfig.size12),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (role == VehicleBookingRole.buyer) {
      return Padding(
        padding: EdgeInsets.only(top: SizeConfig.size12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text(AppStrings.bookingCancelRequest.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.redB4,
              side: BorderSide(color: AppColors.redB4.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizeConfig.size10),
              ),
            ),
          ),
        ),
      );
    }
    // Seller — accept / decline.
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.redB4,
                side: BorderSide(color: AppColors.redB4.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.size10),
                ),
              ),
              child: Text(AppStrings.bookingDecline.tr),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.size10),
                ),
              ),
              child: Text(AppStrings.bookingAccept.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String text, Color color) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size6, vertical: SizeConfig.size2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(SizeConfig.size4),
        ),
        child: CustomText(
          text,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );

  Widget _statusPill(VehicleBookingStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8, vertical: SizeConfig.size3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SizeConfig.size20),
      ),
      child: CustomText(
        status.label,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Color _statusColor(VehicleBookingStatus status) {
    switch (status) {
      case VehicleBookingStatus.pending:
        return AppColors.orangelite;
      case VehicleBookingStatus.accepted:
        return AppColors.green1A;
      case VehicleBookingStatus.declined:
        return AppColors.redB4;
      case VehicleBookingStatus.cancelled:
        return AppColors.secondaryTextColor;
    }
  }

  /// Indian-grouped rupee formatting (e.g. 199000 → "1,99,000"). The
  /// snapshot's `priceText` is pre-formatted; this is only for the
  /// buyer's own offer amount which arrives as a raw number.
  String _formatAmount(double value) => _groupIndian(value.toStringAsFixed(0));

  String _groupIndian(String digits) {
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }
}

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/widget/ride_booking_style.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Runs the full cancellation flow (screenshots 7 and 8) and returns `true`
/// only if the ride was actually cancelled.
///
/// Order of sheets:
///   1. "X is already on the way to you" confirm — skipped when no captain is
///      assigned yet, or when [skipCaptainConfirm] is set.
///   2. "Why do you want to cancel?" reason list.
///
/// The confirm-first order is deliberate: it gives the user a Call Captain
/// escape hatch before asking them to justify a cancellation.
Future<bool?> showRideCancelFlow({
  required RideBookingController controller,
  bool skipCaptainConfirm = false,
}) async {
  final captain = controller.activeBooking.value?.captain;

  if (!skipCaptainConfirm && captain != null) {
    final proceed = await _showCaptainConfirmSheet(captain);
    if (proceed != true) return false;
  }

  return _showReasonSheet(controller);
}

// --------------------------------------------------------- captain confirm

/// Screenshot 8 — last chance to call instead of cancelling.
Future<bool?> _showCaptainConfirmSheet(RideCaptain captain) {
  return Get.bottomSheet<bool>(
    Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RideStyle.sheetRadius),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        (Get.mediaQuery.padding.bottom) + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RideSheetHandle(),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: RideStyle.surfaceTint,
                backgroundImage: (captain.photoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(captain.photoUrl!)
                    : null,
                child: (captain.photoUrl?.isEmpty ?? true)
                    ? const Icon(Icons.person,
                        size: 30, color: RideStyle.inkMuted)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomText(
                  '${captain.name} is already on the way to you',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: RideStyle.ink,
                  maxLines: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: RideStyle.hairline),
          const SizedBox(height: 18),
          CustomText(
            'Are you sure you want to cancel the current order?',
            fontSize: 16,
            color: RideStyle.ink,
            maxLines: 3,
          ),
          const SizedBox(height: 22),
          RideOutlineButton(
            label: 'Cancel Ride',
            color: RideStyle.danger,
            onTap: () => Get.back(result: true),
          ),
          const SizedBox(height: 12),
          RidePrimaryButton(
            label: 'Call Captain',
            onTap: () => _callCaptain(captain.phone),
          ),
          const SizedBox(height: 12),
          RideOutlineButton(
            label: 'Go Back',
            onTap: () => Get.back(result: false),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
    barrierColor: Colors.black54,
  );
}

Future<void> _callCaptain(String? phone) async {
  if (phone == null || phone.isEmpty) {
    commonSnackBar(message: 'Captain phone number is unavailable');
    return;
  }
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    commonSnackBar(message: 'Could not start the call');
  }
}

// ------------------------------------------------------------ reason picker

/// Screenshot 7 — the reason list. Returns `true` once the cancellation is
/// accepted by the server.
Future<bool?> _showReasonSheet(RideBookingController controller) {
  controller.loadCancelReasons();

  return Get.bottomSheet<bool>(
    _CancelReasonSheet(controller: controller),
    isScrollControlled: true,
    barrierColor: Colors.black54,
  );
}

class _CancelReasonSheet extends StatelessWidget {
  const _CancelReasonSheet({required this.controller});

  final RideBookingController controller;

  Future<void> _pick(RideCancelReason reason) async {
    final ok = await controller.cancelRide(reasonCode: reason.code);
    if (ok) {
      Get.back(result: true);
    } else {
      commonSnackBar(message: 'Could not cancel the ride. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RideStyle.sheetRadius),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Obx(() {
        if (controller.isCancelling.value) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RideSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Why do you want to cancel?',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: RideStyle.ink,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    'Please provide the reason for cancellation',
                    fontSize: 15,
                    color: RideStyle.ink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: RideStyle.hairline),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: controller.cancelReasons.length,
                separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, color: RideStyle.hairline),
                ),
                itemBuilder: (context, index) {
                  final reason = controller.cancelReasons[index];
                  return InkWell(
                    onTap: () => _pick(reason),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  reason.label,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: RideStyle.ink,
                                ),
                                if (reason.note != null) ...[
                                  const SizedBox(height: 3),
                                  CustomText(
                                    reason.note!,
                                    fontSize: 13,
                                    color: RideStyle.inkMuted,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: RideStyle.ink),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

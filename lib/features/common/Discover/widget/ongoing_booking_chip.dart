import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/fare_call_queue_screen.dart';
import 'package:BlueEra/features/ride_booking/controller/ride_booking_controller.dart';
import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/view/ride_completed_screen.dart';
import 'package:BlueEra/features/ride_booking/view/ride_searching_screen.dart';
import 'package:BlueEra/features/ride_booking/view/ride_tracking_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Customer-side "Your Ongoing Ride/Booking" chip that sits directly under the
/// Discover search bar (see `assets/ongoing_ride.jpeg`).
///
/// It is the ONE re-entry point into a ride the customer left running: the
/// booking flow unwinds to the bottom nav when they minimise it, and without
/// this the only way back was the draggable mini-map (which they can dismiss).
///
/// ## What it shows, and where a tap goes
///
/// | State                          | Chip                | Tap target             |
/// |--------------------------------|---------------------|------------------------|
/// | Broadcast waves still ringing  | "Finding a captain" | [RideSearchingScreen]  |
/// | Captain assigned / on trip     | captain + distance  | [RideTrackingScreen]   |
/// | Ride finished, not yet rated   | "Ride Completed"    | [RideCompletedScreen]  |
/// | Old `book_your_transport` ride | captain + distance  | [FareCallQueueScreen]  |
///
/// The completed row exists because a ride can end while the customer is
/// somewhere else in the app: [RideTrackingScreen] only shows the summary when
/// it is still mounted, so a ride completed behind the mini-map used to leave
/// the fare receipt and the rating unreachable. The chip holds that state until
/// they open it (or dismiss it with the ✕), then clears the booking.
///
/// Cancelled / no-riders rides deliberately show nothing — there is no screen
/// worth re-opening for them, and the flow already explained what happened.
///
/// Collapses to [SizedBox.shrink] whenever there is no ride, so it costs a
/// zero-height sliver on every other Discover render.
class OngoingBookingChip extends StatelessWidget {
  const OngoingBookingChip({super.key});

  @override
  Widget build(BuildContext context) {
    // Both controllers are created by their own flows — never construct them
    // here, or Discover would spin up a ride controller for a user who has
    // never booked anything.
    final RideBookingController? rideCtrl =
        Get.isRegistered<RideBookingController>()
            ? Get.find<RideBookingController>()
            : null;
    final RideNavigationOverlayController? overlayCtrl =
        Get.isRegistered<RideNavigationOverlayController>()
            ? Get.find<RideNavigationOverlayController>()
            : null;

    if (rideCtrl == null && overlayCtrl == null) return const SizedBox.shrink();

    return Obx(() {
      final data = _resolve(rideCtrl, overlayCtrl);
      if (data == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size12,
          SizeConfig.size12,
          SizeConfig.size12,
          0,
        ),
        child: _ChipCard(data: data),
      );
    });
  }

  /// Pick what to show, newest flow first.
  ///
  /// Reads every reactive field it needs while inside the [Obx] above — the
  /// booking, the overlay's screen type and the rider position all move
  /// independently, and a field read only on one branch still has to be
  /// subscribed to on the other or the chip goes stale.
  _ChipData? _resolve(
    RideBookingController? rideCtrl,
    RideNavigationOverlayController? overlayCtrl,
  ) {
    final booking = rideCtrl?.activeBooking.value;
    if (rideCtrl != null && booking != null) {
      final fromBooking = _fromBooking(rideCtrl, booking, overlayCtrl);
      if (fromBooking != null) return fromBooking;
    }
    return _fromOverlay(overlayCtrl);
  }

  // ------------------------------------------------------ new ride-booking

  _ChipData? _fromBooking(
    RideBookingController ctrl,
    RideBooking booking,
    RideNavigationOverlayController? overlayCtrl,
  ) {
    if (booking.status == RideStatus.completed) {
      return _ChipData(
        title: 'Your Ride Completed',
        subtitle: booking.captain?.hasName == true
            ? '${booking.captain!.name} · Tap to rate & view receipt'
            : 'Tap to rate & view receipt',
        imageUrl: booking.captain?.photoUrl,
        isCompleted: true,
        onTap: () => _openCompleted(ctrl, booking, overlayCtrl),
        onDismiss: () => _clearBooking(ctrl, overlayCtrl),
      );
    }

    if (!booking.status.isActive) return null; // cancelled / no riders

    if (!booking.status.hasCaptain) {
      return _ChipData(
        title: 'Your Ongoing Ride/Booking',
        subtitle: booking.drop.title.isEmpty
            ? 'Finding a captain for you…'
            : 'Finding a captain · ${booking.drop.title}',
        onTap: () => Get.to(() => const RideSearchingScreen()),
      );
    }

    final captain = booking.captain;
    final startOtp = booking.startOtp ?? '';
    return _ChipData(
      title: 'Your Ongoing Ride/Booking',
      subtitle: captain?.hasName == true ? captain!.name : 'Captain',
      imageUrl: captain?.photoUrl,
      // Only until the ride starts — after that the code has been used and
      // leaving it on screen invites the customer to read it out again.
      otp: booking.status == RideStatus.onTrip || startOtp.isEmpty
          ? null
          : startOtp,
      otpLabel: 'Ride Start OTP',
      distanceLabel: _captainDistanceLabel(booking),
      trailingLabel: booking.status == RideStatus.onTrip
          ? 'On trip'
          : (booking.pickupEtaMinutes != null && booking.pickupEtaMinutes! > 0
              ? '${booking.pickupEtaMinutes} min'
              : null),
      phone: captain?.phone,
      onTap: () {
        // Mirrors the mini-map's own tap: drop the floating overlay first, so
        // the customer isn't left with a PiP for the screen they're now on.
        overlayCtrl?.dismissOverlay();
        Get.to(() => const RideTrackingScreen());
      },
    );
  }

  /// "3.2 KM Away" between the captain and whichever end of the trip is next.
  ///
  /// Prefers the server's own `distanceMeters` from the location poll; falls
  /// back to a straight line from the last known captain position. Null when
  /// neither is available — the row then just omits the distance rather than
  /// printing "0 KM".
  String? _captainDistanceLabel(RideBooking booking) {
    final meters = booking.captainDistanceMeters;
    if (meters != null && meters > 0) return _kmLabel(meters / 1000);

    final captain = booking.captain;
    final lat = captain?.latitude;
    final lng = captain?.longitude;
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;

    // Before the OTP the captain is coming to the pickup; after it, the pair
    // are heading for the drop.
    final target =
        booking.status == RideStatus.onTrip ? booking.drop : booking.pickup;
    if (!target.hasCoordinates) return null;

    final km = geo.Geolocator.distanceBetween(
          lat,
          lng,
          target.latitude,
          target.longitude,
        ) /
        1000;
    return km <= 0 ? null : _kmLabel(km);
  }

  static String _kmLabel(double km) =>
      '${km < 1 ? km.toStringAsFixed(1) : km.toStringAsFixed(0)} KM Away';

  /// Open the end-of-ride summary from Discover.
  ///
  /// [RideCompletedScreen] blocks its own pop (`canPop: false`) and hands the
  /// unwind to `onDone`, so the caller owns both the navigation and the reset —
  /// the booking has to survive until the screen is dismissed, since the fare
  /// and captain on it are read from the value passed in.
  void _openCompleted(
    RideBookingController ctrl,
    RideBooking booking,
    RideNavigationOverlayController? overlayCtrl,
  ) {
    Get.to(
      () => RideCompletedScreen(
        booking: booking,
        onDone: () {
          _clearBooking(ctrl, overlayCtrl);
          Get.until((route) => route.isFirst);
        },
      ),
    );
  }

  /// Drop the finished ride everywhere it is still referenced, so neither the
  /// chip nor the floating mini-map keeps pointing at a dead order.
  void _clearBooking(
    RideBookingController ctrl,
    RideNavigationOverlayController? overlayCtrl,
  ) {
    ctrl.resetTrip();
    overlayCtrl?.clearRideData();
  }

  // ------------------------------------------------- legacy transport flow

  /// The older `book_your_transport` ride, driven entirely by the overlay
  /// controller — same source as the Inquiry-tab card.
  _ChipData? _fromOverlay(RideNavigationOverlayController? ctrl) {
    if (ctrl == null) return null;
    // Subscribe to the fields the card reads even when they're empty.
    ctrl.screenType.value;
    ctrl.screenParams.length;
    ctrl.riderLat.value;
    if (!ctrl.hasOngoingCustomerRide) return null;

    final orderId = (ctrl.screenParams['orderId'] ?? '').toString();
    final (otp, otpLabel) = _overlayOtp(orderId);

    return _ChipData(
      title: 'Your Ongoing Ride/Booking',
      subtitle:
          ctrl.customerName.value.isNotEmpty ? ctrl.customerName.value : 'Rider',
      imageUrl: ctrl.riderImage.value.isEmpty ? null : ctrl.riderImage.value,
      distanceLabel: _overlayDistanceLabel(ctrl),
      trailingLabel: ctrl.bookingTimeLabel.value.isEmpty
          ? null
          : ctrl.bookingTimeLabel.value,
      phone: ctrl.riderContact.value.isEmpty ? null : ctrl.riderContact.value,
      otp: otp,
      otpLabel: otpLabel,
      onTap: () {
        ctrl.hideOverlay();
        Get.to(() => FareCallQueueScreen(orderId: orderId));
      },
    );
  }

  /// The OTP the CUSTOMER holds for the legacy ride [orderId], with its label.
  ///
  /// Same rule the tracking screen uses: the ride-start (pickup) OTP until the
  /// rider starts the ride, then the delivery OTP — and never a delivery OTP
  /// for a passenger ride, which has none (`fareCallOrderFor` empty means the
  /// category is still unknown, so that card stays hidden rather than guessing).
  ///
  /// The OTPs live in [DiscoverController], which only ever loaded them when a
  /// tracking screen was opened. That is why the chip used to show nothing
  /// until the customer had been through chat and back — so this also kicks off
  /// the fetch when the value is missing or belongs to another order.
  (String?, String?) _overlayOtp(String orderId) {
    if (orderId.isEmpty) return (null, null);
    if (!Get.isRegistered<DiscoverController>()) return (null, null);
    final dc = Get.find<DiscoverController>();

    final rideStarted = dc.isFareCallRideStarted.value;
    final ownsOtp = dc.fareCallOtpOrderId == orderId;
    final pickupOtp = ownsOtp ? dc.fareCallPickupOtp.value : '';
    final deliveryOtp = ownsOtp ? dc.fareCallDeliveryOtp.value : '';

    if (!rideStarted) {
      if (pickupOtp.isEmpty) _hydrateOtp(dc, orderId, rideStarted);
      return pickupOtp.isEmpty ? (null, null) : (pickupOtp, 'Ride Start OTP');
    }
    if (dc.fareCallOrderFor.value.isEmpty || dc.isFareCallPassengerRide) {
      return (null, null);
    }
    if (deliveryOtp.isEmpty) _hydrateOtp(dc, orderId, rideStarted);
    return deliveryOtp.isEmpty ? (null, null) : (deliveryOtp, 'Delivery OTP');
  }

  /// One fetch per order per ride phase — the chip rebuilds on every rider
  /// position tick, and an ungated call would hit the status endpoint each
  /// time. Deferred past this frame because it writes the Rx values this build
  /// is currently reading.
  static final Set<String> _otpFetchKeys = {};

  void _hydrateOtp(DiscoverController dc, String orderId, bool rideStarted) {
    final key = '$orderId|$rideStarted';
    if (!_otpFetchKeys.add(key)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dc.hydrateFareCallDeliveryOtp(orderId).whenComplete(() {
        // A failed/empty fetch must be retryable — the OTP is only issued once
        // the rider accepts, which can be after this first look. Backed off so
        // the retry rides the next rebuild rather than every rider-position
        // tick.
        final got = rideStarted
            ? dc.fareCallDeliveryOtp.value
            : dc.fareCallPickupOtp.value;
        if (got.isEmpty) {
          Future.delayed(
              const Duration(seconds: 10), () => _otpFetchKeys.remove(key));
        }
      });
    });
  }

  String? _overlayDistanceLabel(RideNavigationOverlayController ctrl) {
    final rLat = ctrl.riderLat.value;
    final rLng = ctrl.riderLng.value;
    final pLat = ctrl.destLat.value;
    final pLng = ctrl.destLng.value;
    if (rLat == 0.0 || rLng == 0.0 || pLat == 0.0 || pLng == 0.0) return null;
    final km = geo.Geolocator.distanceBetween(rLat, rLng, pLat, pLng) / 1000;
    return km <= 0 ? null : _kmLabel(km);
  }
}

/// Everything the chip renders, resolved from whichever flow owns the ride so
/// the card itself never has to know which one that was.
class _ChipData {
  const _ChipData({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageUrl,
    this.distanceLabel,
    this.trailingLabel,
    this.phone,
    this.otp,
    this.otpLabel,
    this.isCompleted = false,
    this.onDismiss,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? imageUrl;

  /// "10 KM Away", or null while no live position is known.
  final String? distanceLabel;

  /// Small text under the trailing action — ETA, booking time or trip state.
  final String? trailingLabel;

  /// Captain's number; the call button is hidden when there isn't one.
  final String? phone;

  /// The code the customer reads out to the rider, and what it is for. Null
  /// while no OTP applies to the current phase of the ride.
  final String? otp;
  final String? otpLabel;

  final bool isCompleted;

  /// Only set for the completed row, which is the one state the customer can
  /// clear without opening anything.
  final VoidCallback? onDismiss;
}

class _ChipCard extends StatelessWidget {
  const _ChipCard({required this.data});

  final _ChipData data;

  /// Warm peach → mint for a live ride, green for a finished one. The tint is
  /// the fastest read on the row: the customer knows which of the two it is
  /// before the text resolves.
  static const List<Color> _liveGradient = [
    Color(0xFFFFF0E4),
    Color(0xFFE7F7EC),
  ];
  static const List<Color> _doneGradient = [
    Color(0xFFE7F7EC),
    Color(0xFFEAF3FF),
  ];

  Color get _accent =>
      data.isCompleted ? const Color(0xFF1FA463) : const Color(0xFFFF8A3D);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: data.onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: data.isCompleted ? _doneGradient : _liveGradient,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withValues(alpha: 0.55)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14101828),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _leading(),
              const SizedBox(width: 12),
              Expanded(child: _text()),
              const SizedBox(width: 8),
              _trailing(),
            ],
          ),
        ),
      ),
    );
  }

  /// Captain avatar for a live ride; a tick for a finished one, where there may
  /// be no photo and the state matters more than the face.
  Widget _leading() {
    if (data.isCompleted && (data.imageUrl == null || data.imageUrl!.isEmpty)) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, color: _accent, size: 26),
      );
    }
    return CachedAvatarWidget(
      imageUrl: (data.imageUrl?.isEmpty ?? true) ? null : data.imageUrl,
      size: 46,
      borderRadius: 23,
      showProfileOnFullScreen: false,
    );
  }

  Widget _text() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          data.title,
          fontSize: SizeConfig.size15,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Flexible(
              child: CustomText(
                data.subtitle,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (data.distanceLabel != null) ...[
              CustomText(
                '  |  ',
                fontSize: SizeConfig.size12,
                color: AppColors.grayText,
              ),
              Icon(Icons.location_on, size: 13, color: AppColors.primaryColor),
              const SizedBox(width: 2),
              CustomText(
                data.distanceLabel!,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ],
          ],
        ),
        if ((data.otp?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 6),
          _BlinkingOtpPill(
            label: data.otpLabel ?? 'OTP',
            otp: data.otp!,
          ),
        ],
      ],
    );
  }

  /// Call the captain on a live ride, dismiss a finished one. Both fall back to
  /// a chevron so the row always shows that it opens something.
  Widget _trailing() {
    final Widget action;
    if (data.isCompleted) {
      action = _circleButton(
        icon: Icons.close_rounded,
        color: AppColors.secondaryTextColor,
        onTap: data.onDismiss ?? data.onTap,
      );
    } else if (data.phone != null && data.phone!.isNotEmpty) {
      action = _circleButton(
        icon: Icons.call,
        color: const Color(0xFF1FA463),
        onTap: () => launchUrl(Uri(scheme: 'tel', path: data.phone!)),
      );
    } else {
      action = _circleButton(
        icon: Icons.chevron_right_rounded,
        color: AppColors.primaryColor,
        onTap: data.onTap,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        action,
        if (data.trailingLabel != null) ...[
          const SizedBox(height: 3),
          // Bounded: this column is the unconstrained end of the row, so a long
          // label (a verbose booking time) would push the text block instead of
          // ellipsising.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 64),
            child: CustomText(
              data.trailingLabel!,
              fontSize: SizeConfig.size10,
              color: AppColors.grayText,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A101828),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// The customer's OTP, pulsing so it is the thing they see on a chip that is
/// otherwise all soft pastels.
///
/// The code is the one piece of the row that is time-critical — the rider is
/// standing there asking for it — so it blinks between a flat tint and a solid
/// fill rather than sitting still like the rest of the card. Tapping copies it,
/// since reading it aloud is not the only way it gets used.
class _BlinkingOtpPill extends StatefulWidget {
  const _BlinkingOtpPill({required this.label, required this.otp});

  final String label;
  final String otp;

  @override
  State<_BlinkingOtpPill> createState() => _BlinkingOtpPillState();
}

class _BlinkingOtpPillState extends State<_BlinkingOtpPill>
    with SingleTickerProviderStateMixin {
  static const Color _hot = Color(0xFFEA4335);
  static const Color _cool = Color(0xFF1A73E8);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final accent = Color.lerp(_cool, _hot, t)!;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.otp));
            commonSnackBar(message: '${widget.label} copied');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10 + (0.14 * t)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.35 + 0.4 * t)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 12, color: accent),
                const SizedBox(width: 4),
                CustomText(
                  widget.label,
                  fontSize: SizeConfig.size11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(width: 6),
                CustomText(
                  widget.otp,
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

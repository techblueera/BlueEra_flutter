import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/auth/controller/order_controllar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../auth/repo/chat_view_repo.dart';
import '../../../../../core/constants/common_methods.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/custom_carousel_slider.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../widget/component_widgets.dart';

class RiderDetailsMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const RiderDetailsMsgCard({
    Key? key,
    required this.message,
    required this.time,
  }) : super(key: key);

  @override
  State<RiderDetailsMsgCard> createState() => _RiderDetailsMsgCardState();
}

class _RiderDetailsMsgCardState extends State<RiderDetailsMsgCard> {
  final orderController = Get.isRegistered<OrderNowController>()
      ? Get.find<OrderNowController>()
      : Get.put(OrderNowController());

  /// Backend order statuses that mean the ride is under way — i.e. the customer
  /// has already handed the pickup OTP to the rider.
  ///
  /// State machine (RIDER_FRONTEND_INTEGRATION_GUIDE §"status"):
  /// `pending → payment-pending → confirmed → in-progress → picked-up →
  /// completed`. The OTP is what moves it to `in-progress`, and it stays
  /// started through `picked-up`.
  static const Set<String> _startedStatuses = {'in-progress', 'picked-up'};

  /// Whether the ride is under way, i.e. the OTP has been handed over. Null
  /// until the first status read lands — the action row keeps offering Cancel
  /// while unknown, since cancelling a ride that has already started fails
  /// server-side, whereas hiding the option from someone still waiting for
  /// their rider would strand them.
  bool? _rideStarted;

  @override
  void initState() {
    super.initState();
    // Old cards are read-only (their buttons are disabled anyway), so there is
    // nothing worth a request for.
    if (!_isExpired) _refreshRideState();
  }

  bool get _isExpired => isMessageOlderThan24Hours(widget.message.createdAt,
      maxAge: const Duration(days: 7));

  String get _orderId => (widget.message.metadata?.order?.id ?? '').toString();

  /// One read of `rider-location`, which carries `rideActive`, the order
  /// `status` and the rider's coordinates together. Returns the payload so the
  /// caller can use the position too, and records the started/not-started
  /// answer on the way through so the action row can re-label itself.
  Future<Map<dynamic, dynamic>?> _refreshRideState() async {
    if (_orderId.isEmpty) return null;
    try {
      final response = await ChatViewRepo().getRiderLiveLocationApi(_orderId);
      if (!response.isSuccess) return null;
      final data = _locationPayload(response.response?.data);
      if (data == null) return null;

      final status = (data['status'] ?? '')
          .toString()
          .toLowerCase()
          .replaceAll('_', '-')
          .trim();
      final started = _startedStatuses.contains(status);
      if (mounted && started != _rideStarted) {
        setState(() => _rideStarted = started);
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  /// "Track Order" → hand off to the phone's Google Maps.
  ///
  /// Which leg it opens depends on where the ride is, because the customer is
  /// asking a different question either side of the OTP:
  ///
  ///   • **Before the OTP is shared** — "where is my rider?" → directions from
  ///     the customer to the rider's LIVE position.
  ///   • **After the OTP is shared** — the rider is already with them and what
  ///     matters is the trip → directions from the customer to the DROP.
  ///
  /// Both omit the origin so Google Maps fills in the device's own location:
  /// that is the "from me" both cases want, and it avoids a location-permission
  /// round-trip here.
  ///
  /// One request answers all of it — `rider-location` returns `rideActive`, the
  /// order `status` and the rider's coordinates together (see
  /// [RiderLocationPollController], which polls the same endpoint).
  Future<void> _openRideTracking() async {
    final order = widget.message.metadata?.order;
    if (_orderId.isEmpty) {
      commonSnackBar(message: AppStrings.locationNotAvailable);
      return;
    }

    // Re-read rather than trusting the value from mount: the ride may have
    // started in the meantime, which flips which leg this button should open.
    final data = await _refreshRideState();
    if (data == null) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return;
    }

    // Terminal ride — there is no leg left to draw.
    if (data['rideActive'] == false) {
      commonSnackBar(message: "Ride has been Completed");
      return;
    }

    final target =
        (_rideStarted ?? false) ? _dropLatLng(order) : _riderLatLng(data);

    if (target == null) {
      // Deliberately NOT falling back to a default coordinate: sending someone
      // navigating to the wrong city is worse than telling them we don't know
      // yet. A rider fix usually lands within a poll or two of assignment.
      commonSnackBar(message: AppStrings.locationNotAvailable);
      return;
    }

    try {
      await openGoogleMapsDirections(
        destinationLat: target.$1,
        destinationLng: target.$2,
      );
    } catch (_) {
      commonSnackBar(message: AppStrings.couldNotOpenGoogleMaps.tr);
    }
  }

  /// Share the ride's details out of the app.
  ///
  /// Replaces Cancel Ride once the ride has started, because the two actions
  /// belong to opposite halves of the trip: before the OTP the useful action is
  /// backing out, and after it the ride can no longer be cancelled — what a
  /// passenger reaches for then is telling someone where they are and who they
  /// are with.
  ///
  /// Plain text rather than a tracking link: there is no public
  /// track-this-ride URL to hand out, and a share that silently dropped the
  /// tracking would be worse than one that never promised it.
  Future<void> _shareRideInfo(Rider? rider) async {
    final order = widget.message.metadata?.order;
    final pickup = order?.pickupLocation?.address;
    final drop = order?.dropLocation?.address;

    final lines = <String>[
      AppStrings.shareRideInfoHeading.tr,
      if ((rider?.name ?? '').isNotEmpty)
        '${AppStrings.riderLabel.tr}: ${rider!.name}'
            '${(rider.contactNo ?? '').isNotEmpty ? ' (${rider.contactNo})' : ''}',
      if ((pickup ?? '').isNotEmpty) '${AppStrings.pickupLabel.tr}: $pickup',
      if ((drop ?? '').isNotEmpty) '${AppStrings.dropLabel.tr}: $drop',
      if (_orderId.isNotEmpty) '${AppStrings.orderIdLabel.tr}: $_orderId',
    ];

    try {
      await SharePlus.instance.share(ShareParams(text: lines.join('\n')));
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    }
  }

  /// The rider's last known position from the location payload.
  (double, double)? _riderLatLng(Map<dynamic, dynamic> data) {
    final rider = data['rider'];
    if (rider is! Map) return null;
    final lat = (rider['latitude'] as num?)?.toDouble();
    final lng = (rider['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    return (lat, lng);
  }

  /// The order's drop, as `[lng, lat]` GeoJSON on the message metadata.
  (double, double)? _dropLatLng(dynamic order) {
    final coords = order?.dropLocation?.location?.coordinates;
    if (coords is! List || coords.length < 2) return null;
    final lng = (coords[0] as num?)?.toDouble();
    final lat = (coords[1] as num?)?.toDouble();
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    return (lat, lng);
  }

  /// The poll fields sit at the root, but some gateway responses wrap them in
  /// `{ data: {...} }`. Accept either — same rule
  /// [RiderLocationPollController] applies.
  Map<dynamic, dynamic>? _locationPayload(dynamic body) {
    if (body is! Map) return null;
    final inner = body['data'];
    if (inner is Map &&
        (inner.containsKey('rideActive') ||
            inner.containsKey('rider') ||
            inner.containsKey('status'))) {
      return inner;
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    Rider? rider = widget.message.metadata?.rider;
    final bool isExpired = isMessageOlderThan24Hours(widget.message.createdAt,
        maxAge: const Duration(days: 7));
    final Color actionColor =
        isExpired ? AppColors.grayText : AppColors.primaryColor;
    // Unknown (first paint, before the status read lands) keeps Cancel — see
    // [_rideStarted].
    final bool rideStarted = _rideStarted ?? false;

    return InkWell(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.only(right: 0, bottom: 2),
        width: SizeConfig.screenWidth * 0.68,
        decoration: BoxDecoration(
          color: AppColors.blueLightShade,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: CustomImageSlideshow(
                isLoading: false,
                width: double.infinity,
                height: 156,
                imagePaths: [rider?.profilePicture ?? ""],
                borderRadius: BorderRadius.zero,
              ),
            ),
            // Title & price
            SizedBox(height: SizeConfig.size10),

            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                rider?.name,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(height: SizeConfig.size4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: AppColors.rating,
                            size: 14,
                          ),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(
                            "${rider?.starRating ?? 0}",
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.grayText,
                            maxLines: 1,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(width: SizeConfig.size6),
                          CustomText(
                            "${rider?.noOfOrder ?? 0} ${AppStrings.orders.tr}",
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.grayText,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                  CustomText(
                    "${widget.time}",
                    fontSize: SizeConfig.size10,
                    fontWeight: FontWeight.w400,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.grayText,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size10),
            _buildPickupDropSection(),
            SizedBox(height: SizeConfig.size10),
            const Divider(
              height: 1,
              color: Colors.grey,
            ),
            // Single action row. Track Order hands off to Google Maps — the
            // rider before the OTP, the drop after it. The second slot follows
            // the same split: Cancel Ride while the ride can still be called
            // off, Share Ride Info once it is under way and cancelling is no
            // longer possible.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed:
                          isExpired ? null : () => _openRideTracking(),
                      icon: SvgPicture.asset(
                        AppIconAssets.location_new,
                        color: actionColor,
                      ),
                      label: CustomText(
                        AppStrings.trackOrder,
                        color: actionColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    height: 12,
                    width: 1,
                    color: AppColors.grayText.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: rideStarted
                        ? TextButton.icon(
                            onPressed:
                                isExpired ? null : () => _shareRideInfo(rider),
                            icon: Icon(
                              Icons.ios_share_rounded,
                              color: actionColor,
                              size: 20,
                            ),
                            label: CustomText(
                              AppStrings.shareRideInfo.tr,
                              color: actionColor,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : TextButton.icon(
                            onPressed: isExpired
                                ? null
                                : () {
                                    _confirmCancelRide(context);
                                  },
                            icon: Icon(
                              Icons.cancel_outlined,
                              color:
                                  isExpired ? AppColors.grayText : AppColors.red,
                              size: 20,
                            ),
                            label: CustomText(
                              AppStrings.cancelRide.tr,
                              color:
                                  isExpired ? AppColors.grayText : AppColors.red,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pickup → Drop location block shown on a rider message. Returns an empty
  /// box when neither address is available so the card layout doesn't break.
  Widget _buildPickupDropSection() {
    final order = widget.message.metadata?.order;
    final pickup = order?.pickupLocation?.address;
    final drop = order?.dropLocation?.address;

    if ((pickup == null || pickup.isEmpty) && (drop == null || drop.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pickup != null && pickup.isNotEmpty)
            _locationRow(
              icon: Icons.my_location,
              iconColor: AppColors.primaryColor,
              label: AppStrings.pickupLabel.tr,
              value: pickup,
            ),
          if (pickup != null &&
              pickup.isNotEmpty &&
              drop != null &&
              drop.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: SizeConfig.size6),
              child: SizedBox(
                height: SizeConfig.size12,
                child: const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
              ),
            ),
          if (drop != null && drop.isNotEmpty)
            _locationRow(
              icon: Icons.location_on,
              iconColor: AppColors.red,
              label: AppStrings.dropLabel.tr,
              value: drop,
            ),
        ],
      ),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                label,
                fontSize: SizeConfig.size10,
                fontWeight: FontWeight.w500,
                color: AppColors.grayText,
                maxLines: 1,
              ),
              CustomText(
                value,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Confirm before cancelling the ride, then call the cancel-order API.
  /// [cancelOrderApi] shows its own success/error snackbar and refreshes the
  /// conversation, so we only need to drive the confirmation here.
  void _confirmCancelRide(BuildContext context) {
    final orderId = widget.message.metadata?.order?.orderId ??
        widget.message.metadata?.orderId ??
        '';
    final conversationId = widget.message.conversationId ?? '';
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.red, size: 56),
                SizedBox(height: SizeConfig.size12),
                CustomText(
                  AppStrings.areYouSureCancelRide.tr,
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.large,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
                SizedBox(height: SizeConfig.size20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.size12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: CustomText(
                          AppStrings.no.tr,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          await orderController.cancelOrderApi(
                              orderId, conversationId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.size12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: CustomText(
                          AppStrings.yes.tr,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

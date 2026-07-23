import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';

import '../../../chat/auth/controller/call_controller.dart';
import '../../../chat/auth/model/rider_orders_details_model.dart';
import '../controller/delivery_partner_orders_controller.dart';
import '../model/grocery_order_details.dart';
import 'customer_rating_badge.dart';

/// Order card for **multi-shop goods orders** booked from
/// `GoodsMultiOrderBookingMain` (`POST /fare/multi-shop/orders`).
///
/// Such an order reaches the rider as a `RiderOrdersDetailsModel` with
/// `orderType == 'fare-call'` and `orderFor == 'grocery'`, carrying several
/// pickup shops under `groceryOrderDetails.businesses` (one entry per shop)
/// plus a single customer drop. The generic [OrderCard] only models a single
/// pickup, so multi-shop orders get this purpose-built card instead.
///
/// Lifecycle the card drives, end-to-end:
///   • New order (pending)  → Accept / Reject via `rideAction`.
///   • Ongoing              → a sequenced per-shop checklist: at each shop the
///     rider taps "Arrived" (`multiShopStopArrive`) then enters that shop's
///     pickup OTP (`multiShopStopPickup`). Once every shop is picked up, the
///     final customer **Delivery OTP** box appears (`verifyDeliveredOtp`,
///     which completes the ride on success).
///   • Completed / cancelled / rejected → read-only summary.
///
/// Use [isMultiShopGoodsOrder] to decide whether to render this card.
///
/// Also catches **single-shop** chat-grocery handoff orders (via
/// [RiderOrdersDetailsModel.isChatGroceryHandoff]) so they ride the same
/// per-shop OTP card as multi-shop — the rider never re-selects shops; the shop
/// is already chosen at booking.
bool isMultiShopGoodsOrder(RiderOrdersDetailsModel order) {
  if (order.isChatGroceryHandoff) return true;
  final isFareCallGrocery = order.orderType == 'fare-call' &&
      (order.orderFor?.toLowerCase() == AppConstants.grocery);
  final hasMultiplePickups =
      (order.groceryOrderDetails?.businesses.length ?? 0) > 1;
  return isFareCallGrocery || hasMultiplePickups;
}

class MultiShopOrderCard extends StatefulWidget {
  final RiderOrdersDetailsModel order;
  final PickUpTab selectedPickUp;

  const MultiShopOrderCard({
    super.key,
    required this.order,
    required this.selectedPickUp,
  });

  @override
  State<MultiShopOrderCard> createState() => _MultiShopOrderCardState();
}

class _MultiShopOrderCardState extends State<MultiShopOrderCard> {
  final controller = getOrPut(() => DeliverPartnerOrdersController());

  // Per-shop local UI state, keyed by businessId. These ride on top of the
  // server truth (`item.isPickedUp`) so the checklist reacts instantly while
  // the SSE stream catches up.
  final Set<String> _arrived = {};
  final Set<String> _pickedLocal = {};

  RiderOrdersDetailsModel get _order => widget.order;

  String get _orderId => _order.id ?? _order.orderId ?? '';

  /// True multi-stop order (per-stop arrive + pickup endpoints). A single-shop
  /// chat-grocery handoff is NOT multi-stop — the shop is confirmed via the
  /// order-level pickup OTP, not the per-stop endpoint.
  bool get _isMultiStop => _order.isMultiStop == true;

  /// Order-level pickup completed (used for single-shop, where there are no
  /// per-stop `stops[]`; the shop confirms the one pickup OTP → status flips).
  bool get _orderPickedUp => _order.status == 'picked-up';

  /// Pickup shops. For single-shop chat-dispatch the order carries no
  /// `groceryOrderDetails.businesses`, so synthesize one row from the order's
  /// shop (receiver) — its OTP falls back to the order-level pickupOTP.
  List<BusinessOrder> get _shops {
    // Multi-stop fare-call orders carry their shops in `stops[]` (NOT
    // groceryOrderDetails). Build one row per stop, ordered by sequence, so the
    // per-stop arrive/pickup endpoints receive each stop's real businessId.
    // Using receiverUserId here only worked when stops happened to share that
    // id; a true multi-shop order would 404 on arrive.
    if (_isMultiStop && (_order.stops?.isNotEmpty ?? false)) {
      final stops = [..._order.stops!]
        ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
      return stops
          .map((s) => BusinessOrder(
                businessId: s.businessId ?? '',
                businessName: s.shopName ?? 'Shop',
                items: const [],
                paymentStatus: false,
                paymentMode: '',
                amountPaid: 0,
              ))
          .toList();
    }
    final list = _order.groceryOrderDetails?.businesses ?? const [];
    if (list.isNotEmpty) return list;
    return [
      BusinessOrder(
        businessId: _order.receiverUserId ?? '',
        businessName: _order.receiverUser?.name ?? 'Shop',
        items: const [],
        paymentStatus: false,
        paymentMode: '',
        amountPaid: 0,
      ),
    ];
  }

  /// The persisted stop record for [businessId] (multi-stop orders), so the
  /// card reflects server state (`arrived` / `picked-up`) after a refresh,
  /// not just this widget's ephemeral local sets.
  RideStop? _stopFor(String businessId) {
    final stops = _order.stops;
    if (stops == null) return null;
    for (final s in stops) {
      if (s.businessId == businessId) return s;
    }
    return null;
  }

  /// Shop pickup coordinates for the map icon. Multi-stop orders carry per-stop
  /// `location`; a single-shop order falls back to the order's pickupLocation.
  (double, double)? _shopLatLng(BusinessOrder shop) {
    final stop = _stopFor(shop.businessId);
    if (stop?.latitude != null && stop?.longitude != null) {
      return (stop!.latitude!, stop.longitude!);
    }
    final coords = _order.pickupLocation?.location?.coordinates;
    if (coords != null && coords.length >= 2) {
      // GeoJSON order is [longitude, latitude].
      return (coords[1].toDouble(), coords[0].toDouble());
    }
    return null;
  }

  /// Shop phone for the call icon. Multi-stop orders carry per-stop `contactNo`;
  /// a single-shop order falls back to the receiver (shop) contact.
  String? _shopPhone(BusinessOrder shop) {
    final stop = _stopFor(shop.businessId);
    final stopPhone = stop?.contactNo;
    if (stopPhone != null && stopPhone.isNotEmpty) return stopPhone;
    return _order.receiverUser?.contactNo;
  }

  /// Open the external maps app at the shop's pickup location.
  void _navigateToShop(BusinessOrder shop) {
    final latLng = _shopLatLng(shop);
    if (latLng == null) {
      commonSnackBar(message: 'Shop location not available');
      return;
    }
    openGoogleMaps(latitude: latLng.$1, longitude: latLng.$2);
  }

  /// Dial the shop's number in the phone dialer (shops are external; no in-app
  /// call). The customer, an app user, is called via the in-app caller instead.
  void _callShop(BusinessOrder shop) {
    final phone = _shopPhone(shop);
    if (phone == null || phone.isEmpty) {
      commonSnackBar(message: 'Shop contact number not available');
      return;
    }
    openDialer(phone);
  }

  /// Small circular icon action used next to a shop name (map / call).
  Widget _shopActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        margin: EdgeInsets.only(left: SizeConfig.size6),
        padding: EdgeInsets.all(SizeConfig.size6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: SizeConfig.size16, color: color),
      ),
    );
  }

  /// Place an in-app audio call to the customer using the app's caller service
  /// (WebRTC), not the phone dialer.
  Future<void> _callCustomerInApp() async {
    final customerId = _order.user?.id ?? '';
    if (customerId.isEmpty) {
      commonSnackBar(message: 'Customer contact not available');
      return;
    }
    final callController = getOrPut(() => CallController());
    final ok = await callController.initiateCall(
      type: CallType.audio,
      otherUserId: customerId,
      userName: _order.user?.name ?? 'Customer',
      userImage: _order.user?.profileImage ?? '',
    );
    if (!ok) {
      commonSnackBar(message: 'Could not start the call');
    }
  }

  bool get _isPending =>
      widget.selectedPickUp == PickUpTab.newOrder ||
      widget.selectedPickUp == PickUpTab.orders;

  bool get _isOngoing => widget.selectedPickUp == PickUpTab.onGoing;

  bool _isShopPicked(BusinessOrder shop) {
    if (_pickedLocal.contains(shop.businessId)) return true;
    // Single-shop: rely on the order-level pickup state (no per-stop items).
    if (!_isMultiStop) return _orderPickedUp;
    // Multi-stop: the shop confirms pickup via the per-stop endpoint, which sets
    // stop.status = 'picked-up' (items aren't flagged), so read the stop status.
    if (_stopFor(shop.businessId)?.status == 'picked-up') return true;
    return shop.items.isNotEmpty && shop.items.every((i) => i.isPickedUp);
  }

  bool get _allShopsPicked {
    if (!_isMultiStop) return _orderPickedUp;
    return _shops.isNotEmpty && _shops.every(_isShopPicked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: SizeConfig.size12),
          _buildRoute(),
          if (_isPending) ...[
            SizedBox(height: SizeConfig.size14),
            _buildAcceptRejectRow(),
          ] else if (_isOngoing && _allShopsPicked) ...[
            SizedBox(height: SizeConfig.size14),
            _buildDeliveryOtpSection(),
          ],
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CachedAvatarWidget(
          imageUrl: _order.user?.profileImage,
          size: SizeConfig.size40,
          borderRadius: SizeConfig.size20,
        ),
        SizedBox(width: SizeConfig.size8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                _order.user?.name ?? 'Customer',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size4),
              Row(
                children: [
                  _multiStopChip(),
                  SizedBox(width: SizeConfig.size6),
                  if (_order.user?.rating != null) ...[
                    CustomerRatingBadge(
                        rating: _order.user!.rating, compact: true),
                    SizedBox(width: SizeConfig.size6),
                  ],
                  if ((_order.orderNo ?? '').isNotEmpty)
                    Flexible(
                      child: CustomText(
                        '#${_order.orderNo}',
                        fontSize: SizeConfig.small11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CustomText(
              _formatTime(_order.createdAt ?? ''),
              fontSize: SizeConfig.extraSmall,
              fontWeight: FontWeight.w400,
              color: AppColors.grey9A,
            ),
            SizedBox(height: SizeConfig.size6),
            _fareBadge(),
          ],
        ),
      ],
    );
  }

  Widget _multiStopChip() {
    final count = _shops.isNotEmpty ? _shops.length : null;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alt_route_rounded,
              size: SizeConfig.size12, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            count != null ? '$count pickups • 1 drop' : 'Multi-stop',
            fontSize: SizeConfig.extraSmall,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _fareBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomText(
        '₹ ${_order.fare ?? 0}',
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryColor,
      ),
    );
  }

  // ── Route (pickups + drop) ──────────────────────────────────────
  Widget _buildRoute() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteFE,
        border: Border.all(color: AppColors.whiteE5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'PICK-UP STOPS',
            fontSize: SizeConfig.extraSmall,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryTextColor,
            letterSpacing: 0.6,
          ),
          SizedBox(height: SizeConfig.size10),
          if (_shops.isEmpty)
            CustomText(
              'Multiple pickup stops',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
            )
          else
            ...List.generate(_shops.length, (i) => _buildShopStop(i)),
          _buildDropStop(),
        ],
      ),
    );
  }

  Widget _buildShopStop(int index) {
    final shop = _shops[index];
    final picked = _isShopPicked(shop);
    // Reflect the persisted stop status too, so a refresh / rebuild doesn't lose
    // the "arrived" state held only in the ephemeral local set.
    final stopStatus = _stopFor(shop.businessId)?.status;
    final arrived = _arrived.contains(shop.businessId) ||
        stopStatus == 'arrived' ||
        stopStatus == 'picked-up';
    final name = shop.businessName.isNotEmpty
        ? shop.businessName
        : 'Shop ${index + 1}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sequence rail: numbered dot + connecting line.
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: picked
                      ? AppColors.green0B
                      : AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: picked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : CustomText(
                        '${index + 1}',
                        fontSize: SizeConfig.small11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
              ),
              Expanded(child: Container(width: 2, color: AppColors.whiteE5)),
            ],
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          name,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.items.isNotEmpty)
                        CustomText(
                          '${shop.items.length} item${shop.items.length == 1 ? '' : 's'}',
                          fontSize: SizeConfig.small11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      // Navigate to the shop + call the shop, while the rider is
                      // still collecting (ongoing and this stop not yet picked).
                      if (_isOngoing && !picked) ...[
                        _shopActionIcon(
                          icon: Icons.directions_rounded,
                          color: AppColors.primaryColor,
                          onTap: () => _navigateToShop(shop),
                        ),
                        _shopActionIcon(
                          icon: Icons.call,
                          color: AppColors.green0B,
                          onTap: () => _callShop(shop),
                        ),
                      ],
                    ],
                  ),
                  if (shop.amountPaid > 0) ...[
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      '₹ ${shop.amountPaid}',
                      fontSize: SizeConfig.small11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                  // Per-stop pickup workflow only while the ride is ongoing.
                  // Flipped direction: the rider taps "Arrived", then this shop's
                  // pickup OTP is shown read-only for the rider to read out to the
                  // shopkeeper, who enters it on their side to release the goods.
                  if (_isOngoing && !picked) ...[
                    SizedBox(height: SizeConfig.size8),
                    // Single-shop has no per-stop "arrive" endpoint — show the
                    // pickup OTP straight away for the rider to read out.
                    if (_isMultiStop && !arrived)
                      _arrivedButton(shop)
                    else
                      _shopOtpDisplay(shop),
                  ],
                  if (picked) ...[
                    SizedBox(height: SizeConfig.size4),
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: SizeConfig.size14,
                            color: AppColors.green0B),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          'Picked up',
                          fontSize: SizeConfig.small11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green0B,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropStop() {
    final address = _order.dropLocation?.address ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.redLite,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on, size: 14, color: Colors.white),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Drop — ${_order.user?.name ?? 'Customer'}',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (address.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  address,
                  fontSize: SizeConfig.small11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        // The customer is an app user → call via the in-app caller service
        // (WebRTC), not the phone dialer. Needs the customer's user id.
        if (_isOngoing && (_order.user?.id?.isNotEmpty ?? false))
          _callButton(),
      ],
    );
  }

  Widget _callButton() {
    return InkWell(
      onTap: _callCustomerInApp,
      child: Container(
        margin: EdgeInsets.only(left: SizeConfig.size6),
        padding: EdgeInsets.all(SizeConfig.size6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.4)),
        ),
        child: Icon(Icons.call,
            size: SizeConfig.size14, color: AppColors.primaryColor),
      ),
    );
  }

  // ── Per-shop "Arrived" + OTP box ────────────────────────────────
  Widget _arrivedButton(BusinessOrder shop) {
    return InkWell(
      onTap: () => _onArrived(shop),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined,
                size: SizeConfig.size14, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            // Flexible + ellipsis so the label shrinks instead of overflowing
            // when the shop-stop column is narrow (e.g. a long shop name pushes
            // the action icons and squeezes this row).
            Flexible(
              child: CustomText(
                'Arrived at shop',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Read-only display of this shop's pickup OTP. The rider reads it out to the
  /// shopkeeper, who enters it on their side (`multiShopStopPickup`); the SSE
  /// `ride:stop:update` then flips the stop to "Picked up".
  Widget _shopOtpDisplay(BusinessOrder shop) {
    final otp = _order.pickupOtpForBusiness(shop.businessId) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Show this pickup OTP to the shopkeeper',
          fontSize: SizeConfig.small11,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,
        ),
        SizedBox(height: SizeConfig.size6),
        if (otp.isEmpty)
          CustomText(
            'OTP not available yet',
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w500,
            color: AppColors.grey9A,
          )
        else
          Row(
            children: otp.split('').map((digit) {
              return Container(
                width: 34,
                height: 40,
                margin: EdgeInsets.only(right: SizeConfig.size6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.3)),
                ),
                child: CustomText(
                  digit,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── Final delivery OTP ──────────────────────────────────────────
  Widget _buildDeliveryOtpSection() {
    return Obx(() {
      final verifying = controller.verifyingOtpMap[_orderId] ?? false;
      final verified = controller.otpVerifiedMap[_orderId] ?? false;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.green0B.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.green0B.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    size: SizeConfig.size16, color: AppColors.green0B),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                  child: CustomText(
                    verified
                        ? 'Delivery verified'
                        : 'Enter customer Delivery OTP',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green0B,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            Row(
              children: [
                Flexible(
                  child: AbsorbPointer(
                    absorbing: verifying || verified,
                    child: Opacity(
                      opacity: (verifying || verified) ? 0.6 : 1,
                      child: _otpPinput(
                        enabled: !verified,
                        onCompleted: (pin) {
                          if (pin.length == 4) {
                            controller.verifyDeliveredOtp(_orderId, pin);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                if (verifying)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    verified
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: verified ? AppColors.green0B : AppColors.grey9A,
                    size: SizeConfig.size22,
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // Shared OTP field — 4-digit numeric box, matching the rest of the app.
  Widget _otpPinput({
    required ValueChanged<String> onCompleted,
    bool enabled = true,
  }) {
    return Pinput(
      length: 4,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onCompleted: onCompleted,
      defaultPinTheme: PinTheme(
        width: 40,
        height: 44,
        textStyle: TextStyle(
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greyE5),
        ),
      ),
      focusedPinTheme: PinTheme(
        width: 40,
        height: 44,
        textStyle: TextStyle(
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryColor, width: 1.4),
        ),
      ),
    );
  }

  // ── Accept / Reject (pending) ───────────────────────────────────
  Widget _buildAcceptRejectRow() {
    return Row(
      children: [
        Expanded(
          child: _ctaButton(
            label: 'Reject',
            bg: AppColors.redLite.withValues(alpha: 0.1),
            border: AppColors.redLite,
            fg: AppColors.redLite,
            onTap: () => _respondToOrder(AppConstants.reject),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: _ctaButton(
            label: 'Accept',
            bg: AppColors.green0B.withValues(alpha: 0.1),
            border: AppColors.green0B,
            fg: AppColors.green0B,
            onTap: () => _respondToOrder(AppConstants.accept),
          ),
        ),
      ],
    );
  }

  Widget _ctaButton({
    required String label,
    required Color bg,
    required Color border,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(100),
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────

  /// Accept/reject the order via the endpoint that matches its type:
  ///   • multi-stop / fare-call grocery → `rideAction` (the fare-call queue
  ///     accept — unchanged, must NOT break).
  ///   • single-shop chat-dispatch (standard) → `/fare/orders/:id/status`,
  ///     which assigns the rider AND emits the handoff OTP cards
  ///     (shop pickup + customer delivery) server-side.
  void _respondToOrder(String action) {
    if (_isMultiStop || _order.orderType == 'fare-call') {
      // rideAction resolves the order by its `orderId` STRING
      // (findOne({orderId})), not the Mongo _id — pass the string id.
      controller.rideAction(action, _order.orderId ?? _orderId);
    } else {
      // `/fare/orders/:id/status` resolves either _id or orderId; _id is fine.
      controller.updateRideOrParcelOrderStatusApi(
        {ApiKeys.action: action},
        _orderId,
      );
    }
  }

  Future<void> _onArrived(BusinessOrder shop) async {
    final ok = await controller.multiShopStopArrive(_orderId, shop.businessId);
    if (ok && mounted) {
      setState(() => _arrived.add(shop.businessId));
      // Re-pull so the persisted stop.status ('arrived') is reflected even after
      // the widget rebuilds (the local set is ephemeral).
      controller.fetchStream();
    }
  }

  String _formatTime(String isoString) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(isoString).toLocal());
    } catch (_) {
      return '';
    }
  }
}

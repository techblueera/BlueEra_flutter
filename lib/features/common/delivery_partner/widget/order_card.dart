import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
// Aliased: this file declares its own `User`, which collides with the order
// payload's `User` from rider_orders_details_model.
import 'package:BlueEra/core/api/model/user_profile_res.dart' as profile_res;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support_screen.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/ride_completed_rating_dialog.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import '../../../chat/auth/controller/call_controller.dart';
import '../../../chat/auth/model/rider_orders_details_model.dart';
import '../../../chat/view/orders_chat/widget/lat_lng_to_location_text.dart';
import '../../../me/laboratory/view/widgets/me_menu_card_design.dart';
import '../controller/delivery_partner_orders_controller.dart';
import '../model/grocery_order_details.dart';
import 'customer_rating_badge.dart';
import 'delivery_pickup_shops_list.dart';
import 'rider_map_actions.dart';

/// The rider's order card.
///
/// NOTE: an `isPipModeOn` flag used to strip this card down to fit an Android
/// picture-in-picture window. There is no rider PiP any more — the rider
/// navigates in the phone's Google Maps and this card carries the job — so the
/// flag and every `if (isPipModeOn == false)` around it are gone rather than
/// left as a permanently-false branch.
class OrderCard extends StatefulWidget {
  final PickUpTab selectedPickUp;
  final RiderOrdersDetailsModel order;

  const OrderCard({
    super.key,
    required this.selectedPickUp,
    required this.order,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  // NOTE: a 1-second `_travelTimer` used to run here to tick a live elapsed-time
  // readout. Nothing on the card counts up any more, so the timer (and the
  // rebuild it forced on every in-progress card, every second) is gone.

  /// The accept/decline currently in flight on THIS card
  /// ([AppConstants.accept] / [AppConstants.reject]), or null when idle.
  String? _respondingAction;

  /// Who the customer is beyond their name — profession for an individual,
  /// category/sub-category for a business. Null until resolved, and stays null
  /// when the lookup fails: the card degrades to name + number rather than
  /// showing a gap where a line was promised.
  _CustomerIdentity? _identity;

  @override
  void initState() {
    super.initState();
    _loadCustomerIdentity();
  }

  @override
  void didUpdateWidget(covariant OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.user?.id != widget.order.user?.id) {
      _identity = null;
      _loadCustomerIdentity();
    }
  }

  /// Passenger / parcel orders — the ones that navigate rather than deliver.
  bool get _isRideOrParcelOrder =>
      widget.order.orderFor == AppConstants.InCity ||
      widget.order.orderFor == AppConstants.OutStation ||
      widget.order.orderFor == AppConstants.HourlyRental ||
      widget.order.orderFor == AppConstants.Parcel;

  /// True once the pickup leg is done. `in-progress` (ride) / `picked-up`
  /// (parcel) / `completed` all mean the pickup OTP has been verified.
  bool get _isPickedUp =>
      widget.order.status == 'in-progress' ||
      widget.order.status == 'picked-up' ||
      widget.order.status == 'completed';

  /// An ongoing ride/parcel job — the rider is working it right now, either
  /// heading to the pickup or carrying to the drop.
  ///
  /// A working job is about GETTING THERE, so its location rows carry distance
  /// + a map shortcut instead of a call button. Nothing is lost: the one call
  /// button the rider needs sits on the customer row, where the name is.
  bool get _isOngoingRideCard =>
      widget.selectedPickUp == PickUpTab.onGoing && _isRideOrParcelOrder;

  /// The "Navigate to Pickup" leg of that job: accepted (`payment-pending` /
  /// `confirmed`) but the passenger isn't aboard yet. The pickup row only
  /// exists during this leg — once picked up it's hidden entirely.
  bool get _isNavigateToPickup => _isOngoingRideCard && !_isPickedUp;

  /// Any ongoing job, either leg. Both use the flat location block and the
  /// direction + stats action row; what differs is the pickup row (gone once
  /// collected) and what sits under it (OTP vs slide-to-complete).
  bool get _isOngoingCard => widget.selectedPickUp == PickUpTab.onGoing;

  /// An offer on the rail that the rider has NOT answered yet — accept and
  /// decline are both still on the card.
  bool get _isUnansweredOrder =>
      widget.selectedPickUp == PickUpTab.newOrder ||
      widget.selectedPickUp == PickUpTab.orders;

  /// True for the ride-type orders whose pickup leg is done — the case that
  /// used to carry the slide-to-complete.
  bool get _isRideInProgress =>
      _isRideOrParcelOrder && widget.order.status == 'in-progress';

  /// Resolve the customer's profession / business category for the customer row.
  ///
  /// The order payload's `user` carries only id / name / profile_image /
  /// contact_no, so this has to be looked up. Two guards keep a list of cards
  /// from turning into a burst of requests: it only runs for the ride/parcel
  /// cards that actually show the row, and results are cached per user id for
  /// the process lifetime (a customer's profession does not change mid-ride).
  Future<void> _loadCustomerIdentity() async {
    if (!_isRideOrParcelOrder) return;
    final userId = widget.order.user?.id;
    if (userId == null || userId.isEmpty) return;

    final cached = _identityCache[userId];
    if (cached != null) {
      _identity = cached;
      return; // already have it — no setState needed, build() reads it
    }

    final identity = await _fetchCustomerIdentity(userId);
    if (identity == null || !mounted) return;
    // The card may have been recycled onto a different order while in flight.
    if (widget.order.user?.id != userId) return;
    setState(() => _identity = identity);
  }

  static Future<_CustomerIdentity?> _fetchCustomerIdentity(String userId) {
    // De-dupe concurrent lookups: several cards in one list can belong to the
    // same customer, and they all build at once.
    return _identityInFlight.putIfAbsent(userId, () async {
      try {
        final response = await UserRepo().getUserById(userId: userId);
        if (!response.isSuccess || response.response?.data == null) return null;

        final user = profile_res.UserProfileRes
            .fromJson(response.response?.data)
            .user;
        final isBusiness =
            (user?.accountType ?? '').toUpperCase().contains('BUSINESS');

        final identity = isBusiness
            ? await _fetchBusinessIdentity(userId)
            // Individual: profession is the headline; designation is the
            // fallback for profiles that only filled the job title in.
            : _CustomerIdentity.of(user?.profession ?? user?.designation);

        if (identity != null) _identityCache[userId] = identity;
        return identity;
      } catch (_) {
        // Fail soft — the row still has the name and number, which is what the
        // rider actually needs at the kerb.
        return null;
      } finally {
        _identityInFlight.remove(userId);
      }
    });
  }

  /// Business customers: category, narrowed by sub-category when both are set.
  /// Only the resolved `*_details.name` values are used — the bare
  /// `category_Of_Business` fields are ids, which would render as a hash.
  static Future<_CustomerIdentity?> _fetchBusinessIdentity(String userId) async {
    final response = await BusinessProfileRepo().viewBusinessProfileById(userId);
    if (!response.isSuccess || response.response?.data == null) return null;

    final details =
        ViewBusinessProfileModel.fromJson(response.response?.data).data;
    return _CustomerIdentity.of(
      details?.categoryDetails?.name,
      secondary: details?.subCategoryDetails?.name,
      isBusiness: true,
    );
  }

  /// Keyed by user id, shared across every card in the list.
  static final Map<String, _CustomerIdentity> _identityCache = {};
  static final Map<String, Future<_CustomerIdentity?>> _identityInFlight = {};

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => DeliverPartnerOrdersController());

    return CustomFormCard(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(context, controller),
            SizedBox(height: SizeConfig.size14),
            _buildLocationSection(context),
            if (_shouldShowActions())
              SizedBox(height: SizeConfig.size14),
            _buildActionSection(controller),
          ],
        ),
      ),
    );
  }

  // ============================================
  Widget _buildHeaderSection(BuildContext context, DeliverPartnerOrdersController controller) {
    switch (widget.selectedPickUp) {
      case PickUpTab.newOrder:
      case PickUpTab.orders:
        return _buildNewOrderHeader(context);
      case PickUpTab.onGoing:
        return _buildOnGoingOrderHeader();
      case PickUpTab.completed:
        return _buildCompletedOrderHeader(context);
      case PickUpTab.cancel:
        return _buildStatusOrderHeader(context, 'Cancelled', AppColors.redLite);
      case PickUpTab.rejected:
        return _buildStatusOrderHeader(context, 'Rejected', AppColors.redLite);
    }
  }

  Widget _buildNewOrderHeader(BuildContext context) {
    return Row(
      children: [
        _buildUserAvatar(context),
        SizedBox(width: SizeConfig.size6),
        Expanded(child: _buildUserName()),
        SizedBox(width: SizeConfig.size6),
        _buildTimeAndReviewBadge(),
      ],
    );
  }

  Widget _buildOnGoingOrderHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(child: _buildOrderIdAndPickupOtp()),
        SizedBox(width: SizeConfig.size6),
        _buildTimeAndStageBadge(),
      ],
    );
  }

  Widget _buildCompletedOrderHeader(BuildContext context) {
    return _buildStatusOrderHeader(context, 'Completed', AppColors.green1A);
  }

  Widget _buildStatusOrderHeader(BuildContext context, String status, Color color) {
    return Row(
      children: [
        _buildUserAvatar(context),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: SizeConfig.size6),
              _buildStatusBadge(status, color),
            ],
          ),
        ),
        SizedBox(width: SizeConfig.size6),
        _buildTimeAndFareBadge(),
      ],
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return InkWell(
      onTap: () => navigatePushTo(
        context,
        ImageViewScreen(
          appBarTitle: '',
          imageUrls: [widget.order.user?.profileImage ?? ''],
          initialIndex: 0,
        ),
      ),
      child: CachedAvatarWidget(
        imageUrl: widget.order.user?.profileImage,
        size: SizeConfig.size40,
        borderRadius: SizeConfig.size20,
      ),
    );
  }

  Widget _buildUserName() {
    // The rating sits with the name, not off in the meta row: on the
    // new-order card this is the moment the rider decides whether to accept,
    // and who they'd be picking up is the deciding fact.
    return Row(
      children: [
        Flexible(
          child: CustomText(
            widget.order.user?.name,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.order.user?.rating != null) ...[
          SizedBox(width: SizeConfig.size6),
          CustomerRatingBadge(rating: widget.order.user!.rating),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size4,
        horizontal: SizeConfig.size8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100.0),
        color: color.withValues(alpha: 0.1),
      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.extraSmall,
        fontWeight: FontWeight.w400,
        color: color,
      ),
    );
  }

  Widget _buildTimeAndReviewBadge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTimeText(),
        SizedBox(height: SizeConfig.size8),
        _buildBadge(
          text: AppStrings.review,
          borderColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildTimeAndFareBadge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTimeText(),
        SizedBox(height: SizeConfig.size8),
        _buildFareWidget(),
      ],
    );
  }

  Widget _buildTimeText() {
    return CustomText(
      _formatTime(widget.order.createdAt ?? ''),
      fontSize: SizeConfig.extraSmall,
      fontWeight: FontWeight.w400,
      color: AppColors.grey9A,
    );
  }

  Widget _buildOrderIdAndPickupOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          '${AppStrings.orderNo.tr} - ${widget.order.orderNo}',
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Passenger rides: the CUSTOMER holds the ride-start (pickup) OTP and
        // reads it to the rider, who only enters it — the rider must never see
        // the digits. Goods/parcel keep showing it (the rider reads it out to
        // the shop/sender). See RIDER_FRONTEND_INTEGRATION_GUIDE §8.
        if (!(widget.order.jobInfo?.isRide ?? false)) ...[
          SizedBox(height: SizeConfig.size6),
          Row(
            children: [
              CustomText(
                '${AppStrings.pickUpOTP.tr}: ',
                fontSize: SizeConfig.small11,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
              ),
              CustomText(
                '${widget.order.pickupOTP}',
                fontSize: SizeConfig.small11,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTimeAndStageBadge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTimeText(),
        SizedBox(height: SizeConfig.size8),
        _buildStageBadge(),
      ],
    );
  }

  /// Where the job stands right now — a LABEL, not a button.
  ///
  /// Two changes from what this slot used to be. It printed the raw backend
  /// status ("payment-pending"), which means nothing to a rider; while the
  /// pickup is still ahead it now reads "Go to Pick Up" in green. And it was
  /// wired to `_handleCancelOrder`, which cancelled the order on tap with no
  /// confirmation — a pill that looks exactly like a status chip must not do
  /// that, so it no longer takes taps at all.
  Widget _buildStageBadge() {
    final isPickupStage = !_isPickedUp;
    // Green heading out, amber once the job is running, and only then does the
    // raw backend status show through (completed / cancelled cards).
    final color = isPickupStage
        ? AppColors.green1A
        : (_isRideInProgress ? AppColors.yellow00 : AppColors.primaryColor);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: CustomText(
        isPickupStage
            ? AppStrings.goToPickUp
            : (_isRideInProgress
                ? AppStrings.rideInProgress
                : widget.order.status),
        fontSize: SizeConfig.small11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  // ============================================
  Widget _buildLocationSection(BuildContext context) {
    return Column(
      children: [
        if (_isOngoingCard)
          _buildPickupStageLocations()
        else
        Container(
          // An UNANSWERED offer gets the flat tinted block the ongoing card
          // uses: a raised, shadowed panel reads as a control, and on the one
          // card where the rider is deciding rather than working, the addresses
          // should sit quietly under the fare and the two buttons. The other
          // tabs (completed, cancelled, rejected) keep the original surface.
          decoration: BoxDecoration(
            border: Border.all(
              color: _isUnansweredOrder
                  ? AppColors.primaryColor.withValues(alpha: 0.10)
                  : AppColors.whiteE5,
            ),
            color: _isUnansweredOrder
                ? AppColors.primaryColor.withValues(alpha: 0.04)
                : AppColors.whiteFE,
            borderRadius: BorderRadius.circular(_isUnansweredOrder ? 14.0 : 10.0),
            boxShadow:
                _isUnansweredOrder ? null : [AppShadows.textFieldShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if((widget.order.orderFor==AppConstants.InCity
                  ||widget.order.orderFor==AppConstants.OutStation
                  ||widget.order.orderFor==AppConstants.HourlyRental
                  ||widget.order.orderFor==AppConstants.Parcel)&& widget.order.status=='in-progress')
                SizedBox()
              else
              _buildPickupLocation(),

              _buildDropLocation(),
            ],
          ),
        ),
        if(widget.order.orderFor==AppConstants.grocery&&widget.selectedPickUp ==PickUpTab.onGoing)
        Container(
          margin: EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.whiteE5),
            color: AppColors.whiteFE,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [AppShadows.textFieldShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroceryShopList(context),
            ],
          ),
        ),
      ],
    );
  }

  /// Pickup + drop in one flat tinted block: title, distance in blue with a pin,
  /// address underneath, a hairline between the two.
  ///
  /// Once the job is collected the pickup row drops out entirely — the rider is
  /// past it, and the only place left to be is the drop. Only for the ongoing
  /// tab; everywhere else keeps the bordered/shadowed card and its own row
  /// content (call button, grocery shop list, …).
  Widget _buildPickupStageLocations() {
    final dropLat =
        widget.order.dropLocation?.location?.coordinates?[1].toDouble() ?? 0.0;
    final dropLng =
        widget.order.dropLocation?.location?.coordinates?[0].toDouble() ?? 0.0;
    final dropKm = calculateDistance(dropLat, dropLng)?.toStringAsFixed(2);
    final pickupKm = _cleanDistance(widget.order.distanceToPickup);

    return Container(
      decoration: BoxDecoration(
        // Barely-there blue wash, not a grey panel — the block should recede
        // behind the addresses printed on it. The hairline keeps it a defined
        // panel on white rather than a smudge.
        color: AppColors.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isPickedUp &&
              (widget.order.pickupLocation?.location?.coordinates?.isNotEmpty ??
                  false)) ...[
            _buildStageLocationRow(
              title: AppStrings.pickupLocation.tr,
              dotColor: AppColors.green0B,
              distance: pickupKm == null ? null : _withKm(pickupKm),
              latitude: widget.order.pickupLocation?.location?.coordinates?[1]
                      .toDouble() ??
                  0.0,
              longitude: widget.order.pickupLocation?.location?.coordinates?[0]
                      .toDouble() ??
                  0.0,
              onTap: _handleOpenPickupLocation,
            ),
            _buildDivider(),
          ],
          _buildStageLocationRow(
            title: AppStrings.dropLocation.tr,
            dotColor: AppColors.redLite,
            distance: dropKm != null ? '$dropKm KM' : null,
            latitude: dropLat,
            longitude: dropLng,
            onTap: _handleOpenDropLocation,
            // Who is being dropped to, and on what number. Once the pickup row
            // is gone this is the only place the receiver appears, and it is
            // what the rider needs at the far end of the trip.
            leadingLine: _receiverName.isNotEmpty ? '$_receiverName,' : null,
            addressLine: _dropAddressLine,
          ),
        ],
      ),
    );
  }

  String get _receiverName => (widget.order.receiverUser?.name ?? '').trim();

  String get _receiverContact =>
      (widget.order.receiverUser?.contactNo ?? '').trim();

  /// Drop address and receiver phone as ONE grey line, the way the design reads
  /// them ("Bishnupur, Lucknow Gomtinagar, +91 1234567890").
  ///
  /// Uses the address the order already carries; null falls the row back to the
  /// reverse-geocoded [LocationTextWidget], which can't be concatenated because
  /// it resolves asynchronously in its own widget.
  String? get _dropAddressLine {
    final address = (widget.order.dropLocation?.address ?? '').trim();
    if (address.isEmpty) return null;
    if (_receiverContact.isEmpty) return address;
    return '$address, ${normalisePhone(_receiverContact)}';
  }

  Widget _buildStageLocationRow({
    required String title,
    required Color dotColor,
    required String? distance,
    required double latitude,
    required double longitude,
    required VoidCallback onTap,
    String? leadingLine,
    String? addressLine,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Green = where the job starts, red = where it ends. The two
                // rows read identically otherwise, and the rider scans this
                // block at a glance.
                Icon(
                  Icons.radio_button_checked,
                  size: SizeConfig.size16,
                  color: dotColor,
                ),
                SizedBox(width: SizeConfig.size6),
                Flexible(
                  child: CustomText(
                    '$title : ',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (distance != null) ...[
                  CustomText(
                    distance,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                  ),
                  SizedBox(width: SizeConfig.size4),
                  // The app's own map-pin glyph, not Material's GPS-style
                  // crosshair/pin — same pin the rest of the app uses for a
                  // place.
                  LocalAssets(
                    imagePath: AppIconAssets.location_outline,
                    imgColor: AppColors.primaryColor,
                    height: SizeConfig.size16,
                    width: SizeConfig.size16,
                  ),
                ],
              ],
            ),
            SizedBox(height: SizeConfig.size6),
            if (leadingLine != null)
              CustomText(
                leadingLine,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (addressLine != null)
              CustomText(
                addressLine,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              _buildLocationText(latitude: latitude, longitude: longitude),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupLocation() {
    if(widget.order.pickupLocation?.location?.coordinates?.isNotEmpty??false){
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(SizeConfig.size10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPickupLocationInfo()),
                    if (_isNavigateToPickup)
                      _buildDistanceMapAction(
                        distance: widget.order.distanceToPickup,
                        onTap: _handleOpenPickupLocation,
                      )
                    else if (widget.selectedPickUp == PickUpTab.onGoing)
                      _buildCallButton(widget.order.receiverUser?.contactNo),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                _buildLocationText(
                  latitude: widget.order.pickupLocation?.location?.coordinates?[1].toDouble() ?? 0.0,
                  longitude: widget.order.pickupLocation?.location?.coordinates?[0].toDouble() ?? 0.0,
                ),
              ],
            ),
          ),
          _buildDivider(),
        ],
      );
    }else{
      return SizedBox();
    }

  }

  Widget _buildPickupLocationInfo() {
    return InkWell(
      onTap: () => _handleOpenPickupLocation(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CustomText(
            'Pick- Up: ',
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
          // Before pickup the distance moves to the end of the row, beside the
          // map shortcut — printing it in both places just repeats it.
          if (!_isNavigateToPickup) ...[
            CustomText(
              '${widget.order.distanceToPickup}',
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size2),
            Icon(
              Icons.location_on_outlined,
              size: SizeConfig.size12,
              color: AppColors.primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  /// Trailing distance + map shortcut, in place of the call button while the
  /// rider is still heading to the pickup.
  ///
  /// [distance] is dropped when the server sends nothing usable (it spells the
  /// blank three different ways), leaving the map icon on its own rather than a
  /// stray "N/A".
  Widget _buildDistanceMapAction({
    required String? distance,
    required VoidCallback onTap,
  }) {
    final text = _cleanDistance(distance);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100.0),
      child: Padding(
        padding: EdgeInsets.only(left: SizeConfig.size6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text != null) ...[
              CustomText(
                text,
                fontSize: SizeConfig.small11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size4),
            ],
            Icon(
              Icons.map_outlined,
              size: SizeConfig.size16,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// The API sends an absent distance as `N/A`, `null` (the string) or empty.
  /// Distance values arrive as bare numbers on some orders and already
  /// unit-suffixed on others, so the card printed a naked "5.05" next to a
  /// "10 KM". Adds the unit only when there isn't one, never "km km".
  static String _withKm(String value) =>
      RegExp(r'[a-zA-Z]').hasMatch(value) ? value : '$value KM';

  static String? _cleanDistance(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value == 'N/A' || value == 'null') return null;
    return value;
  }

  Widget _buildGroceryShopList(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText("Pick-Up From",fontSize: 10,fontWeight: FontWeight.w400,),
            ],
          ),
           SizedBox(height: SizeConfig.size10),
          ...widget.order.groceryOrderDetails?.businesses.map((business) {
            return InkWell(
              onTap: (){
                showItemsReceivedDialog(
                  context,
                  businessName: business.businessName.isNotEmpty
                      ? business.businessName
                      : business.businessId,
                  items: business.items,
                  onSubmit: (allReceived, missingItems) {
                    // Track received/missing items status
                    if (allReceived) {
                      commonSnackBar(message: 'All items received from ${business.businessName.isNotEmpty ? business.businessName : "store"}');
                    } else {
                      commonSnackBar(message: '${missingItems.length} item(s) missing');
                    }
                  },
                );

              },
              child: Container(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          business.businessName.isNotEmpty
                              ? business.businessName
                              : business.businessId,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                         SizedBox(height: SizeConfig.size4),
                        Row(
                          children: [
                            CustomText('${business.items.length} Items',
                            fontWeight: FontWeight.w400,
                              fontSize: 10,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: SizeConfig.size4,),
                            CustomText('₹ ${business.amountPaid} Price',
                            fontWeight: FontWeight.w400,
                              fontSize: 10,
                              color: AppColors.black,
                            )
                          ],
                        )
                        //
                        // ...business.items.map((item) {
                        //   return Padding(
                        //     padding: const EdgeInsets.only(bottom: 4),
                        //     child: CustomText(
                        //       item.productDetails.product.name,
                        //       fontSize: 11,
                        //       fontWeight: FontWeight.w400,
                        //     ),
                        //   );
                        // }).toList(),
                      ],
                    ),
                    CustomToggleSwitch(
                      isOn: business.items.every((item) => item.isPickedUp),
                      onChanged: (val){
                        // Toggle is informational — items are marked via the dialog
                      },
                    )
                  ],
                ),
              ),
            );
          }).toList()??[],
        ],
      ),
    );
  }

  void showItemsReceivedDialog(
      BuildContext context, {
        required String businessName,
        required List<OrderItem> items,
        required Function(bool allReceived, List<OrderItem> missingItems) onSubmit,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selectedIds = <String>{};

            void toggleItem(OrderItem item, bool value) {
              setState(() {
                if (value) {
                  selectedIds.add(item.inventoryId);
                } else {
                  selectedIds.remove(item.inventoryId);
                }
              });
            }

            final allSelected = selectedIds.length == items.length;
            final missingCount = items.length - selectedIds.length;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// HEADER
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            businessName,

                              fontSize: 16,
                              fontWeight: FontWeight.bold,

                          ),
                        ),
                        InkWell(
                            onTap: (){
                              Get.back();
                            },
                            child: Icon(Icons.close))
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// ITEM LIST
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, index) {
                          final item = items[index];
                          final product =
                              item.productDetails.product.name ;
                          final variant = item.productDetails.variantName ;

                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.whiteE5
                              )
                            ),
                            padding: EdgeInsets.all(10),
                            child: Row(
                              children: [
                                /// IMAGE
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteE5,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.shopping_bag_outlined, size: 24, color: AppColors.secondaryTextColor),
                                ),

                                const SizedBox(width: 10),

                                /// NAME
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        product,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                            fontWeight: FontWeight.w500
                                      ),
                                      Row(
                                        children: [

                                          CustomText(
                                            variant,
                                                fontSize: 12, color: AppColors.grayText
                                          ),
                                          SizedBox(width: 10,),
                                          CustomText(
                                              item.productDetails.product.brand,
                                              fontSize: 12, color: AppColors.black
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                /// CHECKBOX
                                Checkbox(
                                  value: selectedIds.contains(item.inventoryId),
                                  onChanged: (v) =>
                                      toggleItem(item, v ?? false),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// STATUS TEXT
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        allSelected
                            ? 'All Items Received'
                            : '$missingCount item(s) missing',
                        style: TextStyle(
                          color: allSelected
                              ? Colors.green
                              : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedIds.isEmpty
                            ? null
                            : () {
                          final missingItems = items
                              .where((e) =>
                          !selectedIds.contains(e.inventoryId))
                              .toList();

                          onSubmit(allSelected, missingItems);
                          Navigator.pop(context);
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropLocation() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildDropLocationInfo()),

              // Both legs, not just the pickup one: after pickup this row is the
              // only location on the card, and "how far to the drop + open it
              // in maps" is what the rider is asking it.
              if (_isOngoingRideCard)
                _buildDistanceMapAction(
                  distance: widget.order.distancePickupToDrop,
                  onTap: _handleOpenDropLocation,
                )
              else
                _buildCallButton(widget.order.user?.contactNo),
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          _buildDropLocationDetails(),
        ],
      ),
    );
  }

  Widget _buildDropLocationInfo() {
    return InkWell(
      onTap: () => _handleOpenDropLocation(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.dropLocation,
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
          // As on the pickup row: on a working job this pair moves to the end
          // of the row, next to the map shortcut.
          if (!_isOngoingRideCard) ...[
            CustomText(
              ' ${_cleanDistance(widget.order.distancePickupToDrop) ?? ''}',
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size2),
            if (_cleanDistance(widget.order.distancePickupToDrop) != null)
              Icon(
                Icons.location_on_outlined,
                size: SizeConfig.size12,
                color: AppColors.primaryColor,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropLocationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationText(
          latitude:  widget.order.dropLocation?.location?.coordinates?[1].toDouble() ?? 0.0,
          longitude: widget.order.dropLocation?.location?.coordinates?[0].toDouble() ?? 0.0,
        ),
        // if (_shouldShowContactNumber()) ...[
        //   SizedBox(height: SizeConfig.size4),
        //   Row(
        //     children: [
        //       Icon(Icons.phone_outlined, size: 12, color: AppColors.secondaryTextColor),
        //       SizedBox(width: SizeConfig.size4),
        //       CustomText(
        //         '+91 ${widget.order.user?.contactNo}',
        //         fontSize: SizeConfig.small11,
        //         fontWeight: FontWeight.w600,
        //         color: AppColors.secondaryTextColor,
        //       ),
        //     ],
        //   ),
        // ],
        SizedBox(height: SizeConfig.size6),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 12, color: AppColors.secondaryTextColor),
            SizedBox(width: SizeConfig.size4),
            CustomText(
              '${
                calculateDistance(
                    widget.order.dropLocation?.location?.coordinates?[1].toDouble() ?? 0.0,
                    widget.order.dropLocation?.location?.coordinates?[0].toDouble() ?? 0.0)?.toStringAsFixed(2)
              } KM Away',
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCallButton(String? contactNo) {
    return InkWell(
      onTap: () => _handleCallAction(contactNo),
      child: Container(
        margin: EdgeInsets.only(left: SizeConfig.size6),
        padding: EdgeInsets.all(SizeConfig.size5),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.secondaryTextColor),
        ),
        child: LocalAssets(
            imagePath: AppIconAssets.call,
            imgColor: AppColors.secondaryTextColor,
            height: SizeConfig.size14,
            width: SizeConfig.size14
        ),
      ),
    );
  }

  // ============================================
  Widget _buildActionSection(DeliverPartnerOrdersController controller) {
    switch (widget.selectedPickUp) {
      case PickUpTab.newOrder:
      case PickUpTab.orders:
        return _buildNewOrderActions(controller);
      case PickUpTab.onGoing:
        return _buildOnGoingOrderActions(controller);
      case PickUpTab.completed:
      case PickUpTab.cancel:
      case PickUpTab.rejected:
        return SizedBox();
    }
  }

  Widget _buildNewOrderActions(DeliverPartnerOrdersController controller) {
    final isFareCall = widget.order.orderType == 'fare-call';

    // In flight — the loader replaces the buttons on THIS card, so the rider
    // sees which order they answered and the rest of the list stays usable.
    // It also makes the pair un-tappable, which the global dialog used to do.
    if (_respondingAction != null) {
      final rejecting = _respondingAction == AppConstants.reject;
      return Row(
        children: [
          _buildFareWidget(),
          const Spacer(),
          SizedBox(
            height: SizeConfig.size16,
            width: SizeConfig.size16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: rejecting ? AppColors.redLite : AppColors.green0B,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          CustomText(
            rejecting ? 'Declining…' : 'Accepting…',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildFareWidget(),
        Spacer(),
        SizedBox(width: SizeConfig.size6),
        _buildActionButton(
          onTap: () {
            if(widget.order.orderFor==AppConstants.InCity
                ||widget.order.orderFor==AppConstants.OutStation
                ||widget.order.orderFor==AppConstants.HourlyRental
                ||widget.order.orderFor==AppConstants.Parcel){
              _runOrderResponse(AppConstants.reject, () {
                return isFareCall
                    ? controller.rideAction(
                        AppConstants.reject, widget.order.id ?? "")
                    : controller.updateRideOrParcelOrderStatusApi(
                        {ApiKeys.action: AppConstants.reject},
                        widget.order.id ?? "",
                      );
              });
            }else{
              _handleRejectOrder(controller);
            }
          },
          text: AppStrings.reject,
          bgColor: AppColors.redLite.withValues(alpha: 0.1),
          borderColor: AppColors.redLite,
          textColor: AppColors.redLite,
        ),
        SizedBox(width: SizeConfig.size6),
        _buildActionButton(
          onTap: () {
            if(widget.order.orderFor==AppConstants.InCity
                ||widget.order.orderFor==AppConstants.OutStation
                ||widget.order.orderFor==AppConstants.HourlyRental
                ||widget.order.orderFor==AppConstants.Parcel){
              _runOrderResponse(AppConstants.accept, () {
                return isFareCall
                    ? controller.rideAction(
                        AppConstants.accept, widget.order.id ?? "")
                    : controller.updateRideOrParcelOrderStatusApi(
                        {ApiKeys.action: AppConstants.accept},
                        widget.order.id ?? "",
                      );
              });
            }else if(widget.order.orderFor?.toLowerCase()==AppConstants.grocery){
              Get.to(()=>DeliveryPickupShopsList(
                order: widget.order,
                orderId: widget.order.orderId??'', rideOrderId: widget.order.id??'',));
            }else if(widget.order.orderFor?.toLowerCase()==AppConstants.product
                ||widget.order.orderFor?.toLowerCase()==AppConstants.food
                ||widget.order.orderFor?.toLowerCase()==AppConstants.medical){
              _handleAcceptOrder(controller);
            }
           },
          text: AppStrings.accept,
          bgColor: AppColors.green0B.withValues(alpha: 0.1),
          borderColor: AppColors.green0B,
          textColor: AppColors.green0B,
        ),
      ],
    );
  }

  /// Runs an accept/decline with the card showing its own loader.
  ///
  /// A second tap while one is in flight is dropped — the buttons are gone by
  /// then, but the guard also covers the double-tap that lands in the same
  /// frame. The flag is cleared in a `finally` so a failed call gives the
  /// buttons back rather than freezing the card on a spinner.
  Future<void> _runOrderResponse(
    String action,
    Future<bool> Function() run,
  ) async {
    if (_respondingAction != null) return;
    setState(() => _respondingAction = action);
    try {
      await run();
    } finally {
      if (mounted) setState(() => _respondingAction = null);
    }
  }

  /// Turn-by-turn to the PICKUP point, in the phone's Google Maps.
  void _handleNavigateToPickup() {
    if (!_hasPickupCoordinates) {
      commonSnackBar(message: AppStrings.locationNotAvailable);
      return;
    }
    openGoogleMapsNavigation(latitude: _pickupLat, longitude: _pickupLng);
  }

  /// Turn-by-turn to the DROP point, in the phone's Google Maps.
  ///
  /// This replaces the in-app destination screen (live map + polyline + PiP)
  /// that the post-pickup CTA used to push. The rider is driving, so the
  /// phone's own navigation is what they actually follow, and everything that
  /// screen showed beside the map now lives on this card.
  void _handleNavigateToDrop() {
    if (!_hasDropCoordinates) {
      commonSnackBar(message: AppStrings.locationNotAvailable);
      return;
    }
    openGoogleMapsNavigation(latitude: _dropLat, longitude: _dropLng);
  }

  /// Customer identity block for the ongoing ride card: photo, name, what they
  /// do, and a call button.
  ///
  /// "What they do" is a profession for an individual and a category (narrowed
  /// by sub-category) for a business. Neither travels on the order payload, so
  /// both come from [_loadCustomerIdentity] and the line simply doesn't render
  /// until it resolves — it replaces the phone number, which was only ever a
  /// stand-in for it and is still one tap away on the call button.
  ///
  /// [labelledCall] swaps the small circular call icon for a labelled "Call"
  /// pill — used on the pre-pickup leg, where calling the customer is the row's
  /// whole point and the icon alone read as decoration.
  /// [emergency] paints the call pill red and labels it "Emergency Call" — for
  /// the leg where the passenger is aboard and a call is an incident, not a
  /// courtesy. It dials the same customer number either way.
  Widget _buildCustomerInfoRow({
    bool labelledCall = false,
    bool emergency = false,
  }) {
    final user = widget.order.user;
    final name = (user?.name ?? '').trim();
    final contact = (user?.contactNo ?? '').trim();
    if (name.isEmpty && contact.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: labelledCall
            ? AppColors.white
            : AppColors.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        children: [
          _buildUserAvatar(context),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  name.isNotEmpty ? name : 'Customer',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_identity != null) ...[
                  SizedBox(height: SizeConfig.size2),
                  _buildCustomerIdentityLine(_identity!),
                ],
              ],
            ),
          ),
          if (contact.isNotEmpty)
            labelledCall
                ? _buildLabelledCallButton(
                    contact,
                    label: emergency ? AppStrings.emergencyCall : null,
                    color: emergency ? AppColors.redLite : null,
                  )
                : _buildCallButton(contact),
        ],
      ),
    );
  }

  /// Outlined "Call" pill (icon + word), for rows where calling is the primary
  /// action rather than an afterthought. [onTap] overrides the default
  /// customer-call behaviour (used by the customer-care row).
  Widget _buildLabelledCallButton(
    String contactNo, {
    VoidCallback? onTap,
    String? label,
    Color? color,
  }) {
    final tint = color ?? AppColors.primaryColor;
    return InkWell(
      onTap: onTap ?? () => _handleCallAction(contactNo),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: EdgeInsets.only(left: SizeConfig.size6),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          // A whisper of the accent behind an emergency pill, so it reads as
          // charged rather than as another outlined button.
          color: color == null ? AppColors.white : tint.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tint),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.call,
              imgColor: tint,
              height: SizeConfig.size14,
              width: SizeConfig.size14,
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              label ?? AppStrings.call.tr,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: tint,
            ),
          ],
        ),
      ),
    );
  }

  /// The profession / category line, tinted to read as an attribute of the
  /// customer rather than a second name.
  Widget _buildCustomerIdentityLine(_CustomerIdentity identity) {
    return Row(
      children: [
        Icon(
          identity.isBusiness ? Icons.storefront_outlined : Icons.work_outline,
          size: SizeConfig.size12,
          color: AppColors.primaryColor,
        ),
        SizedBox(width: SizeConfig.size4),
        Expanded(
          child: CustomText(
            identity.label,
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Whether the order carries a pickup point worth navigating to. Guards the
  /// direction CTA so it never launches Maps at (0, 0).
  bool get _hasPickupCoordinates {
    final coords = widget.order.pickupLocation?.location?.coordinates;
    if (coords == null || coords.length < 2) return false;
    return coords[0].toDouble() != 0.0 || coords[1].toDouble() != 0.0;
  }

  bool get _hasDropCoordinates {
    final coords = widget.order.dropLocation?.location?.coordinates;
    if (coords == null || coords.length < 2) return false;
    return coords[0].toDouble() != 0.0 || coords[1].toDouble() != 0.0;
  }

  /// A ride/parcel the rider is carrying right now — the card shows
  /// slide-to-complete instead of an OTP field. Goods deliveries keep the OTP:
  /// they are closed out by the customer's delivery code, not by the rider.
  bool get _showsRideCompletion =>
      _isRideOrParcelOrder &&
      _isPickedUp &&
      // `_isPickedUp` is also true for a finished ride; offering to complete
      // one again would just bounce off the server.
      widget.order.status != 'completed';

  /// Slide-to-complete, moved here from PassengerDestinationScreen. Completing
  /// calls the same rider-only endpoint that screen used, which reports the
  /// rider's location and closes the ride.
  ///
  /// Uses [SlideToCompleteButton] rather than a slider built inline: it keeps
  /// the drag in its own StatefulWidget (so a drag doesn't rebuild this whole
  /// card), shows its own "Completing…" state, and starts tracking on
  /// touch-down — without that last part the orders list steals the gesture and
  /// the knob barely moves.
  Widget _buildSlideToComplete() {
    return SlideToCompleteButton(
      height: SizeConfig.size48,
      text: AppStrings.swipeCompleteTheRide,
      onComplete: _handleCompleteRide,
    );
  }

  /// The controller reports success/failure to the rider itself, so a failed
  /// attempt simply leaves the card as it is and can be swiped again.
  ///
  /// On success the completion dialog takes over: confirmation, the payment QR,
  /// and the customer rating.
  Future<void> _handleCompleteRide() async {
    final orderId = widget.order.id ?? '';
    if (orderId.isEmpty) return;
    // Read what the dialog needs BEFORE the await. Completing the ride makes
    // the orders SSE stream push a list without this order, which rebuilds the
    // ongoing tab and disposes this card — often before the call even returns.
    final customerName = (widget.order.user?.name ?? '').trim();

    final completed = await getOrPut(() => DeliverPartnerOrdersController())
        .completePickupRiderApi(orderId);
    if (!completed) return;

    // Deliberately NOT this card's context, and no `mounted` guard: by now the
    // card is usually gone, and both of those silently swallowed the dialog.
    // The dialog belongs to the app, not to the card that started it.
    await showRideCompletedDialog(
      customerName: customerName,
      // Order-identifying payload for now — the payment string replaces it once
      // the collection flow is defined.
      qrData: orderId,
    );
  }

  /// The ongoing card's action row: the direction CTA plus the trip length —
  /// [ Pickup Direction | Travel Dist. ] heading out, [ Drop Location | Travel
  /// Dist. ] once the job is running.
  ///
  /// Both hand navigation to the Google Maps app; nothing here opens an in-app
  /// map. A box whose value isn't known is dropped rather than rendered blank,
  /// so the row collapses gracefully to two items or one.
  Widget _buildActionStatsRow() {
    final distance = _cleanDistance(widget.order.distancePickupToDrop);

    final tiles = <Widget>[
      _buildDirectionButton(
        label: _isPickedUp
            ? AppStrings.dropLocationDirection
            : AppStrings.pickupDirection,
        onTap: _isPickedUp ? _handleNavigateToDrop : _handleNavigateToPickup,
      ),
      if (distance != null)
        _buildStatBox(
          iconAsset: AppIconAssets.distanceLocation,
          label: _isPickedUp ? AppStrings.travelDist : AppStrings.travelDistance,
          value: _withKm(distance),
          tint: AppColors.primaryColor,
          onTap: _handleOpenPickupToDropRoute,
        ),
    ];

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

  /// Outlined CTA that hands the rider to the Google Maps app.
  ///
  /// Wrapped in a slow pulse: this is the one thing a rider on a live job is
  /// meant to reach for next, and it otherwise sits as a quiet outline among
  /// tiles of the same size and weight.
  Widget _buildDirectionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return RiderDirectionButton(label: label, onTap: onTap);
  }

  /// Tinted label-over-value tile sitting beside the direction CTA — trip
  /// length, elapsed time. [onTap] is optional; a tile with nothing to open is
  /// simply not tappable.
  Widget _buildStatBox({
    String? iconAsset,
    IconData? icon,
    required String label,
    required String value,
    required Color tint,
    VoidCallback? onTap,
  }) {
    return RiderStatBox(
      iconAsset: iconAsset,
      icon: icon,
      label: label,
      value: value,
      tint: tint,
      onTap: onTap,
    );
  }


  Widget _buildOnGoingOrderActions(DeliverPartnerOrdersController controller) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Who the rider is going to meet, and how they get there. The rider
        // needs the name and a way to call before setting off, and the ongoing
        // card showed neither.
        if (!_isPickedUp) ...[
          // Heading to the pickup — direction + trip length side by side,
          // customer underneath. Shown for EVERY order type: a grocery / food /
          // medical delivery starts with the same drive to a pickup, and those
          // cards previously carried no customer row and no map action at all
          // (both were gated on ride/parcel).
          if (_hasPickupCoordinates)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildActionStatsRow(),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCustomerInfoRow(labelledCall: true),
          ),
        ] else ...[
          // Job running: drop direction + trip stats, then the customer with an
          // emergency call. No in-app ride map — navigation is the phone's
          // Google Maps, and everything the rider needs is on this card.
          if (_hasDropCoordinates)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildActionStatsRow(),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCustomerInfoRow(
              labelledCall: true,
              emergency: true,
            ),
          ),
        ],

        if(!_showsRideCompletion &&
            !(widget.order.orderFor==AppConstants.InCity
            ||widget.order.orderFor==AppConstants.OutStation
            ||widget.order.orderFor==AppConstants.HourlyRental
            ||widget.order.orderFor==AppConstants.Parcel))
        CustomText(
          AppStrings.deliveryOTP,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
        ),
        SizedBox(height:SizeConfig.size8),

        // A running ride ends HERE now. The slide-to-complete used to live on
        // PassengerDestinationScreen, reached through an in-app map that no
        // longer opens — so the control moved to the card, beside the fare it
        // settles. Everything that screen showed alongside it (passenger,
        // distance, elapsed time) is already above.
        //
        // Its own row, because the slider is taller than a line of text and the
        // fare beside it has to match — a fixed height plus `stretch` pulls the
        // fare box up to the slider. NOT IntrinsicHeight: the slider measures
        // its track with a LayoutBuilder, which cannot report an intrinsic
        // height, and the pair threw "RenderBox was not laid out" on every
        // in-progress card. The OTP row below keeps centre alignment, where
        // both children are a single line.
        if (_showsRideCompletion)
          SizedBox(
            height: SizeConfig.size48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildSlideToComplete()),
                SizedBox(width: SizeConfig.size8),
                _buildFareWidget(fillHeight: true),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: _buildOtpInputSection(controller),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildFareWidget(),
              ),
            ],
          ),

        // Support, at the foot of the working card — the rider is mid-job and
        // whatever has gone wrong (customer not at pickup, address wrong, order
        // stuck) is happening now.
        SizedBox(height: SizeConfig.size12),
        _buildCustomerCareRow(),
      ],
    );
  }

  /// "Call To Customer Care" — a quiet footer link under a hairline, not
  /// another bordered card. It's the least-used control here and shouldn't
  /// compete with the customer row or the completion slider above it.
  Widget _buildCustomerCareRow() {
    return Column(
      children: [
        _buildDivider(),
        InkWell(
          onTap: _handleCallCustomerCare,
          child: Padding(
            // Asymmetric: the card already contributes its own bottom padding
            // below this, so an even 12/12 here left the footer floating well
            // clear of the card edge.
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

  /// Dials support when a number is configured; otherwise opens the app's
  /// Help & Support screen, which is where support actually lives today.
  /// See [AppStrings.customerCareNumber].
  void _handleCallCustomerCare() {
    final number = AppStrings.customerCareNumber.trim();
    if (number.isEmpty) {
      Get.to(() => const HelpAndSupportScreen());
      return;
    }
    openDialer(number);
  }

  // NOTE: `_buildTravelSummary` / `_buildTravelStat` lived here — the
  // time+distance readout an in-progress ride showed where the slide-to-complete
  // now sits. Both numbers moved into the action row's stat tiles
  // ([_buildStatBox]), so the block itself is gone.

  Widget _buildOtpInputSection(DeliverPartnerOrdersController controller) {
    return Obx(() {
      final orderId = widget.order.id ?? '';
      final isVerifying = controller.verifyingOtpMap[orderId] ?? false;
      final isVerified = controller.otpVerifiedMap[orderId] ?? false;

      return Row(
        children: [
          _buildOtpInput(isVerified, orderId, controller),
          Padding(
            padding: EdgeInsets.only(left: SizeConfig.size8),
            child: _buildOtpStatusIndicator(isVerifying, isVerified),
          ),
        ],
      );
    });
  }

  Widget _buildOtpInput(
      bool isVerified,
      String orderId,
      DeliverPartnerOrdersController controller,
      ) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: AbsorbPointer(
        absorbing: isVerified,
        child: Opacity(
          opacity: isVerified ? 0.6 : 1.0,
          child: Pinput(
            length: 4,
            enabled: !isVerified,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onCompleted: (pin) => _handleOtpSubmit(pin, orderId, controller),
            // Bigger, softer boxes: 48², radius 12, a near-white fill and a
            // hairline border. They were 40², radius 6, white with a drop
            // shadow, which read as four raised buttons rather than fields.
            defaultPinTheme: PinTheme(
              width: 48,
              height: 48,
              textStyle: TextStyle(
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.whiteFE,
                border: Border.all(color: AppColors.greyE5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpStatusIndicator(bool isVerifying, bool isVerified) {
    if (isVerifying) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Icon(
      isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
      color: isVerified ? Colors.green : Colors.grey,
      size: 22,
    );
  }

  // ============================================
  Widget _buildBadge({
    required String text,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: CustomText(
        text,
        fontSize: SizeConfig.small11,
        fontWeight: FontWeight.w600,
        color: AppColors.mainTextColor,
      ),
    );
  }

  /// [fillHeight] centres the label so the box reads correctly when a parent
  /// stretches it to a taller neighbour (the in-progress travel row). Left off
  /// elsewhere, where the box hugs its text — setting an alignment there would
  /// make it expand to the row's full height.
  Widget _buildFareWidget({bool fillHeight = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        // Tighter when stacked: two lines plus 12/12 didn't fit the row's fixed
        // height, so the FittedBox below had to shrink the amount to cope.
        vertical: fillHeight ? SizeConfig.size4 : SizeConfig.size12,
      ),
      alignment: fillHeight ? Alignment.center : null,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.20)),
      ),
      // The money the rider is working for — printed in the accent colour on
      // its tinted chip instead of the same grey as every secondary label.
      //
      // Stacked when it stands beside the completion slider: the label sits on
      // its own line so the AMOUNT gets the width and the size, which is the
      // half of it the rider is actually reading. On the wide rows it stays a
      // single line, where a stack would just be a tall gap.
      child: fillHeight
          // Scaled down rather than clipped: two lines of text in a
          // fixed-height row overflow the moment the device's font scale goes
          // up, and a fare is the one number that must stay readable.
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label in the body colour, amount in the accent — the word
                  // is just a caption, the number is the point.
                  CustomText(
                    AppStrings.fare.tr,
                    fontSize: SizeConfig.small11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                  ),
                  CustomText(
                    '₹ ${widget.order.fare}',
                    fontSize: SizeConfig.medium15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                    maxLines: 1,
                  ),
                ],
              ),
            )
          : CustomText(
              '${AppStrings.fare.tr} ₹ ${widget.order.fare}',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String text,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(100.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(icon, color: textColor),
              ),
            CustomText(
              text,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: SizeConfig.size1,
      width: double.infinity,
      color: AppColors.whiteE5,
    );
  }

  Widget _buildLocationText({
    required double latitude,
    required double longitude,
  }) {
    return LocationTextWidget(
      latitude: double.parse("$latitude"),
      longitude: double.parse("$longitude"),
      fontSize: 13,
      color: Colors.grey,
    );
  }

  // ============================================
  bool _shouldShowActions() {
    return widget.selectedPickUp == PickUpTab.newOrder ||
        widget.selectedPickUp == PickUpTab.onGoing ||
        widget.selectedPickUp == PickUpTab.orders;
  }


  // ============================================
  // NOTE: `_handleCancelOrder` lived here — the ongoing card's status pill used
  // to cancel the order on tap, with no confirmation. The pill is now an inert
  // stage label (see [_buildStageBadge]), so nothing on this card cancels any
  // more. Restoring it is a controller call away:
  //   controller.cancelOrderFromPialot(
  //       {ApiKeys.status: AppConstants.cancelled}, widget.order.id ?? "");

  void _handleRejectOrder(DeliverPartnerOrdersController controller) {
    controller.updateOrderStatusFromPialot(
      {ApiKeys.action: AppConstants.reject},
      widget.order.id ?? "",
    );
  }

  void _handleAcceptOrder(DeliverPartnerOrdersController controller) {
    controller.updateOrderStatusFromPialot(
      {ApiKeys.action:AppConstants.accept},
      widget.order.id ?? "",
    );
  }

  Future<void> _handleCallAction(String? contactNo) async {
    // For ride/parcel ongoing orders, use in-app calling via WebRTC
    if (widget.selectedPickUp == PickUpTab.onGoing &&
        (widget.order.orderFor == AppConstants.InCity ||
            widget.order.orderFor == AppConstants.OutStation ||
            widget.order.orderFor == AppConstants.HourlyRental ||
            widget.order.orderFor == AppConstants.Parcel)) {
      final userId = widget.order.user?.id;
      if (userId != null && userId.isNotEmpty) {
        if (!Get.isRegistered<CallController>()) {
          Get.put(CallController());
        }
        final callController = Get.find<CallController>();
        final success = await callController.initiateCall(
          type: CallType.audio,
          otherUserId: userId,
          userName: widget.order.user?.name ?? '',
          userImage: widget.order.user?.profileImage ?? '',
        );
        // Navigation handled by [CallController.initiateCall] (t=0 push).
        if (success) {}
        return;
      }
    }
    // Fallback to phone dialer for delivery orders (grocery, food, medical)
    if (contactNo?.isNotEmpty ?? false) {
      openDialer(contactNo ?? '');
    } else {
      commonSnackBar(message: AppStrings.contactNumberNotFound.tr);
    }
  }

  /// Tapping the pickup row → Google Maps directions, current position → pickup.
  void _handleOpenPickupLocation() {
    _openDirections(
      destinationLat: _pickupLat,
      destinationLng: _pickupLng,
    );
  }

  /// Tapping the drop row → Google Maps directions, current position → drop.
  void _handleOpenDropLocation() {
    _openDirections(
      destinationLat: _dropLat,
      destinationLng: _dropLng,
    );
  }

  /// Tapping the travel-distance box → Google Maps directions for the JOB'S
  /// leg: pickup → drop, not from wherever the rider happens to be standing.
  void _handleOpenPickupToDropRoute() {
    _openDirections(
      originLat: _pickupLat,
      originLng: _pickupLng,
      destinationLat: _dropLat,
      destinationLng: _dropLng,
    );
  }

  /// Hands off to the Google Maps app's directions view, which draws the route.
  /// A missing/zero coordinate says so instead of opening a map of the ocean at
  /// (0, 0).
  void _openDirections({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
  }) {
    final destinationMissing = destinationLat == 0.0 && destinationLng == 0.0;
    final originMissing =
        originLat != null && originLng != null && originLat == 0.0 && originLng == 0.0;
    if (destinationMissing || originMissing) {
      commonSnackBar(message: AppStrings.locationNotAvailable);
      return;
    }

    openGoogleMapsDirections(
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      originLat: originLat,
      originLng: originLng,
    );
  }

  double get _pickupLat =>
      widget.order.pickupLocation?.location?.coordinates?[1].toDouble() ?? 0.0;

  double get _pickupLng =>
      widget.order.pickupLocation?.location?.coordinates?[0].toDouble() ?? 0.0;

  double get _dropLat =>
      widget.order.dropLocation?.location?.coordinates?[1].toDouble() ?? 0.0;

  double get _dropLng =>
      widget.order.dropLocation?.location?.coordinates?[0].toDouble() ?? 0.0;

  Future<void> _handleOtpSubmit(
      String pin,
      String orderId,
      DeliverPartnerOrdersController controller,
      ) async {
    if (pin.length == 4) {
      log('is correct--> ${pin}');
      if(widget.order.orderFor==AppConstants.InCity
          ||widget.order.orderFor==AppConstants.OutStation
          ||widget.order.orderFor==AppConstants.HourlyRental
          ||widget.order.orderFor==AppConstants.Parcel){
        // Nothing to navigate to on success. The card itself flips to the
        // ride-started layout (drop direction, trip stats, emergency call,
        // slide-to-complete) as soon as the refreshed order arrives; this used
        // to push the in-app destination screen.
        await controller.verifyPickupOtpRideOrParcelApi(
          {ApiKeys.pickupOTP: pin},
          widget.order.id ?? "",
        );
      }else {
        controller.verifyDeliveredOtp(orderId, pin);
      }
    }
  }

  // ============================================
  String _formatTime(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return DateFormat('hh:mm a').format(dateTime);
  }
}

/// What the customer does, for the ongoing ride card's customer row.
///
/// One type for both account kinds because the row renders them identically —
/// only the icon differs — and the card should not have to know which lookup
/// produced the text.
class _CustomerIdentity {
  /// `Plumber`, or `Restaurant · Bakery` for a business with a sub-category.
  final String label;
  final bool isBusiness;

  const _CustomerIdentity({required this.label, required this.isBusiness});

  /// Builds an identity from values that are routinely null or blank, returning
  /// null when there is nothing worth showing. [secondary] narrows [primary]
  /// (sub-category under category) and is dropped when it merely repeats it.
  ///
  /// [isBusiness] is passed explicitly rather than inferred from [secondary]
  /// being present: a business that never set a sub-category still has to read
  /// as a business.
  static _CustomerIdentity? of(
    String? primary, {
    String? secondary,
    bool isBusiness = false,
  }) {
    final head = primary?.trim() ?? '';
    final tail = secondary?.trim() ?? '';
    if (head.isEmpty) {
      return tail.isEmpty
          ? null
          : _CustomerIdentity(label: tail, isBusiness: isBusiness);
    }
    final sameThing = tail.isEmpty || tail.toLowerCase() == head.toLowerCase();
    return _CustomerIdentity(
      label: sameThing ? head : '$head · $tail',
      isBusiness: isBusiness,
    );
  }
}

/// Breathes a soft halo around its child to pull the eye to it.
///
/// Used on the direction CTA: on a live job that button is the one thing the
/// rider is meant to reach for next, but it sits in a row of tiles the same
/// size and weight, so nothing marks it as the action.
///
/// A GLOW rather than a flashing colour or a jumping scale — it has to survive
/// being on screen for the length of a ride without becoming something the
/// rider wants to get away from. It is also skipped entirely when the device
/// asks for reduced motion, where a pulsing control is exactly what that
/// setting exists to prevent.
// NOTE: `_PulsingHighlight`, the direction button and the stat tile lived here.
// They moved to rider_map_actions.dart when the multi-shop card needed the same
// Google-Maps hand-off, so the two cards share one implementation instead of
// two that drift.

/// Self-contained slide-to-complete control.
///
/// Kept in its own [StatefulWidget] so dragging only rebuilds THIS widget (not
/// the whole heavy order card) — that's what makes the slide feel smooth. It
/// also shows an inline "Completing…" loader while [onComplete] runs, so no
/// global progress dialog is needed.
class SlideToCompleteButton extends StatefulWidget {
  /// The completion action. Awaited so the inline loader shows for its whole
  /// duration.
  final Future<void> Function() onComplete;
  final double height;
  final String text;

  const SlideToCompleteButton({
    super.key,
    required this.onComplete,
    this.height = 46,
    this.text = 'Slide to complete',
  });

  @override
  State<SlideToCompleteButton> createState() => _SlideToCompleteButtonState();
}

class _SlideToCompleteButtonState extends State<SlideToCompleteButton> {
  double _dragX = 0;
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        final buttonWidth = height;
        final maxDrag = (sliderWidth - buttonWidth).clamp(0.0, double.infinity);

        // While the API runs, replace the track with an inline loader.
        if (_completing) {
          return Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.green1A,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Completing…',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.whiteF3,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Indented past the knob so the label is centred in the track the
              // rider can actually see, rather than half-hidden behind the knob
              // at rest.
              Padding(
                padding: EdgeInsets.only(left: buttonWidth),
                child: Center(
                  child: Text(
                    widget.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                      fontSize: SizeConfig.small,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _dragX,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Start tracking on touch-down (not after the scroll slop) so
                  // the knob follows the finger immediately and doesn't lose the
                  // gesture to the surrounding scroll view.
                  dragStartBehavior: DragStartBehavior.down,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragX =
                          (_dragX + details.delta.dx).clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (_) => _onDragEnd(maxDrag),
                  child: Container(
                    height: height,
                    width: buttonWidth,
                    decoration: const BoxDecoration(
                      color: AppColors.green1A,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onDragEnd(double maxDrag) async {
    // Completed if dragged past 70% of the track.
    if (_dragX > maxDrag * 0.7) {
      setState(() {
        _dragX = maxDrag;
        _completing = true;
      });
      try {
        await widget.onComplete();
      } finally {
        if (mounted) {
          setState(() {
            _completing = false;
            _dragX = 0;
          });
        }
      }
    } else {
      // Snap back.
      setState(() => _dragX = 0);
    }
  }
}

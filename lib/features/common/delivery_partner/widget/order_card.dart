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
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
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
import '../../../chat/view/call_screen/rider_call/rider_pickup_navigation_screen.dart';
import '../../../chat/view/call_screen/rider_call/passenger_destination_screen.dart';
import 'customer_rating_badge.dart';
import 'delivery_pickup_shops_list.dart';

class OrderCard extends StatefulWidget {
  final PickUpTab selectedPickUp;
  final RiderOrdersDetailsModel order;
  final bool? isPipModeOn;

  const OrderCard({
    super.key,
    required this.selectedPickUp,
    required this.order,
    this.isPipModeOn = false,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  /// Drives the live travel-time readout on an in-progress ride. Only ever
  /// running for that one case, so idle cards in the list cost nothing.
  Timer? _travelTimer;

  /// Who the customer is beyond their name — profession for an individual,
  /// category/sub-category for a business. Null until resolved, and stays null
  /// when the lookup fails: the card degrades to name + number rather than
  /// showing a gap where a line was promised.
  _CustomerIdentity? _identity;

  @override
  void initState() {
    super.initState();
    _syncTravelTimer();
    _loadCustomerIdentity();
  }

  @override
  void didUpdateWidget(covariant OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A status change (accepted → in-progress → completed) arrives as a new
    // order object on the same card, so re-evaluate rather than leaving a timer
    // ticking on a finished ride.
    _syncTravelTimer();
    if (oldWidget.order.user?.id != widget.order.user?.id) {
      _identity = null;
      _loadCustomerIdentity();
    }
  }

  @override
  void dispose() {
    _travelTimer?.cancel();
    super.dispose();
  }

  void _syncTravelTimer() {
    final needed = _isRideInProgress && _rideStartedAt != null;
    if (needed && _travelTimer == null) {
      _travelTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!needed) {
      _travelTimer?.cancel();
      _travelTimer = null;
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

  /// True for the ride-type orders whose pickup leg is done — the case that
  /// used to carry the slide-to-complete.
  bool get _isRideInProgress =>
      _isRideOrParcelOrder && widget.order.status == 'in-progress';

  /// When the ride actually started, read out of the order's `timestamps` map.
  ///
  /// That map is untyped and its key names aren't documented anywhere in the
  /// app, so this tries the plausible spellings. If none match, the travel-time
  /// readout is hidden (never guessed from `createdAt`/`updatedAt`, which track
  /// the order, not the journey) and the available keys are logged once so the
  /// right one can be pinned down.
  DateTime? get _rideStartedAt {
    final stamps = widget.order.timestamps;
    if (stamps == null || stamps.isEmpty) return null;

    const candidates = [
      'pickedUpAt',
      'picked_up_at',
      'inProgressAt',
      'in_progress_at',
      'rideStartedAt',
      'ride_started_at',
      'tripStartedAt',
      'startedAt',
      'started_at',
      'pickupCompletedAt',
      'pickupVerifiedAt',
      'otpVerifiedAt',
    ];

    for (final key in candidates) {
      for (final entry in stamps.entries) {
        if (entry.key.toString().toLowerCase() != key.toLowerCase()) continue;
        final parsed = DateTime.tryParse(entry.value?.toString() ?? '');
        if (parsed != null) return parsed.toLocal();
      }
    }

    log('⏱ order.timestamps has no known ride-start key. Available: '
        '${stamps.keys.toList()}');
    return null;
  }

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
            if(widget.isPipModeOn==false)
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
        return _buildOnGoingOrderHeader(controller);
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

  Widget _buildOnGoingOrderHeader(DeliverPartnerOrdersController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(child: _buildOrderIdAndPickupOtp()),
        SizedBox(width: SizeConfig.size6),
        _buildTimeAndCancelButton(controller),
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

  Widget _buildTimeAndCancelButton(DeliverPartnerOrdersController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildTimeText(),
        SizedBox(height: SizeConfig.size8),
        InkWell(
          onTap: () => _handleCancelOrder(controller),
          borderRadius: BorderRadius.circular(100.0),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10,
              vertical: SizeConfig.size4,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryColor),
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(100.0),
            ),
            child: CustomText(
              widget.order.status,
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  Widget _buildLocationSection(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.whiteE5),
            color: AppColors.whiteFE,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [AppShadows.textFieldShadow],
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
              else if ((widget.selectedPickUp == PickUpTab.onGoing)?widget.isPipModeOn==false:true)
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
              if (isFareCall) {
                controller.rideAction(AppConstants.reject, widget.order.id ?? "");
              } else {
                controller.updateRideOrParcelOrderStatusApi(
                  {ApiKeys.action:AppConstants.reject},
                  widget.order.id ?? "",
                );
              }
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
              if (isFareCall) {
                controller.rideAction(AppConstants.accept, widget.order.id ?? "");
              } else {
                controller.updateRideOrParcelOrderStatusApi(
                  {ApiKeys.action:AppConstants.accept},
                  widget.order.id ?? "",
                );
              }
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

  /// Navigate to the appropriate ride map screen based on OTP status
  void _navigateToRideMap() {
    final order = widget.order;
    final pickupLat = order.pickupLocation?.location?.coordinates != null &&
            order.pickupLocation!.location!.coordinates!.length >= 2
        ? order.pickupLocation!.location!.coordinates![1].toDouble()
        : 0.0;
    final pickupLng = order.pickupLocation?.location?.coordinates != null &&
            order.pickupLocation!.location!.coordinates!.length >= 2
        ? order.pickupLocation!.location!.coordinates![0].toDouble()
        : 0.0;
    final dropLat = order.dropLocation?.location?.coordinates != null &&
            order.dropLocation!.location!.coordinates!.length >= 2
        ? order.dropLocation!.location!.coordinates![1].toDouble()
        : 0.0;
    final dropLng = order.dropLocation?.location?.coordinates != null &&
            order.dropLocation!.location!.coordinates!.length >= 2
        ? order.dropLocation!.location!.coordinates![0].toDouble()
        : 0.0;

    final customerName = order.user?.name ?? 'Customer';
    final customerImage = order.user?.profileImage ?? '';
    final fare = order.fare?.toDouble() ?? 0.0;
    final distance = double.tryParse(order.distancePickupToDrop ?? '') ?? 0.0;
    final paymentMethod = order.modeOfPayment ?? 'Cash';
    final pickupAddress = order.pickupLocation?.address ?? 'Pickup location';
    final dropAddress = order.dropLocation?.address ?? 'Drop location';
    // Past-pickup = OTP already verified. After the pickup OTP the ride order
    // becomes 'in-progress' (parcel/goods may report 'picked-up'); both, plus
    // 'completed', mean the pickup leg is done → go to the destination screen.
    final isPickedUp = _isPickedUp;

    if (isPickedUp) {
      // OTP verified / past pickup — open the rider destination screen (live
      // map + fare + slide-to-complete).
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PassengerDestinationScreen(
            pickupLocation: pickupAddress,
            dropLocation: dropAddress,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            dropLat: dropLat,
            dropLng: dropLng,
            fareAmount: fare,
            distanceKm: distance,
            customerName: customerName,
            customerImage: customerImage,
            paymentMethod: paymentMethod,
            orderId: order.id ?? '',
            customerUserId: order.user?.id ?? '',
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RiderPickupNavigationScreen(
            pickupLocation: pickupAddress,
            dropLocation: dropAddress,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            dropLat: dropLat,
            dropLng: dropLng,
            fareAmount: fare,
            distanceKm: distance,
            customerName: customerName,
            customerImage: customerImage,
            // Passenger rides: rider must not hold the OTP — pass empty so
            // verification always goes through the server (the customer holds
            // it). Goods/parcel keep passing it (rider reads it to the shop).
            otp: (order.jobInfo?.isRide ?? false) ? '' : (order.pickupOTP ?? ''),
            // REQUIRED so the pickup screen can call verifyPickupOtpRideOrParcelApi.
            // For a ride the rider doesn't hold the OTP (otp is empty), so
            // without this the screen has no order reference and can't verify.
            orderId: order.id ?? '',
            paymentMethod: paymentMethod,
            customerUserId: order.user?.id ?? '',
          ),
        ),
      );
    }
  }

  /// Customer identity block for the ongoing ride card: photo, name, what they
  /// do, and a call button.
  ///
  /// "What they do" is a profession for an individual and a category (narrowed
  /// by sub-category) for a business. Neither travels on the order payload, so
  /// both come from [_loadCustomerIdentity] and the line simply doesn't render
  /// until it resolves — it replaces the phone number, which was only ever a
  /// stand-in for it and is still one tap away on the call button.
  Widget _buildCustomerInfoRow() {
    final user = widget.order.user;
    final name = (user?.name ?? '').trim();
    final contact = (user?.contactNo ?? '').trim();
    if (name.isEmpty && contact.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.04),
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
          if (contact.isNotEmpty) _buildCallButton(contact),
        ],
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

  Widget _buildViewRideOnMapButton() {
    // 'in-progress' (ride) / 'picked-up' (parcel) / 'completed' all mean the
    // pickup OTP is done, so the CTA reads "View Ride on Map".
    final isPickedUp = _isPickedUp;
    return GestureDetector(
      onTap: _navigateToRideMap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isPickedUp
              ? const Color(0xFF4285F4).withValues(alpha: 0.08)
              : const Color(0xFF00C853).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPickedUp
                ? const Color(0xFF4285F4).withValues(alpha: 0.2)
                : const Color(0xFF00C853).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_rounded,
              size: 18,
              color: isPickedUp ? const Color(0xFF4285F4) : const Color(0xFF00C853),
            ),
            const SizedBox(width: 8),
            Text(
              isPickedUp ? 'View Ride on Map' : 'Navigate to Pickup',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'OpenSans',
                color: isPickedUp ? const Color(0xFF4285F4) : const Color(0xFF00C853),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isPickedUp ? const Color(0xFF4285F4) : const Color(0xFF00C853),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnGoingOrderActions(DeliverPartnerOrdersController controller) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Who the rider is going to meet, directly above the navigate CTA —
        // the rider needs the name and a way to call before setting off, and
        // the ongoing card showed neither.
        if (widget.order.orderFor == AppConstants.InCity ||
            widget.order.orderFor == AppConstants.OutStation ||
            widget.order.orderFor == AppConstants.HourlyRental ||
            widget.order.orderFor == AppConstants.Parcel) ...[
          if (widget.isPipModeOn == false)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCustomerInfoRow(),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildViewRideOnMapButton(),
          ),
        ],

        if(!(widget.order.orderFor==AppConstants.InCity
            ||widget.order.orderFor==AppConstants.OutStation
            ||widget.order.orderFor==AppConstants.HourlyRental
            ||widget.order.orderFor==AppConstants.Parcel))
        CustomText(
          AppStrings.deliveryOTP,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
        ),
        if(widget.isPipModeOn==false)
        SizedBox(height:SizeConfig.size8),

        // In-progress rides used to carry a slide-to-complete here. It was a
        // second way to finish the ride — PassengerDestinationScreen (one tap
        // away via "View Ride on Map") owns that action — so the space now
        // reports the journey instead.
        //
        // Its own row, because the travel box is two lines tall and the fare
        // beside it has to match: IntrinsicHeight measures the tallest child
        // and `stretch` pulls the fare box up to it. The OTP row below keeps
        // centre alignment, where both children are a single line.
        if (_isRideInProgress)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildTravelSummary()),
                if (widget.isPipModeOn == false) ...[
                  SizedBox(width: SizeConfig.size8),
                  _buildFareWidget(fillHeight: true),
                ],
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
              if(widget.isPipModeOn==false)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: _buildFareWidget(),
              ),
            ],
          ),
      ],
    );
  }

  /// Journey readout shown in place of the retired slide-to-complete: how long
  /// the rider has been travelling, and how far the trip is.
  ///
  /// The time half is omitted when the ride's start time isn't known (see
  /// [_rideStartedAt]) rather than showing a zero that would tick up from the
  /// moment the card was built.
  Widget _buildTravelSummary() {
    final startedAt = _rideStartedAt;
    final distance = widget.order.distancePickupToDrop;
    final hasDistance = distance != null &&
        distance.isNotEmpty &&
        distance != 'N/A' &&
        distance != 'null';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (startedAt != null)
            Expanded(
              child: _buildTravelStat(
                icon: Icons.timer_outlined,
                value: _formatElapsed(DateTime.now().difference(startedAt)),
                label: AppStrings.travelTime,
              ),
            ),
          if (startedAt != null && hasDistance)
            Container(
              width: 1,
              height: SizeConfig.size24,
              color: AppColors.primaryColor.withValues(alpha: 0.18),
            ),
          if (hasDistance)
            Expanded(
              child: _buildTravelStat(
                icon: Icons.straighten_rounded,
                value: distance,
                label: AppStrings.travelDistance,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTravelStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: SizeConfig.size14, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            Flexible(
              child: CustomText(
                value,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size2),
        CustomText(
          label,
          fontSize: SizeConfig.extraSmall,
          color: AppColors.secondaryTextColor,
          maxLines: 1,
        ),
      ],
    );
  }

  /// `H:MM:SS` once past an hour, `MM:SS` before that — a ride rarely runs long
  /// enough for the hour slot to be worth reserving up front.
  String _formatElapsed(Duration elapsed) {
    final total = elapsed.isNegative ? Duration.zero : elapsed;
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = total.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

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
            defaultPinTheme: PinTheme(
              width: 40,
              height: 40,
              textStyle: TextStyle(
                fontSize: SizeConfig.medium,
                color: Colors.black,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.white,
                border: Border.all(color: AppColors.greyE5),
                boxShadow: [AppShadows.textFieldShadow],
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
        vertical: SizeConfig.size8,
      ),
      alignment: fillHeight ? Alignment.center : null,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: CustomText(
        '${AppStrings.fare.tr} ₹ ${widget.order.fare}',
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
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
  void _handleCancelOrder(DeliverPartnerOrdersController controller) {
    controller.cancelOrderFromPialot(
      {ApiKeys.status: AppConstants.cancelled},
      widget.order.id ?? "",
    );
  }

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
        if (success) {
          Get.toNamed('/CallRoomScreen');
        }
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

  void _handleOpenPickupLocation() {
    openGoogleMaps(
      latitude: widget.order.pickupLocation?.location?.coordinates?[1].toDouble() ?? 0.0,
      longitude: widget.order.pickupLocation?.location?.coordinates?[0].toDouble() ?? 0.0,
    );
  }

  void _handleOpenDropLocation() {
    openGoogleMaps(
      latitude: widget.order.dropLocation?.location?.coordinates?[1].toDouble() ?? 0.0,
      longitude: widget.order.dropLocation?.location?.coordinates?[0].toDouble() ?? 0.0,
    );
  }

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
        final verified = await controller.verifyPickupOtpRideOrParcelApi(
          {ApiKeys.pickupOTP: pin},
          widget.order.id ?? "",
        );
        // Navigate to ride navigation screen after successful pickup OTP
        if (verified && mounted) {
          _navigateToRideMap();
        }
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
              color: Colors.green,
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
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
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
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18,
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

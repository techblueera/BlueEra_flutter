import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
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
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
import '../../../chat/view/call_screen/rider_call/rider_ride_navigation_screen.dart';
import 'delivery_pickup_shops_list.dart';

class OrderCard extends StatefulWidget {
  final PickUpTab selectedPickUp;
  final RiderOrdersDetailsModel order;
  final bool? isPipModeOn;

  const OrderCard({
    super.key,
    required this.selectedPickUp,
    required this.order, this.isPipModeOn=false,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  double dragX = 0;

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
    return CustomText(
      widget.order.user?.name,
      fontSize: SizeConfig.large,
      fontWeight: FontWeight.w600,
      color: AppColors.mainTextColor,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
                    if (widget.selectedPickUp == PickUpTab.onGoing)
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
      ),
    );
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

              if ((widget.selectedPickUp == PickUpTab.onGoing)?widget.isPipModeOn==false:true)
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
          CustomText(
            ' ${(widget.order.distancePickupToDrop=="N/A"||widget.order.distancePickupToDrop==''||widget.order.distancePickupToDrop=="null")?"":widget.order.distancePickupToDrop}',
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor,
          ),
          SizedBox(width: SizeConfig.size2),
          if((widget.order.distancePickupToDrop=="N/A"||widget.order.distancePickupToDrop==''||widget.order.distancePickupToDrop=="null"))
            SizedBox()
          else
            Icon(
            Icons.location_on_outlined,
            size: SizeConfig.size12,
            color: AppColors.primaryColor,
          ),
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
    final pickupAddress = order.dropLocation?.address ?? 'Pickup location';
    final dropAddress = order.dropLocation?.address ?? 'Drop location';
    final isPickedUp = order.status == 'picked-up' || order.status == 'completed';

    if (isPickedUp) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RiderRideNavigationScreen(
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
            otp: order.pickupOTP ?? '',
            paymentMethod: paymentMethod,
            customerUserId: order.user?.id ?? '',
          ),
        ),
      );
    }
  }

  Widget _buildViewRideOnMapButton() {
    final isPickedUp = widget.order.status == 'picked-up' || widget.order.status == 'completed';
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
        // "View Ride on Map" button for ride orders
        if (widget.order.orderFor == AppConstants.InCity ||
            widget.order.orderFor == AppConstants.OutStation ||
            widget.order.orderFor == AppConstants.HourlyRental ||
            widget.order.orderFor == AppConstants.Parcel)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildViewRideOnMapButton(),
          ),

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

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if((widget.order.orderFor==AppConstants.InCity
                ||widget.order.orderFor==AppConstants.OutStation
                ||widget.order.orderFor==AppConstants.HourlyRental
                ||widget.order.orderFor==AppConstants.Parcel)&& widget.order.status=='in-progress')
              Expanded(
                child: slideToComplete(
                  dragX: dragX,
                  onDragUpdate: (val) => setState(() => dragX = val),
                  onComplete: () async{
                    await controller.completePickupRiderApi(widget.order.id??'');
                  },
                ),
              )

            // CustomBtn(
              //   width: 160,
              //     height: 40,
              //     isValidate: true,
              //     onTap: ()async{
              //    await controller.completePickupRiderApi(order.id??'');
              // }, title: "Complete")
            else
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

  Widget slideToComplete({
    required double dragX,
    required Function(double) onDragUpdate,
    required VoidCallback onComplete,
    double height = 44,
    String text = "Slide to complete",
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        final buttonWidth = height;

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
                  text,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                left: dragX,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    double newDrag =
                    (dragX + details.delta.dx).clamp(0, sliderWidth - buttonWidth);
                    onDragUpdate(newDrag);
                  },
                  onHorizontalDragEnd: (_) {
                    if (dragX > (sliderWidth - buttonWidth) * 0.7) {
                      onComplete();
                    }
                    onDragUpdate(0);
                  },
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

  Widget _buildFareWidget() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size8,
      ),
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
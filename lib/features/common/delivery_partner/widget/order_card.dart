import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
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
import '../../../chat/auth/model/rider_orders_details_model.dart';
import '../../../chat/view/orders_chat/widget/lat_lng_to_location_text.dart';
import '../controller/delivery_partner_orders_controller.dart';

class OrderCard extends StatelessWidget {
  final PickUpTab selectedPickUp;
  final RiderOrdersDetailsModel order;

  const OrderCard({
    super.key,
    required this.selectedPickUp,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DeliverPartnerOrdersController>()
        ? Get.find<DeliverPartnerOrdersController>()
        : Get.put(DeliverPartnerOrdersController());

    return CustomFormCard(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        children: [
          _buildHeaderSection(context, controller),
          SizedBox(height: SizeConfig.size14),
          _buildLocationSection(),
          if (_shouldShowActions())
            SizedBox(height: SizeConfig.size14),
          _buildActionSection(controller),
        ],
      ),
    );
  }

  // ============================================
  // HEADER SECTION BUILDERS
  // ============================================

  Widget _buildHeaderSection(BuildContext context, DeliverPartnerOrdersController controller) {
    switch (selectedPickUp) {
      case PickUpTab.newOrder:
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
          imageUrls: [order.user?.profileImage ?? ''],
          initialIndex: 0,
        ),
      ),
      child: CachedAvatarWidget(
        imageUrl: order.user?.profileImage,
        size: SizeConfig.size40,
        borderRadius: SizeConfig.size20,
      ),
    );
  }

  Widget _buildUserName() {
    return CustomText(
      order.user?.name,
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
      _formatTime(order.createdAt ?? ''),
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
          '${AppStrings.orderNo.tr} - ${order.orderNo}',
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
              AppStrings.pickUp,
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
            ),
            CustomText(
              '${order.pickupOTP}',
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
              order.status,
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
  // LOCATION SECTION BUILDERS
  // ============================================

  Widget _buildLocationSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.whiteE5),
        color: AppColors.whiteFE,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPickupLocation(),
          _buildDivider(),
          _buildDropLocation(),
        ],
      ),
    );
  }

  Widget _buildPickupLocation() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPickupLocationInfo()),
              if (selectedPickUp == PickUpTab.onGoing)
                _buildCallButton(order.receiverUser?.contactNo),
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          _buildLocationText(
            latitude: order.pickupLocation?.location?.coordinates?[1].toDouble() ?? 0.0,
            longitude: order.pickupLocation?.location?.coordinates?[0].toDouble() ?? 0.0,
          ),
        ],
      ),
    );
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
            '${order.distanceToPickup}',
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

  Widget _buildDropLocation() {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDropLocationInfo()),
              if (selectedPickUp == PickUpTab.onGoing)
                _buildCallButton(order.user?.contactNo),
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
            '${order.distancePickupToDrop}',
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

  Widget _buildDropLocationDetails() {
    return Wrap(
      children: [
        _buildLocationText(
          latitude: order.dropLocation?.location?.coordinates?[1].toDouble() ?? 0.0,
          longitude: order.dropLocation?.location?.coordinates?[0].toDouble() ?? 0.0,
        ),
        if (_shouldShowContactNumber())
          CustomText(
            '+91 ${order.user?.contactNo}',
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
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
  // ACTION SECTION BUILDERS
  // ============================================

  Widget _buildActionSection(DeliverPartnerOrdersController controller) {
    switch (selectedPickUp) {
      case PickUpTab.newOrder:
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
    return Row(
      children: [
        _buildFareWidget(),
        Spacer(),
        SizedBox(width: SizeConfig.size6),
        _buildActionButton(
          onTap: () => _handleRejectOrder(controller),
          text: AppStrings.reject,
          bgColor: AppColors.redLite.withValues(alpha: 0.1),
          borderColor: AppColors.redLite,
          textColor: AppColors.redLite,
        ),
        SizedBox(width: SizeConfig.size6),
        _buildActionButton(
          onTap: () => _handleAcceptOrder(controller),
          text: AppStrings.accept,
          bgColor: AppColors.green0B.withValues(alpha: 0.1),
          borderColor: AppColors.green0B,
          textColor: AppColors.green0B,
        ),
      ],
    );
  }

  Widget _buildOnGoingOrderActions(DeliverPartnerOrdersController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.deliveryOTP,
          fontSize: SizeConfig.small,
          fontWeight: FontWeight.w400,
          color: AppColors.secondaryTextColor,
        ),
        SizedBox(height: SizeConfig.size8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: _buildOtpInputSection(controller),
            ),
            SizedBox(width: SizeConfig.size6),
            _buildFareWidget(),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpInputSection(DeliverPartnerOrdersController controller) {
    return Obx(() {
      final orderId = order.id ?? '';
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
  // REUSABLE COMPONENT BUILDERS
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
        '${AppStrings.fare.tr} ₹ ${order.fare}',
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
  // HELPER METHODS
  // ============================================

  bool _shouldShowActions() {
    return selectedPickUp == PickUpTab.newOrder ||
        selectedPickUp == PickUpTab.onGoing;
  }

  bool _shouldShowContactNumber() {
    return selectedPickUp == PickUpTab.newOrder ||
        selectedPickUp == PickUpTab.onGoing;
  }

  // ============================================
  // ACTION HANDLERS
  // ============================================

  void _handleCancelOrder(DeliverPartnerOrdersController controller) {
    controller.cancelOrderFromPialot(
      {ApiKeys.status: "cancelled"},
      order.id ?? "",
    );
  }

  void _handleRejectOrder(DeliverPartnerOrdersController controller) {
    controller.updateOrderStatusFromPialot(
      {ApiKeys.action: "reject"},
      order.id ?? "",
    );
  }

  void _handleAcceptOrder(DeliverPartnerOrdersController controller) {
    controller.updateOrderStatusFromPialot(
      {ApiKeys.action: "accept"},
      order.id ?? "",
    );
  }

  void _handleCallAction(String? contactNo) {
    if (contactNo?.isNotEmpty ?? false) {
      openDialer(contactNo ?? '');
    } else {
      commonSnackBar(message: AppStrings.contactNumberNotFound.tr);
    }
  }

  void _handleOpenPickupLocation() {
    openGoogleMaps(
      latitude: order.pickupLocation?.location?.coordinates?[1].toDouble() ?? 0.0,
      longitude: order.pickupLocation?.location?.coordinates?[0].toDouble() ?? 0.0,
    );
  }

  void _handleOpenDropLocation() {
    openGoogleMaps(
      latitude: order.dropLocation?.location?.coordinates?[1].toDouble() ?? 0.0,
      longitude: order.dropLocation?.location?.coordinates?[0].toDouble() ?? 0.0,
    );
  }

  void _handleOtpSubmit(
      String pin,
      String orderId,
      DeliverPartnerOrdersController controller,
      ) {
    if (pin.length == 4) {
      log('is correct--> ${pin == order.deliveryOTP}');
      if (pin == order.deliveryOTP) {
        controller.verifyDeliveredOtp(orderId, pin);
      } else {
        commonSnackBar(message: AppStrings.otpIsNotCorrect.tr);
      }
    }
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  String _formatTime(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return DateFormat('hh:mm a').format(dateTime);
  }
}
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ================== MOCK MODELS ==================

class UserModel {
  final String name;
  final String profileImage;
  final String contactNo;

  UserModel({
    required this.name,
    required this.profileImage,
    required this.contactNo,
  });
}

class OrderModel {
  final String id;
  final String orderNo;
  final String createdAt;
  final String fare;
  final String pickupOTP;
  final String deliveryOTP;
  final String status;
  final UserModel user;

  OrderModel({
    required this.id,
    required this.orderNo,
    required this.createdAt,
    required this.fare,
    required this.pickupOTP,
    required this.deliveryOTP,
    required this.status,
    required this.user,
  });
}

class EarnServiceOrderCard extends StatelessWidget {
  final EarnServiceOrdersStatus selectedOrdersStatus;
  final OrderModel order;

  const EarnServiceOrderCard({
    super.key,
    required this.selectedOrdersStatus,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        children: [
          _buildHeaderSection(context),
          SizedBox(height: SizeConfig.size14),
          _buildLocationSection(),
          SizedBox(height: SizeConfig.size14),
          _buildActionSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    switch (selectedOrdersStatus) {
      case EarnServiceOrdersStatus.newAndOnGoingOrder:
        return _buildNewOrderHeader(context);
      case EarnServiceOrdersStatus.completed:
        return _buildCompletedOrderHeader(context);
      case EarnServiceOrdersStatus.cancelled:
        return _buildStatusOrderHeader(context, 'Cancelled', AppColors.redLite);
    }
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

  Widget _buildUserAvatar(BuildContext context) {
    return InkWell(
      onTap: () => navigatePushTo(
        context,
        ImageViewScreen(
          appBarTitle: '',
          imageUrls: [order.user.profileImage],
          initialIndex: 0,
        ),
      ),
      child: CachedAvatarWidget(
        imageUrl: order.user.profileImage,
        size: SizeConfig.size40,
        borderRadius: SizeConfig.size20,
      ),
    );
  }

  Widget _buildUserName() {
    return CustomText(
      order.user.name,
      fontSize: SizeConfig.large,
      fontWeight: FontWeight.w600,
      color: AppColors.mainTextColor,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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

  Widget _buildChatButton() {
    return InkWell(
      onTap: () {
        // _handleCallAction(contactNo);
      },
      child: Container(
        margin: EdgeInsets.only(left: SizeConfig.size6),
        padding: EdgeInsets.all(SizeConfig.size5),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.secondaryTextColor),
        ),
        child: LocalAssets(
            imagePath: AppIconAssets.chat,
            imgColor: AppColors.secondaryTextColor,
            height: SizeConfig.size14,
            width: SizeConfig.size14
        ),
      ),
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
        color: AppColors.primaryColor,
      ),
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

  Widget _buildTimeText() {
    return CustomText(
      _formatTime(order.createdAt),
      fontSize: SizeConfig.extraSmall,
      fontWeight: FontWeight.w400,
      color: AppColors.grey9A,
    );
  }

  String _formatTime(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return DateFormat('hh:mm a').format(dateTime);
  }

  // Widget _buildOnGoingOrderHeader(DeliverPartnerOrdersController controller) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.start,
  //     children: [
  //       Expanded(child: _buildOrderIdAndPickupOtp()),
  //       SizedBox(width: SizeConfig.size6),
  //       _buildTimeAndCancelButton(controller),
  //     ],
  //   );
  // }




  // ================= LOCATION =================

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomText(
                      'Order Location : ',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                    CustomText(
                      '10KM',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
                SizedBox(width: SizeConfig.size8),
                _buildChatButton()
           ]
          ),
          const SizedBox(height: 6),
          CustomText(
            'Amit Kumar',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
          const SizedBox(height: 2),
          CustomText(
            'Bishnupur, Lucknow Gomtinagar, +91 1234567890',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  // ================= ACTIONS =================

  Widget _buildActionSection() {
    switch (selectedOrdersStatus) {
      case EarnServiceOrdersStatus.newAndOnGoingOrder:
        return _newAndOngoingOrderActions();
      case EarnServiceOrdersStatus.completed:
      case EarnServiceOrdersStatus.cancelled:
        return SizedBox();
    }
  }

  Widget _newAndOngoingOrderActions() {
    return Row(
      children: [
        _TimeSection(),
        const Spacer(),
        if(order.status.toLowerCase() == 'new')
          ...[
            _actionButton('Reject', color: AppColors.redLite),
            const SizedBox(width: 8),
            _actionButton('Accept', color: AppColors.greenShade),
          ]
        else
          _actionButton('On Going', color: AppColors.greenShade),
      ],
    );
  }


  // ================= SMALL UI =================



  // Widget _time() => Text(
  //   DateFormat('hh:mm a').format(DateTime.parse(order.createdAt)),
  //   style: const TextStyle(fontSize: 12, color: Colors.grey),
  // );

  Widget _TimeSection() => Chip(
    label: CustomText(
        'Time - 10:00 am',
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
    ),
    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
  );

  Widget _actionButton(String text,{Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color?.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: color!=null ? Border.all(color: color) : null,
    ),
    child: CustomText(
        text,
        color: color,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w400,
      ),
  );
  //
  // Widget _otpBoxes() => Row(
  //   children: List.generate(
  //     4,
  //         (_) => Container(
  //       margin: const EdgeInsets.only(right: 6),
  //       height: 36,
  //       width: 36,
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(6),
  //         border: Border.all(color: Colors.grey),
  //       ),
  //     ),
  //   ),
  // );

}

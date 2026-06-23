import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/chat/auth/controller/order_controllar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/custom_carousel_slider.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../widget/component_widgets.dart';
import 'track_rider_live_location_page.dart';

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
  final chatViewController = Get.find<ChatViewController>();

  /// Open the live rider-tracking map (mirrors the `rider_map` card's "Track
  /// Order" action). Confirms the ride is still active first; on back the
  /// tracking page minimises into the app-wide floating mini-map.
  Future<void> _openRideTracking(Rider? rider) async {
    final order = widget.message.metadata?.order;
    final orderId = order?.id;
    final double dropLat =
        order?.dropLocation?.location?.coordinates?[1] ?? 26.7836;
    final double dropLng =
        order?.dropLocation?.location?.coordinates?[0] ?? 80.9013;

    final bool active =
        await chatViewController.checkTrackOrderStatusApi("$orderId");
    if (active) {
      Get.to(() => TrackRiderLiveLocationPage(
            riderId: rider?.userId ?? '',
            dropLat: dropLat,
            dropLng: dropLng,
            orderId: orderId,
          ));
    } else {
      commonSnackBar(message: "Ride has been Completed");
    }
  }

  @override
  Widget build(BuildContext context) {
    Rider? rider = widget.message.metadata?.rider;
    final bool isExpired = isMessageOlderThan24Hours(widget.message.createdAt,
        maxAge: const Duration(days: 7));
    final Color actionColor =
        isExpired ? AppColors.grayText : AppColors.primaryColor;

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
            // View Ride → opens the live tracking map; on back it minimises
            // into the app-wide floating mini-map so the ride keeps tracking.
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
                      onPressed: isExpired ? null : () => _openRideTracking(rider),
                      icon: SvgPicture.asset(
                        AppIconAssets.location_new,
                        color: actionColor,
                      ),
                      label: CustomText(
                        AppStrings.viewRide.tr,
                        color: actionColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: Colors.grey,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.white,
              ),
              child: (widget.message.myMessage == false)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: isExpired
                                ? null
                                : () {
                                    openDialer(rider?.contactNo ?? '');
                                  },
                            icon: SvgPicture.asset(
                              AppIconAssets.rider_call_icon,
                              color: actionColor,
                            ),
                            label: CustomText(
                              AppStrings.callNow,
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
                          child: TextButton.icon(
                            onPressed: isExpired
                                ? null
                                : () {
                                    _confirmCancelRide(context);
                                  },
                            icon: Icon(
                              Icons.cancel_outlined,
                              color: isExpired ? AppColors.grayText : AppColors.red,
                              size: 20,
                            ),
                            label: CustomText(
                              AppStrings.cancelRide.tr,
                              color: isExpired ? AppColors.grayText : AppColors.red,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: isExpired
                                ? null
                                : () {
                                    openDialer(rider?.contactNo ?? '');
                                  },
                            icon: SvgPicture.asset(
                              AppIconAssets.rider_call_icon,
                              color: actionColor,
                            ),
                            label: CustomText(
                              AppStrings.callNow,
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
                          child: TextButton.icon(
                            onPressed: isExpired ? null : () {},
                            icon: SvgPicture.asset(
                              AppIconAssets.quillChatIcon,
                              color: actionColor,
                            ),
                            label: CustomText(
                              AppStrings.chatNow,
                              color: actionColor,
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

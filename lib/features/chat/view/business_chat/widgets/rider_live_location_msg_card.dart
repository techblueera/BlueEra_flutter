import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/track_rider_live_location_page.dart';
import 'package:BlueEra/widgets/static_map_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../widget/component_widgets.dart';

class RiderLiveLocationMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const RiderLiveLocationMsgCard({
    Key? key,
    required this.message,
    required this.time,
  }) : super(key: key);

  @override
  State<RiderLiveLocationMsgCard> createState() =>
      _RiderLiveLocationMsgCardState();
}

class _RiderLiveLocationMsgCardState extends State<RiderLiveLocationMsgCard> {
  final chatViewController = Get.find<ChatViewController>();

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
            // A picture, not a live `GoogleMap`. Chat rows are disposed on
            // scroll-out and rebuilt on scroll-in, so the interactive map this
            // replaced bought a Dynamic Maps load on every pass.
            // See docs/GOOGLE_MAPS_COST_GUIDE.md §3.5.
            //
            // NOTE: the coordinate below is HARD-CODED and always has been —
            // it is not the rider's position, it is a fixed point in Lucknow
            // shown to every user in every thread. Preserved verbatim so this
            // change stays a like-for-like swap, but it needs wiring to the
            // real rider location (or the map removing altogether).
            Container(
              decoration: BoxDecoration(
                color: AppColors.blueLightShade,
                borderRadius: BorderRadius.circular(10),
              ),
              height: 160,
              child: const StaticMapPreview(
                latitude: 26.7836,
                longitude: 80.9013,
                width: 400,
                height: 160,
                zoom: 14,
                borderRadius: BorderRadius.all(Radius.circular(10)),
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
                  )
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size14),
            const Divider(
              height: 1,
              color: Colors.grey,
            ),
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
                      onPressed: isExpired
                          ? null
                          : () async {
                              bool value = await chatViewController
                                  .checkTrackOrderStatusApi(
                                      "${widget.message.metadata?.order?.id}");
                              if (value) {
                                Get.to(() => TrackRiderLiveLocationPage(
                                      riderId: rider?.userId ?? '',
                                      // orderId drives the 10s location poll on
                                      // the tracking page (keyed on the order).
                                      orderId:
                                          "${widget.message.metadata?.order?.id}",
                                      dropLat: widget
                                              .message
                                              .metadata
                                              ?.order
                                              ?.dropLocation
                                              ?.location
                                              ?.coordinates?[1] ??
                                          26.7836,
                                      dropLng: widget
                                              .message
                                              .metadata
                                              ?.order
                                              ?.dropLocation
                                              ?.location
                                              ?.coordinates?[0] ??
                                          80.9013,
                                    ));
                              } else {
                                commonSnackBar(
                                    message: "Ride has been Completed");
                              }
                            },
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

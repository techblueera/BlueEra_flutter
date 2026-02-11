import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/track_rider_live_location_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:mappls_gl/mappls_gl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/GetListOfMessageData.dart';

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
  MapplsMapController? mapController;

  Future<void> _onMapCreated(MapplsMapController controller) async {
    mapController = controller;
    await mapController?.addSymbol(
      SymbolOptions(
        geometry: LatLng(26.7836, 80.9013),
        iconSize: 1.2,
        iconImage: "marker-icon",
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Rider? rider = widget.message.metadata?.rider;

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
            Container(
              decoration: BoxDecoration(
                color: AppColors.blueLightShade,
                borderRadius: BorderRadius.circular(10),
              ),
              height: 160,
              child: MapplsMap(
                onMapCreated: (controller) => _onMapCreated(controller),
                initialCameraPosition: CameraPosition(
                  target: LatLng(26.7836, 80.9013),
                  zoom: 14.0,
                ),
                myLocationEnabled: false,
                compassEnabled: false,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
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
                      onPressed: ()async {
                       bool value= await chatViewController.checkTrackOrderStatusApi("${widget.message.metadata?.order?.id}");
                      if(value){
                        Get.to(() => TrackRiderLiveLocationPage(
                          riderId: rider?.userId ?? '',
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
                      }else{
                        commonSnackBar(
                            message: "Ride has been Completed");
                      }

                      },
                      icon: SvgPicture.asset(AppIconAssets.location_new,color: AppColors.primaryColor,),
                      label: CustomText(
                        AppStrings.trackOrder,
                        color: AppColors.primaryColor,
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

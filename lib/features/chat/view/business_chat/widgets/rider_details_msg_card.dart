import 'package:BlueEra/features/chat/auth/controller/order_controllar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/custom_carousel_slider.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../widget/component_widgets.dart';
class RiderDetailsMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const RiderDetailsMsgCard({
    Key? key,
  required this.message, required this.time,
  }) : super(key: key);

  @override
  State<RiderDetailsMsgCard> createState() => _RiderDetailsMsgCardState();
}

class _RiderDetailsMsgCardState extends State<RiderDetailsMsgCard> {

  final orderController = Get.isRegistered<OrderNowController>()
      ? Get.find<OrderNowController>()
      : Get.put(OrderNowController());

  @override
  Widget build(BuildContext context) {
    Rider? rider=widget.message.metadata?.rider;

    return InkWell(
      onTap: () {

      },
      child: Container(
        margin: EdgeInsets.only(right:0,bottom: 2),
        width:SizeConfig.screenWidth*0.68,
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
                imagePaths: [rider?.profilePicture??""],
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
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star,color: AppColors.rating,size: 14,),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(
                            "${rider?.starRating??0}",
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
                            "${rider?.noOfOrder??0} Orders",
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
            SizedBox(height: SizeConfig.size14),
            const Divider(height: 1,color: Colors.grey,),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.white,
              ),
              child: (widget.message.myMessage==false)?
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        launchDialPad(rider?.contactNo??'');
                      },
                      icon: SvgPicture.asset(AppIconAssets.rider_call_icon),
                      label:   CustomText(
                        'Call Now',
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    height: 12,
                    width: 1,
                    color: AppColors.grayText.withOpacity(0.4),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _openBusinessToRiderOTP(context,widget.message);
                      },
                      icon: SvgPicture.asset(AppIconAssets.rider_otp),
                      label:   CustomText(
                        'OTP',
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ):Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        launchDialPad(rider?.contactNo??'');
                      },
                      icon: SvgPicture.asset(AppIconAssets.rider_call_icon),
                      label:   CustomText(
                        'Call Now',
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    height: 12,
                    width: 1,
                    color: AppColors.grayText.withOpacity(0.4),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {

                      },
                      icon: SvgPicture.asset(AppIconAssets.quillChatIcon,color: AppColors.primaryColor,),
                      label:   CustomText(
                        'Chat Now',
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
  void launchDialPad(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch dialer';
    }
  }
  void _openBusinessToRiderOTP(BuildContext context, Messages message){
    showDialog(
         barrierDismissible: true,
        context: context, builder: (context){
      return Dialog(
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(
        minWidth: 280,
        maxWidth: 400,
        minHeight: 200,
      ),
        child: BusinessToRiderOtpVerificationCard(
          onSubmit: (String p1)async {
            Map<String,dynamic> data={
        ApiKeys.pickupOTP: "$p1"
        };
          await orderController.uploadThePickupOtp(data,message.metadata?.orderId??'');
         Get.back();
          },),
      );
    });
  }

}

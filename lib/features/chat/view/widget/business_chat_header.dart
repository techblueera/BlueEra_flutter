import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



class HeaderWidgets extends StatefulWidget {
  final String businessName;
  final String logoUrl;
  final String businessType;
  final String userId;
  final String location;
  final String businessId;

  const HeaderWidgets({
    super.key,
    required this.businessName,
    required this.logoUrl,
    required this.businessType,
    required this.userId,
    required this.location,
    required this.businessId,
  });

  @override
  State<HeaderWidgets> createState() => _HeaderWidgetsState();
}

class _HeaderWidgetsState extends State<HeaderWidgets> {
  late VisitProfileController controller;
  final viewBusiness = Get.find<ViewBusinessDetailsController>();
  final chatViewController = Get.find<ChatViewController>();
  @override
  void initState() {
    super.initState();
    controller = Get.put(VisitProfileController());
  }
  @override
  Widget build(BuildContext context) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.all(SizeConfig.size10),
          padding: EdgeInsets.all(SizeConfig.size3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: SizeConfig.size28,
            backgroundColor: AppColors.red,
            child: Image.asset("assets/images/brand_logo.png"),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      "McDonalds King Burger",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontSize: SizeConfig.size18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: SizeConfig.size16,
                  ),
                  CustomBtn(
                    onTap: () {},
                    title: "Follow",
                    fontWeight: FontWeight.bold,
                    height: SizeConfig.size30,
                    bgColor: AppColors.skyBlueDF,
                    width: SizeConfig.size60,
                    radius: SizeConfig.size12,
                  ),
                  SizedBox(
                    width: SizeConfig.size4,
                  ),
                  Icon(Icons.more_vert)
                ],
              ),
              SizedBox(height: SizeConfig.size6),
              Row(
                children: [
                  _buildTag("Restaurant"),
                  SizedBox(width: SizeConfig.size6),
                  _buildTag("Closed",
                      borderColor: AppColors.red,
                      textColor: AppColors.red),
                  SizedBox(width: SizeConfig.size6),
                  _buildTag("14.2 KM Far"),
                ],
              )
            ],
          ),
        ),
      ],
    );



  }


  Widget _buildTag(
      String text, {
        Color borderColor = AppColors.greyA5,
        Color textColor = AppColors.black,
      }) {
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size4, vertical: SizeConfig.size4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size20),
          border: Border.all(color: borderColor),
        ),
        child: CustomText(
          text,
          fontSize: SizeConfig.size12,
          color: textColor,
        ));
  }


}
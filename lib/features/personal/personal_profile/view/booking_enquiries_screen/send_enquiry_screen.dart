import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'controller/send_enquiry_controller.dart';



/// Opened through [RouteHelper.sentEnquiresRoute], whose SendEnquiryBinding
/// provides the controller for the channel and video.
class SendEnquiryScreen extends StatefulWidget {
  const SendEnquiryScreen({super.key});
  @override
  State<SendEnquiryScreen> createState() =>
      _SendEnquiryScreenState();
}





class _SendEnquiryScreenState extends State<SendEnquiryScreen> {

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final enquiryController = TextEditingController();
  final enquiry = Get.find<SendEnquiryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Enquiry Form ',
        isLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Type
              CommonTextField(
                title: 'Name',
                hintText: "Enter your full name",
                textEditController: nameController,
              ),

              // Mobile
              SizedBox(height: SizeConfig.size16),
              CustomText("Mobile Number"),
              SizedBox(height: SizeConfig.size6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 60,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("+91"),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: CommonTextField(
                      textEditController: mobileController,
                      hintText: "Enter your mobile number",
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size16),
              // Email
              CommonTextField(
                textEditController: emailController,
                title: 'Email',
                hintText: "Enter your email address",
              ),

              SizedBox(height: SizeConfig.size24),

              CommonTextField(
                maxLine: 5,
                minLines: 3,
                textEditController: enquiryController,
                title: 'Your Enquiry',
                hintText: "Type your message or question here...",
              ),

              SizedBox(height: SizeConfig.size10),
              SizedBox(height: SizeConfig.size24),

              // Submit Button
              CustomBtn(
                radius: SizeConfig.size6,
                bgColor: Colors.blue,
                onTap: () async {
                  final sent = await enquiry.send(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    mobile: mobileController.text.trim(),
                    message: enquiryController.text.trim(),
                  );
                  if (sent) {
                    Get.offAllNamed(
                      RouteHelper.getBottomNavigationBarScreenRoute(),
                      arguments: {ApiKeys.initialIndex: 1},
                    );
                  }

                },
                title: "Send Enquiry",
                textColor: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }



  // Helper Widgets




}

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'controller/booking_controller.dart';
import 'model/appointment_booking_model.dart';



class SendEnquiryScreen extends StatefulWidget {
  final String channelId;
  final String videoId;

  const SendEnquiryScreen({super.key, required this.channelId,  required this.videoId});
  @override
  State<SendEnquiryScreen> createState() =>
      _SendEnquiryScreenState();
}





class _SendEnquiryScreenState extends State<SendEnquiryScreen> {

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final enquiryController = TextEditingController();
  final BookingTabController bookingController = Get.put(BookingTabController());

  @override
  void initState() {
    super.initState();



  }
  @override
  Widget build(BuildContext context) {
    print("userchannelId:$channelId",);
    print("userVideoId:${widget.videoId}");
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
                    child: CustomText(countryCode),
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
                hintText: "Type your message or question here..",
              ),

              SizedBox(height: SizeConfig.size10),
              SizedBox(height: SizeConfig.size24),

              // Submit Button
              CustomBtn(
                radius: SizeConfig.size6,
                bgColor: Colors.blue,
                onTap: () {
                  final name = nameController.text.trim();
                  final mobile = mobileController.text.trim();
                  final email = emailController.text.trim();
                  final msg = enquiryController.text.trim();
                  enquiryController.text.trim();


                  final customer = CustomerDetails(
                    name: name,
                    mobileNumber: mobile,
                    email: email,
                  );
                  Map<String,dynamic> params = {
                    ApiKeys.serviceProvider_channelId: "${widget.channelId}",
                    ApiKeys.message : msg,
                    ApiKeys.videoId: "${widget.videoId}",
                   ApiKeys.user_email:email,
                   ApiKeys.user_phone:mobile,
                   ApiKeys.user_name:name
                  };
                  print("giugg ${widget.videoId}");
                  print("sgf ${customer}");
                  bookingController.addEnquiry(params: params);

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

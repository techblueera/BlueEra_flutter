import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'controller/booking_controller.dart';

class MyEnquiriesPage extends StatelessWidget {
  final BookingTabController controller = Get.put(BookingTabController());

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.green;
      case 'Closed':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'My Enquiries',
        isLeading: true,
      ),

      body: Obx(() => ListView.builder(
        itemCount: controller.enquiry.length,
        itemBuilder: (context, index) {
          final enquiry = controller.enquiry[index];
          return Container(
            margin:  EdgeInsets.symmetric(horizontal:  SizeConfig.size10, vertical:  SizeConfig.size8),
            padding:  EdgeInsets.all( SizeConfig.size12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SizeConfig.size10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title + Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      enquiry.title,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    
                    CustomText(
                      enquiry.status,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(enquiry.status),
                    ),

                  ],
                ),
                 SizedBox(height:SizeConfig.size20),
                Row(
                  children: [
                    CustomText(
                    "Name: ",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                    ),
                    CustomText(
                      enquiry.userName,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ],
                ),
                    Row(
                  children: [
                    CustomText(
                    "Mobile: ",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                    ),
                    CustomText(
                      enquiry.userPhone,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ],
                ),
   Row(
                  children: [
                    CustomText(
                    "Email: ",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                    ),
                    CustomText(
                      enquiry.userEmail,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ],
                ),
                   Row(
                  children: [
                    CustomText(
                    "Enquiry: ",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                    ),
                    CustomText(
                      enquiry.message,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ],
                ),
                 SizedBox(height:SizeConfig.size8),

                /// Message
                // CustomText(
                //   enquiry.message,
                //   fontSize: SizeConfig.medium15,
                //   fontWeight: FontWeight.w500,
                //   color: Colors.black87,
                // ),
                // SizedBox(height:SizeConfig.size8),
                 CustomBtn(
                  height: 40,
                  radius: SizeConfig.size12,
                  bgColor:Colors.white,
borderColor: Colors.blue,

                  onTap: () {

                  },
                  title: "Message",textColor: Colors.blue,

                ),

              ],
            ),
          );
        },
      )),
    );
  }
}

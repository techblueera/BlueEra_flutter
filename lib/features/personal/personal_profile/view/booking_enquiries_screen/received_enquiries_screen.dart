// received_bookings_screen.dart
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/controller/booking_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/videography_tutorial_screen2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_image_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';

class ReceivedEnquiriesScreen extends StatelessWidget {
final  String channelId;
   ReceivedEnquiriesScreen({super.key, required this.channelId});

  @override
  Widget build(BuildContext context) {
     final controller = Get.put(BookingTabController());
    controller.getReceivedEnquiryList(channelId:channelId,);
    final bookings = List.generate(
      5,
          (index) => {
        "title": "Videography Tutorial",
        "postedOn": "07-Feb-2025",
        "date": "27 Feb, 2025",
        "time": "10:00 AM",
        "fees": "1500 INR",
        "location":
        index % 2 == 0 ? "Google Meet (Online)" : "Zoom Call (Online)"
      },
    );

    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Received Enquires',
        isLeading: true,
      ),
      body: ListView.builder(
          padding: EdgeInsets.all(SizeConfig.size8),
          itemCount: controller.receivedenquiryList.length,
          itemBuilder: (context, index) {
            final enquiry = controller.receivedenquiryList[index];
           
  int seconds = int.parse(enquiry.createdAt.seconds);
  int nanos = enquiry.createdAt.nanos;


  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
      (seconds * 1000) + (nanos ~/ 1000000),
      isUtc: true);


 

            return Container(
              margin: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size4, vertical: SizeConfig.size4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Container(
                        width: 120,
                        child: Image.network(
                          enquiry.coverUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size4,
                            vertical: SizeConfig.size8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CustomText(
                                    enquiry.title,
                                    fontSize: SizeConfig.large,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Icon(Icons.more_vert, size: 20),
                              ],
                            ),
                            SizedBox(height: SizeConfig.size4),
                            CustomText(
                              'Posted On: ${ DateFormat("dd MMM yyyy ").format(dateTime)}',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w300,
                              color: Colors.black54,
                            ),
                            Divider(
                              thickness: 0.1,
                              color: AppColors.grayText,
                            ),
                            SizedBox(height: SizeConfig.size4),
                            _buildDetailRow("Status :", enquiry.status),
                          //  SizedBox(height: SizeConfig.size4),
                           // _buildDetailRow("Message :", enquiry.message),
                            SizedBox(height: SizeConfig.size4),
                            // _buildDetailRow(
                            //     "User :", enquiry.userName ?? 'N/A'),
                            // SizedBox(height: SizeConfig.size4),
                            // _buildDetailRow(
                            //     "Contact :", enquiry.userPhone ?? enquiry.userEmail ?? 'N/A'),
                            SizedBox(height: SizeConfig.size12),
                            CustomBtn(
                              height:  SizeConfig.size50,
                              radius: SizeConfig.size6,
                              bgColor: AppColors.white,
                              borderColor: AppColors.skyBlueDF,
                              onTap: () {
                                Get.to(()=>VideographyTutorialScreen2(channelId: enquiry.channelId,videoId: enquiry.id,));
                                //Get.toNamed(RouteHelper.getVideographyTutorialScreen2Route());
                              },
                              title: "Enquires (${enquiry.inquiryCount})",
                              textColor: AppColors.skyBlueDF,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return RichText(
      text: TextSpan(
        text: '$title ',
        style: TextStyle(
          color: Colors.black54,
          fontSize: SizeConfig.size14,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/widget/common_popup.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import 'controller/booking_controller.dart';

class VideographyTutorialScreen2 extends StatefulWidget {
  final String? videoId;
  final String? channelId;
  const VideographyTutorialScreen2({super.key, this.videoId, this.channelId});

  @override
  State<VideographyTutorialScreen2> createState() =>
      _VideographyTutorialScreen2State();
}

class _VideographyTutorialScreen2State
    extends State<VideographyTutorialScreen2> {
  final controller = Get.put(BookingTabController());
  int selectedIndex = 0;
  final List<Map<String, dynamic>> bookings = [
    {
      'name': 'Emma Thompson',
      'date': '27 Feb, 2025',
      'message': "Hi, is this still available?",
    },
    {
      'name': 'Alex John',
      'date': '27 Feb, 2025',
      'message': "Can you share more details about this?",
    },
    {
      'name': 'Alisha',
      'message': "Is there any discount if I buy in bulk?",
    },
    {
      'name': 'Neha Singh',
      'date': '27 Feb, 2025',
      'message': "Hi, I'm interested in your video... read more",
    },
  ];

  bool isLoading = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("datata${widget.channelId},${widget.videoId}");
      controller.getReceivedvideoEnquiryList(
          channelId: widget.channelId, videoId: widget.videoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
    //    title: 'Videography Tutorial',
        isLeading: true,
      ),
      backgroundColor: const Color(0xFFF2F2F2),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size10),
          // Filter Chips

          SizedBox(height: SizeConfig.size10),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
              itemCount: controller.receivedenquiry.length,
              separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
              itemBuilder: (context, index) {
                final booking = controller.receivedenquiry[index];




                return Container(
                  padding: EdgeInsets.all(SizeConfig.size12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            booking.videoTitle,
                            fontSize: SizeConfig.large,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size2),
                      CustomText(
                        "${DateFormat('dd-MMM-yyyy').format(DateTime.parse(booking.createdAt.toString()))}",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w300,
                        color: Colors.black87,
                      ),
                      SizedBox(height: SizeConfig.size8),
                       _buildDetailRow("Name :", booking.datumUserName.toString()),
                       SizedBox(height: SizeConfig.size8),
                       _buildDetailRow("Mobile :", booking.userPhone.toString()),
                         SizedBox(height: SizeConfig.size8),
                       _buildDetailRow("Email :", booking.datumUserEmail.toString()),
                         SizedBox(height: SizeConfig.size8),
                      _buildDetailRow("Enquiry :", booking.subject.toString()),

                      SizedBox(height: SizeConfig.size12),
                      Row(
                        children: [
                          Expanded(
                              child: CommonPopupButton(menuItems: [
                            PopupMenuItem(
                              value: 'Open',
                              onTap: () {
                                  controller.bookingUpdate(
                                  bookingId: booking.id,
                                  params: {"status": "open"},
                                ).then((_) {
                                  controller.getReceivedvideoBookingList(
                                    channelId: widget.channelId,
                                    videoId: widget.videoId,
                                  );
                                });
                              },
                              child: CustomText(
                                'Open',
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                  controller.bookingUpdate(
                                  bookingId: booking.id,
                                  params: {"status": "Closed"},
                                ).then((_) {
                                  controller.getReceivedvideoBookingList(
                                    channelId: widget.channelId,
                                    videoId: widget.videoId,
                                  );
                                });
                              },
                              value: 'Close',
                              child: CustomText(
                                'Close',
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                controller.bookingUpdate(
                                  bookingId: booking.id,
                                  params: {"status": "inprogress"},
                                ).then((_) {
                                  controller.getReceivedvideoBookingList(
                                    channelId: widget.channelId,
                                    videoId: widget.videoId,
                                  );
                                });
                              },
                              value: 'In Progress',
                              child: CustomText(
                                'In Progress',
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ], title: "Status")),
                          SizedBox(width: SizeConfig.size12),
                          Expanded(
                            child: CustomBtn(
                              height: 40,
                              radius: SizeConfig.size12,
                              bgColor: Colors.blue,
                              onTap: () {},
                              title: "Replay",
                              textColor: AppColors.white,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
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

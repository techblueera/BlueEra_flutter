import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/widget/common_popup.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/horizontal_tab_selector.dart';
import 'controller/booking_controller.dart';

class VideographyTutorialScreen extends StatefulWidget {
 final  String? videoId;
 final String? channelId;
  const VideographyTutorialScreen({super.key,  this.videoId, this.channelId});

  @override
  State<VideographyTutorialScreen> createState() => _VideographyTutorialScreenState();
}

class _VideographyTutorialScreenState extends State<VideographyTutorialScreen> {
  
final controller = Get.put(BookingTabController());
  int selectedIndex = 0;

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'open':
      case 'pending':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  String formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  void initState() {
    super.initState();
   
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("datata${widget.channelId},${widget.videoId}");
      controller.getReceivedvideoBookingList(channelId:widget.channelId,videoId: widget.videoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Videography Tutorial',
        isLeading: true,
      ),
      backgroundColor: const Color(0xFFF2F2F2),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size10),
          // Filter Chips
          Obx(() => HorizontalTabSelector(
            tabs: controller.filters2,
            selectedIndex: controller.selectedIndex2.value,
            onTabSelected: (index, value) {
              controller.updateTab2(index);
            },
            labelBuilder: (label) => label,
          )),
          SizedBox(height: SizeConfig.size10),
          Expanded(
            child: Obx(() {
              // Show loading indicator while fetching data
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // Filter bookings based on selected tab
              final filtered = controller.selectedTab2 == 'All'
                  ? controller.receivedbookings
                  : controller.receivedbookings
                      .where((booking) => booking.status.toLowerCase() == controller.selectedTab2.toLowerCase())
                      .toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: CustomText(
                    "No Bookings Found",
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: SizeConfig.size12),
                itemBuilder: (context, index) {
                  final booking = filtered[index];
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
                            Expanded(
                              child: CustomText(
                                booking.customerDetails.name,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            CustomText(
                              booking.status,
                              color: getStatusColor(booking.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size8),
                        
                       
                        CustomText("Date: ${formatDate(booking.bookingTime)}"),
                        CustomText("Time: ${formatTime(booking.bookingTime)}"),
                        
                      
                        if (booking.durationInMinutes != null)
                          CustomText("Duration: ${booking.durationInMinutes} minutes"),
                        if (booking.amount != null)
                          CustomText("Amount: ${booking.amount} INR"),
                        
                      
                        SizedBox(height: SizeConfig.size8),
                        CustomText(
                          "Customer Details:",
                          fontWeight: FontWeight.w600,
                          fontSize: SizeConfig.medium,
                        ),
                        CustomText("Email: ${booking.customerDetails.email}"),
                        CustomText("Phone: ${booking.customerDetails.mobileNumber}"),
                        
                        // Video Title
                        if (booking.videoTitle.isNotEmpty) ...[
                          SizedBox(height: SizeConfig.size8),
                          CustomText(
                            "Video: ${booking.videoTitle}",
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                        
                        SizedBox(height: SizeConfig.size12),
                        Row(
                          children: [
                                                         Expanded(child: CustomBtn(
                               height: 40,
                               radius: SizeConfig.size12,
                               bgColor: AppColors.white,
                               borderColor: AppColors.red,
                               onTap: () {
                                
                                 controller.bookingUpdate(
                                   bookingId: booking.id,
                                   params: {"status": "rejected"},
                                 ).then((_) {
                                  
                                   controller.getReceivedvideoBookingList(
                                     channelId: widget.channelId,
                                     videoId: widget.videoId,
                                   );
                                 });
                               },
                               title: "Cancel",
                               textColor: AppColors.red,
                             ),),
                            SizedBox(width: SizeConfig.size12),
                            Expanded(
                              child: CommonPopupButton(
                                menuItems: [
                                  PopupMenuItem(
                                    value: 'Accept Booking',
                                    child: CustomText(
                                      'Accept Booking',
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'Message',
                                    child: CustomText(
                                      'Message',
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                                title: "Next Step",
                                onSelected: (value) {
                                  if (value == 'Accept Booking') {
                                  
                                    controller.bookingUpdate(
                                      bookingId: booking.id,
                                      params: {"status": "accepted"},
                                    ).then((_) {
                                    
                                      controller.getReceivedvideoBookingList(
                                        channelId: widget.channelId,
                                        videoId: widget.videoId,
                                      );
                                    });
                                  } else if (value == 'Message') {
                                   
                                    print('Message functionality to be implemented');
                                  }
                                },
                              )
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

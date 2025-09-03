import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/horizontal_tab_selector.dart';
import 'controller/booking_controller.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final controller = Get.put(BookingTabController());
  int selectedIndex = 0;
  final List<Map<String, dynamic>> bookings = [
    {
      'name': 'Emma Thompson',
      'date': '27 Feb, 2025',
      'time': '10:00 AM',
      'location': 'Google Meet (Online)',
      'status': 'Booked',
    },
    {
      'name': 'Emma Thompson',
      'date': '27 Feb, 2025',
      'time': '10:00 AM',
      'location': 'Google Meet (Online)',
      'status': 'Rejected',
    },
    {
      'name': 'Emma Thompson',
      'date': '27 Feb, 2025',
      'time': '10:00 AM',
      'location': 'Google Meet (Online)',
      'status': 'Rescheduled',
    },
    {
      'name': 'Emma Thompson',
      'date': '27 Feb, 2025',
      'time': '10:00 AM',
      'location': 'Google Meet (Online)',
      'status': 'Open',
    },
    {
      'name': 'Emma Thompson',
      'date': '27 Feb, 2025',
      'time': '10:00 AM',
      'location': 'Google Meet (Online)',
      'status': 'Booked',
    },
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case 'Booked':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Rescheduled':
        return Colors.orange;
      case 'Pending':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller.getMyBookingList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'My Bookings',
        isLeading: true,
      ),
      backgroundColor: const Color(0xFFF2F2F2),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size10),
          Obx(() => HorizontalTabSelector(
            tabs: controller.filters,
            selectedIndex: controller.selectedIndex.value,
            onTabSelected: (index, value) {
              controller.updateTab(index);
            },
            labelBuilder: (label) => label,
          )),
          SizedBox(height: SizeConfig.size10),
          Obx(() {
            if (controller.isLoading.value) {
              return const Expanded(child: Center(child: CircularProgressIndicator()));
            }

            final filtered = controller.selectedTab.value == 'All'
                ? controller.bookings
                : controller.bookings.where((b) => b.status == controller.selectedTab.value).toList();

            if (filtered.isEmpty) {
              return const Expanded(child: Center(child: CustomText("No Bookings Found")));
            }

            return Expanded(
              child: RefreshIndicator(
                onRefresh: controller.getMyBookingList,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
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
                              CustomText(
                                booking.customerDetails.name,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
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
                          CustomText("Timings: ${formatTime(booking.bookingTime)}"),
                          Row(
                            children: [
                              CustomText("Location: "),
                              CustomText("Google Meet (Online)", color: Colors.blue),
                            ],
                          ),
                          SizedBox(height: SizeConfig.size12),
                          Row(
                            children: [
                              Expanded(
                                child: CustomBtn(
                                  radius: SizeConfig.size6,
                                  bgColor: AppColors.white,
                                  borderColor: AppColors.red,
                                  onTap: () {
                                    // Cancel logic here
                                  },
                                  title: "Cancel",
                                  textColor: AppColors.red,
                                ),
                              ),
                              SizedBox(width: SizeConfig.size12),
                              Expanded(
                                child: CustomBtn(
                                  radius: SizeConfig.size6,
                                  bgColor: Colors.blue,
                                  onTap: () {
                                    // Reschedule logic here
                                  },
                                  title: "Reschedule",
                                  textColor: AppColors.white,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
  String formatDate(DateTime dateTime) {
    return "${dateTime.day} ${_monthName(dateTime.month)}, ${dateTime.year}";
  }

  String formatTime(DateTime dateTime) {
    return TimeOfDay.fromDateTime(dateTime).format(Get.context!);
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

}

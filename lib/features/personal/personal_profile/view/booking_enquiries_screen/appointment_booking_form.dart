import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/widget/custom_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/common_drop_down.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/new_common_date_selection_dropdown.dart';
import 'controller/booking_controller.dart';
import 'model/appointment_booking_model.dart';

enum BookingType { online, offline }

class AppointmentBookingScreen extends StatefulWidget {
  final String channelId;
  final String videoId;

  const AppointmentBookingScreen({super.key, required this.channelId,  required this.videoId});
  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

String? _selectedFromTime;
String? _selectedToTime;
bool _acceptBookings = false;
List<String> _timeOfDay = [];


class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  BookingType selectedType = BookingType.offline;
  int? _selectedDay, _selectedMonth, _selectedYear;
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final BookingTabController bookingController = Get.put(BookingTabController());

  @override
  void initState() {
    super.initState();

    _timeOfDay = generate24HoursAmPm();
    
    // Fetch calendar data when screen loads
    bookingController.getAvailabilityData(channelId:widget.channelId);
  }
  @override
  Widget build(BuildContext context) {
    print("Channelids:${widget.channelId}");
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Appointment Booking Form',
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
              Text("Booking Type",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: SizeConfig.size8),
              Row(
                children: [
                  buildBookingOption("Online", BookingType.online),
                  SizedBox(width: SizeConfig.size12),
                  buildBookingOption("Offline", BookingType.offline),
                ],
              ),

              SizedBox(height: SizeConfig.size12),

              // Address (only for offline)
              if (selectedType == BookingType.offline)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Address: Gomti Nagar, Lucknow, UP",
                      style: TextStyle(color: Colors.black87),
                    ),
                    SizedBox(height: SizeConfig.size16),
                  ],
                ),
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

              // Select Date
              CustomText(
                'Select Date',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),

              SizedBox(height: SizeConfig.size10),

              SizedBox(
                height: SizeConfig.size10,
              ),
              Obx(() => bookingController.isLoadingCalendar.value
                ? Center(child: CircularProgressIndicator())
                : !bookingController.isAvailabilitySet
                  ? Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 24),
                          SizedBox(height: 8),
                          CustomText(
                            'No availability set',
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                          SizedBox(height: 4),
                          CustomText(
                            'The service provider needs to set their availability first',
                            fontSize: SizeConfig.small,
                            color: Colors.orange.shade700,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : bookingController.availableDates.isEmpty
                    ? CustomText(
                        'No available dates found',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      )
                    : (() {
                       
                        final years = bookingController.availableDates
                            .map((d) => d.year)
                            .toSet()
                            .toList()
                          ..sort();

                        final months = _selectedYear != null
                            ? (bookingController.availableDates
                                    .where((d) => d.year == _selectedYear)
                                    .map((d) => d.month)
                                    .toSet()
                                    .toList()
                                  ..sort())
                            : <int>[];

                        final days = (_selectedYear != null && _selectedMonth != null)
                            ? (bookingController.availableDates
                                    .where((d) => d.year == _selectedYear && d.month == _selectedMonth)
                                    .map((d) => d.day)
                                    .toSet()
                                    .toList()
                                  ..sort())
                            : <int>[];

                        return NewDatePicker(
                          selectedDay: _selectedDay,
                          selectedMonth: _selectedMonth,
                          selectedYear: _selectedYear,
                          allowedYears: years,
                          allowedMonths: months,
                          allowedDays: days,
                          onDayChanged: (value) {
                            setState(() {
                              _selectedDay = value;
                              // Reset time selection when date changes
                              _selectedFromTime = null;
                              _selectedToTime = null;
                            });
                          },
                          onMonthChanged: (value) {
                            setState(() {
                              _selectedMonth = value;
                              // Reset day and time when month changes
                              _selectedDay = null;
                              _selectedFromTime = null;
                              _selectedToTime = null;
                            });
                          },
                          onYearChanged: (value) {
                            setState(() {
                              _selectedYear = value;
                              // Reset month, day and time when year changes
                              _selectedMonth = null;
                              _selectedDay = null;
                              _selectedFromTime = null;
                              _selectedToTime = null;
                            });
                          },
                        );
                      })(),
              ),
              SizedBox(height: SizeConfig.size12),
              Obx(() => bookingController.isLoadingCalendar.value
                ? Center(child: CircularProgressIndicator())
                : CustomText(
                    'Charges/ Fees: ${bookingController.charges.value.isNotEmpty ? "${bookingController.charges.value} INR" : "Not set"}',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
              ),
              SizedBox(height: SizeConfig.size16),
              // Select Time
              CustomText(
                'Select Time',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),

              SizedBox(height: SizeConfig.size8),
              Obx(() {
                // Get available time slots for selected date
                List<String> availableSlots = [];
                if (_selectedDay != null && _selectedMonth != null && _selectedYear != null) {
                  final selectedDate = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
                  availableSlots = bookingController.getAvailableTimeSlotsForDate(selectedDate);
                }
                
                return bookingController.isLoadingCalendar.value
                  ? Center(child: CircularProgressIndicator())
                  : !bookingController.isAvailabilitySet
                    ? SizedBox.shrink() // Hide time selection if no availability set
                    : availableSlots.isEmpty
                      ? CustomText(
                          'No available time slots for selected date',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        )
                      : Row(
                        children: [
                          Expanded(
                            child: CommonDropdown<String>(
                              items: availableSlots,
                              selectedValue: _selectedFromTime ?? null,
                              hintText: "Select Time Slot",
                              displayValue: (value) => value,
                              onChanged: (value) {
                                _selectedFromTime = value;
                                setState(() {});
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a time slot';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      );
              }),

              SizedBox(height: SizeConfig.size24),

              // Submit Button
              Obx(() => CustomBtn(
                radius: SizeConfig.size6,
                bgColor: bookingController.isAvailabilitySet ? Colors.blue : Colors.grey,
                onTap: bookingController.isAvailabilitySet ? () {
                  final name = nameController.text.trim();
                  final mobile = mobileController.text.trim();
                  final email = emailController.text.trim();

                  if (name.isEmpty || mobile.isEmpty || email.isEmpty || _selectedDay == null || _selectedMonth == null || _selectedYear == null || _selectedFromTime == null) {
                    Get.snackbar('Error', 'Please fill all required fields');
                    return;
                  }

                  // Parse the selected time slot (format: "startTime - endTime")
                  final timeSlotParts = _selectedFromTime!.split(' - ');
                  if (timeSlotParts.length != 2) {
                    Get.snackbar('Error', 'Invalid time slot format');
                    return;
                  }

                  final startTime = timeSlotParts[0];
                  final bookingDateTime = DateTime(
                    _selectedYear!,
                    _selectedMonth!,
                    _selectedDay!,
                    _parseTimeToHour(startTime),
                    _parseTimeToMinute(startTime),
                  );

                  final customer = CustomerDetails(
                    name: name,
                    mobileNumber: mobile,
                    email: email,
                  );
                  Map<String,dynamic> params = {

                    ApiKeys.serviceProvider_channelId:"${widget.channelId}",
                    // "${68a5290138686a9a3fc59e3a}",
                    ApiKeys.videoId: "${widget.videoId}",
                    ApiKeys.bookingTime: "$bookingDateTime",
                    ApiKeys.customerDetails:customer.toJson(),
                  };
                  print("giugg ${widget.videoId}");
                  print("sgf ${widget.channelId}");
                bookingController.addBooingAppointment(params: params);

                } : null,
                title: "Book Appointment",
                textColor: AppColors.white,
              )),
            ],
          ),
        ),
      ),
    );
  }
  int _getHour(String time) {
    final parts = time.split(' ');
    var hour = int.parse(parts[0].split(':')[0]);
    if (parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts[1] == 'AM' && hour == 12) hour = 0;
    return hour;
  }

  int _getMinute(String time) {
    return int.parse(time.split(' ')[0].split(':')[1]);
  }

  // Parse time from 24-hour format (e.g., "14:30" or "09:00")
  int _parseTimeToHour(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]);
  }

  int _parseTimeToMinute(String time) {
    final parts = time.split(':');
    return int.parse(parts[1]);
  }

  Widget buildBookingOption(String label, BookingType type) {
    final isSelected = selectedType == type;
    return Row(
      children: [
        CircularCheckbox(
          isChecked: isSelected,
          onChanged: () {
            setState(() => selectedType = type);
          },
        ),
        SizedBox(width: SizeConfig.size6),
        CustomText(label),
        SizedBox(width: SizeConfig.size16),
      ],
    );
  }

  // Helper Widgets

  Widget buildInputField(String hint,
      {required TextEditingController controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget buildDropdown(
      List<String> items, String? selected, ValueChanged<String?> onChanged) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected ?? items.first,
            isExpanded: true,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

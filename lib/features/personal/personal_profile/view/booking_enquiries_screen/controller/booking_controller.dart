
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/received_booking.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/received_enquiry_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/video_booking_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/video_enquiry_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/repo/booking_enquiries_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/api/apiService/api_keys.dart';
import '../enquiry_model.dart';
import '../model/mybooking_model.dart';
import '../model/availability_model.dart';
import '../model/calendar_model.dart';
import '../repo/booking_repo.dart';
enum BookingType {
  online,
  offline,
  both;

  /// Human-readable title (capitalised)
  String get title => name[0].toUpperCase() + name.substring(1);
}

class BookingTabController extends GetxController {
  ApiResponse addAvailabilityResponse = ApiResponse.initial('Initial');
  var isLoading = false.obs;
  final formKey = GlobalKey<FormState>();
  TextEditingController locationController = TextEditingController();
  TextEditingController feeController = TextEditingController();
  RxInt selectedIndex = 0.obs;
  RxInt selectedIndex2 = 0.obs;
  var selectedType = BookingType.offline.obs;
  RxString selectedTimeSlot = '30 Min'.obs;
  var bookings = <Booking>[].obs;
  var receivedbookingList = <ReceivedBookingData>[].obs;
  var receivedenquiryList = <ReceivedEnquiryData>[].obs;
  var receivedbookings = <ReceivedBooking>[].obs;
   var receivedenquiry = <ReceivedEnquiry>[].obs;
  var enquiry = <Enquiry>[].obs;
  ApiResponse addAppointment = ApiResponse.initial('Initial');
  
  // Calendar data
  var calendarData = Rxn<CalendarResponse>();
  var availableDates = <DateTime>[].obs;
  var availableTimeSlots = <String>[].obs;
  var charges = ''.obs;
  var isLoadingCalendar = false.obs;
  var availabilityDetails = Rxn<AvailabilityModel>();
  bool _editAvailabilityInitialized = false;
  bool _userChangedBookingType = false;

  @override
  void onInit() {
    super.onInit();
    getMyBookingList();
    getMyEnquiry();
  
  }



  Future<void> addBooingAppointment({required Map<String, dynamic> params}) async {
    try {
      final response = await BookingRepo().postAppointment(bodyRequest: params);
      if (response.isSuccess) {
        addAppointment = ApiResponse.complete(response);
        commonSnackBar(message: response.message ?? AppStrings.success);
        
    Get.offAllNamed(
          RouteHelper.getBottomNavigationBarScreenRoute(),
          arguments: {ApiKeys.initialIndex: 0},
        );
      } else {
        addAppointment = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addAppointment =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }
   Future<void> addEnquiry({required Map<String, dynamic> params}) async {
    try {
      final response = await BookingRepo().postEnquiry(bodyRequest: params);
      if (response.isSuccess) {
        addAppointment = ApiResponse.complete(response);
        commonSnackBar(message: response.message ?? AppStrings.success);
           Get.offAllNamed(
          RouteHelper.getBottomNavigationBarScreenRoute(),
          arguments: {ApiKeys.initialIndex: 0},
        );


      } else {
        addAppointment = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addAppointment =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  void setBookingType(BookingType type) {
    _userChangedBookingType = true;
    selectedType.value = type;
  }
  final List<String> filters = ['All', 'Open', 'Booked', 'Rescheduled', 'Rejected'];

  final List<String> filters2 = ['All', 'Open', 'Accepted', 'Rejected'];
  RxList<Enquiry> enquiries = <Enquiry>[
    Enquiry(title: "Videography Tutorial", date: "07-Feb-2025", message: "Hi, is this still available?", status: "Open"),
    Enquiry(title: "Videography Tutorial", date: "07-Feb-2025", message: "Hi, is this still available?", status: "Closed"),
    Enquiry(title: "Videography Tutorial", date: "07-Feb-2025", message: "Hi, is this still available?", status: "Pending"),
    Enquiry(title: "Videography Tutorial", date: "07-Feb-2025", message: "Hi, is this still available?", status: "Open"),
  ].obs;
  var selectedTab = 'All'.obs;
  void updateTab(int index) {
    selectedIndex.value = index;
    selectedTab.value = filters[index];
  }
  void updateTab2(int index) {
    selectedIndex2.value = index;
  }


  String get selectedTab2 => filters2[selectedIndex2.value];

  Future<void> addVideoBookingAvailability({required String id}) async {
   
    if (formKey.currentState?.validate() ?? false) {

      final visitingHoursSelectorController = Get.find<VisitingHoursSelectorController>();

      // Format visiting hours data for API in the required JSON format
      List<Map<String, dynamic>> visitingHoursData = [];

      visitingHoursSelectorController.visitingHours.forEach((day, isOpen) {
        if (isOpen) {
          // Only include days that are toggled on (open)
          final startTime = visitingHoursSelectorController
              .formatTime(visitingHoursSelectorController.startTimes[day]!);
          final endTime = visitingHoursSelectorController
              .formatTime(visitingHoursSelectorController.endTimes[day]!);

          // Format as a Map with day, open status, startTime and endTime
          visitingHoursData.add({
            "day": day,
            "isOpen": true,
            "timeSlots": [{
              "startTime": startTime,
              "endTime": endTime
            }],

          });
        }
      });

      logs("Visiting Hours: $visitingHoursData");

      Map<String, dynamic> params = {
        ApiKeys.bookingType: selectedType.value.title,
        ApiKeys.location: locationController.text,
        ApiKeys.fee: feeController.text,
        ApiKeys.durationInMinutes: selectedTimeSlot.value.replaceAll(' Min', ''),
        if(visitingHoursData.isNotEmpty) ApiKeys.schedule: visitingHoursData,
      };

      try {
        ResponseModel? response = await BookingEnquiriesRepo().addVideoBookingAvailability(channelId: id, params: params);

        if (response.isSuccess) {
          addAvailabilityResponse = ApiResponse.complete(response);
          Get.back(result: true);
          commonSnackBar(message: "Availability added");
        } else {
          addAvailabilityResponse = ApiResponse.error('error');
          commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        }
      } catch (e) {
        addAvailabilityResponse = ApiResponse.error('error');
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    }
  }

  Future<void> getMyBookingList() async {
    try {
      isLoading.value = true;
      final response = await BookingRepo().getMyBooking();
      if (response.statusCode == 200) {
        final bookingResponse = BookingResponse.fromJson(response.response!.data);
        bookings.value = bookingResponse.data;
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> getMyEnquiry() async {
    try {
      isLoading.value = true;
      final response = await BookingRepo().getMyInquiries();
     
      if (response.statusCode == 200) {
        final bookingResponse = EnquiryResponse.fromJson(response.response!.data);
        enquiry.value = bookingResponse.data;
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> bookingUpdate({required String bookingId,  required Map<String, dynamic> params}) async {
    try {
      final response = await BookingRepo().bookingStatusUpdate(
       id: bookingId,
        params: params,
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);
        // Get.offAllNamed(
        //   RouteHelper.getBottomNavigationBarScreenRoute(),
        //   arguments: {ApiKeys.initialIndex: 0},
        // );
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> enquirybookingUpdate({required String bookingId,  required Map<String, dynamic> params}) async {
    try {
      final response = await BookingRepo().bookingStatusUpdate(
       id: bookingId,
        params: params,
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);
        // Get.offAllNamed(
        //   RouteHelper.getBottomNavigationBarScreenRoute(),
        //   arguments: {ApiKeys.initialIndex: 0},
        // );
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> getReceivedBookingList({String?channelId,String?videoId}) async {
    try {
      isLoading.value = true;
      final response = await BookingRepo().getReceivedBooking(channelId: channelId,videoId: videoId);
      log("datares:${response.statusCode}");
      if (response.statusCode == 200) {
        final bookingResponse = ReceivedBookingList.fromJson(response.response!.data);
        receivedbookingList.value = bookingResponse.data;
        log("Received booking data: ${receivedbookingList.value.length} items");
      } else {
        print("API failed with status: ${response.statusCode}");
        receivedbookingList.clear();
      }
    } catch (e) {
      print("Error in getReceivedBookingList: $e");
      receivedbookingList.clear();
    } finally {
      isLoading.value = false;
    }
  }
    Future<void> getReceivedEnquiryList({String?channelId,String?videoId}) async {
    try {
      isLoading.value = true;
      final response = await BookingRepo().getReceivedInquiries(channelId: channelId);
      if (response.statusCode == 200) {
        final bookingResponse = ReceivedEnquiryList.fromJson(response.response!.data);
        receivedenquiryList.value = bookingResponse.data;
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      receivedenquiryList.clear();
    } finally {
      isLoading.value = false;
    }
  }

   Future<void> getReceivedvideoBookingList({String?channelId,String?videoId}) async {
    try {
      isLoading.value = true;

      if (channelId == null || videoId == null) {
        
        receivedbookings.clear();
        return;
      } 
      final response = await BookingRepo().getVideoBookings(channelId: channelId, videoId: videoId);

      if (response.statusCode == 200 && response.response?.data != null) {
     
        try {
          final bookingResponse = ReceivedBookingResponse.fromJson(response.response!.data);
          receivedbookings.value = bookingResponse.data;
         
        } catch (parseError) {
          
          log("Response data: ${response.response!.data}");
          receivedbookings.clear();
        }
      } else {
        log("API error message: ${response.message}");
        receivedbookings.clear();
      }
    } catch (e) {
      log("Error in getReceivedvideoBookingList: $e");
      receivedbookings.clear();
    } finally {
      isLoading.value = false;
    }
  }
   Future<void> getReceivedvideoEnquiryList({String?channelId,String?videoId}) async {
    try {
      isLoading.value = true;

      if (channelId == null || videoId == null) {
        
        receivedbookings.clear();
        return;
      } 
      final response = await BookingRepo().getVideoEnquiry(channelId: channelId, videoId: videoId);

      if (response.statusCode == 200 && response.response?.data != null) {
     
        try {
          final bookingResponse = ReceivedEnquiryResponse.fromJson(response.response!.data);
          receivedenquiry.value = bookingResponse.data;
         
        } catch (parseError) {
          
          log("Response data: ${response.response!.data}");
          receivedbookings.clear();
        }
      } else {
        log("API error message: ${response.message}");
        receivedbookings.clear();
      }
    } catch (e) {
      log("Error in getReceivedvideoBookingList: $e");
      receivedbookings.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void clearValues() {
    selectedType.value = BookingType.offline;
    selectedTimeSlot.value = '30 Min';
    locationController.text = '';
    feeController.text = '';
    _userChangedBookingType = false;

 
    if (Get.isRegistered<VisitingHoursSelectorController>()) {
      final v = Get.find<VisitingHoursSelectorController>();
      for (final day in v.visitingHours.keys) {
        v.visitingHours[day] = false;
        v.startTimes[day] = const TimeOfDay(hour: 10, minute: 0);
        v.endTimes[day] = const TimeOfDay(hour: 23, minute: 0);
      }
    }
  }

  
  Future<void> getAvailabilityData({required String channelId}) async {
    try {
      isLoadingCalendar.value = true;
      
             final response = await BookingRepo().getavailableCalender(
         channelId: channelId,
         params: {},
       );
      
      print("Calendar API Response Status: ${response.statusCode}");
      print("Calendar API Response Success: ${response.isSuccess}");
      print("Calendar API Response Data: ${response.response?.data}");
      
      if (response.isSuccess && response.response?.data != null) {
        try {
          print("Calendar API Response Type: ${response.response!.data.runtimeType}");
          print("Calendar API Response: ${response.response!.data}");
          
                     final calendarResponse = CalendarResponse.fromJson(response.response!.data);
           calendarData.value = calendarResponse;
           
           // Extract charges/fees
           if (calendarResponse.fee != null) {
             charges.value = calendarResponse.fee!;
           }
           
           // Generate available dates from calendar
           _generateAvailableDatesFromCalendar(calendarResponse.data);
          
        } catch (e) {
          print("Error parsing calendar response: $e");
          print("Response data type: ${response.response!.data.runtimeType}");
          print("Response data: ${response.response!.data}");
        }
      } else {
        print("Failed to fetch calendar: ${response.message}");
        print("Response status: ${response.statusCode}");
      }

      // Fetch availability details to ensure fee/charges and schedule are populated
      try {
        final availabilityRes = await BookingRepo().getAvailability(
          channelId: channelId,
          params: {},
        );
        if (availabilityRes.isSuccess && availabilityRes.response?.data != null) {
          try {
            final availability = AvailabilityResponse.fromJson(availabilityRes.response!.data);
            final fee = availability.data?.fee?.toString() ?? '';
            if (fee.isNotEmpty) {
              charges.value = fee;
            }
            availabilityDetails.value = availability.data;
          } catch (e) {
            print("Error parsing availability response: $e");
          }
        } else {
          print("Availability fetch failed or empty: ${availabilityRes.message}");
        }
      } catch (e) {
        print("Error fetching availability details: $e");
      }
    } catch (e) {
      print("Error fetching calendar: $e");
    } finally {
      isLoadingCalendar.value = false;
    }
  }
 Future<void>getavailablitydata({required String channelId})async{
       try {
        final availabilityRes = await BookingRepo().getAvailability(
          channelId: channelId,
          params: {},
        );
        if (availabilityRes.isSuccess && availabilityRes.response?.data != null) {
          try {
            final availability = AvailabilityResponse.fromJson(availabilityRes.response!.data);
            final fee = availability.data?.fee?.toString() ?? '';
            if (fee.isNotEmpty) {
              charges.value = fee;

            }
            availabilityDetails.value = availability.data;
          } catch (e) {
            print("Error parsing availability response: $e");
          }
        } else {
          print("Availability fetch failed or empty: ${availabilityRes.message}");
        }
      } catch (e) {
        print("Error fetching availability details: $e");
      }
 }
Future<void> initAvailabilityForEdit({required String channelId}) async {
  if (_editAvailabilityInitialized) return;
  _editAvailabilityInitialized = true;
print("channelId:$channelId");
  try {
    final availabilityRes = await BookingRepo().getAvailability(
      channelId: channelId,
      params: {},
    );
    
logs('datass:$availabilityRes');
    logs('initAvailabilityForEdit status: ${availabilityRes.statusCode}, success: ${availabilityRes.isSuccess}');
    logs('initAvailabilityForEdit raw data: ${availabilityRes.response?.data}');

    if (availabilityRes.isSuccess && availabilityRes.response?.data != null) {
      try {
        final availability = AvailabilityResponse.fromJson(availabilityRes.response!.data);
        final data = availability.data;
        availabilityDetails.value = data;

        // Prefill booking type only if user hasn't changed it yet
        if (data?.bookingType != null && !_userChangedBookingType) {
          final bt = data!.bookingType!.toLowerCase();
          if (bt == 'online') {
            selectedType.value = BookingType.online;
          } else if (bt == 'offline') {
            selectedType.value = BookingType.offline;
          } else {
            selectedType.value = BookingType.both;
          }
        }

        // Prefill location, fee, duration
        locationController.text = data?.location ?? '';
        feeController.text = data?.fee?.toString() ?? '';
        if ((data?.durationInMinutes ?? '').isNotEmpty) {
          final candidate = '${data!.durationInMinutes} Min';
          const allowed = ['15 Min', '30 Min', '60 Min'];
          selectedTimeSlot.value = allowed.contains(candidate) ? candidate : '30 Min';
        }

        // Prefill visiting hours
        final v = Get.isRegistered<VisitingHoursSelectorController>()
            ? Get.find<VisitingHoursSelectorController>()
            : Get.put(VisitingHoursSelectorController());

        // Reset all to closed first
        for (final day in v.visitingHours.keys) {
          v.visitingHours[day] = false;
        }

        final schedule = data?.schedule ?? [];
        for (final sch in schedule) {
          final apiDay = (sch.day ?? '').toLowerCase();
          final uiDay = _mapApiDayToUiDay(apiDay);
          if (uiDay == null) continue;

          final isOpen = sch.isOpen ?? false;
          v.visitingHours[uiDay] = isOpen;

          // Pick first slot
          final firstSlot = (sch.timeSlots ?? []).isNotEmpty ? sch.timeSlots!.first : null;
          if (firstSlot != null) {
            final start = _parseTimeOfDay(firstSlot.startTime);
            final end = _parseTimeOfDay(firstSlot.endTime);
            if (start != null) v.startTimes[uiDay] = start;
            if (end != null) v.endTimes[uiDay] = end;
          }
        }
      } catch (e) {
        logs('initAvailabilityForEdit parse error: $e');
        clearValues();
      }
    } else {
      clearValues();
    }
  } catch (e) {
    logs('initAvailabilityForEdit error: $e');
    clearValues();
  }
}

  String? _mapApiDayToUiDay(String apiDayLower) {
    switch (apiDayLower) {
      case 'monday':
      case 'mon':
        return 'Monday';
      case 'tuesday':
      case 'tue':
      case 'tues':
        return 'Tuesday';
      case 'wednesday':
      case 'wed':
        return 'Wednesday';
      case 'thursday':
      case 'thu':
      case 'thur':
      case 'thurs':
        return 'Thursday';
      case 'friday':
      case 'fri':
        return 'Friday';
      case 'saturday':
      case 'sat':
        return 'Saturday';
      case 'sunday':
      case 'sun':
        return 'Sunday';
      default:
        return null;
    }
  }

  TimeOfDay? _parseTimeOfDay(String? raw) {
    if (raw == null) return null;
    try {
      String value = raw.trim();
      String upper = value.toUpperCase();
      bool hasMeridian = upper.contains('AM') || upper.contains('PM');
      final regex = RegExp(r'^(\d{1,2}):(\d{2})');
      final match = regex.firstMatch(upper);
      if (match == null) return null;
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      if (hasMeridian) {
        if (upper.contains('PM') && hour != 12) hour += 12;
        if (upper.contains('AM') && hour == 12) hour = 0;
      }
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  // Generate available dates from calendar data
  void _generateAvailableDatesFromCalendar(List<String>? calendarData) {
    print("Generating dates from calendar data: $calendarData");
    if (calendarData == null) {
      print("Calendar data is null");
      return;
    }
    
    availableDates.clear();
    
    // Process calendar data to get available dates
    for (var dateString in calendarData) {
      try {
        print("Parsing date string: $dateString");
        final date = DateTime.parse(dateString);
        availableDates.add(date);
        print("Successfully parsed date: $date");
      } catch (e) {
        print("Error parsing date: $dateString - $e");
      }
    }
    
    print("Total available dates: ${availableDates.length}");
  }

  

  // Get available time slots for a specific date from API availability (schedule + duration)
  List<String> getAvailableTimeSlotsForDate(DateTime date) {
    final details = availabilityDetails.value;
    if (details == null || details.schedule == null || details.schedule!.isEmpty) {
      return [];
    }

    // Map weekday to string used in schedule
    String dayName;
    switch (date.weekday) {
      case DateTime.monday:
        dayName = 'monday';
        break;
      case DateTime.tuesday:
        dayName = 'tuesday';
        break;
      case DateTime.wednesday:
        dayName = 'wednesday';
        break;
      case DateTime.thursday:
        dayName = 'thursday';
        break;
      case DateTime.friday:
        dayName = 'friday';
        break;
      case DateTime.saturday:
        dayName = 'saturday';
        break;
      case DateTime.sunday:
        dayName = 'sunday';
        break;
      default:
        dayName = 'monday';
    }

    final scheduleForDay = details.schedule!
        .where((s) => (s.day?.toLowerCase() ?? '') == dayName && (s.isOpen ?? false))
        .toList();
    if (scheduleForDay.isEmpty) {
      return [];
    }

    final int slotMinutes = int.tryParse(details.durationInMinutes ?? '') ?? 60;
    final List<String> slots = [];

    for (final sch in scheduleForDay) {
      final slotsForDay = sch.timeSlots ?? [];
      for (final ts in slotsForDay) {
        final start = _tryParseHHmm(ts.startTime);
        final end = _tryParseHHmm(ts.endTime);
        if (start == null || end == null) continue;

        var cursor = start;
        while (cursor.isBefore(end)) {
          final next = cursor.add(Duration(minutes: slotMinutes));
          if (next.isAfter(end)) {
            break;
          }
          slots.add('${_formatHHmm(cursor)} - ${_formatHHmm(next)}');
          cursor = next;
        }
      }
    }

    return slots;
  }

  DateTime? _tryParseHHmm(String? hhmm) {
    if (hhmm == null) return null;
    final raw = hhmm.trim();
    if (raw.isEmpty) return null;
    try {
      String upper = raw.toUpperCase();
      bool hasMeridian = upper.contains('AM') || upper.contains('PM');
      final regex = RegExp(r'^(\d{1,2}):(\d{2})');
      final match = regex.firstMatch(upper);
      if (match == null) return null;
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      if (hasMeridian) {
        if (upper.contains('PM') && hour != 12) hour += 12;
        if (upper.contains('AM') && hour == 12) hour = 0;
      }
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  String _formatHHmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // Check if availability is set for the channel
  bool get isAvailabilitySet {
    return calendarData.value != null && 
           calendarData.value!.data != null && 
           calendarData.value!.data!.isNotEmpty;
  }
}
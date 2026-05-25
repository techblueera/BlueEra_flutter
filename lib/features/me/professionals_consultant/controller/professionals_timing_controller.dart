import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professionals_timing_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/repo/professionals_repo.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DayTiming {
  String day;
  RxBool isOpen;
  RxString openTime;
  RxString closeTime;

  DayTiming({
    required this.day,
    bool isOpen = false,
    String openTime = "10:00 AM",
    String closeTime = "10:00 PM",
  }) : 
    isOpen = isOpen.obs,
    openTime = openTime.obs,
    closeTime = closeTime.obs;
}

class ProfessionalsTimingController extends GetxController {
  final ProfessionalsRepo _repo = ProfessionalsRepo();
  var timingList = <DayTiming>[].obs;
  final List<String> timeSlots = [];
  var isLoading = false.obs;
  var isFirstTime = true; // To track if we should POST or PUT

  @override
  void onInit() {
    super.onInit();
    _generateTimeSlots();
    _initializeDefaultTimings();

    fetchTimings();
  }

  void _generateTimeSlots() {
    timeSlots.clear();
    // Generate times from 12:00 AM to 11:30 PM in 30 min intervals
    final periods = ['AM', 'PM'];
    for (var period in periods) {
      for (var hour = 0; hour < 12; hour++) {
        // Handle 12 AM/PM special case
        int displayHour = hour == 0 ? 12 : hour;
        
        for (var min = 0; min < 60; min += 30) {
          String minStr = min.toString().padLeft(2, '0');
          timeSlots.add("$displayHour:$minStr $period");
        }
      }
    }
  }

  void _initializeDefaultTimings() {
    timingList.clear();
    List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    for (var day in days) {
      timingList.add(DayTiming(
        day: day,
        isOpen: false,
      ));
    }

  }

  Future<void> fetchTimings() async {
    isLoading.value = true;
    try {
      ResponseModel response = await _repo.getTimingRepo();
      if (response.isSuccess == true && response.response?.data!= null) {
        ProfessionalsTimingData model = ProfessionalsTimingData.fromJson(response.response?.data['data']);
        isFirstTime = false; // Data exists, so next time we PUT
        _mapModelToUI(model);
      } else {
        isFirstTime = true;
        // No data, so we POST
      }
    } catch (e) {
      print("Error fetching timings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _mapModelToUI(ProfessionalsTimingData model) {
    void updateDay(String dayName, ProfessionalDaySchedule? schedule) {
      final index = timingList.indexWhere((element) => element.day.toLowerCase() == dayName.toLowerCase());
      if (index != -1 && schedule != null) {
        timingList[index].isOpen.value = schedule.isOpen ?? false;
        if (schedule.openTime != null && schedule.openTime!.isNotEmpty) {
            timingList[index].openTime.value = _convert24to12(schedule.openTime!);
        }
        if (schedule.closeTime != null && schedule.closeTime!.isNotEmpty) {
            timingList[index].closeTime.value = _convert24to12(schedule.closeTime!);
        }
      }
    }

    updateDay("Monday", model.schedule?.monday);
    updateDay("Tuesday", model.schedule?.tuesday);
    updateDay("Wednesday", model.schedule?.wednesday);
    updateDay("Thursday", model.schedule?.thursday);
    updateDay("Friday", model.schedule?.friday);
    updateDay("Saturday", model.schedule?.saturday);
    updateDay("Sunday", model.schedule?.sunday);
  }

  void toggleDay(int index, bool value) {
    timingList[index].isOpen.value = value;
  }
  
  void updateTime(int index, String newTime, bool isOpenTime) {
    if (isOpenTime) {
      timingList[index].openTime.value = newTime;
    } else {
      timingList[index].closeTime.value = newTime;
    }
  }

  Future<void> submit() async {
    isLoading.value = true;
    Map<String, dynamic> body = {};

    for (var timing in timingList) {
      body[timing.day.toLowerCase()] = {
        "isOpen": timing.isOpen.value,
        "openTime": timing.isOpen.value ? _convert12to24(timing.openTime.value) : "",
        "closeTime": timing.isOpen.value ? _convert12to24(timing.closeTime.value) : "",
      };
    }

    try {
      ResponseModel response;
         response = await _repo.updateTimingRepo(body);


      if (response.isSuccess== true) {
         commonSnackBar(message: "Availability updated successfully");
         isFirstTime = false;
         Get.back(result: true);
      } else {
         commonSnackBar(message: response.response?.data['message'] != null ? response.response?.data['message'] : "Failed to update availability");
      }
    } catch (e) {
      print("Error submitting timings: $e");
      commonSnackBar(message: "An error occurred");
    } finally {
      isLoading.value = false;
    }
  }

  String _convert24to12(String time24) {
    try {
      DateTime date = DateFormat("HH:mm").parse(time24);
      return DateFormat("h:mm a").format(date);
    } catch (e) {
      return time24;
    }
  }

  String _convert12to24(String time12) {
    try {
      // Handle cases like "10:00 AM" -> "10:00"
      DateTime date = DateFormat("h:mm a").parse(time12);
      return DateFormat("HH:mm").format(date);
    } catch (e) {
      return time12;
    }
  }
}

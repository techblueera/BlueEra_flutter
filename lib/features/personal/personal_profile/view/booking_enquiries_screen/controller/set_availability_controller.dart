import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/shared_preference_utils.dart';
import '../../../../../../core/constants/snackbar_helper.dart';
import '../repo/booking_repo.dart';

enum BookingType { online, offline, both }

class VisitingDayModel {
  String day;
  bool isOpen;
  List<Map<String, String>> timeSlots;

  VisitingDayModel({required this.day, required this.isOpen, required this.timeSlots});

  Map<String, dynamic> toJson() => {
    "day": day,
    "isOpen": isOpen,
    "timeSlots": timeSlots,
  };
}

class SpecialOverrideModel {
  String date;
  bool isOpen;
  List<Map<String, String>> timeSlots;

  SpecialOverrideModel({required this.date, required this.isOpen, required this.timeSlots});

  Map<String, dynamic> toJson() => {
    "date": date,
    "isOpen": isOpen,
    "timeSlots": timeSlots,
  };
}

class SetAvailabilityController extends GetxController {
  var selectedType = BookingType.online.obs;
  var location = ''.obs;
  var fee = ''.obs;
  var slotDuration = 30.obs; // in minutes
  var schedule = <VisitingDayModel>[].obs;
  var specialOverrides = <SpecialOverrideModel>[].obs;

  void setBookingType(BookingType type) {
    selectedType.value = type;
  }

  void setSlotDuration(String value) {
    switch (value) {
      case '15 mins':
        slotDuration.value = 15;
        break;
      case '30 mins':
        slotDuration.value = 30;
        break;
      case '60 mins':
        slotDuration.value = 60;
        break;
    }
  }
  Future<String> getChannelId() async {
    final channelId = await SharedPreferenceUtils.getSecureValue(
      SharedPreferenceUtils.channel_Id,
    );
    return channelId ?? "";
  }
  Future<void> postAvailability() async {
    String channelId=await getChannelId();
    try {
      print('sdlfhnjsf');
      final params = {
        "bookingType": selectedType.value.name.capitalizeFirst,
        "location": location.value,
        "fee": int.tryParse(fee.value) ?? 0,
        "durationInMinutes": slotDuration.value,
        "timezone": "Asia/Kolkata",
        "schedule": schedule.map((e) => e.toJson()).toList(),
        "specialOverrides": specialOverrides.map((e) => e.toJson()).toList(),
      };
      final response = await BookingRepo().checkAvailability(
        channelId: channelId,
        params: params,
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);

      } else {
        print('slfng');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
    print("srkgwr$e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }


}

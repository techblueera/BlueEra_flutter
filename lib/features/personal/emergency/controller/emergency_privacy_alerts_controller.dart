import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/emergency/repo/emergency_service_repo.dart';
import 'package:get/get.dart';

class EmergencyPrivacyAlertsController extends GetxController {
  final EmergencyServiceRepo _repo = EmergencyServiceRepo();
  final isSaving = false.obs;

  final maskPhoneNumber = false.obs;
  final sendSmsAlertWithLocation = false.obs;
  final shareMedicalInfo = false.obs;
  final sendChatAlertWithGps = false.obs;

  final confirmAccurateInfo = false.obs;
  final agreeToShareDuringEmergency = false.obs;

  bool get isValid =>
      confirmAccurateInfo.value && agreeToShareDuringEmergency.value;

  Future<void> submit() async {
    if (!isValid) {
      commonSnackBar(message: "Please confirm and agree before submitting");
      return;
    }
    try {
      isSaving.value = true;
      final body = {
        "maskPhoneNumber": maskPhoneNumber.value,
        "sendSmsAlertWithLocation": sendSmsAlertWithLocation.value,
        "shareMedicalInfo": shareMedicalInfo.value,
        "sendChatAlertWithGps": sendChatAlertWithGps.value,
      };
      final ResponseModel res = await _repo.submitPrivacyAlerts(body: body);
      if (res.isSuccess) {
        Get.offNamedUntil(
          RouteHelper.getBottomNavigationBarScreenRoute(),
          (route) => false,
        );
        commonSnackBar(message: "Saved privacy settings");
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

/// Generic catalog-node editor: tracks an `isActive` flag and an optional
/// `data` payload per node id, and submits the whole set to the policies
/// endpoint as `{ nodes: [...] }`.
///
/// Currently has no view bindings — kept for the catalog-builder flow.
class HotelPropertyController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final RxBool isSaving = false.obs;
  final RxBool is24Hours = false.obs;

  /// `{ catalogNodeId: payload }` — populated by the editor widgets.
  final RxMap<String, dynamic> userSelections = <String, dynamic>{}.obs;

  /// `{ catalogNodeId: isActive }`.
  final RxMap<String, bool> activeStates = <String, bool>{}.obs;

  final List<String> timeSlots =
      List.generate(24, (i) => "${i.toString().padLeft(2, '0')}:00");

  Future<void> submitData() async {
    final nodes = activeStates.entries.map((e) {
      final node = <String, dynamic>{
        "catalogNodeId": e.key,
        "isActive": e.value,
      };
      if (userSelections.containsKey(e.key)) {
        node["data"] = userSelections[e.key];
      }
      return node;
    }).toList();

    try {
      isSaving.value = true;
      final ResponseModel response =
          await _repo.addHotelPoliciesRepo(reqBody: {"nodes": nodes});

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(message: response.response?.data['message']);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSaving.value = false;
    }
  }
}

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:get/get.dart';

/// Bootstraps a brand-new hotel record after the user signs up under a Motel
/// business type. The only consumer is the auth flow in
/// `auth_controller.dart`, which passes a fully-built request body.
class HotelServiceController extends GetxController {
  final HotelServiceRepo _repo = HotelServiceRepo();

  final RxBool isSaving = false.obs;

  Future<void> createHotelServiceController(
      {required Map<String, dynamic> reqParm}) async {
    try {
      isSaving.value = true;
      final ResponseModel response =
          await _repo.createHotelServiceRepo(reqBody: reqParm);

      if (response.isSuccess) {
        final hotelID = response.response?.data['data']?['_id'] as String?;
        await setHotelID(hotelID?.isNotEmpty == true ? hotelID! : "");
        await getHotelID();
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      commonSnackBar(message: e.toString());
    } finally {
      isSaving.value = false;
    }
  }
}

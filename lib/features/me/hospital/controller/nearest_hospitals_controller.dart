import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:get/get.dart';
import '../model/hospital_details_list_res_model.dart';

class NearestHospitalsController extends GetxController {
  final MedicalRepo _repo = MedicalRepo();

  final hospitalsResponse = ApiResponse.initial('Initial').obs;
  final hospitals = <HospitalDetailsData>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  String pincode = '';
  int radius = 0;

  Future<void> fetchNearest({required String pin, required int rad}) async {
    pincode = pin;
    radius = rad;
    isLoading.value = true;
    error.value = '';
    hospitalsResponse.value = ApiResponse.initial('Initial');
    hospitals.clear();
    try {
      final ResponseModel res = await _repo.fetchNearestHospitalsRepo(
        params: {
          'pincode': pincode,
          'radius': radius,
        },
      );

      if (res.isSuccess) {
        hospitalsResponse.value = ApiResponse.complete(res);
        final parsed =
            HospitalDetailsListResModel.fromJson(res.response?.data);
        final List<HospitalDetailsData> list = parsed.data ?? [];
        hospitals.assignAll(list);
        if (list.isEmpty) {
          error.value = 'No hospitals found';
        }
      } else {
        error.value = res.message ?? AppStrings.somethingWentWrong;
        hospitalsResponse.value = ApiResponse.error(error.value);
        commonSnackBar(message: error.value);
      }
    } catch (e) {
      error.value = e.toString();
      hospitalsResponse.value = ApiResponse.error(AppStrings.somethingWentWrong);
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }
}

import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';

import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/common_bloc/place/repo/place_repo.dart';
import '../auth/model/referral_get_bdm_details_model.dart';

class ReferralController extends GetxController {
final fullNameController=TextEditingController();
final emailController=TextEditingController();
final alternatePhoneNumberController=TextEditingController();
final highestEducationalQualificationController=TextEditingController();
final workLocationPinCodeController=TextEditingController();
final cityController=TextEditingController();
final addressController=TextEditingController();
final mainReferralCode=TextEditingController();
RxList<String> stateList = AppConstants.stateList.obs;
final List<String> qualificationsList = AppConstants.qualificationList;

RxInt? selectedDay = 0.obs, selectedMonth = 0.obs, selectedYear = 0.obs;
final FocusNode referralFocusNode = FocusNode();
RxString selectedState = "Andhra Pradesh".obs;
RxString selectQualification = ''.obs;
RxString selectedCity = "".obs;
RxBool submitLoading = false.obs;
RxBool termAccept = false.obs;
RxBool makeReferralEditable = false.obs;
RxBool updateNewCodeLoading = false.obs;
RxBool updateIsTextFormValidate= false.obs;
Rx<ReferralGetBdmDetailsModel> referralBdmDetails = ReferralGetBdmDetailsModel().obs;
Rx<ApiResponse> referralBdmDetailsResponse = ApiResponse.initial('Initial').obs;


/// Search States


/// Search Cities based on selected state

void selectState(String state) {
  selectedState.value = state;
  selectedCity.value = "";

}

void selectCity(String city) {
  selectedCity.value = city;
}

  Future<void> fetchMyReferralId() async {
    try {

      final res = await UserRepo().getMyReferralCodeApi();

      if (res.isSuccess) {
        log("My Referral Id  ${res.response?.data}");

      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
      }
    } catch (e) {
    } finally {

    }
  }

  Future<void> joinAsBdmApi() async {
    submitLoading.value=true;
    try {
    var params={
      ApiKeys.name: fullNameController.text,
      ApiKeys.email: emailController.text,
      ApiKeys.dob: "${selectedYear}-${selectedMonth}-${selectedDay}",
      ApiKeys.alternatePhoneNumber: alternatePhoneNumberController.text,
      ApiKeys.highestEducationalQualification: selectQualification.value,
      ApiKeys.workLocationPinCode: workLocationPinCodeController.text,
      ApiKeys.preferredState: selectedState.value,
      ApiKeys.preferredCity: cityController.text,
      ApiKeys.address: addressController.text,
      ApiKeys.acceptedTerms: true,
      ApiKeys.aadharDocumentId: "doc_aadhar_123",
      ApiKeys.panDocumentId: "doc_pan_456",
      ApiKeys.addressProofDocumentId: "doc_address_789",
      ApiKeys.bankDetailsDocumentId: "doc_bank_012"
    };

      final res = await UserRepo().joinAsBdmApi(params);

      if (res.isSuccess) {
        submitLoading.value=false;
        getBdmDetails();

        commonSnackBar(
          message: res.message ?? "Joined as Business Development",
        );
        clearForm();
        Get.back();
      } else {
        submitLoading.value=false;

        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
      }
    } catch (e) {
      submitLoading.value=false;

    } finally {

    }
  }
void clearForm() {
  // Clear text controllers
  fullNameController.clear();
  emailController.clear();
  alternatePhoneNumberController.clear();
  highestEducationalQualificationController.clear();
  workLocationPinCodeController.clear();
  cityController.clear();
  addressController.clear();

  // Reset dropdown selections
  selectedState.value = "";
  selectedCity.value = "";
  selectQualification.value = "";

  // Reset date values
  selectedDay?.value = 0;
  selectedMonth?.value = 0;
  selectedYear?.value = 0;

  // Reset lists (important for dependent dropdown)

  // Reset other states
  termAccept.value = false;
  submitLoading.value = false;
}
  Future<void> getMyReferralHistoryApi() async {
    try {

      final res = await UserRepo().getMyReferralHistoryApi();

      if (res.isSuccess) {
        log("My Referral History  ${res.response?.data}");

      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
      }
    } catch (e) {
    } finally {

    }
  }
Future<void> getBdmDetails() async {
  try {
    final res = await UserRepo().getBdmDetails();

    if (res.isSuccess) {
      referralBdmDetails.value =ReferralGetBdmDetailsModel.fromJson(res.data);
      referralBdmDetailsResponse.value=ApiResponse.complete(referralBdmDetails.value);
    } else {
      commonSnackBar(
        message: res.message ?? AppStrings.somethingWentWrong.tr,
      );
      referralBdmDetailsResponse.value=ApiResponse.error("${res.message ?? AppStrings.somethingWentWrong.tr}");

    }
  } catch (e) {
  } finally {

  }
}
Future<void> saveNewReferralCodeApi() async {
  try {
    updateNewCodeLoading.value=true;
    var params={
      ApiKeys.referral_code: mainReferralCode.text
    };
    final res = await UserRepo().saveNewReferralCodeApi(params);

    if (res.isSuccess) {
      commonSnackBar(
        message: res.message ?? "Your New Referral Code Updated Successfully",
      );
      referralBdmDetails.value=    referralBdmDetails.value.copyWith(
        isReferralCodeSaved: true
      );
      updateNewCodeLoading.value=false;
    } else {
      commonSnackBar(
        message: res.message ?? AppStrings.somethingWentWrong.tr,
      );
      updateNewCodeLoading.value=false;

    }
  } catch (e) {
    updateNewCodeLoading.value=false;
  }
}
}
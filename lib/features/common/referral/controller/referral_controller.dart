import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/referral/model/referral_get_bdm_details_model.dart';
import 'package:BlueEra/features/common/referral/model/wallet_referral_history_response.dart';
import 'package:BlueEra/features/common/referral/model/wallet_referral_stats_response.dart';

import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_response.dart';

class ReferralController extends GetxController {
  Rx<ApiResponse> referralBdmDetailsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> referralSuggestionsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> walletReferralHistoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> locationFromPinCodeResponse =
      ApiResponse.initial('Initial').obs;

final fullNameController=TextEditingController();
final emailController=TextEditingController();
final alternatePhoneNumberController=TextEditingController();
final highestEducationalQualificationController=TextEditingController();
final workLocationPinCodeController=TextEditingController();
final stateController=TextEditingController();
final cityController=TextEditingController();
final addressController=TextEditingController();
final mainReferralCode=TextEditingController();
RxList<String> stateList = AppConstants.stateList.obs;
final List<String> qualificationsList = AppConstants.qualificationList;

RxInt? selectedDay = 0.obs, selectedMonth = 0.obs, selectedYear = 0.obs;
final FocusNode referralFocusNode = FocusNode();
RxString selectedState = "Andhra Pradesh".obs;
var selectQualification = Rxn<Qualification>();
RxString selectedCity = "".obs;
RxBool submitLoading = false.obs;
RxBool termAccept = false.obs;
RxBool makeReferralEditable = false.obs;
RxBool updateNewCodeLoading = false.obs;
RxBool updateIsTextFormValidate= false.obs;
  RxBool bdmRegisterLoading = false.obs;

Rx<ReferralGetBdmDetailsModel> referralBdmDetails = ReferralGetBdmDetailsModel().obs;
Rx<WalletRefferalStatsData> referralStatsData = WalletRefferalStatsData().obs;
RxList<WalletReferralHistoryData> referralHistoryData = <WalletReferralHistoryData>[].obs;

  RxString selectedFilter = 'All'.obs;
  final List<String> filters = [
    'All',
    'Pending',
    'Subscribe',
    'Un-Subscribe',
    'Expired',
  ];
  RxList<String> referralSuggestions = <String>[].obs;
  RxString selectedSuggestion = ''.obs;

/// Search States


/// Search Cities based on selected state

void selectState(String state) {
  selectedState.value = state;
  selectedCity.value = "";

}

void selectCity(String city) {
  selectedCity.value = city;
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
  selectQualification.value = null;

  // Reset date values
  selectedDay?.value = 0;
  selectedMonth?.value = 0;
  selectedYear?.value = 0;

  // Reset lists (important for dependent dropdown)

  // Reset other states
  termAccept.value = false;

submitLoading.value = false;
}



  Future<void> getWalletReferralHistoryApi(String filter) async {
    try {

      Map<String, dynamic> _queryParms = {};
      switch(filter){
        case 'All':
          break;
        case 'Pending':
          _queryParms['pending'] = true;
          break;
        case 'Subscribe':
          _queryParms['subscribed'] = true;
          break;
        case 'Un-Subscribe':
          _queryParms['non-subscribed'] = true;
          break;
        case 'Expired':
          _queryParms['expired'] = true;
          break;
      }

      walletReferralHistoryResponse.value =
          ApiResponse.initial('Initial');

      final res = await UserRepo().getWalletReferralHistoryRepo(queryParms: _queryParms);

      if (res.isSuccess) {
        walletReferralHistoryResponse.value =
            ApiResponse.complete(res.response?.data);
        var walletReferralHistory = WalletReferralHistoryResponse.fromJson(res.response?.data);
        referralHistoryData.value = walletReferralHistory.data ?? [];

      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
        walletReferralHistoryResponse.value =
            ApiResponse.error("${res.message ?? AppStrings.somethingWentWrong.tr}");
      }
    } catch (e) {
      walletReferralHistoryResponse.value =
          ApiResponse.error(e.toString());
    }
  }

  Future<void> getBdmDetails() async {
    final myDocumentController = Get.find<MyDocumentsController>();

    try {
      final res = await UserRepo().getBdmDetailsRepo();

      if (res.isSuccess) {
        referralBdmDetails.value = ReferralGetBdmDetailsModel.fromJson(res.response?.data);

        if(referralBdmDetails.value.status == 'PENDING'){
          myDocumentController.fetchAllDocumentStatusApi();
        } else if (referralBdmDetails.value.status == 'COMPLETED') {
          await getWalletReferralStatsApi();
        }

        referralBdmDetailsResponse.value =
            ApiResponse.complete(res.response?.data);

      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
        referralBdmDetailsResponse.value =
            ApiResponse.error("${res.message ?? AppStrings.somethingWentWrong.tr}");

      }
    } catch (e) {
      referralBdmDetailsResponse.value =
          ApiResponse.error(e.toString());
     }
  }

  Future<void> getWalletReferralStatsApi() async {
    try {

      // walletReferralStatsResponse.value =
      //     ApiResponse.initial('Initial');

      final res = await UserRepo().getWalletReferralStatsRepo();

      if (res.isSuccess) {
        var walletReferralStats = WalletReferralStatsResponse.fromJson(res.response?.data);
        if(walletReferralStats.data!=null){
          referralStatsData.value = walletReferralStats.data!;
          // walletReferralStatsResponse.value =
          //     ApiResponse.complete(referralStatsData.value);
        }

      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
        // walletReferralStatsResponse.value =
        //     ApiResponse.error("${res.message ?? AppStrings.somethingWentWrong.tr}");
      }
    } catch (e) {
      debugPrint("Failed to fetch wallet stats: $e");
        // walletReferralStatsResponse.value =
        //     ApiResponse.error(e.toString());
    }
  }

  Future<void> bdmRegisterStepOneApi() async {
    bdmRegisterLoading.value = true;

    try {
      var params={
        ApiKeys.fullName: fullNameController.text,
        ApiKeys.email: emailController.text,
        ApiKeys.dob: {
          ApiKeys.day: selectedYear?.value,
          ApiKeys.month: selectedMonth?.value,
          ApiKeys.year: selectedDay?.value
        },
        ApiKeys.alternateMobileNo: alternatePhoneNumberController.text,
        ApiKeys.education: selectQualification.value?.value,
        ApiKeys.location:{
          ApiKeys.pincode: workLocationPinCodeController.text,
          ApiKeys.state: selectedState.value,
          ApiKeys.city: cityController.text,
          ApiKeys.addressString : addressController.text,
        },
        // ApiKeys.acceptedTerms: true,
        // ApiKeys.aadharDocumentId: "doc_aadhar_123",
        // ApiKeys.panDocumentId: "doc_pan_456",
        // ApiKeys.addressProofDocumentId: "doc_address_789",
        // ApiKeys.bankDetailsDocumentId: "doc_bank_012"
      };

      final res = await UserRepo().bdmRegisterStepOneRepo(params);

      if (res.isSuccess) {
        submitLoading.value = false;
        getBdmDetails();

        commonSnackBar(
          message: res.message ?? "Joined as Business Development",
        );
        clearForm();
        Get.back();
      } else {

        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
      }
    } catch (e) {

    } finally {
      bdmRegisterLoading.value = false;
    }
  }

  Future<void> bdmRegisterStepTwoApi() async {
    final myDocumentController = Get.find<MyDocumentsController>();

    try {
      bdmRegisterLoading.value = true;

      final aadharId = myDocumentController.documentStatuses[DocumentKeys.aadhar]?.id;
      final panId = myDocumentController.documentStatuses[DocumentKeys.pan]?.id;
      final addressId = myDocumentController.documentStatuses[DocumentKeys.addressProof]?.id;
      // final bankId = myDocumentController.documentStatuses[DocumentKeys.bankDetails]?.id;
      final bankersCancelledCheque = myDocumentController.documentStatuses[DocumentKeys.bankersCancelledCheque]?.id;

      var params={
        'documents': {
          if (aadharId != null && aadharId.isNotEmpty) "aadharCard": aadharId,
          if (panId != null && panId.isNotEmpty) "panCard": panId,
          if (addressId != null && addressId.isNotEmpty) "addressProof": addressId,
          // if (bankId != null && bankId.isNotEmpty) "bankDetails": bankId,
          if (bankersCancelledCheque != null && bankersCancelledCheque.isNotEmpty) "bankDetails": bankersCancelledCheque,
        },
        ApiKeys.referralCode: mainReferralCode.text
      };
      final res = await UserRepo().bdmRegisterStepTwoRepo(params);

      if (res.isSuccess) {
        commonSnackBar(
          message: res.message ?? "Your New Referral Code Updated Successfully",
        );
        getBdmDetails();
      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );

      }
    } catch (e) {
    }
    finally{
      bdmRegisterLoading.value = false;
    }
  }

  Future<void> referralSuggestionsApi() async {
    try {

      referralSuggestionsResponse.value =
          ApiResponse.initial('Initial');

      final res = await UserRepo().referralSuggestionsRepo();

      if (res.isSuccess) {
        // The API returns `data` as a List<dynamic>; assigning it
        // directly to RxList<String> throws a TypeError that gets
        // swallowed by the outer try/catch, leaving the suggestion
        // chips empty. Cast each element explicitly so the list is
        // populated and the Obx sees the new state.
        final raw = res.response?.data['data'];
        referralSuggestions.value = raw is List
            ? raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
            : <String>[];
        referralSuggestionsResponse.value =
            ApiResponse.complete(res.response?.data);

      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
        referralSuggestionsResponse.value =
            ApiResponse.error("${res.message ?? AppStrings.somethingWentWrong.tr}");
      }
    } catch (e) {
      referralSuggestionsResponse.value =
          ApiResponse.error(e.toString());
    }
  }


  Future<void> fetchLocationFromPinCode(String pinCode) async {
    if (pinCode.length != 6) return;

    try {

      locationFromPinCodeResponse.value =
          ApiResponse.initial('Initial');

      final res = await PlaceRepo().fetchLocationFromPinCodeRepo(pinCode: pinCode);


      if (res.isSuccess) {

        locationFromPinCodeResponse.value =
            ApiResponse.complete(res.response?.data);

        final data = res.response?.data as List<dynamic>?;

        // Check if the API successfully found the PIN code
        if (data != null && data.isNotEmpty && data[0]['Status'] == 'Success') {

          // Extract the first Post Office from the list
          final postOffice = data[0]['PostOffice'][0];

          final String state = postOffice['State'] ?? '';
          final String city = postOffice['District'] ?? ''; // 'District' is usually the City name

          // Auto-fill your text fields!
          stateController.text = state;
          cityController.text = city;

          // If you are using Rx variables for your dropdowns instead of controllers:
          // selectedState.value = state;

          print("✅ Found: $city, $state");
        } else {
          print("❌ Invalid PIN Code");
          locationFromPinCodeResponse.value =
              ApiResponse.error("${res.message ?? AppStrings.somethingWentWrong.tr}");
        }
      }
    } catch (e) {
      print("❌ API Error: $e");
      locationFromPinCodeResponse.value =
          ApiResponse.error(e.toString());
    }
  }


}
import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/gst_verify_model.dart';
import 'package:BlueEra/core/api/model/otp_verify_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/guest_res_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/auth/model/username_res_model.dart';
import 'package:BlueEra/features/common/auth/model/version_control_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/auth/views/screens/create_business_account_step_two.dart';
import 'package:BlueEra/features/common/feed/models/block_user_response.dart';
import 'package:BlueEra/widgets/uploading_progressing_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/notifications/one_signal_services.dart';

class AuthController extends GetxController {
  ApiResponse mobileNoOtpSendResponse = ApiResponse.initial('Initial');
  ApiResponse businessCategoryResponse = ApiResponse.initial('Initial');
  ApiResponse professionListingResponse = ApiResponse.initial('Initial');
  ApiResponse otpVerificationResponse = ApiResponse.initial('Initial');
  ApiResponse addUserResponse = ApiResponse.initial('Initial');
  Rx<ApiResponse> gstVerifyResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getUserNameCheckResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> deleteUserAccountResponse =
      ApiResponse.initial('Initial').obs;
  ApiResponse versionControlResponse = ApiResponse.initial('Initial');
  ApiResponse blockUserResponse = ApiResponse.initial('Initial');
  final mobileNumberEditController = TextEditingController(text: '');
  final referralCodeController = TextEditingController();
  final otherNatureOfBusinessTextController = TextEditingController();
  Rx<String> imgPath = "".obs;
  RxString isOtpType = "".obs;
  RxBool isAddUserLoading = false.obs;

  RxInt? selectedDay = 0.obs, selectedMonth = 0.obs, selectedYear = 0.obs;

  ///SEND OTP...
  Future<void> sendOTP() async {
    Map<String, dynamic> requestData = {
      ApiKeys.contact_no: mobileNumberEditController.text,
      ApiKeys.action: AppConstants.REGISTER,
      ApiKeys.type: isOtpType.value,
    };
    try {
      ResponseModel responseModel =
          await AuthRepo().authMobileOtpSendRepo(bodyRequest: requestData);
      logs("responseModel: ${responseModel.statusCode}");
      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.message ?? AppStrings.success);
        Get.offNamed(
          RouteHelper.getOtpPageScreenRoute(),
          arguments: {ApiKeys.argMobileNumber: mobileNumberEditController.text},
        );
        mobileNoOtpSendResponse = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      mobileNoOtpSendResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///VERIFY OTP...
  Future<void> verifyOTP({required String? otp}) async {
    Map<String, dynamic> requestData = {
      ApiKeys.contact_no: mobileNumberEditController.text,
      ApiKeys.otp: otp,
      ApiKeys.device_token: "",
      ApiKeys.one_signal_player_id: "",
    };
    try {
      ResponseModel response =
          await AuthRepo().authMobileOtpVerifyRepo(bodyRequest: requestData);

      if (response.statusCode == 200) {
        final data = response.response?.data[ApiKeys.user];
        if (data == false) {
          // await createGuestAccountUserController(reqData: {
          //   ApiKeys.contact_no: mobileNumberEditController.text,
          //   ApiKeys.account_type: AppConstants.guest
          // });
          Get.offNamed(
            RouteHelper.getSelectAccountScreenRoute(),
            arguments: {
              ApiKeys.argMobileNumber: mobileNumberEditController.text
            },
          );
        } else {
          commonSnackBar(message: response.message ?? AppStrings.success);

          OtpVerifyModel data =
              otpVerifyModelFromJson(jsonEncode(response.response?.data));
          if (data.token != null && (data.token?.isNotEmpty ?? false)) {
            OnesignalService.setOneSignalUserIdentity(
                data.data?.username ?? '');

            await SharedPreferenceUtils.userLoggedIn(
                businesId: data.business != null ? "${data.business?.id}" : "",
                loginUserId_: "${data.data?.id}",
                contactNo: "${data.data?.contactNo}",
                autToken: "${data.token}",
                name: data.data?.accountType?.toUpperCase() ==
                    AppConstants.business
                    ? ""
                    : "${data.data?.name}",
                profileImage: data.data?.accountType?.toUpperCase() ==
                        AppConstants.business
                    ? "${data.business?.logo}"
                    : "${data.data?.profileImage}",
              profession: data.data?.accountType?.toUpperCase() ==
                  AppConstants.business
                  ? ""
                  : "${data.data?.profession}",
            );
            await SharedPreferenceUtils.setSecureValue(
                SharedPreferenceUtils.accountType, data.data?.accountType);

            await getUserLoginData();
            Get.offNamedUntil(
              RouteHelper.getBottomNavigationBarScreenRoute(),
              (route) => false,
            );
          } else {
            commonSnackBar(message: response.message ?? AppStrings.tokenIsNull);
          }
          otpVerificationResponse = ApiResponse.complete(response);
        }
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      otpVerificationResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  ///Add User...
  Future<void> addNewUser({required Map<String, dynamic>? reqData}) async {
    try {
      UploadProgressDialog.show(title: "Creating account...");

      logs("REQ DATA==== ${reqData}");
      ResponseModel response =
          await AuthRepo().authUserRegisterRepo(bodyRequest: reqData);
      if (response.isSuccess) {
        OtpVerifyModel otpVerifyModel =
            otpVerifyModelFromJson(jsonEncode(response.response?.data));

        UploadProgressDialog.update(0.5);

        if (otpVerifyModel.success ?? false) {
          await SharedPreferenceUtils.userLoggedIn(
              businesId: otpVerifyModel.business != null
                  ? "${otpVerifyModel.business?.id}"
                  : "",
              loginUserId_: "${otpVerifyModel.data?.id}",
              contactNo: "${otpVerifyModel.data?.contactNo}",
              autToken: "${otpVerifyModel.token}",
              name: otpVerifyModel.data?.accountType?.toUpperCase() ==
                  AppConstants.business
                  ? ""
                  : "${otpVerifyModel.data?.name}",
                profileImage: otpVerifyModel.data?.accountType?.toUpperCase() ==
                        AppConstants.business
                    ? "${otpVerifyModel.business?.logo}"
                    : "${otpVerifyModel.data?.profileImage}",
              profession: otpVerifyModel.data?.accountType?.toUpperCase() ==
                  AppConstants.business
                  ? ""
                  : "${otpVerifyModel.data?.profession}",
          );
          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.accountType, otpVerifyModel.data?.accountType);

          await getUserLoginData();

          print('closing soon...');
          UploadProgressDialog.update(0.7);

          if (otpVerifyModel.data?.accountType?.toUpperCase() ==
              AppConstants.business) {
            final viewProfileController = Get.put(ViewBusinessDetailsController());
            await viewProfileController.viewBusinessProfile();

            UploadProgressDialog.update(1.0);
            await Future.delayed(const Duration(milliseconds: 300));
            UploadProgressDialog.close();

            Get.offAll(()=> CreateBusinessAccountStepTwo());
          } else {
            print('closed..');
            UploadProgressDialog.update(1.0);
            await Future.delayed(const Duration(milliseconds: 300));
            UploadProgressDialog.close();

            Get.offNamedUntil(
              RouteHelper.getBottomNavigationBarScreenRoute(),
              (route) => false,
            );
          }
          clearAllData();
          commonSnackBar(message: response.message ?? AppStrings.success);
          addUserResponse = ApiResponse.complete(response);

        } else {
          UploadProgressDialog.close();
          commonSnackBar(
              message: otpVerifyModel.message ?? AppStrings.somethingWentWrong);
        }
      } else {
        UploadProgressDialog.close();
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      UploadProgressDialog.close();
      addUserResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  List<CategoryData> businessCategories = [];
  List<SubCategories> businessSubCategoriesList = [];

  Future<void> getAllCategories() async {
    try {
      ResponseModel responseModel =
          await AuthRepo().getBusinessCategoriesRepo();

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        businessCategories = CategoryModel.fromJson(data).data ?? [];
        businessCategoryResponse = ApiResponse.complete(responseModel);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      businessCategoryResponse = ApiResponse.error('error');
      update();
    }
  }

  Rx<GstVerifyModel>? gstVerifyModel = GstVerifyModel().obs;
  RxBool isValidate = false.obs,
      isHaveGstApprove = false.obs,
      hasGstNumber = false.obs;
  final businessNameTextController = TextEditingController();
  final businessOtherCategoryTextController = TextEditingController();
  RxString businessName = "".obs;

  Future<void> getGstVerify({required String? gstNumber}) async {
    try {
      ResponseModel responseModel =
          await AuthRepo().getUserVerifyGstRepo(gstNumber: gstNumber);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        gstVerifyModel?.value = GstVerifyModel.fromJson(data);
        List<String>? parts =
            gstVerifyModel?.value.data?.registrationDate?.split("/");

        selectedDay?.value = int.parse(parts?[0] ?? "");
        selectedMonth?.value = int.parse(parts?[1] ?? "");
        selectedYear?.value = int.parse(parts?[2] ?? "");
        isHaveGstApprove.value = true;
        businessNameTextController.text =
            gstVerifyModel?.value.data?.tradeName ?? "";
        Get.toNamed(RouteHelper.getBusinessAccountRoute());
        gstVerifyResponse.value = ApiResponse.complete(responseModel);
      } else {
        isHaveGstApprove.value = false;

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isHaveGstApprove.value = false;

      gstVerifyResponse.value = ApiResponse.error('error');
    }
  }

  ///CHECK USER NAME....

  /// -1 = none selected
  final selectedIndex = (-1).obs;

  void select(int i) {
    // Single select; tap again to unselect (optional)
    selectedIndex.value = (selectedIndex.value == i) ? -1 : i;
  }

  String? get selectedValue =>
      selectedIndex.value == -1 ? null : userNameList[selectedIndex.value];
  RxBool isShowCheck = true.obs;
  RxList<String> userNameList = <String>[].obs;
  Rx<UsernameResModel> usernameResModel = UsernameResModel().obs;

  Future<void> getCheckUsernameController({required String? value}) async {
    userNameList.clear();
    try {
      ResponseModel responseModel =
          await AuthRepo().getCheckUsernameRepo(userName: value);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        usernameResModel.value = UsernameResModel.fromJson(data);
        if (usernameResModel.value.sampleUsername?.isNotEmpty ?? false)
          userNameList.addAll(usernameResModel.value.sampleUsername ?? []);
        isShowCheck.value = false;

        // commonSnackBar(
        //     message: usernameResModel.value.message ?? "username is available");
        getUserNameCheckResponse.value = ApiResponse.complete(responseModel);
      } else {
        isShowCheck.value = true;

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isShowCheck.value = true;

      getUserNameCheckResponse.value = ApiResponse.error('error');
    }
  }

  ///DELETE USER ACCOUNT
  // Future<void> deleteUserController({required String? value}) async {
  //   try {
  //     ResponseModel responseModel =
  //     await AuthRepo().deleteUserAccountRepo(userName: value);
  //
  //     if (responseModel.isSuccess) {
  //       final data = responseModel.response?.data;
  //       // usernameResModel.value = UsernameResModel.fromJson(data);
  //
  //
  //       commonSnackBar(message: usernameResModel.value.message??"User Account Deleted Successfully");
  //       deleteUserAccountResponse.value = ApiResponse.complete(responseModel);
  //
  //     } else {
  //       deleteUserAccountResponse.value = ApiResponse.error('error');
  //
  //       commonSnackBar(
  //           message: responseModel.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //
  //     deleteUserAccountResponse.value = ApiResponse.error('error');
  //   }
  // }

  ///CLEAR ALL DATA..
  clearAllData() {
    selectedDay?.value = 0;
    selectedMonth?.value = 0;
    selectedYear?.value = 0;
    isValidate.value = false;
    isHaveGstApprove.value = false;
    businessNameTextController.clear();
    mobileNumberEditController.clear();
  }

  /// Force Update
  Future<VersionControlModel?> forceUpdateApi(
      {required String platform, required String currentVersion}) async {
    try {
      Map<String, dynamic> params = {
        ApiKeys.platform: platform,
        ApiKeys.version: currentVersion
      };

      ResponseModel response =
          await AuthRepo().callForceUpdateApi(params: params);

      if (response.isSuccess) {
        versionControlResponse = ApiResponse.complete(response);
        final data = response.response?.data;
        VersionControlModel versionControlModel =
            VersionControlModel.fromJson(data);
        return versionControlModel;
      } else {
        versionControlResponse = ApiResponse.error('error');
        // commonSnackBar(
        //     message: response.message ?? AppStrings.somethingWentWrong);
        return null;
      }
    } catch (e) {
      versionControlResponse = ApiResponse.error('error');
      return null;
    }
  }

  ///USER BLOCK(PARTIAL AND FULL)...
  Future<void> userBlocked(
      {required bool isPartialBlocked, required String otherUserId}) async {
    try {
      Map<String, dynamic> params = {
        ApiKeys.blockedTo: otherUserId,
        ApiKeys.type: isPartialBlocked
            ? BlockedType.partial.label
            : BlockedType.full.label,
        ApiKeys.duration: 0
      };

      final response = await AuthRepo().blockUser(params: params);

      if (response.isSuccess) {
        blockUserResponse = ApiResponse.complete(response);
        BlockUserResponse blockUser =
            BlockUserResponse.fromJson(response.response?.data);
        commonSnackBar(message: blockUser.message, isFromHomeScreen: true);
      } else {
        blockUserResponse = ApiResponse.error('error');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      blockUserResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {}
  }

  List<ProfessionTypeData> professionTypeDataList = [];
  List<SubcategoriesFiledName> subcategoriesFiledNameList = [];

  Future<void> getAllProfessionController() async {
    try {
      professionTypeDataList.clear();
      ResponseModel responseModel = await AuthRepo().getAllProfessionsRepo();

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        professionTypeDataList =
            PersonalProfessionModel.fromJson(data).data ?? [];
        professionListingResponse = ApiResponse.complete(responseModel);
        update();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        professionListingResponse = ApiResponse.error('error');
        update();
      }
    } catch (e) {
      professionListingResponse = ApiResponse.error('error');
      update();
    }
  }

  ///Add User...
  Future<void> createGuestAccountUserController(
      {required Map<String, dynamic> reqData}) async {
    try {
      ResponseModel response =
          await AuthRepo().createGuestAccountRepo(params: reqData);
      if (response.isSuccess) {
        GuestResModel guestResModel =
            guestResModelFromJson(jsonEncode(response.response?.data));
        if (guestResModel.success ?? false) {
          commonSnackBar(message: response.message ?? AppStrings.success);
          await SharedPreferenceUtils.guestUserLoggedIn(
            contactNo: "${guestResModel.data?.contactNo}",
            autToken: "${guestResModel.token}",
            getUserName: "${guestResModel.data?.name}",
          );
          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.accountType, AppConstants.guest);
          await getGuestUserLoginData();
          await Future.delayed(Duration(milliseconds: 350));
          Get.offNamedUntil(
            RouteHelper.getBottomNavigationBarScreenRoute(),
            (route) => false,
          );

          clearAllData();
          addUserResponse = ApiResponse.complete(response);
        } else {
          commonSnackBar(
              message: guestResModel.message ?? AppStrings.somethingWentWrong);
        }
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addUserResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}

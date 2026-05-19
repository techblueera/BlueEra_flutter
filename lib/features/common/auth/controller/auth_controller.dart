import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/gst_verify_model.dart';
import 'package:BlueEra/core/api/model/guest_model_response.dart';
import 'package:BlueEra/core/api/model/otp_verify_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/model/business_category_response_model.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/guest_res_model.dart';
import 'package:BlueEra/features/common/auth/model/individual_field_response_model.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/auth/model/single_business_category_response.dart';
import 'package:BlueEra/features/common/auth/model/username_res_model.dart';
import 'package:BlueEra/features/chat/auth/socket/chat_socket.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/features/common/auth/views/screens/complete_guest_profile_screen.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/common/auth/views/screens/create_account_type_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/view/bottom_navigation_bar_screen.dart';
import 'package:BlueEra/features/common/feed/models/block_user_response.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_service_controller.dart';
import 'package:geocoding/geocoding.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../bottomNavigationBar/controller/bottom_bar_controller.dart';

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
  Rx<ApiResponse> businessSubCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> contentCreatorFieldResponse =
      ApiResponse.initial('Initial').obs;
  ApiResponse blockUserResponse = ApiResponse.initial('Initial');
  final mobileNumberEditController = TextEditingController(text: '');
  final referralCodeController = TextEditingController();
  final otherNatureOfBusinessTextController = TextEditingController();
  final subCategorySpecializationTextController = TextEditingController();
  Rx<String> imgPath = "".obs;
  RxString isOtpType = "".obs;
  RxString errorMessage = "".obs;
  RxString categorySpecializationText = ''.obs;
  RxBool isSearchOpen = false.obs;
  RxInt? selectedDay = 0.obs, selectedMonth = 0.obs, selectedYear = 0.obs;

  RxString selectedParentSlug = AppConstants.individual.obs;
  Rxn<OnboardingCategoryModel> selectedIndividualOnboardingProfile =
      Rxn<OnboardingCategoryModel>();
  Rxn<OnboardingCategoryModel> selectedBusinessOnboardingProfile =
      Rxn<OnboardingCategoryModel>();

  RxBool isAppLoading = false.obs;

  // CategoryData? selectedCategoryData;
  String? selectedCategorySlugId;
  String? selectedCategoryName;
  SubCategories? selectedSubCategoryData;
  BusinessType? selectedTypeOfBusiness;
  NatureOfBusiness? selectedNatureOfBusiness;
  String? selectedNumberOfEmployees;
  String? selectedNumberOfBranch;

  final List<String> employeeRangeOptions = [
    "1–10 Employees",
    "11–50 Employees",
    "51–100 Employees",
    "100+ Employees",
    "200+ Employees",
    "500+ Employees",
    "1000+ Employees",
    "1500+ Employees",
    "2000+ Employees",
    "5000+ Employees",
    "9999+ Employees",
  ];

  final List<String> branchUnitOptions = [
    "Single Branch/Unit",
    "2-5 Branch/Units",
    "5–10 Branch/Units",
    "10+ Branch/Units",
    "15+ Branch/Units",
    "20+ Branch/Units",
    "50+ Branch/Units",
    "100+ Branch/Units",
    "150+ Branch/Units",
    "200+ Branch/Units",
    "500+ Branch/Units",
  ];

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
      // logs("responseModel: ${responseModel.statusCode}");
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
      commonSnackBar(message: e.toString());
    }
  }

  ///VERIFY OTP...
  Future<void> verifyOTP({required String? otp}) async {
    String? token;
    try {
      // Always force-refresh on login so the backend gets the latest FCM
      // token bound to this user. Relying on the cached value caused the
      // previous user's stale token to be re-sent after a 401 auto-logout
      // when the cleanup path hadn't successfully rotated it.
      token = await AppNotificationHandler.refreshFcmToken();
      if (token == null || token.isEmpty) {
        // Refresh failed (GMS unavailable, APNs not ready, etc.) — fall
        // back to whatever is in cache so verifyOTP still sends something.
        token = await SharedPreferenceUtils.getSecureValue(
            SharedPreferenceUtils.notificationDeviceToken);
      }
      print("TOKEN = $token");

      Map<String, dynamic> requestData = {
        ApiKeys.contact_no: mobileNumberEditController.text,
        ApiKeys.otp: otp,
        ApiKeys.device_token: token,
        ApiKeys.one_signal_player_id: "",
      };
      ResponseModel response =
          await AuthRepo().authMobileOtpVerifyRepo(bodyRequest: requestData);

      if (response.statusCode == 200) {
        OtpVerifyModel data =
            otpVerifyModelFromJson(jsonEncode(response.response?.data));

        final dataUser = response.response?.data?[ApiKeys.user] ?? false;

        ///if true user key the user created successfully....
        if (dataUser) {
          commonSnackBar(message: response.message ?? AppStrings.success);

          if (data.token != null && (data.token?.isNotEmpty ?? false)) {
            // OnesignalService.setOneSignalUserIdentity(
            //     data.data?.username ?? '');
            if (data.data?.accountType?.toUpperCase() ==
                AppConstants.business) {
              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.accountType, AppConstants.business);
              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.userBusinessId, data.data?.business);
              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.authToken, data.token);
              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.userLoginMobile, data.data?.contactNo);
              // eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzZXNzaW9uSWQiOiI2OWM3NzE2MGI2OWQ3YzJhMzU5ODkwMWMiLCJfaWQiOnsiX2lkIjoiNjljNzcxNjA0YjAzNjI0ZTBhNTEzYWQ1IiwiaWQiOiI2OWM3NzE2MDRiMDM2MjRlMGE1MTNhZDUiLCJhY2NvdW50X3R5cGUiOiJHVUVTVCIsImNvbnRhY3Rfbm8iOiIwMDEzMzAwMDAwIiwiYnVzaW5lc3NfaWQiOm51bGwsIm5hbWUiOiJHdWVzdDAwMDAiLCJwcm9maWxlX2ltYWdlIjoiIn0sImlhdCI6MTc3NDY3ODM2OCwiZXhwIjoxNzkwMjMwMzY4fQ.BQoIDhS442PXg92LoOLfl7Xi6IX65PanzhKAFI5Bx2A
              await getMobileNo();
              await getUserLoginBusinessId();
              await getUserLoginAccountType();
              await getUserAuthToken();
              // Token is now in `authTokenGlobal` — open the chat socket
              // so incoming-call / chat events flow immediately this
              // session. CallController.onInit skipped the cold-start
              // connect while logged out; this is the first authenticated
              // connect, on which buffered call-event listeners replay.
              unawaited(ChatSocketService().connectToSocket());
              final viewProfileController =
                  getOrPut(() => ViewBusinessDetailsController(), permanent: true);

              await viewProfileController.viewBusinessProfile();
            } else if (data.data?.accountType?.toUpperCase() ==
                AppConstants.individual) {
              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.userLoginMobile, data.data?.contactNo);
              await getMobileNo();

              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.accountType, AppConstants.individual);
              await getUserLoginAccountType();

              await SharedPreferenceUtils.setSecureValue(
                  SharedPreferenceUtils.authToken, data.token);

              await getUserAuthToken();
              // First authenticated connect — see business branch above.
              unawaited(ChatSocketService().connectToSocket());
              final personalController =
                  Get.put(ViewPersonalDetailsController(), permanent: true);
              await personalController.viewPersonalProfile();
            }

            final wasDeletionCancelled = data.accountDeletionCancelled == true;
            Get.offNamedUntil(
              RouteHelper.getBottomNavigationBarScreenRoute(),
              (route) => false,
                arguments: {ApiKeys.initialIndex: 1},

            );

            // Navigator.pushNamedAndRemoveUntil(
            //   context,
            //   RouteHelper.getBottomNavigationBarScreenRoute(),
            //   arguments: {ApiKeys.initialIndex: 3},
            //       (route) => false,
            // );

            if (wasDeletionCancelled) {
              Future.delayed(const Duration(milliseconds: 400), () {
                commonSnackBar(
                  message: AppStrings.accountDeletionCancelledBanner.tr,
                  isFromHomeScreen: true,
                );
              });
            }
          } else {
            commonSnackBar(message: response.message ?? AppStrings.tokenIsNull);
          }
          otpVerificationResponse = ApiResponse.complete(response);
        }

        ///Guest create account but profile create.....
        else if (data.data?.accountType?.toUpperCase() == AppConstants.guest) {
          await SharedPreferenceUtils.guestUserLoggedIn(
            loginUserId_: "${data.data?.id}",
            contactNo: "${data.data?.contactNo}",
            autToken: "${data.token}",
            getUserName: "${data.data?.name ?? data.data?.username}",
            profileImage: data.data?.profileImage ?? '',
          );
          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.accountType, AppConstants.guest);
          await getGuestUserLoginData();
          await Future.delayed(Duration(milliseconds: 350));
          // Get.offAll(() => const ChooseAccountTypeScreen());
          Get.offAll(() => const CreateAccountTypeScreen());
          // Get.toNamed(RouteHelper.getCreateAccountTypeScreenRoute());

          // Get.offNamedUntil(
          //   RouteHelper.getBottomNavigationBarScreenRoute(),
          //   (route) => false,
          // );
        }

        ///GUEST ACCOUNT.....
        else {
          Get.offAll(() => const CompleteGuestProfileScreen());
        }
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        // message:  response.response?.data?[ApiKeys.message]  ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      logs("ERROR ${e}");
      logs("STACK TRACE: $s");
      otpVerificationResponse = ApiResponse.error('error');
      commonSnackBar(message: e.toString());
      // Get.dialog(CustomText(e.toString()));
    }
  }

  Future<void> addIndividualUser(
      {required Map<String, dynamic>? reqData}) async {
    try {
      ResponseModel response = await AuthRepo()
          .updateIndividualAccountUserRepo(bodyRequest: reqData);
      if (response.isSuccess) {
        GuestUserResModel guestUserResModel =
            GuestUserResModel.fromJson(response.response?.data);
        if (guestUserResModel.status ?? false) {
          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.accountType, AppConstants.individual);

          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.authToken, guestUserResModel.token);

          await getUserLoginAccountType();
          await getUserAuthToken();
          // Guest → individual upgrade: token just landed, open the chat
          // socket so call/chat events flow without an app restart.
          unawaited(ChatSocketService().connectToSocket());

          commonSnackBar(message: response.message ?? AppStrings.success);
          final personalController =
              Get.put(ViewPersonalDetailsController(), permanent: true);
          await personalController.viewPersonalProfile();

          final dobJsonString = reqData?[ApiKeys.date_of_birth_Obj];
          final dobMap = jsonDecode(dobJsonString);

          ///FOR PROFESSIONAL....
          if (reqData?['profileType'] == PROFESSIONAL) {
            final controller = getOrPut(() => AiProfessionalsController());

            Map<String, dynamic> data = {
              "name": reqData?['name'],
              "email": reqData?['email'],
              "gender": reqData?['gender'],
              "profileType": reqData?['profileType'],
              "profession": reqData?['profession'],
              "designation": reqData?['designation'],
              "pincode": reqData?['pincode'],
              "address": reqData?['address'],
            };

            await controller.createServiceController(reqParm: data);
          }

          ///FOR SELF_EMPLOYED — create a placeholder earn-service row
          /// with just the minimum required fields. The user fills in
          /// price / service type / description / etc. one by one from
          /// the Service tab's section cards after onboarding.
          if (reqData?['profileType'] == SELF_EMPLOYED) {
            final controller = getOrPut(() => SelfWorkServiceController());
            controller.designation = reqData?['designation'];
            await controller.createMinimalEarnService(
              serviceSubType: 'selfWork',
              designationOverride: reqData?['designation'],
            );
          }

          if (Get.isRegistered<BottomBarController>()) {
            Get.find<BottomBarController>().currentIndex.value = 1;
          }

          // Already on the bottom-nav root — pop any profile-creation
          // screens stacked on top, then push the Add Bio screen on top
          // of bottom nav. Do NOT offAllNamed back to bottom nav:
          // recreating it re-runs meScreens()'s post-frame init and
          // re-opens the "complete profile" sheet on top of this screen.
          Get.until((route) => route.isFirst);
          Get.toNamed(
            RouteHelper.getAddBioViaAiScreenRoute(),
            arguments: {
              ApiKeys.argProfession: reqData?[ApiKeys.profession],
              ApiKeys.argDesignation: reqData?[ApiKeys.designation],
              ApiKeys.argSelectedDay: dobMap[ApiKeys.date],
              ApiKeys.argSelectedMonth: dobMap[ApiKeys.month],
              ApiKeys.argSelectedYear: dobMap[ApiKeys.year]
            },
          );

          clearAllData();
          addUserResponse = ApiResponse.complete(response);
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRPR $e");
      addUserResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  RxBool isAddBusinessUserLoading = false.obs;

  Future<void> addBusinessUser({required Map<String, dynamic>? reqData}) async {
    try {
      isAddBusinessUserLoading.value = true;
      ResponseModel response = await AuthRepo().updateBusinessAccountUserRepo(
          bodyRequest: reqData, showProgress: false);
      if (response.isSuccess) {
        GuestUserResModel guestUserResModel =
            GuestUserResModel.fromJson(response.response?.data);
        if (guestUserResModel.status ?? false) {
          commonSnackBar(message: response.message ?? AppStrings.success);
          // await getUserLoginData();

          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.accountType, AppConstants.business);
          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.userBusinessId,
              guestUserResModel.businessId);
          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.authToken, guestUserResModel.token);

          await getUserLoginBusinessId();
          await getUserLoginAccountType();
          await getUserAuthToken();
          // Guest → business upgrade: token just landed, open the chat
          // socket so call/chat events flow without an app restart.
          unawaited(ChatSocketService().connectToSocket());
          final viewProfileController =
              getOrPut(() => ViewBusinessDetailsController(), permanent: true);
          await viewProfileController.viewBusinessProfile();

          logs(
              " ApiKeys.category_Of_Business = ${reqData![ApiKeys.type_of_business]}");
          logs(
              " ApiKeys.ApiKeys.sub_category_Of_Business = ${reqData[ApiKeys.sub_category_Of_Business]}");
          logs(
              " ApiKeys.category_Of_Business = ${reqData[ApiKeys.category_Of_Business]}");
          String typeOfBusiness =
              reqData[ApiKeys.type_of_business].toString().toUpperCase();
          Map<String, dynamic> reqBody = {
            ApiKeys.business_name: reqData[ApiKeys.business_name],
            ApiKeys.business_location: reqData[ApiKeys.business_location],
            ApiKeys.type_of_business: reqData[ApiKeys.type_of_business],
            ApiKeys.nature_of_business: reqData[ApiKeys.nature_of_business],
            ApiKeys.date_of_incorporation:
                reqData[ApiKeys.date_of_incorporation],
            ApiKeys.category_Of_Business: reqData[ApiKeys.category_Of_Business],
            ApiKeys.sub_category_Of_Business:
                reqData[ApiKeys.sub_category_Of_Business],
            ApiKeys.number_of_Employees: reqData[ApiKeys.number_of_Employees],
            ApiKeys.number_of_branch: reqData[ApiKeys.number_of_branch],
          };

          ///FOR SCHOOL....
          if (typeOfBusiness == BusinessType.Siksha.name.toUpperCase()) {
            final controller = getOrPut(() => SchoolController());
            await controller.createSchoolController(reqData: reqData);
          }

          ///FOR LAB....

          else if (reqData[ApiKeys.category_Of_Business]
                  .toString()
                  .toUpperCase() ==
              AppConstants.DIAGNOSTIC_TESTING_CENTERSWith_.toUpperCase()) {
            final controller = getOrPut(() => LabServiceAiController());
            await controller.createLabServiceController(reqData: reqBody);
          } else if ((reqData[ApiKeys.category_Of_Business]
                      .toString()
                      .toUpperCase() ==
                  AppConstants.HOSPITALS_SECTOR.toUpperCase()) ||
              (reqData[ApiKeys.category_Of_Business].toString().toUpperCase() ==
                  "ALTERNATIVE_WELLNESS") ||
              (reqData[ApiKeys.category_Of_Business].toString().toUpperCase() ==
                  "CLINIC_DOCTORS")) {
            final controller = getOrPut(() => HospitalServiceAiController());
            await controller.createHospitalServiceController(reqData: reqBody);
          } else if ((reqData[ApiKeys.category_Of_Business]
                      .toString()
                      .toUpperCase() ==
                  "SUPPORT_SERVICES") ||
              (typeOfBusiness == BusinessType.Service.name.toUpperCase())) {
            final controller = getOrPut(() => BusinessProfileFullController());
            reqBody['profileName'] = reqData[ApiKeys.business_name];
            await controller.createOtherProfileController(reqParm: reqBody);
          } else if ((typeOfBusiness == "FINANCE") ||
              (typeOfBusiness == "BANKING_SECTOR")) {
            final controller = getOrPut(() => BusinessProfileFullController());
            reqBody['profileName'] = reqData[ApiKeys.business_name];
            reqBody['type'] = "finance";
            reqBody['sub_type'] = typeOfBusiness;

            await controller.createOtherProfileController(reqParm: reqBody);
          } else if ((typeOfBusiness ==
              BusinessType.Motel.name.toUpperCase())) {
            final controller = getOrPut(() => HotelServiceController());

            final locationMap = jsonDecode(reqData[ApiKeys.business_location]);
            final lat = locationMap[ApiKeys.lat];
            final lon = locationMap[ApiKeys.lon];

            // Reverse-geocode lat/lon to fill city, state, pincode.
            String city = '';
            String state = '';
            String pincode = '';
            final double? latD =
                lat is num ? lat.toDouble() : double.tryParse(lat.toString());
            final double? lonD =
                lon is num ? lon.toDouble() : double.tryParse(lon.toString());
            if (latD != null && lonD != null) {
              try {
                final placemarks = await placemarkFromCoordinates(latD, lonD);
                if (placemarks.isNotEmpty) {
                  final p = placemarks.first;
                  city = p.locality?.isNotEmpty == true
                      ? p.locality!
                      : (p.subAdministrativeArea ?? '');
                  state = p.administrativeArea ?? '';
                  pincode = p.postalCode ?? '';
                }
              } catch (e) {
                log('Motel reverse-geocode failed: $e');
              }
            }

            final reqDataParm = {
              ApiKeys.businessId: businessId,
              "name": reqData[ApiKeys.business_name],
              "description": "",
              "website": "",
              "address": {"city": city, "state": state, "pincode": pincode},
              "location": {
                "name": "",
                "type": "Point",
                "coordinates": [lat, lon]

                // "coordinates": [reqData[ApiKeys.business_location]['lat'],reqData[ApiKeys.business_location]['lon'],]
              },
              "bus_station_location": {
                "name": "",
                "type": "Point",
                "coordinates": []
              },
              "category": businessCategoryGlobal
            };
            controller.createHotelServiceController(reqParm: reqDataParm);
          }

          if (Get.isRegistered<BottomBarController>()) {
            Get.find<BottomBarController>().currentIndex.value = 1;
          }

          // Already on the bottom-nav root — pop any business-creation
          // screens stacked on top, then push step 2 on top of bottom nav.
          // Do NOT offAllNamed back to bottom nav: recreating it re-runs
          // resolveBusinessScreen()'s post-frame init and re-opens the
          // "complete profile" sheet underneath / on top of step 2.
          Get.until((route) => route.isFirst);
          Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepTwoRoute());

          addUserResponse = ApiResponse.complete(response);
          clearAllData();
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRPR $e");
      addUserResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isAddBusinessUserLoading.value = false;
    }
  }

  Rx<GstVerifyModel>? gstVerifyModel = GstVerifyModel().obs;
  RxBool isValidate = false.obs,
      isHaveGstApprove = false.obs,
      hasGstNumber = false.obs;
  RxBool isGstVerifyLoading = false.obs;
  final businessNameTextController = TextEditingController();
  final businessOtherCategoryTextController = TextEditingController();
  RxString businessName = "".obs;

  Future<void> getGstVerify({required String? gstNumber}) async {
    try {
      isGstVerifyLoading.value = true;
      gstVerifyResponse.value = ApiResponse.loading('loading');

      ResponseModel responseModel =
          await AuthRepo().getUserVerifyGstRepo(gstNumber: gstNumber);

      if (responseModel.isSuccess) {
        final data = responseModel.response?.data;
        gstVerifyModel?.value = GstVerifyModel.fromJson(data);

        if (gstVerifyModel?.value.isVerified == true) {
          List<String>? parts =
              gstVerifyModel?.value.data?.registrationDate?.split("/");

          selectedDay?.value = int.tryParse(parts?[0] ?? "") ?? 0;
          selectedMonth?.value = int.tryParse(parts?[1] ?? "") ?? 0;
          selectedYear?.value = int.tryParse(parts?[2] ?? "") ?? 0;
          isHaveGstApprove.value = true;
          businessNameTextController.text =
              gstVerifyModel?.value.data?.tradeName ?? "";
          businessName.value = gstVerifyModel?.value.data?.tradeName ?? "";

          gstVerifyResponse.value = ApiResponse.complete(responseModel);

          await _updateGstBusinessDetails(gstNumber: gstNumber);
        } else {
          isHaveGstApprove.value = false;
          gstVerifyResponse.value = ApiResponse.error(
              responseModel.message ?? AppStrings.somethingWentWrong);
          commonSnackBar(
              message: responseModel.message ?? AppStrings.somethingWentWrong);
        }
      } else {
        isHaveGstApprove.value = false;
        gstVerifyResponse.value = ApiResponse.error(
            responseModel.message ?? AppStrings.somethingWentWrong);
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isHaveGstApprove.value = false;
      gstVerifyResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isGstVerifyLoading.value = false;
    }
  }

  Future<void> _updateGstBusinessDetails({required String? gstNumber}) async {
    try {
      final data = gstVerifyModel?.value.data;
      final List<String>? parts = data?.registrationDate?.split("/");

      final Map<String, dynamic> body = {
        ApiKeys.gstNo: gstNumber ?? data?.gstin ?? "",
        if ((data?.tradeName ?? "").isNotEmpty)
          ApiKeys.businessName: data?.tradeName,
        if (parts != null && parts.length == 3)
          ApiKeys.date_of_incorporation: {
            ApiKeys.date: int.tryParse(parts[0]) ?? 0,
            ApiKeys.month: int.tryParse(parts[1]) ?? 0,
            ApiKeys.year: int.tryParse(parts[2]) ?? 0,
          },
        if (selectedTypeOfBusiness != null)
          ApiKeys.type_of_business: selectedTypeOfBusiness?.name,
        if (selectedNatureOfBusiness != null)
          ApiKeys.Nature_of_Business: selectedNatureOfBusiness?.name,
        if ((selectedCategorySlugId ?? "").isNotEmpty)
          ApiKeys.category_Of_Business: selectedCategorySlugId,
      };
      logs("bodyRequest for gst ==== ${body}");
      final ResponseModel response =
          await AuthRepo().authBusinessUserRegisterRepo(bodyRequest: body);

      if (response.isSuccess) {
        Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepOneRoute());
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("updateGstBusinessDetails ERROR: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
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
    subCategorySpecializationTextController.clear();
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

  RxBool isCreateGuestAccountLoading = false.obs;

  ///Add User...
  Future<void> createGuestAccountUserController(
      {required Map<String, dynamic> reqData}) async {
    try {
      isCreateGuestAccountLoading.value = true;
      final imagePath = reqData[ApiKeys.profile_image];
      if (imagePath is String && imagePath.isNotEmpty) {
        final image = await multiPartImage(imagePath: imagePath);
        if (image != null) {
          reqData[ApiKeys.profile_image] = image;
        } else {
          reqData.remove(ApiKeys.profile_image);
        }
      }
      ResponseModel response =
          await AuthRepo().createGuestAccountRepo(params: reqData);
      if (response.isSuccess) {
        GuestResModel guestResModel =
            guestResModelFromJson(jsonEncode(response.response?.data));
        if (guestResModel.success ?? false) {
          commonSnackBar(message: response.message ?? AppStrings.success);
          await SharedPreferenceUtils.guestUserLoggedIn(
            loginUserId_: "${guestResModel.data?.id}",
            contactNo: "${guestResModel.data?.contactNo}",
            autToken: "${guestResModel.token}",
            getUserName: "${guestResModel.data?.name}",
            profileImage: guestResModel.data?.profileImage ?? '',
          );
          await SharedPreferenceUtils.setSecureValue(
              SharedPreferenceUtils.accountType, AppConstants.guest);
          await getGuestUserLoginData();
          await Future.delayed(Duration(milliseconds: 350));
          Get.offAll(() => const BottomNavigationBarScreen(initialIndex: 1));
          // Get.offAll(() => const ChooseAccountTypeScreen());

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
    } finally {
      isCreateGuestAccountLoading.value = false;
    }
  }

  RxBool isBusinessSubCategoriesLoading = false.obs;
  List<SubCategories> businessSubCategoriesList = [];
  Rxn<String> subCategoryErrorMessage = Rxn<String>();

  Future<void> fetchBusinessSubCategories(
      {required String categorySlugId}) async {
    try {
      isBusinessSubCategoriesLoading.value = true;
      businessSubCategoriesList.clear();
      subCategoryErrorMessage.value = null;

      final response =
          await AuthRepo().getBusinessSubCategoriesRepo(tagId: categorySlugId);

      if (!response.isSuccess) {
        subCategoryErrorMessage.value = response.message;
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      final businessCategoryModel =
          SingleBusinessCategoryModelResponse.fromJson(jsonData);
      businessSubCategoriesList = businessCategoryModel.subCategories ?? [];

      businessSubCategoryResponse.value = ApiResponse.complete(response);
    } catch (e) {
      subCategoryErrorMessage.value = e.toString();
      businessSubCategoryResponse.value = ApiResponse.error('error');
    } finally {
      isBusinessSubCategoriesLoading.value = false;
    }
  }

  RxBool isBusinessCategoriesLoading = false.obs;
  List<BusinessCategory> businessCategoriesList = [];
  Rxn<String> categoryErrorMessage = Rxn<String>();

  Future<void> fetchBusinessCategoriesByType(
      {required BusinessType businessTpe}) async {
    try {
      isBusinessCategoriesLoading.value = true;
      businessCategoriesList.clear();
      categoryErrorMessage.value = null;

      final response = await AuthRepo()
          .fetchBusinessCategoriesByTypeRepo(businessType: businessTpe.name);

      if (!response.isSuccess) {
        categoryErrorMessage.value = response.message;
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      final businessCategoryResponseModel =
          BusinessCategoryResponseModel.fromJson(jsonData);
      businessCategoriesList =
          businessCategoryResponseModel.businessCategory ?? [];

      businessCategoryResponse = ApiResponse.complete(response);
    } catch (e) {
      categoryErrorMessage.value = e.toString();
      businessCategoryResponse = ApiResponse.error('error');
    } finally {
      isBusinessCategoriesLoading.value = false;
    }
  }

  RxBool isIndividualFieldLoading = false.obs;
  RxList<IndividualFields> arrIndividualFields = <IndividualFields>[].obs;
  RxList<SubCategories> arrIndividualSubCategories = <SubCategories>[].obs;

  Future<void> fetchIndividualFields({required String tagId}) async {
    try {
      isIndividualFieldLoading.value = true;
      arrIndividualFields.clear();
      arrIndividualSubCategories.clear();

      final response = await AuthRepo().getIndividualFieldsRepo(
        tagId: tagId,
      );

      if (response.isSuccess) {
        contentCreatorFieldResponse.value = ApiResponse.complete(response);
        final individualFieldsResponseModel =
            IndividualFieldsResponseModel.fromJson(response.response?.data);
        arrIndividualFields.value =
            individualFieldsResponseModel.data?.fields ?? [];
      } else {
        contentCreatorFieldResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      contentCreatorFieldResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isIndividualFieldLoading.value = false;
    }
  }

  /// Business and Personal Category

  /// True until we've populated the onboarding category buckets from
  /// either Hive or the network. Discover (and any other consumer) shows
  /// a shimmer / spinner while this is true, then swaps to the real cards.
  RxBool isInitialCategoriesLoading = true.obs;

  /// Cache-first loader for the master onboarding lists.
  Future<void> loadCategoriesCacheFirstThenRefresh() async {
    final hive = HiveServices();

    final cachedBusiness = hive.getAllCategories();
    final cachedProfessions = hive.getAllProfessions();

    final hasCachedBusiness = cachedBusiness != null && cachedBusiness.isNotEmpty;
    final hasCachedProfessions =
        cachedProfessions != null && cachedProfessions.isNotEmpty;

    if (hasCachedBusiness) {
      updateBusinessCategoriesFromApi(cachedBusiness);
    }
    if (hasCachedProfessions) {
      updateIndividualCategoriesFromApi(cachedProfessions);
    }

    // If we have any cache, render immediately and let the network
    // refresh happen silently in the background.
    if (hasCachedBusiness || hasCachedProfessions) {
      isInitialCategoriesLoading.value = false;
    }

    // Silent refresh — `_getAllBusinessCategories` / `_getAllIndividualProfession`
    // both write through to Hive on success and rebuild the in-memory
    // buckets. Consumers that are already on screen during this refresh
    // keep showing the cached snapshot until the next natural rebuild
    // (tab change, navigation pop, pull-to-refresh) — that's acceptable
    // because category data changes rarely. Fresh data is always visible
    // on the next launch via the cache hit. These two methods are private
    // so external callers must always go through this cache-first entry
    // point — single source of truth, no path that bypasses Hive.
    await Future.wait<void>([
      _getAllBusinessCategories(),
      _getAllIndividualProfession(),
    ]);

    // First-launch path: no cache existed, so the shimmer was still
    // visible. Drop it now that the network has filled the buckets.
    if (isInitialCategoriesLoading.value) {
      isInitialCategoriesLoading.value = false;
    }
  }

  List<ProfessionTypeData> individualOnboardingSocialProfileList = [];
  List<ProfessionTypeData> individualOnboardingGigWorkList = [];
  List<ProfessionTypeData> individualOnboardingSkillWorkList = [];
  List<ProfessionTypeData> individualOnboardingConsultationList = [];

  /// Derived flat master list of profession types — concatenates the four
  /// onboarding buckets (which are the source of truth). Exposed as a
  /// getter (not a stored field) so there's no second copy of the data
  /// that can drift from the buckets, and so profession state stays
  /// symmetric with business state, which has always lived as buckets
  /// only. Callers that previously read the stored `professionTypeDataList`
  /// field (profession-picker dialogs, `.isEmpty` guards in profile setup
  /// screens) keep working unchanged.
  List<ProfessionTypeData> get professionTypeDataList => [
        ...individualOnboardingSocialProfileList,
        ...individualOnboardingGigWorkList,
        ...individualOnboardingSkillWorkList,
        ...individualOnboardingConsultationList,
      ];

  /// Network-level fetch for the master profession list. Private — callers
  /// outside this controller MUST go through `loadCategoriesCacheFirstThenRefresh`
  /// so they can't accidentally bypass the Hive cache.
  Future<void> _getAllIndividualProfession() async {
    try {
      ResponseModel responseModel = await AuthRepo().getAllProfessionsRepo();

      if (responseModel.isSuccess) {
        professionListingResponse = ApiResponse.complete(responseModel);
        final data = responseModel.response?.data;
        // Local var only — there is no stored master list field. The
        // bucketing call below is the source of truth, and the
        // `professionTypeDataList` getter on this controller derives a
        // flat list from those buckets when consumers need one.
        final professions =
            PersonalProfessionModel.fromJson(data).data ?? [];
        // Persist BEFORE bucketing so each item's `individualProfileType`
        // enum is still null at serialize time — bucketing sets that
        // enum, and enums don't round-trip through jsonEncode.
        await HiveServices().saveProfessionList(professions);
        updateIndividualCategoriesFromApi(professions);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        professionListingResponse = ApiResponse.error('error');
      }
    } catch (e) {
      professionListingResponse = ApiResponse.error('error');
    }
  }

  void updateIndividualCategoriesFromApi(
      List<ProfessionTypeData> categoryData) {
    individualOnboardingSocialProfileList.clear();
    individualOnboardingGigWorkList.clear();
    individualOnboardingSkillWorkList.clear();
    individualOnboardingConsultationList.clear();

    for (var apiCategory in categoryData) {
      final String apiType = apiCategory.profileType ?? "";
      // log('apitype-- $apiType');

      switch (apiType) {
        case 'Social Profile':
          apiCategory.individualProfileType =
              IndividualProfileType.SOCIAL_PROFILE;
          individualOnboardingSocialProfileList.add(apiCategory);
          break;
        case 'GigWork':
          apiCategory.individualProfileType = IndividualProfileType.GIG_WORKER;
          individualOnboardingGigWorkList.add(apiCategory);
          break;
        case 'Self Employed':
          apiCategory.individualProfileType =
              IndividualProfileType.SELF_EMPLOYED;
          individualOnboardingSkillWorkList.add(apiCategory);
          break;
        case 'Professional':
          apiCategory.individualProfileType =
              IndividualProfileType.PROFESSIONAL;
          individualOnboardingConsultationList.add(apiCategory);
          break;
      }
    }
  }

  RxBool isAllBusinessCategoriesLoading = false.obs;
  List<CategoryData> businessOnboardingServicesCategories = [];
  List<CategoryData> businessOnboardingProductsCategories = [];
  List<CategoryData> businessOnboardingGroceriesCategories = [];
  List<CategoryData> businessOnboardingFoodsCategories = [];
  List<CategoryData> businessOnboardingManufacturingCategories = [];
  List<CategoryData> businessOnboardingAutomotiveServicesCategories = [];
  List<CategoryData> businessOnboardingHealthcareSectorsCategories = [];
  List<CategoryData> businessOnboardingHospitalityStayCategories = [];
  List<CategoryData> businessOnboardingEducationTrainingCategories = [];
  List<CategoryData> businessOnboardingFinancialSectorsCategories = [];

  /// Network-level fetch for the master business-category list. Private —
  /// callers outside this controller MUST go through
  /// `loadCategoriesCacheFirstThenRefresh` so they can't accidentally
  /// bypass the Hive cache.
  Future<void> _getAllBusinessCategories() async {
    try {
      isAllBusinessCategoriesLoading.value = true;

      final response = await AuthRepo().getBusinessCategoriesRepo();

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      List<CategoryData> businessCategories =
          CategoryModel.fromJson(jsonData).data ?? [];
      await HiveServices().saveCategoryList(businessCategories);
      updateBusinessCategoriesFromApi(businessCategories);
      businessCategoryResponse = ApiResponse.complete(response);
    } catch (e) {
      businessCategoryResponse = ApiResponse.error('error');
    } finally {
      isAllBusinessCategoriesLoading.value = false;
    }
  }

  void updateBusinessCategoriesFromApi(List<CategoryData> categoryData) {
    businessOnboardingServicesCategories.clear();
    businessOnboardingProductsCategories.clear();
    businessOnboardingGroceriesCategories.clear();
    businessOnboardingFoodsCategories.clear();
    businessOnboardingManufacturingCategories.clear();
    businessOnboardingAutomotiveServicesCategories.clear();
    businessOnboardingHealthcareSectorsCategories.clear();
    businessOnboardingHospitalityStayCategories.clear();
    businessOnboardingEducationTrainingCategories.clear();
    businessOnboardingFinancialSectorsCategories.clear();

    for (var apiCategory in categoryData) {
      final String apiType = apiCategory.type ?? "";
      // log('apitype-- $apiType');

      switch (apiType) {
        case 'Service':
          apiCategory.businessType = BusinessType.Service;
          businessOnboardingServicesCategories.add(apiCategory);
          break;
        case 'Product':
          apiCategory.businessType = BusinessType.Product;
          businessOnboardingProductsCategories.add(apiCategory);
          break;
        case 'Grocery':
          apiCategory.businessType = BusinessType.Grocery;
          businessOnboardingGroceriesCategories.add(apiCategory);
          break;
        case 'Food':
          apiCategory.businessType = BusinessType.Food;
          businessOnboardingFoodsCategories.add(apiCategory);
          break;
        case 'Manufacturing':
          apiCategory.businessType = BusinessType.Manufacturing;
          businessOnboardingManufacturingCategories.add(apiCategory);
          break;
        case 'Automotive':
          apiCategory.businessType = BusinessType.Automotive;
          businessOnboardingAutomotiveServicesCategories.add(apiCategory);
          break;
        case 'Healthcare':
          apiCategory.businessType = BusinessType.Healthcare;
          businessOnboardingHealthcareSectorsCategories.add(apiCategory);
          break;
        case 'Motel':
          apiCategory.businessType = BusinessType.Motel;
          businessOnboardingHospitalityStayCategories.add(apiCategory);
          break;
        case 'Siksha':
          apiCategory.businessType = BusinessType.Siksha;
          businessOnboardingEducationTrainingCategories.add(apiCategory);
          break;
        case 'Finance':
          apiCategory.businessType = BusinessType.Finance;
          businessOnboardingFinancialSectorsCategories.add(apiCategory);
          break;
      }
    }
  }

  // void debugPrintBusinessCategories() {
  //   if (kDebugMode) {
  //     final categoryGroups = {
  //       'Services': businessOnboardingServicesCategories,
  //       'Products': businessOnboardingProductsCategories,
  //       'Groceries': businessOnboardingGroceriesCategories,
  //       'Foods': businessOnboardingFoodsCategories,
  //       'Manufacturing': businessOnboardingManufacturingCategories,
  //       'Automotive': businessOnboardingAutomotiveServicesCategories,
  //       'Healthcare': businessOnboardingHealthcareSectorsCategories,
  //       'Hospitality': businessOnboardingHospitalityStayCategories,
  //       'Education': businessOnboardingEducationTrainingCategories,
  //       'Finance': businessOnboardingFinancialSectorsCategories,
  //     };
  //
  //     log('=== BUSINESS CATEGORIES DEBUG START ===', name: 'CategorySync');
  //
  //     categoryGroups.forEach((name, list) {
  //       if (list.isNotEmpty) {
  //         log('--- $name (${list.length} items) ---', name: 'CategorySync');
  //         for (var item in list) {
  //           // Replace 'name' with whatever property identifies your CategoryData
  //           log('  ID: ${item.id} | Title: ${item.name} | Tag Id: ${item.tagId}',
  //               name: 'CategorySync');
  //         }
  //       } else {
  //         log('--- $name (Empty) ---', name: 'CategorySync');
  //       }
  //     });
  //
  //     log('=== BUSINESS CATEGORIES DEBUG END ===', name: 'CategorySync');
  //   }
  // }

}

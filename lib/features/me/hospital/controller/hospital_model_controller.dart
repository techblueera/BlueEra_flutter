import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/me/hospital/model/docters_details_model.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../core/services/location/location_service.dart';
import '../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../medical/model/medical_lab_details.dart';
import '../../medical/repo/medical_repo.dart';
import '../model/get_beds_details_model.dart';
import '../model/get_contact_us_details_model.dart';
import '../model/hospital_main_page_model.dart';
import '../model/hospital_model_class.dart';
import '../view/category/opd_out_patient_page.dart';

enum DepartmentType {
  OPD,
  IPD,
  Emergency,
  Diagnostic,
  MedicalStore,
  Other,
}

class HospitalModelController extends GetxController {
  //Text Controllers
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final hospitalNameTextController = TextEditingController();
  final hospitalAddressTextController = TextEditingController();
  final hospitalLinkTextController = TextEditingController();
  final nameController = TextEditingController();
  final websiteController = TextEditingController();
  final admissionNoController = TextEditingController();
  final principalNoController = TextEditingController();
  final specializationController = TextEditingController();
  final totalBedsController = TextEditingController();
  final bedsDescriptionController = TextEditingController();
  final qualificationController = TextEditingController();
  final availabilityController = TextEditingController();
  final feesController = TextEditingController();

  //Api Response Models
  Rx<ApiResponse> getHospitalMainResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getHospitalSubResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> hospitalAiDataResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> hospitalAiDataSaveResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getDoctorsResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getBedsResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getContactUsResponse = ApiResponse.initial('Initial').obs;

  //Repo
  final medicalRepo = MedicalRepo();

  //Rx Values
  RxList<DoctorsDetailsModel> staffList = <DoctorsDetailsModel>[].obs;
  RxList<BedDetailsModel> bedsList = <BedDetailsModel>[].obs;
  Rx<HospitalPreviewResponse> hospitalData = HospitalPreviewResponse().obs;
  Rx<HospitalContactUsDetailsModel> hospitalContactUsDetailsModel = HospitalContactUsDetailsModel().obs;
  Rx<MainHospitalDepartmentResponse> hospitalMainPageData =
      MainHospitalDepartmentResponse().obs;
  RxList<Department> hospitalSubCate = <Department>[].obs;
  RxString hospitalCurrentAddress = ''.obs;
  RxString addDepartmentTypeValue = '${DepartmentType.OPD.name}'.obs;
  RxBool isActive = true.obs;
  RxBool addDoctorLoading = false.obs;
  RxBool isAiBtnLoading = false.obs;
  RxBool addDepartmentLoading = false.obs;
  RxBool saveAiDetailsLoading = false.obs;
  RxBool editFeeSubmitLoading = false.obs;

  //Other
  Map<String, dynamic> aiRawDetails = {};
  String? prePhotoImage;
  Rx<File?> pickedDoctorImage = Rx<File?>(null);
  Rx<DateTime?> fromDate = Rx<DateTime?>(null);
  Rx<DateTime?> toDate = Rx<DateTime?>(null);

  void setLeaveDatesFromResponse({
    required String leaveFrom,
    required String leaveTo,
  }) {
    fromDate.value = DateUtils.dateOnly(
      DateTime.parse(leaveFrom).toLocal(),
    );

    toDate.value = DateUtils.dateOnly(
      DateTime.parse(leaveTo).toLocal(),
    );
  }

  int get leaveDays {
    if (fromDate.value == null || toDate.value == null) return 0;
    return toDate.value!.difference(fromDate.value!).inDays + 1;
  }

  String get formattedFrom => fromDate.value == null
      ? ''
      : DateFormat('dd/MM/yyyy').format(fromDate.value!);

  String get formattedTo => toDate.value == null
      ? ''
      : DateFormat('dd/MM/yyyy').format(toDate.value!);

  Future<void> pickDate(
    BuildContext context,
    bool isFrom,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      if (isFrom) {
        fromDate.value = picked;
        if (toDate.value != null && picked.isAfter(toDate.value!)) {
          toDate.value = null;
        }
      } else {
        toDate.value = picked;
      }
    }
  }

  Future<void> pickDoctorImage(File? image) async {
    if (image != null) {
      pickedDoctorImage.value = File(image.path);
    }
  }

  void setContactControllers(ContactUs? contact) {
    phoneController.text = contact?.phone ?? '';
    emergencyController.text = contact?.emergencyPhone ?? '';
    emailController.text = contact?.email ?? '';
    addressController.text = contact?.address ?? '';
  }

  void clearStaffForm() {
    nameController.clear();
    specializationController.clear();
    qualificationController.clear();
    availabilityController.clear();
    bedsDescriptionController.clear();
    totalBedsController.clear();
    feesController.clear();
    emailController.clear();
    admissionNoController.clear();
    principalNoController.clear();
    addressController.clear();
    websiteController.clear();
  }

  Future<void> fetchAddressByLatLng(
      {required double lat, required double lng}) async {
    String? address = await LocationService.getAddressUsingLatLng(
        latitude: lat, longitude: lng);
    hospitalCurrentAddress.value = address;
  }

  Future<void> fetchHospitalCategoryData() async {
    ResponseModel response = await medicalRepo.fetchHospitalMainCateApi();
    if (response.isSuccess) {
      hospitalMainPageData.value =
          MainHospitalDepartmentResponse.fromJson(response.response?.data);
      getHospitalMainResponse.value =
          ApiResponse.complete(hospitalMainPageData);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getHospitalMainResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> addHospitalDepartmentApi(
      {String? preType, String? categoryId}) async {
    addDepartmentLoading.value = true;
    Map<String, dynamic> params = {
      if (preType != null) ApiKeys.parentId: categoryId,
      ApiKeys.name: nameController.text,
      ApiKeys.type: preType ?? addDepartmentTypeValue.value,
      ApiKeys.icon: "",
      ApiKeys.isActive: isActive.value
    };
    ResponseModel response = await medicalRepo.addHospitalDepartmentApi(params);
    if (response.isSuccess) {
      nameController.clear();
      addDepartmentTypeValue.value = '${DepartmentType.OPD.name}';
      addDepartmentLoading.value = false;
      isActive.value = true;
      if (preType != null) {
        await fetchHospitalSubCategoryData(categoryId ?? '');
      } else {
        await fetchHospitalCategoryData();
      }
    } else {
      addDepartmentLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  //Doctor
  Future<void> getAllDoctors(String id) async {
    getDoctorsResponse.value = ApiResponse.initial("Initial");
    ResponseModel response = await medicalRepo.getAllDoctors(id);
    if (response.isSuccess) {
      final responseList = response.data as List;
      staffList.value =
          responseList.map((e) => DoctorsDetailsModel.fromJson(e)).toList();
      getDoctorsResponse.value = ApiResponse.complete(staffList);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getDoctorsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> addDoctors({String? departmentId}) async {
    addDoctorLoading.value = true;
    String? publicUrlOfPhoto = await getPreSignUrl();
    final params = {
      ApiKeys.departmentId: departmentId,
      ApiKeys.name: nameController.text.trim(),
      ApiKeys.specialization: specializationController.text.trim(),
      ApiKeys.qualification: qualificationController.text.trim(),
      ApiKeys.photo: publicUrlOfPhoto,
      ApiKeys.availability: availabilityController.text.trim(),
      ApiKeys.fees: int.tryParse(feesController.text) ?? 0,
    };
    ResponseModel response = await medicalRepo.addDoctors(params);
    if (response.isSuccess) {
      addDoctorLoading.value = false;
      await getAllDoctors(departmentId ?? '');
      clearStaffForm();
    } else {
      addDoctorLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> updateLeaveStatusToDoctor(String id) async {
    final params = {
      ApiKeys.leaveFrom: DateFormat('yyyy-MM-dd').format(fromDate.value!),
      ApiKeys.leaveTo: DateFormat('yyyy-MM-dd').format(toDate.value!),
    };

    ResponseModel response = await medicalRepo.updateLeaveStatus(id, params);
    if (response.isSuccess) {
      DoctorsDetailsModel model = DoctorsDetailsModel.fromJson(response.data);
      final index = staffList.indexWhere((e) => e.id == id);

      if (index != -1) {
        staffList[index] = staffList[index].copyWith(
          leaveFrom: model.leaveFrom,
          leaveTo: model.leaveTo,
          isOnLeave: model.isOnLeave,
        );
        staffList.refresh();
      }
      Get.back();
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> updateDoctorsFeesDetails(String id, bool isEditFee) async {
    editFeeSubmitLoading.value = true;
    Map<String, dynamic> params = {
      if (isEditFee)
        ApiKeys.fees: feesController.text.trim()
      else
        ApiKeys.availability: availabilityController.text.trim()
    };

    ResponseModel response =
        await medicalRepo.updateDoctorsFeesDetails(id, params);
    if (response.isSuccess) {
      DoctorsDetailsModel model = DoctorsDetailsModel.fromJson(response.data);
      final index = staffList.indexWhere((e) => e.id == id);
      if (index != -1) {
        staffList[index] = staffList[index]
            .copyWith(fees: model.fees, availability: model.availability);
        staffList.refresh();
      }
      editFeeSubmitLoading.value = false;

      Get.back();
    } else {
      editFeeSubmitLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> editDoctorDetails(String id) async {
    addDoctorLoading.value = true;

    Object? publicUrlOfPhoto = pickedDoctorImage.value != null
        ? await getPreSignUrl()
        : prePhotoImage ?? '';

    Map<String, dynamic> params = {
      ApiKeys.name: nameController.text.trim(),
      ApiKeys.specialization: specializationController.text.trim(),
      ApiKeys.qualification: qualificationController.text.trim(),
      ApiKeys.photo: publicUrlOfPhoto,
      ApiKeys.availability: availabilityController.text.trim(),
      ApiKeys.fees: int.tryParse(feesController.text) ?? 0,
    };
    ResponseModel response =
        await medicalRepo.updateDoctorsFeesDetails(id, params);
    if (response.isSuccess) {
      DoctorsDetailsModel model = DoctorsDetailsModel.fromJson(response.data);
      final index = staffList.indexWhere((e) => e.id == id);
      if (index != -1) {
        staffList[index] = staffList[index].copyWith(
            fees: model.fees,
            availability: model.availability,
            createdAt: model.createdAt,
            name: model.name,
            photo: model.photo,
            qualification: model.qualification,
            specialization: model.specialization,
            updatedAt: model.updatedAt);
        staffList.refresh();
      }
      addDoctorLoading.value = false;

      Get.back();
    } else {
      addDoctorLoading.value = false;

      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> deleteDoctorDetails(String id) async {
    ResponseModel response = await medicalRepo.deleteDoctor(id);
    if (response.isSuccess) {
      final index = staffList.indexWhere((e) => e.id == id);
      if (index != -1) {
        staffList.removeAt(index);
        staffList.refresh();
      }
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  //Ward
  Future<void> getAllBeds(String id) async {
    getBedsResponse.value = ApiResponse.initial("Initial");
    ResponseModel response = await medicalRepo.getAllBeds(id);
    if (response.isSuccess) {
      final responseList = response.data as List;
      bedsList.value =
          responseList.map((e) => BedDetailsModel.fromJson(e)).toList();
      getBedsResponse.value = ApiResponse.complete(bedsList);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getBedsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> addNewBedsDetails({String? departmentId}) async {
    addDoctorLoading.value = true;
    String? publicUrlOfPhoto = await getPreSignUrl();
    final params = {
      ApiKeys.wardId: departmentId,
      ApiKeys.name: nameController.text,
      ApiKeys.bedNumber: totalBedsController.text,
      ApiKeys.image: publicUrlOfPhoto,
      ApiKeys.description: bedsDescriptionController.text,
      ApiKeys.fees: int.tryParse(feesController.text) ?? 0,
    };
    ResponseModel response = await medicalRepo.addNewBeds(params);
    if (response.isSuccess) {
      addDoctorLoading.value = false;
      BedDetailsModel model =BedDetailsModel.fromJson(response.data);
      bedsList.add(model);
      bedsList.refresh();
      clearStaffForm();
    } else {
      addDoctorLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> editBedsDetails({String? departmentId,required String bedId}) async {
    addDoctorLoading.value = true;
    Object? publicUrlOfPhoto = pickedDoctorImage.value != null
        ? await getPreSignUrl()
        : prePhotoImage ?? '';
    final params = {
      ApiKeys.wardId: departmentId,
      ApiKeys.name: nameController.text,
      ApiKeys.bedNumber: totalBedsController.text,
      ApiKeys.image: publicUrlOfPhoto,
      ApiKeys.description: bedsDescriptionController.text,
      ApiKeys.fees: int.tryParse(feesController.text) ?? 0,
    };
    ResponseModel response = await medicalRepo.editNewBeds(params,bedId??'');
    if (response.isSuccess) {
      addDoctorLoading.value = false;
      getAllBeds(departmentId??'');
      bedsList.refresh();
      clearStaffForm();
    } else {
      addDoctorLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> deleteBedsDetails({required BedDetailsModel model}) async {

    ResponseModel response = await medicalRepo.deleteBeds(model.id??'');
    if (response.isSuccess) {
      bedsList.remove(model);
      bedsList.refresh();
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> addContactUsDetails() async {
    addDoctorLoading.value = true;
    final params = {
      ApiKeys.hospitalName: nameController.text,
      ApiKeys.website: websiteController.text,
      ApiKeys.address: addressController.text,
      ApiKeys.admissionPhone: admissionNoController.text,
      ApiKeys.principalPhone: principalNoController.text,
      ApiKeys.email: emailController.text
    };
    ResponseModel response = await medicalRepo.addHospitalContactUsApi(params);
    if (response.isSuccess) {
      addDoctorLoading.value = false;
      hospitalContactUsDetailsModel.value=HospitalContactUsDetailsModel.fromJson(response.data);
      getContactUsResponse.value = ApiResponse.complete(hospitalContactUsDetailsModel.value);
    } else {
      addDoctorLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> editHospitalNameDetails() async {

    final params = {
      ApiKeys.hospitalName: nameController.text,
    };
    ResponseModel response = await medicalRepo.editHospitalContactUsApi(params);
    if (response.isSuccess) {
      getContactUsDetails();
      getContactUsResponse.value = ApiResponse.complete(hospitalContactUsDetailsModel.value);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> editHospitalAdmissionCellDetails() async {

    final params = {
      ApiKeys.admissionPhone: admissionNoController.text,
    };
    ResponseModel response = await medicalRepo.editHospitalContactUsApi(params);
    if (response.isSuccess) {
      getContactUsDetails();
      getContactUsResponse.value = ApiResponse.complete(hospitalContactUsDetailsModel.value);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> editHospitalPrincipalCellDetails() async {

    final params = {
      ApiKeys.principalPhone: principalNoController.text,
    };
    ResponseModel response = await medicalRepo.editHospitalContactUsApi(params);
    if (response.isSuccess) {
      getContactUsDetails();
      getContactUsResponse.value = ApiResponse.complete(hospitalContactUsDetailsModel.value);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> editHospitalEmailDetails() async {

    final params = {
      ApiKeys.email: emailController.text
    };
    ResponseModel response = await medicalRepo.editHospitalContactUsApi(params);
    if (response.isSuccess) {
      getContactUsDetails();
      getContactUsResponse.value = ApiResponse.complete(hospitalContactUsDetailsModel.value);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> getContactUsDetails() async {
    ResponseModel response = await medicalRepo.getHospitalContactDetails();
    if (response.isSuccess) {
      hospitalContactUsDetailsModel.value=HospitalContactUsDetailsModel.fromJson(response.data);
      getContactUsResponse.value = ApiResponse.complete(hospitalContactUsDetailsModel.value);
    } else {
      addDoctorLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getContactUsResponse.value = ApiResponse.error(response.message);

    }
  }

  // Future<void> updateLeaveStatusToDoctor(String id) async {
  //   final params = {
  //     ApiKeys.leaveFrom: DateFormat('yyyy-MM-dd').format(fromDate.value!),
  //     ApiKeys.leaveTo: DateFormat('yyyy-MM-dd').format(toDate.value!),
  //   };
  //
  //   ResponseModel response = await medicalRepo.updateLeaveStatus(id, params);
  //   if (response.isSuccess) {
  //     DoctorsDetailsModel model = DoctorsDetailsModel.fromJson(response.data);
  //     final index = staffList.indexWhere((e) => e.id == id);
  //
  //     if (index != -1) {
  //       staffList[index] = staffList[index].copyWith(
  //         leaveFrom: model.leaveFrom,
  //         leaveTo: model.leaveTo,
  //         isOnLeave: model.isOnLeave,
  //       );
  //       staffList.refresh();
  //     }
  //     Get.back();
  //   } else {
  //     commonSnackBar(message: AppStrings.somethingWentWrong);
  //   }
  // }
  //
  // Future<void> updateDoctorsFeesDetails(String id, bool isEditFee) async {
  //   editFeeSubmitLoading.value = true;
  //   Map<String, dynamic> params = {
  //     if (isEditFee)
  //       ApiKeys.fees: feesController.text.trim()
  //     else
  //       ApiKeys.availability: availabilityController.text.trim()
  //   };
  //
  //   ResponseModel response =
  //   await medicalRepo.updateDoctorsFeesDetails(id, params);
  //   if (response.isSuccess) {
  //     DoctorsDetailsModel model = DoctorsDetailsModel.fromJson(response.data);
  //     final index = staffList.indexWhere((e) => e.id == id);
  //     if (index != -1) {
  //       staffList[index] = staffList[index]
  //           .copyWith(fees: model.fees, availability: model.availability);
  //       staffList.refresh();
  //     }
  //     editFeeSubmitLoading.value = false;
  //
  //     Get.back();
  //   } else {
  //     editFeeSubmitLoading.value = false;
  //     commonSnackBar(message: AppStrings.somethingWentWrong);
  //   }
  // }
  //
  // Future<void> editDoctorDetails(String id) async {
  //   addDoctorLoading.value = true;
  //
  //   Object? publicUrlOfPhoto = pickedDoctorImage.value != null
  //       ? await getPreSignUrl()
  //       : prePhotoImage ?? '';
  //
  //   Map<String, dynamic> params = {
  //     ApiKeys.name: nameController.text.trim(),
  //     ApiKeys.specialization: specializationController.text.trim(),
  //     ApiKeys.qualification: qualificationController.text.trim(),
  //     ApiKeys.photo: publicUrlOfPhoto,
  //     ApiKeys.availability: availabilityController.text.trim(),
  //     ApiKeys.fees: int.tryParse(feesController.text) ?? 0,
  //   };
  //   ResponseModel response =
  //   await medicalRepo.updateDoctorsFeesDetails(id, params);
  //   if (response.isSuccess) {
  //     DoctorsDetailsModel model = DoctorsDetailsModel.fromJson(response.data);
  //     final index = staffList.indexWhere((e) => e.id == id);
  //     if (index != -1) {
  //       staffList[index] = staffList[index].copyWith(
  //           fees: model.fees,
  //           availability: model.availability,
  //           createdAt: model.createdAt,
  //           name: model.name,
  //           photo: model.photo,
  //           qualification: model.qualification,
  //           specialization: model.specialization,
  //           updatedAt: model.updatedAt);
  //       staffList.refresh();
  //     }
  //     addDoctorLoading.value = false;
  //
  //     Get.back();
  //   } else {
  //     addDoctorLoading.value = false;
  //
  //     commonSnackBar(message: AppStrings.somethingWentWrong);
  //   }
  // }
  //
  // Future<void> deleteDoctorDetails(String id) async {
  //   ResponseModel response = await medicalRepo.deleteDoctor(id);
  //   if (response.isSuccess) {
  //     final index = staffList.indexWhere((e) => e.id == id);
  //     if (index != -1) {
  //       staffList.removeAt(index);
  //       staffList.refresh();
  //     }
  //   } else {
  //     commonSnackBar(message: AppStrings.somethingWentWrong);
  //   }
  // }
  Future<void> fetchHospitalSubCategoryData(String categoryTopic) async {
    getHospitalSubResponse.value = ApiResponse.initial("Initial");
    ResponseModel response =
        await medicalRepo.fetchHospitalSubCateApi(categoryTopic);
    if (response.isSuccess) {
      List rawList = response.response?.data['data']['subDepartments'];
      hospitalSubCate.value =
          rawList.map((e) => Department.fromJson(e)).toList();
      getHospitalSubResponse.value = ApiResponse.complete(hospitalSubCate);
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getHospitalSubResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  List<MedicalLabDataListModel> updateCategoryStatusById({
    required List<MedicalLabDataListModel> list,
    required String id,
    required bool isActive,
  }) {
    return list.map((item) {
      if (item.id == id) {
        return item.copyWith(isActive: isActive);
      }

      if (item.children != null && item.children!.isNotEmpty) {
        return item.copyWith(
          children: updateCategoryStatusById(
            list: item.children!,
            id: id,
            isActive: isActive,
          ),
        );
      }

      return item;
    }).toList();
  }

  Future<void> updateEnableStatus(
    String categoryTopicId,
    Map<String, dynamic> params,
  ) async {
    ResponseModel response =
        await medicalRepo.enableHotelServiceStatusApi(categoryTopicId, params);
    if (response.isSuccess) {
      final bool updatedStatus = params['isActive'];
      //
      // hospitalCategoryDataList.value = updateCategoryStatusById(
      //   list: hospitalCategoryDataList,
      //   id: categoryTopicId,
      //   isActive: updatedStatus,
      // );

      // reassign API response for UI

      commonSnackBar(message: response.response?.statusMessage ?? '');
    } else {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> fetchHospitalViaAi() async {
    Map<String, dynamic> params = {
      ApiKeys.name: hospitalNameTextController.text,
      ApiKeys.address: hospitalAddressTextController.text,
      ApiKeys.url: hospitalLinkTextController.text
    };
    isAiBtnLoading.value = true;
    ResponseModel response = await medicalRepo.getHospitalFromAi(params);
    if (response.isSuccess) {
      aiRawDetails = response.response?.data;
      hospitalData.value =
          HospitalPreviewResponse.fromJson(response.response?.data);
      Get.back();
      isAiBtnLoading.value = false;
      hospitalAiDataResponse.value = ApiResponse.complete(hospitalData.value);
    } else {
      isAiBtnLoading.value = false;
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
      hospitalAiDataResponse.value = ApiResponse.error("Error");
    }
  }

  Future<void> saveAiHospitalDetails() async {
    Map<String, dynamic> params = {"data": aiRawDetails['data']};
    saveAiDetailsLoading.value = true;
    ResponseModel response = await medicalRepo.saveAiDetailsOfHospital(params);
    if (response.isSuccess) {
      hospitalAiDataSaveResponse.value =
          ApiResponse.complete(response.response?.data);
      saveAiDetailsLoading.value = false;
    } else {
      isAiBtnLoading.value = false;
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
      hospitalAiDataSaveResponse.value = ApiResponse.error("Error");
      saveAiDetailsLoading.value = false;
    }
  }

  Future<String?> getPreSignUrl() async {
    File? selectedFiles = pickedDoctorImage.value;
    String? fileNames;
    String? fileTypes;

    Map<String, String?> fileInfo = getFileInfo(selectedFiles ?? File(""));
    fileNames = fileInfo['fileName'];
    fileTypes = fileInfo['mimeType'];

    final uploadParams = {
      ApiKeys.fileName: fileNames,
      ApiKeys.fileType: fileTypes,
    };

    saveAiDetailsLoading.value = true;
    ResponseModel response =
        await medicalRepo.getHealthAndServiceImageUpload(uploadParams);
    if (response.isSuccess) {
      //{uploadUrl: https://be-hospital-bkt.s3.ap-
      // south-1.amazonaws.com/uploads/1768589161576-66
      // 12fd23-b448-46ab-9b95-086bf8a402ea.png?X-Amz-Algorithm=AWS4
      // -HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-C
      // redential=AKIAXQIQALRC6IAIRZXD%2F20260116%2Fap-south-1%2Fs
      // 3%2Faws4_request&X-Amz-Date=20260116T184601Z&X-Amz-Expires=
      // 1800&X-Amz-Signature=a87c5175f28422942435fcd1a5f6917a25daf0d33
      // 2c6449991d08aa9da5ab2fc&X-Amz-SignedHeaders=host&x-amz-acl=public-read&x-amz-checksum-c
      // rc32=AAAAAA%3D%3D&x-amz-sdk-checksum-algorithm=CRC32&x-id=PutObject, publicUrl: https://be-hospital-bkt.s3.ap-south-1.amazonaws.com/uploads%2F1768589161576-6612fd23-b448-46ab-9b95-086bf8a402ea.png, fileKey: uploads/1768589161576-6612fd23-b448-46ab-9b95-086bf8a402ea.png}
      await uploadFileToS3(
          file: pickedDoctorImage.value ?? File(''),
          fileType: fileTypes ?? '',
          preSignedUrl: response.response?.data['uploadUrl']);
      return response.response?.data['publicUrl'];
    } else {
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    }
    return null;
  }

  Future<void> uploadFileToS3(
      {required File file,
      required String fileType,
      required String preSignedUrl}) async {
    try {
      ResponseModel? response = await medicalRepo.uploadVideoToS3(
          onProgress: (double progress) {
            // VideoUploadProgress.value = (progress * 100).toStringAsFixed(2);
          },
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl);
      if (response?.isSuccess ?? false) {
      } else {
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  String findDepartmentName(String title) {
    return (title.toLowerCase().contains('opd'))
        ? DepartmentType.OPD.name
        : (title.toLowerCase().contains('ipd'))
            ? DepartmentType.IPD.name
            : '';
  }
}

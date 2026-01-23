
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class MedicalRepo extends BaseService {
  Future<ResponseModel> fetchMedicalCategoryData(String endPoint) async {
    final response = await ApiBaseHelper().getHTTP(
        getMedicalCategoryApi(endPoint),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> fetchMedicalAdminProduct(String endPoint) async {
    final response = await ApiBaseHelper().getHTTP(
        getMedicalAdminProduct(endPoint),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> enableHotelServiceStatusApi(String categoryId,Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().patchHTTP(
        enableHotelServiceStatus(categoryId),
        params: params,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getHospitalFromAi(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        fetchHospitalFromAi,
        params: params,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> saveAiDetailsOfHospital(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        saveHospitalAiDetails,
        params: params,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getHealthAndServiceImageUpload(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        healthAndServiceImageUpload,
        params: params,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel> fetchHospitalDetailsAPi() async {
    final response = await ApiBaseHelper().getHTTP(
        fetchHospitalDetails,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> fetchHospitalMainCateApi() async {
    final response = await ApiBaseHelper().getHTTP(
        fetchHospitalMainCate,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> fetchHospitalSubCateApi(String id) async {
    final response = await ApiBaseHelper().getHTTP(
        fetchHospitalSubCate(id),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> fetchHospitalIpdWards() async {
    final response = await ApiBaseHelper().getHTTP(
        getHospitalWards,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> editHospitalIpdWards(String id,Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
        editHospitalWards(id),
        showProgress: false,
   params: params,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> deleteHospitalIpdWards(String id) async {
    final response = await ApiBaseHelper().deleteHTTP(
        editHospitalWards(id),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addHospitalDepartmentApi(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        addHospitalDepartment,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addDoctors(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        addDoctorsApi,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addCoverPhoto(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        addCoverImage,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  } Future<ResponseModel> addLogoImageHospital(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        addLogoImage,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addBuildGalleryHospital(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        addBuildGallery,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addNewBeds(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        addBedsApi,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addNewWard(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        getHospitalWards,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  } Future<ResponseModel> editNewBeds(Map<String,dynamic> params,String bedId) async {
    final response = await ApiBaseHelper().putHTTP(
        params: params,
        editBedDetails(bedId),
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> deleteBeds(String bedId) async {
    final response = await ApiBaseHelper().deleteHTTP(
        deleteBedDetails(bedId),
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addHospitalContactUsApi(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().postHTTP(
        params: params,
        addHospitalContactUs,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> editHospitalContactUsApi(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
        params: params,
        addHospitalContactUs,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }  Future<ResponseModel> getHospitalContactDetails() async {
    final response = await ApiBaseHelper().getHTTP(
        addHospitalContactUs,
        showProgress: true,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }

  Future<ResponseModel?> uploadVideoToS3({required Function(double progress) onProgress, required File file, required String fileType, required String preSignedUrl}) async {
    final response = await ApiBaseHelper().uploadVideoToS3(
      preSignedUrl,
      file: file,
      fileType: fileType,
      showProgress: false,
      onProgress: onProgress,
    );
    return response;
  }

  Future<ResponseModel> getAllDoctors(String id) async {
    final response = await ApiBaseHelper().getHTTP(
        fetchDoctorsByDepartment(id),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getAllBeds(String id) async {
    final response = await ApiBaseHelper().getHTTP(
        fetchBedsByDepartment(id),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getHospitalHomeDetailsApi() async {
    final response = await ApiBaseHelper().getHTTP(
        getHospitalHomeDetails,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updateLeaveStatus(String id,Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
      params: params,
        updateDoctorsLeave(id),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addAboutUsDetailsApi(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
      params: params,
        addAboutUsDetails,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> getAboutUsDetailsApi() async {
    final response = await ApiBaseHelper().getHTTP(
        addAboutUsDetails,
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> updateDoctorsFeesDetails(String id,Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
      params: params,
        updateDoctorsFees(id),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> deleteDoctor(String id) async {
    final response = await ApiBaseHelper().deleteHTTP(
        deleteDoctorApi(id),
        showProgress: false,
   onError: (error) {}, onSuccess: (data) {});
    return response;
  }

}

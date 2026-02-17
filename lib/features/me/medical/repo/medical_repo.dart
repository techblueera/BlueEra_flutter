
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class MedicalRepo extends BaseService {
  Future<ResponseModel> fetchMedicalCategoryData() async {
    final response = await ApiBaseHelper().getHTTP(
        getMedicalCategoryApi,
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
  }Future<ResponseModel> MedicalAddProduct(Map Params) async {
    final response = await ApiBaseHelper().postHTTP(
        postMedicalAddProduct,
        params: Params,
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
  Future<ResponseModel> getHealthAndServiceImageUpload(Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().getHTTP(
        healthAndServiceImageUpload,
        params: params,
        showProgress: false,
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



  Future<ResponseModel> getProductVarientbyId(String id) async {
    final response = await ApiBaseHelper().getHTTP(
        getProductVarient(id),
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> addProductVarientbyId(Map Params) async {
    final response = await ApiBaseHelper().postHTTP(
        addProductVarient,
        params: Params,
        showProgress: false,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> editProductVarients(String id,Map<String,dynamic> params) async {
    final response = await ApiBaseHelper().putHTTP(
        putProductVarient(id),
        showProgress: false,
        params: params,
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  Future<ResponseModel> fetchNearestHospitalsRepo({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      'health-service/api/hp/hospitals/nearest',
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> fetchNearestPharmaciesRepo({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      'health-service/api/ms/nearest',
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}

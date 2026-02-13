import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class LabServiceRepo extends BaseService {
  ///GET AI LAB SERVICE DETAILS...
  Future<ResponseModel> aiLabFetchDetailsRepo(
      {required Map<String, dynamic> reqBody}) async {
    final response = await ApiBaseHelper().postHTTP(aiLabsService,
        params: reqBody, onError: (error) {}, onSuccess: (data) {});
    return response;
  }
  /// LIST: Laboratory Profiles (paginated)
  Future<ResponseModel> listLaboratoryProfiles({
    required int page,
    required int limit,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      "lab-service/laboratory-profiles?page=$page&limit=$limit",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  // GET: Fetch property photos
  Future<ResponseModel> getOtherServicePhotosRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      labServiceGallery,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Upload/Add a new photo
  Future<ResponseModel> addOtherServicePhotosRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      labServiceGallery,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Remove a specific photo
  Future<ResponseModel> deleteOtherServicePhotosRepo({required String imgID,required Map<String,dynamic> reqBody}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$labServiceGallery/$imgID/images",
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }



  // POST: Create a new contact
  Future<ResponseModel> addSocialContactRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      labServiceContactUs,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> createLabServiceRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      labServiceProcessResponse,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getSocialContactByIdRepo(
      ) async {
    final response = await ApiBaseHelper().getHTTP(
      "${labServiceContactUs}/laboratory/$labIDGlobal",
      onError: (error) {},
      showProgress: true,
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> getLabFullDetailsByIdRepo(
      ) async {
    final response = await ApiBaseHelper().getHTTP(
      "${labFullDetails}",
      onError: (error) {},
      showProgress: true,
      onSuccess: (data) {},
    );
    return response;
  }
}

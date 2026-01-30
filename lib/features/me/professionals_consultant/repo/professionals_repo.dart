import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class ProfessionalsRepo extends BaseService {
  Future<dynamic> createAiProfessionalsRepo() async {
    return await ApiBaseHelper().postHTTP(
      aiProfessionals,
      params: {},
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  ///GET FULL PROFILE VIA USER ID...
  Future<dynamic> getByUserIdProfessionalsRepo() async {
    return await ApiBaseHelper().getHTTP(
      professionalsFull,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> createProfessionalsRepo({required dynamic bodyREQ}) async {
    return await ApiBaseHelper().putHTTP(
      professionalsUpdate,
      params: bodyREQ,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> addProfessionalCertificateRepo(
      {required Map<String, dynamic> bodyREQ}) async {
    return await ApiBaseHelper().postHTTP(
      professionalsCertificate,
      params: bodyREQ,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateProfessionalCertificateRepo(
      {required String id, required Map<String, dynamic> bodyREQ}) async {
    return await ApiBaseHelper().putHTTP(
      "$professionalsCertificate/$id",
      params: bodyREQ,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteProfessionalCertificateRepo({
    required String id,
  }) async {
    return await ApiBaseHelper().deleteHTTP(
      "$professionalsCertificate/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getProfessionalByIdRepo(
     ) async {
    final response = await ApiBaseHelper().getHTTP(
      "${professionalsContactUsById}$userId/contact",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // POST: Create a new contact
  Future<ResponseModel> addProfessionalContactRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      professionalsContactUs,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }


  Future<dynamic> updateTimingRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "${professionalsTiming}/timings",
      params: {"schedule":body},
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }


  Future<ResponseModel> getTimingRepo() async {
    return await ApiBaseHelper().getHTTP(
      "${professionalsTiming}/${userId}/timings",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // POST: Upload/Add a new photo
  Future<ResponseModel> addProfessionalsServicePhotosRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "${professionalsTiming}/gallery",
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  // GET: Fetch property photos
  Future<ResponseModel> getProfessionalsServicePhotosRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      "${professionalsTiming}/$userId/gallery",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  // DELETE: Remove a specific photo
  Future<ResponseModel> deleteProfessionalsServicePhotosRepo({required String imgID,}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$professionalsTiming/gallery",
      params: {"key":imgID},
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}

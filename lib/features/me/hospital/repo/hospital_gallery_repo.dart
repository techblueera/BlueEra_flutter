import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HospitalGalleryRepo extends BaseService{

  // GET: Fetch property photos
  Future<ResponseModel> getHospitalPropertyPhotosRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      hospitalGetAllPhotos,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  // DELETE: Remove a specific photo
  Future<ResponseModel> deleteHospitalPropertyPhotosRepo({required Map<String,dynamic> reqBODY,required String id}) async {
    final response = await ApiBaseHelper().patchHTTP(
      "$hospitalRemovePhotos$id/remove-image",params: reqBODY,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  // POST: Upload/Add a new photo
  Future<ResponseModel> addHospitalPropertyPhotosRepo({
    required Map<String, dynamic> reqBody,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      hospitalPhotos,
      params: reqBody,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
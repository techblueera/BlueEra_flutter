
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/add_place_req_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:dio/dio.dart';

class AddPlaceRepo extends BaseService {
  Future<ResponseModel> fetchCategories() async {
    final response = await ApiBaseHelper().getHTTP(
      placeCategory,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> fetchPlaceList({required double lat,required double lng}) async {
    final response = await ApiBaseHelper().getHTTP(
      getPlaceByLat(lat,lng),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> fetchPlaceDetails({required String placeId}) async {
    final response = await ApiBaseHelper().getHTTP(
    getPlaceById(placeId),
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }
  Future<ResponseModel> addPlacePost({
    required AddPlaceReqModel placeReq,
  }) async {
    try {
      FormData formData = FormData();
      // Add media files
      for (int i = 0; i < placeReq.photoPath.length; i++) {
        String fileName = placeReq.photoPath[i].split('/').last;
        formData.files.add(
          MapEntry(
            ApiKeys.photos,
            await MultipartFile.fromFile(
              placeReq.photoPath[i],
              filename: fileName,
            ),
          ),
        );
      }

      ///REQ...
      formData.fields.add(MapEntry(ApiKeys.name, placeReq.name));
      if (placeReq.latitude.isNotEmpty && placeReq.longitude.isNotEmpty) {
        formData.fields.add(MapEntry(ApiKeys.latitude, placeReq.latitude));
        formData.fields.add(MapEntry(ApiKeys.longitude, placeReq.longitude));
      }
      // Add category IDs to the form data
      formData.fields
          .add(MapEntry(ApiKeys.categories, placeReq.category.join(",")));
      formData.fields.add(MapEntry(ApiKeys.address, placeReq.address));
      if (placeReq.isCommercial ?? false)
        formData.fields.add(
            MapEntry(ApiKeys.isCommercial, placeReq.isCommercial.toString()));

      if (placeReq.shortDescription?.isNotEmpty ?? false)
        formData.fields.add(MapEntry(
            ApiKeys.shortDescription, placeReq.shortDescription ?? ""));
      if (placeReq.phone?.isNotEmpty ?? false)
        formData.fields.add(MapEntry(ApiKeys.phone, placeReq.phone ?? ""));
      if (placeReq.email?.isNotEmpty ?? false)
        formData.fields.add(MapEntry(ApiKeys.email, placeReq.email ?? ""));
      if (placeReq.visitingHours?.isNotEmpty ?? false)
        formData.fields
            .add(MapEntry(ApiKeys.visitingHours, placeReq.visitingHours ?? ""));
      final response = await ApiBaseHelper().postMultiImage(addPlace,
          params: formData, isArrayReq: true, isMultipart: true);
      return response;
    } catch (e) {
      logs("ERROR ${e.toString()}");
      rethrow;
    }
  }
}

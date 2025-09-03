
import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:dio/dio.dart';

class TravelRepo extends BaseService {
  Future<ResponseModel> travelCreatePost(
      {Map<String, dynamic>? reqParma}) async {
    final response = await ApiBaseHelper().postHTTP(
      travelServiceJourney,
      params: reqParma,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> travelEndJourney({required String? journeyId}) async {
    final response = await ApiBaseHelper().patchHTTP(
      "${travelServiceJourney}/${journeyId}/end",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> journeyStatusPost() async {
    final response = await ApiBaseHelper().getHTTP(
      journeyStatus,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> journeyDetails({required String? journeyId}) async {
    final response = await ApiBaseHelper().getHTTP(
      "${travelJourneyPost}/$journeyId",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> updateTravelJourneyPost({
    FormData? reqParma,
  }) async {
    logs("REQ JOURNEY ${reqParma?.fields}");
    final response = await ApiBaseHelper().postMultiImage(
      travelJourneyPost, // Using the endpoint specified in requirements
      params: reqParma,
      isMultipart: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}

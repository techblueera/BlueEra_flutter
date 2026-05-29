import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class PropertyRepo extends BaseService {
  Future<ResponseModel> createProperty(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      properties,
      params: body,
      showProgress: false,
      isMultipart: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getProperties() async {
    return await ApiBaseHelper().getHTTP(
      properties,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getPropertyById(String id) async {
    return await ApiBaseHelper().getHTTP(
      propertyById(id),
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getPropertyStats() async {
    return await ApiBaseHelper().getHTTP(
      propertyStats,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> updateProperty(
      String id, Map<String, dynamic> body,
      {bool isMultipart = false}) async {
    return await ApiBaseHelper().putHTTP(
      propertyById(id),
      params: body,
      showProgress: false,
      isMultipart: isMultipart,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> getFilteredProperties(
      String listingType, String propertyType) async {
    return await ApiBaseHelper().getHTTP(
      propertiesByFilter(listingType, propertyType),
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> deleteProperty(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      propertyById(id),
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<ResponseModel> discoverProperties(
      Map<String, dynamic> queryParams) async {
    return await ApiBaseHelper().getHTTP(
      properties,
      params: queryParams,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  /// Submits a rating (+ optional comment) for a property. Body shape
  /// mirrors the user/business rating endpoints: `{rating, comment}`.
  Future<ResponseModel> rateProperty(
      String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      propertyRatings(id),
      params: body,
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }
}

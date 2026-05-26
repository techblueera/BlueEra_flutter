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

  Future<ResponseModel> getFilteredProperties(
      String listingType, String propertyType) async {
    return await ApiBaseHelper().getHTTP(
      propertiesByFilter(listingType, propertyType),
      showProgress: false,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }
}

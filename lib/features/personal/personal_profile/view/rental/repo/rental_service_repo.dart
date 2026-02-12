import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class RentalServiceRepo extends BaseService{

  /// ADD RENTAL SERVICE...
  Future<ResponseModel> addRentalServiceRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      rentalService,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// UPDATE RENTAL SERVICE...
  Future<ResponseModel> updateRentalServiceRepo({
    required String rentalId,
    required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().putHTTP(
      updateRentalService(rentalId),
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET HOME DESCRIPTION VIA AI...
  Future<ResponseModel> generateHomeDescriptionRepo({required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      generateHomeDescription,
      isMultipart: true,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// GET RENTAL SERVICES
  Future<ResponseModel> getRentalService({required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      rentalService,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// DELETE RENTAL SERVICES
  Future<ResponseModel> deleteRentalServiceRepo({required String rentalId}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      deleteRentalService(rentalId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// UPLOAD RENTAL IMAGES
  Future<ResponseModel> uploadRentalImagesRepo({
    required String rentalId,
    required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().patchHTTP(
      uploadRentalImages(rentalId),
      params: params,
      isMultipart: true,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

}
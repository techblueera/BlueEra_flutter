import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// `user-service/addresses` CRUD.
///
/// Every route sits behind the JWT guard and is scoped to the token's user on
/// the server, so no request here sends a userId — the Dio interceptor in
/// [ApiBaseHelper] attaches `Authorization: Bearer …` and a 401 triggers the
/// global logout.
class AddressRepo extends BaseService {
  /// `GET /addresses` — the caller's own addresses.
  Future<ResponseModel> getAddresses({bool showProgress = false}) async {
    return await ApiBaseHelper().getHTTP(
      getAddressApi,
      showProgress: showProgress,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// `GET /addresses/:id` — one address.
  Future<ResponseModel> getAddress(String addressId,
      {bool showProgress = false}) async {
    return await ApiBaseHelper().getHTTP(
      addressById(addressId),
      showProgress: showProgress,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// `POST /addresses` — create.
  Future<ResponseModel> createAddress(Map<String, dynamic> params) async {
    return await ApiBaseHelper().postHTTP(
      getAddressApi,
      params: params,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// `PUT /addresses/:id` — partial update; only the keys sent are changed.
  Future<ResponseModel> updateAddress(
      String addressId, Map<String, dynamic> params) async {
    return await ApiBaseHelper().putHTTP(
      addressById(addressId),
      params: params,
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }

  /// `DELETE /addresses/:id`.
  Future<ResponseModel> deleteAddress(String addressId) async {
    return await ApiBaseHelper().deleteHTTP(
      addressById(addressId),
      showProgress: true,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }
}

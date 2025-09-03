import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class PaymentRepo extends BaseService {
  // Method FOR ADD ACCOUNT
  Future<ResponseModel> postAddAccount({dynamic params}) async {
    final response = await ApiBaseHelper().postHTTP(
      addAccountApi,
      params: params,
      isMultipart: false,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }

// Method FOR GET ACCOUNT
  Future<ResponseModel> getAddAccountApi() async {
    final response = await ApiBaseHelper().getHTTP(
      getAccountApi,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

// UPDATE ACCOUNT DETAILS Method
  Future<ResponseModel> updateAccount({
    required String Id,
    dynamic params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      // "$updateAccountIdApi/$userId",
      updateAccountIdApi + Id,
      params: params,
      onError: (error) {
        print("Update user failed: $error");
      },
      onSuccess: (res) {
        print("User updated: ${res.data}");
      },
    );

    return response;
  }

//
  Future<ResponseModel> deleteAccount({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      accountDeleteApi + id,
      onError: (error) {},
      onSuccess: (res) {
        print("Successfully Deleted: ${res.data}");
      },
    );

    return response;
  }

  // Patch
  Future<ResponseModel> seletctDefaultBank({required String id}) async {
    final response = await ApiBaseHelper().patchHTTP(
      setDefaultBankApi + id,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}

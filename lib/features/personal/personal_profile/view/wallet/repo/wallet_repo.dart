import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class WalletRepo extends BaseService {
  Future<ResponseModel> addWithdrawApi({dynamic params}) async {
    final response = await ApiBaseHelper().postHTTP(
      WithdrawalApi,
      params: params,
      isMultipart: false,
      onError: (error) {},
      onSuccess: (data) {},
    );

    return response;
  }

// Method FOR GET Wallet
  Future<ResponseModel> getWalletApi() async {
    final response = await ApiBaseHelper().getHTTP(
      WalletApi,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
  Future<ResponseModel> getWalletWithdrawalMethod(
      {Map<String, dynamic>? params}) async {
    final response = await ApiBaseHelper().getHTTP(
      walletWithdrawalMethod,
      showProgress: false,
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// Fetch a user's UPI details — `wallet-service/wallet/user/{userId}/upi`.
  /// Used to build the pay-to QR for the conversation person.
  Future<ResponseModel> getUserUpiRepo({required String userId}) async {
    final response = await ApiBaseHelper().getHTTP(
      getUserUpiApi(userId),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// DELETE wallet-service/withdrawal-methods/{id}
  Future<ResponseModel> deleteWithdrawalMethod({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$walletWithdrawalMethod/$id",
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// PUT wallet-service/withdrawal-methods/{id} — edits the bank/UPI details.
  Future<ResponseModel> updateWithdrawalMethod({
    required String id,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "$walletWithdrawalMethod/$id",
      params: params,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  /// PATCH wallet-service/withdrawal-methods/set-default/{id}
  /// `showProgress: false` — set-default updates the list in place, no global
  /// blocking dialog / full-screen spinner.
  Future<ResponseModel> setDefaultWithdrawalMethod({required String id}) async {
    final response = await ApiBaseHelper().patchHTTP(
      "$walletWithdrawalMethod/set-default/$id",
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  Future<ResponseModel> walletTransactionApi({
    String? status,
    String? type,
    String? source,
    int? page = 1,
    int? limit = 10,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      WalletTransctionApi +
          (status != null ? "status=$status&" : "") +
          (type != null ? "type=$type&" : "") +
          (source != null ? "source=$source&" : "") +
          ("page=$page&limit=$limit"),
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}

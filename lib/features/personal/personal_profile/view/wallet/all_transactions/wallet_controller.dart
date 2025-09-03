import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/wallet_transaction_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/wallet_Repo/wallet_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/wallet_response_modal.dart';
import 'package:get/get.dart';

class WalletController extends GetxController {
  WalletResponseModalClass? walletResponseModalClass;
  WalletTransactionResponseModalClass? walletTransactionResponseModalClass;

  @override
  void onInit() {
    getwalletApi();
    getWalletTransactionApi(); 
    super.onInit();
  }

  Future<void> getwalletApi() async {
    ResponseModel response = await WalletRepo().getWalletApi();
    if (response.isSuccess) {
      walletResponseModalClass =
          WalletResponseModalClass.fromJson(response.response!.data);
      update();
    }
  }

  Future<void> getWalletTransactionApi() async {
    ResponseModel response = await WalletRepo().walletTransactionApi();
    if (response.isSuccess) {
      walletTransactionResponseModalClass =
          WalletTransactionResponseModalClass.fromJson(response.response!.data);
      update();
    }
  }
}

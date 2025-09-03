import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/wallet_transaction_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/wallet_Repo/wallet_repo.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SeeAllTransactionController extends GetxController {
  WalletTransactionResponseModalClass? walletTransactionResponseModalClass;
  String? selectedStatus;
  String? selectedType;
  String? selectedSource;

  ScrollController listScrollController = ScrollController();
  bool isLoading = false;
  int page = 1;
  bool isMoreDataInList = true;

  @override
  void onInit() {
    listScrollController.addListener(listener);
    getWalletTransactionApi(isFromFilter: false);
    super.onInit();
  }

  Future<void> getWalletTransactionApi({bool isFromFilter = true}) async {
    if (isFromFilter) {
      page = 1;
      isMoreDataInList = true;
    }
    ResponseModel response = await WalletRepo().walletTransactionApi(
        source: selectedSource,
        status: selectedStatus,
        type: selectedType,
        page: page);
    if (response.isSuccess) {
      walletTransactionResponseModalClass =
          WalletTransactionResponseModalClass.fromJson(response.response!.data);
      isMoreDataInList =
          (walletTransactionResponseModalClass!.pagination!.page! <
              walletTransactionResponseModalClass!.pagination!.pages!);
      update();
    }

  }

  void listener() {
    if (listScrollController.position.maxScrollExtent ==
        listScrollController.offset) {
      if (!isLoading && isMoreDataInList) {
        page++;
        getWalletTransactionApi(isFromFilter: false);
      }
    }
  }
}

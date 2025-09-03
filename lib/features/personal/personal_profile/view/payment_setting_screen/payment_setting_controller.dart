import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_screen/get_account_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/repo/payment_repo.dart';
import 'package:get/get.dart';

class PaymentSettingController extends GetxController {
  GetAccountResponseModalClass? getAccountResponseModalClass;

  @override
  void onInit() {
    getAccountApi();
    super.onInit();
  }

  void deleteBankAccount(String id) {
    deleteAccount(id: id);
  }

  void deleteUpiAccount(String id) {
    deleteAccount(id: id);
  }

  void editUpiAccount(String id) {
    Get.toNamed(RouteHelper.getAddAccountUpiScreenRoute());
    // TODO: Implement edit functionality
    print('Edit UPI account: $id');
  }

  void addBankAccount() {
    Get.toNamed(
      RouteHelper.getAddAccountScreenRoute(),
    )?.then(
      (value) => getAccountApi(),
    );
    print('Add bank account');
  }

  void addUpiAccount() {
    Get.toNamed(
      RouteHelper.getAddAccountUpiScreenRoute(),
    )?.then(
      (value) => getAccountApi(),
    );
    // TODO: Implement add UPI account functionalityfc
    print('Add UPI account');
  }

  Future<void> getAccountApi() async {
    ResponseModel response = await PaymentRepo().getAddAccountApi();
    if (response.isSuccess) {
      getAccountResponseModalClass =
          GetAccountResponseModalClass.fromJson(response.response!.data);
      DatumGetAccountResponseModalClass? temp = getAccountResponseModalClass!
          .data!
          .firstWhereOrNull((e) => e.isDefault ?? false);
      if (temp != null) {
        getAccountResponseModalClass!.data!.remove(temp);
        getAccountResponseModalClass!.data!.insert(0, temp);
      }
      update();
    }
  }

  Future<void> deleteAccount({required String id}) async {
    ResponseModel response = await PaymentRepo().deleteAccount(id: id);
    if (response.isSuccess) {
      getAccountApi();
    }
  }

  void setAccountAsDefault({required String id}) async {
    var response = await PaymentRepo().seletctDefaultBank(
      id: id,
    );
    if (response.isSuccess) {
      getAccountApi();
    }
  }

  // Future<void> setDefaultBank({required String id}) async {
  //   var response = await PaymentRepo().seletctDefaultBank(id: id, params: {
  //     "isDefault": true,
  //   });
  //   if (response.isSuccess) {
  //     print("Default bank set successfully: ${response.data}");
  //   }
  // }
}

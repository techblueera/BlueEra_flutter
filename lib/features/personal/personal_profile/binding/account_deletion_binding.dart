import 'package:get/get.dart';
import 'package:BlueEra/features/common/account_deletion/controller/account_deletion_controller.dart';

/// Registers [AccountDeletionController].
///
/// `fenix: true`: it is also read outside the screen that owns it, so the
/// builder must survive a route pop and rebuild on the next Get.find.
///
/// NOTE: nothing calls Get.isRegistered<AccountDeletionController>() — that was checked before
/// binding it. A binding (fenix especially) keeps the key registered, which would
/// permanently flip any such guard.
class AccountDeletionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountDeletionController>(() => AccountDeletionController(),
        fenix: true);
  }
}

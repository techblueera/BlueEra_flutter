import 'package:get/get.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_contact_us_controller.dart';

/// Registers [LabContactUsController].
///
/// Owned by a single screen; nothing else reads it.
///
/// NOTE: nothing calls Get.isRegistered<LabContactUsController>() — that was checked before
/// binding it. A binding (fenix especially) keeps the key registered, which would
/// permanently flip any such guard.
class LabContactUsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LabContactUsController>(() => LabContactUsController());
  }
}

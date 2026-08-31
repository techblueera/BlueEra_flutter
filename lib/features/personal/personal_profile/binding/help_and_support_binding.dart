import 'package:get/get.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/help_and_support_controller.dart';

/// Registers [HelpAndSupportController] for [QueriesCard].
///
/// This screen is opened with Get.to (not a named route), so the binding is
/// passed at each call site. Every call site must pass it: without one the
/// screen's Get.find would throw.
class HelpAndSupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpAndSupportController>(() => HelpAndSupportController());
  }
}

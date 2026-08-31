import 'package:get/get.dart';
import 'package:BlueEra/features/common/ott/controller/search_channel_controller.dart';

/// Registers [SearchChannelController] for [SearchChannelScreen].
///
/// This screen is opened with Get.to (not a named route), so the binding is
/// passed at each call site. Every call site must pass it: without one the
/// screen's Get.find would throw.
class SearchChannelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SearchChannelController>(() => SearchChannelController());
  }
}

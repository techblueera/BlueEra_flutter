import 'package:BlueEra/features/common/Discover/controller/search_address_controller.dart';
import 'package:get/get.dart';

/// Scopes a [SearchAddressController] to the pickup/drop search route
/// (SearchAddressScreen); GetX deletes it when that screen closes.
class SearchAddressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SearchAddressController());
  }
}

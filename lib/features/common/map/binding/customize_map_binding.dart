import 'package:get/get.dart';
import 'package:BlueEra/features/common/map/controller/getplace_list_controller.dart';
import 'package:BlueEra/features/common/map/controller/map_service_controller.dart';

/// Registers the two controllers [CustomizeMapScreen] drives.
///
/// Both are also `Get.put` by map bottom sheets that are built inline as plain
/// widgets (service_card, store_list_widget, food/home/rental sheets). That is
/// safe alongside this binding: `Get.put` keeps an existing non-dirty
/// registration and returns it (get_instance.dart:157-180), so whoever gets
/// there first wins and the rest share that instance.
class CustomizeMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlaceController>(() => PlaceController());
    Get.lazyPut<MapServiceController>(() => MapServiceController());
  }
}

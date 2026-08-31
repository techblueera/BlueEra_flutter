import 'package:get/get.dart';
import 'package:BlueEra/features/me/hotel/controller/room_detail_controller.dart';

/// Registers [RoomDetailController].
///
/// `fenix: true`: it is also read outside the screen that owns it, so the
/// builder must survive a route pop and rebuild on the next Get.find.
///
/// NOTE: nothing calls Get.isRegistered<RoomDetailController>() — that was checked before
/// binding it. A binding (fenix especially) keeps the key registered, which would
/// permanently flip any such guard.
class RoomDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoomDetailController>(() => RoomDetailController(),
        fenix: true);
  }
}

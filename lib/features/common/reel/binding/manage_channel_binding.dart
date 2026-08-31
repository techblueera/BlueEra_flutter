import 'package:get/get.dart';
import 'package:BlueEra/features/common/reel/controller/channel_controller.dart';
import 'package:BlueEra/features/common/reel/controller/manage_channel_controller.dart';

/// Bindings for the ManageChannelScreen route.
///
/// `fenix: true` where the controller is also read by something that can
/// outlive this route: GetX keeps the builder after a delete, so the next
/// Get.find rebuilds it (empty) instead of throwing.
///
/// App-wide controllers this screen also uses live in InitialBinding, not here.
class ManageChannelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChannelController>(() => ChannelController(), fenix: true);
    Get.lazyPut<ManageChannelController>(() => ManageChannelController());
  }
}

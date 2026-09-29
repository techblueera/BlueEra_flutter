import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/ai_chat_guest_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:get/get.dart';

/// The session-wide controllers the bottom-nav shell and its tabs share.
///
/// All are permanent. The shell is not a GetX-managed route: it is rebuilt by
/// `offAllNamed` from ~30 places while the old shell is still in the stack,
/// and GetX 4.7.3 closes (`onClose`) a controller that a new route re-registers
/// while the old route's copy is being removed. So the session owns these
/// instead; LogoutHelper deletes the account-specific ones.
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    BottomBarController.to;
    ChatViewController.to;
    getOrPut(() => ViewPersonalDetailsController(), permanent: true);
    InventoryController.to;
    getOrPut(() => DeliverPartnerOrdersController(), permanent: true);
    ChatThemeController.to;
    getOrPut(() => DialogService(), permanent: true);
  }
}

import 'package:get/get.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/controller/booking_controller.dart';

/// Registers [BookingController].
///
/// `fenix: true`: it is also read outside the screen that owns it, so the
/// builder must survive a route pop and rebuild on the next Get.find.
///
/// NOTE: nothing calls Get.isRegistered<BookingController>() — that was checked before
/// binding it. A binding (fenix especially) keeps the key registered, which would
/// permanently flip any such guard.
class BookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingController>(() => BookingController(), fenix: true);
  }
}

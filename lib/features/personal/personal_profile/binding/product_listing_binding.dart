import 'package:get/get.dart';
import 'package:BlueEra/features/personal/personal_profile/view/product_listing_screen/product_listing_controller.dart';

/// Registers [ProductListingController] for the ProductListingScreen route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class ProductListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductListingController>(() => ProductListingController());
  }
}

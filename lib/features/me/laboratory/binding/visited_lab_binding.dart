import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/visited_lab_controller.dart';
import 'package:get/get.dart';

/// Scopes a [VisitedLabController] to the lab detail route, tagged with the
/// lab's business id so two visited labs on the stack keep separate lists.
class VisitedLabBinding extends Bindings {
  VisitedLabBinding({required this.businessId});

  final String businessId;

  @override
  void dependencies() {
    Get.lazyPut(
      () => VisitedLabController(
        businessId: businessId,
        businessDetails: Get.isRegistered<ViewBusinessDetailsController>()
            ? Get.find<ViewBusinessDetailsController>()
            : Get.put(ViewBusinessDetailsController(), permanent: true),
      ),
      tag: businessId,
    );
  }
}

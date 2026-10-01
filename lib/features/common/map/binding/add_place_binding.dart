import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_one_controller.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_two_controller.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/features/common/map/repo/add_place_repo.dart';
import 'package:get/get.dart';

/// Scopes the add-place flow's controllers to its first route
/// (AddPlaceStepOneScreen). Category selection and step two are pushed on top
/// and share them, so going back to step one and forward again keeps step
/// two's answers; GetX deletes them all when step one's route closes, so the
/// next place starts empty.
///
/// All are created here, not lazily: GetX ties an instance to the route that
/// is on top when it is first created, which for a lazy one would be step
/// two's own route.
class AddPlaceBinding extends Bindings {
  @override
  void dependencies() {
    // VisitingHoursSelectorController is shared by name with the booking,
    // self-work and business-hours editors. Start from a clean one so hours
    // from an earlier editor don't show up in (or leak out of) this place.
    deleteIfRegistered<VisitingHoursSelectorController>();
    // `Get.put` would keep a leftover instance (e.g. from a flow still closing).
    deleteIfRegistered<AddPlaceStepOneController>();
    deleteIfRegistered<AddPlaceStepTwoController>();
    final stepOne = Get.put(AddPlaceStepOneController());
    final visitingHours = Get.put(VisitingHoursSelectorController());
    Get.put(AddPlaceStepTwoController(
        repo: AddPlaceRepo(), stepOne: stepOne, visitingHours: visitingHours));
  }
}

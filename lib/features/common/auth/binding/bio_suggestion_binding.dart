import 'package:get/get.dart';
import 'package:BlueEra/features/common/auth/controller/ai_suggestion_controller.dart';
import 'package:BlueEra/features/common/auth/controller/bio_suggestion_controller.dart';

/// Bindings for the addBioViaAiScreen route.
///
/// `fenix: true` where the controller is also read by something that can
/// outlive this route: GetX keeps the builder after a delete, so the next
/// Get.find rebuilds it (empty) instead of throwing.
///
/// App-wide controllers this screen also uses live in InitialBinding, not here.
class BioSuggestionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiSuggestionController>(() => AiSuggestionController(),
        fenix: true);
    Get.lazyPut<BioSuggestionController>(() => BioSuggestionController());
  }
}

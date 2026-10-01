import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/repo/delivery_partner_repo.dart';
import 'package:get/get.dart';

/// Answers a rider-association request carried by a chat message, for both the
/// request card and the rider details sheet it opens.
class RiderAssociationService {
  RiderAssociationService({DeliveryPartnerRepo? repo})
      : _repo = repo ?? DeliveryPartnerRepo();

  final DeliveryPartnerRepo _repo;

  /// Sends [action] (`accept` / `reject`) for the association on [message].
  ///
  /// On success, records the new status on the message (so the card keeps it
  /// when rebuilt) and nudges [DeliveryPartnerController] to rebuild, then
  /// returns the status (`accepted` / `rejected`). Returns null when the
  /// message has no association id or the server refused.
  Future<String?> respond(Messages message, String action) async {
    final association = message.metadata?.riderAssociation;
    final associationId = association?.associationId ?? '';
    if (associationId.isEmpty) return null;

    final response = await _repo.respondToAssociationRepo(
      associationId: associationId,
      action: action,
    );
    if (!response.isSuccess) return null;

    final newStatus = action == 'accept' ? 'accepted' : 'rejected';
    association?.status = newStatus;
    if (Get.isRegistered<DeliveryPartnerController>()) {
      Get.find<DeliveryPartnerController>().update();
    }
    return newStatus;
  }
}

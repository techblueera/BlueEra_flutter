import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_booking_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/features/me/vehicle/v3/repo/vehicle_v3_repo.dart';
import 'package:get/get.dart';

/// Actions on an existing enquiry — accept, decline, cancel — plus the two
/// enquiry lists.
///
/// Split out from the seller and buyer controllers because these are used
/// from a third place entirely: the **chat** enquiry card. Creating an
/// enquiry opens a chat card automatically (§7), so the card is where a
/// seller usually answers one, and it needs the mutations without dragging in
/// either dashboard's state.
class VehicleEnquiryControllerV3 extends GetxController {
  final VehicleV3Repo _repo = VehicleV3Repo();

  /// Id of the enquiry currently being actioned, so a card can disable its
  /// own buttons without blocking every other card in the thread.
  final RxnString actionInFlightId = RxnString();

  final RxList<VehicleBooking> received = <VehicleBooking>[].obs;
  final RxList<VehicleBooking> sent = <VehicleBooking>[].obs;

  /// Seller accepts or declines a pending enquiry.
  ///
  /// A 409 means someone already actioned it elsewhere — the message says so
  /// rather than reporting a generic failure, because the user's intent did
  /// in fact already happen.
  Future<bool> respondToEnquiry({
    required String id,
    required bool accept,
  }) async {
    actionInFlightId.value = id;
    try {
      final res = await _repo.setEnquiryStatus(
        id,
        accept ? 'accepted' : 'declined',
      );
      if (res.isSuccess) {
        commonSnackBar(
            message: accept ? 'Request accepted' : 'Request declined');
        return true;
      }
      if ((res.response?.statusCode ?? res.statusCode) == 409) {
        commonSnackBar(message: 'This request was already answered.');
        return false;
      }
      commonSnackBar(
        message: VehicleV3Envelope.errorMessage(res.response?.data) ??
            'Action failed',
      );
      return false;
    } catch (e) {
      logs('VEHICLE_V3_ENQUIRY: respondToEnquiry failed — $e');
      commonSnackBar(message: 'Action failed');
      return false;
    } finally {
      actionInFlightId.value = null;
    }
  }

  /// Buyer cancels their own enquiry. Only valid while it is pending.
  Future<bool> cancelEnquiry(String id) async {
    actionInFlightId.value = id;
    try {
      final res = await _repo.cancelEnquiry(id);
      if (res.isSuccess) {
        commonSnackBar(message: 'Request cancelled');
        return true;
      }
      if ((res.response?.statusCode ?? res.statusCode) == 409) {
        commonSnackBar(message: 'This request can no longer be cancelled.');
        return false;
      }
      commonSnackBar(
        message: VehicleV3Envelope.errorMessage(res.response?.data) ??
            'Could not cancel',
      );
      return false;
    } catch (e) {
      logs('VEHICLE_V3_ENQUIRY: cancelEnquiry failed — $e');
      commonSnackBar(message: 'Could not cancel');
      return false;
    } finally {
      actionInFlightId.value = null;
    }
  }

  /// Enquiries this seller has received.
  Future<void> fetchReceived() async {
    try {
      final res = await _repo.getEnquiriesReceived();
      if (!res.isSuccess) return;
      received.assignAll(_parse(res.response?.data));
    } catch (e) {
      logs('VEHICLE_V3_ENQUIRY: fetchReceived failed — $e');
    }
  }

  /// Enquiries this buyer has sent.
  Future<void> fetchSent() async {
    try {
      final res = await _repo.getEnquiriesSent();
      if (!res.isSuccess) return;
      sent.assignAll(_parse(res.response?.data));
    } catch (e) {
      logs('VEHICLE_V3_ENQUIRY: fetchSent failed — $e');
    }
  }

  /// `/bookings` reads answer `{status, bookings, pagination}` rather than
  /// the `{data}` shape the rest of the service uses, which the envelope
  /// helper already accounts for.
  List<VehicleBooking> _parse(dynamic body) => VehicleV3Envelope.list(body)
      .whereType<Map>()
      .map((e) => VehicleBooking.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

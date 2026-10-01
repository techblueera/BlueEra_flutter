import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:BlueEra/features/chat/auth/repo/make_order_repo.dart';

/// The rider side of an order as the chat cards see it: where the rider is,
/// and handing over the pickup OTP.
class RiderOrderService {
  RiderOrderService({ChatViewRepo? chatRepo, MakeOrderRepo? orderRepo})
      : _chatRepo = chatRepo ?? ChatViewRepo(),
        _orderRepo = orderRepo ?? MakeOrderRepo();

  final ChatViewRepo _chatRepo;
  final MakeOrderRepo _orderRepo;

  /// One read of `rider-location`, which carries `rideActive`, the order
  /// `status` and the rider's coordinates together. Null when it fails.
  Future<Map<dynamic, dynamic>?> riderLocation(String orderId) async {
    if (orderId.isEmpty) return null;
    try {
      final response = await _chatRepo.getRiderLiveLocationApi(orderId);
      if (!response.isSuccess) return null;
      return locationPayload(response.response?.data);
    } catch (_) {
      return null;
    }
  }

  /// The location object in a `rider-location` body: nested under `data` on
  /// some deployments, at the top level on others.
  static Map<dynamic, dynamic>? locationPayload(dynamic body) {
    if (body is! Map) return null;
    final inner = body['data'];
    if (inner is Map &&
        (inner.containsKey('rideActive') ||
            inner.containsKey('rider') ||
            inner.containsKey('status'))) {
      return inner;
    }
    return body;
  }

  /// Verifies the pickup OTP the shop entered. A multi-stop order goes to its
  /// own per-shop endpoint ([businessId] required); the single-shop POST
  /// 404s for those. Null on success, else the server's message ('' when it
  /// gave none, or the call threw).
  Future<String?> verifyPickupOtp({
    required String orderId,
    required String otp,
    String? businessId,
    bool multiStop = false,
  }) async {
    try {
      final res = multiStop
          ? await _orderRepo.multiShopStopPickupApi(
              orderId: orderId, businessId: businessId!, pickupOTP: otp)
          : await _orderRepo.uploadThePickupOtp({'pickupOTP': otp}, orderId);
      return res.isSuccess ? null : (res.message ?? '');
    } catch (_) {
      return '';
    }
  }
}

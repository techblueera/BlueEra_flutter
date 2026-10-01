import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';

/// Opens the support chat for an order (ride customer care).
///
/// `order-support` is a CHAT-service route (`chat-service/support/
/// order-support`); the same path under rider-service is a 404.
class OrderSupportService {
  OrderSupportService({ChatViewRepo? repo}) : _repo = repo ?? ChatViewRepo();

  final ChatViewRepo _repo;

  /// Opens (or reuses) the support thread for [orderId], with [reason] as its
  /// first message. Returns the conversation to land on, or null when there
  /// is none — including the documented 500 while the support team account
  /// is unset on the chat service.
  Future<({String conversationId, String? displayName})?> open({
    required String orderId,
    required String reason,
    String? note,
    String? vehicleType,
    Map<String, dynamic>? ride,
  }) async {
    final response = await _repo.openOrderSupportApi(
      orderId: orderId,
      reason: reason,
      note: note,
      vehicleType: vehicleType,
      ride: ride,
    );
    final body = response.response?.data;
    final map = body is Map ? Map<String, dynamic>.from(body) : null;
    final conversationId = (map?['conversation_id'] ?? '').toString();
    if (!response.isSuccess || conversationId.isEmpty) return null;
    return (
      conversationId: conversationId,
      displayName: (map?['display_name'] as String?)?.trim(),
    );
  }
}

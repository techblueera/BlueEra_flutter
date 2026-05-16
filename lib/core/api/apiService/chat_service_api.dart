/// All `chat-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: the call-service endpoint (`callHistory`) targets a different host
/// (`callBaseUrl`) and is intentionally left in `BaseService` itself.
mixin ChatServiceApi {
  /// ADD POST
  final String sendMessage = 'chat-service/chat/send-message';
  final String updateMessage = 'chat-service/chat/update-message';
  final String generateUploadUrls = 'chat-service/s3/generate-upload-urls';
  final String generateDownloadUrls = 'chat-service/s3/generate-download-url';
  final String sendDownloadLargeFile =
      'chat-service/chat/send-message-large-file';
  final String sync_offline_messages =
      'chat-service/chat/sync-offline-messages';

  final String forwardMessage = 'chat-service/chat/forward-messages';
  final String createGroup = 'chat-service/group/create';
  final String updateGroup = 'chat-service/group/update';
  final String getGroupDetails = 'chat-service/group/details';
  final String getGroupMembersChat = 'chat-service/group/members';
  final String addGroupMember = "chat-service/group/add-members";
  final String checkChatConnection =
      'chat-service/connections/check-connection';
  final String getGroupMembers = 'chat-service/chat/get-group-members';
  final String deleteChatList = 'chat-service/chat/delete-chatlist';
  final String clearAllChat = 'chat-service/chat/clear-all-chat';
  final String deleteMessage = 'chat-service/chat/delete-messages';
  final String deleteGroupMessage = 'chat-service/chat/delete-messages';
  final String addToPinMessage = 'chat-service/chat/add-to-pin-message';
  final String getPinMessageList = 'chat-service/chat/pin-message-list';
  final String addToStarMessage = 'chat-service/chat/add-to-star-message';
  final String getStarMessageList = 'chat-service/chat/star-message-list';
  final String getOneToOneMedia = 'chat-service/chat/get-one-to-one-media';
  final String addToArchive = 'chat-service/chat/add-to-archive';
  final String messageLikeUnlike = 'chat-service/chat/message-like-unlike';

  final String getChatRequest = 'chat-service/connections/requests';
  final String getChatRequestsList = 'chat-service/chat/requests';
  // v1.1: consent-gated symbol-reply request endpoints. See
  // lib/docs/symbol-reply-request-integration-guide.md §2.3–2.5.
  final String chatRequestRespond = 'chat-service/chat/requests/respond';
  final String chatRequestCancel = 'chat-service/chat/requests/cancel';
  String chatRequestById(String id) => 'chat-service/chat/requests/$id';
  final String getLatestChat = 'chat-service/chat/latest-chat';
  final String getChatExportAll = 'chat-service/chat/export-all';
  final String reactChatRequest = 'chat-service/connections/respond';
  final String connectionsSync = 'chat-service/connections/sync';
  final String findServiceByContact =
      'chat-service/connections/filter-by-profileType';
  final String myconnectionsSync = 'chat-service/connections/my';
  final String requestForPersonalChat = 'chat-service/connections/request';
  final String updateMessageOrderStatus = 'chat-service/chat/order-status';

  // ── E2E Encryption API (Phase 1–4) ──────────────────────────────────────
  // Phase 1: Protocol versioning
  String e2eCapability(String userId) =>
      'chat-service/protocol/capability/$userId';

  // Phase 2: Key infrastructure
  final String e2eKeysRegister = 'chat-service/keys/register';
  final String e2eKeysOpks = 'chat-service/keys/opks';
  String e2eKeysBundle(String userId) => 'chat-service/keys/bundle/$userId';
  String e2eKeysDevice(String deviceId) => 'chat-service/keys/device/$deviceId';

  // Phase 3: Encrypted media
  final String e2eEncryptedMediaUploadUrl =
      'chat-service/encrypted-media/upload-url';

  // Phase 4: Sync engine
  final String e2eSyncMessages = 'chat-service/sync/messages';
  final String e2eSyncAck = 'chat-service/sync/ack';

  final String callUser = 'chat-service/call/user';
  final String messageToOrderTab = "chat-service/order/send-message";
  final String createGroceryOrderConvoApi =
      'chat-service/grocery-order/send-message';

  final String clearChatHistory = 'chat-service/group/clear';
  final String setReminder = 'chat-service/reminders/set-reminder';
  //gst
  final String getGst = 'chat-service/reminders/set-reminder';
}

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// `contact-service/*` calls — "Contacts on BlueEra" + the `contact_joined`
/// push notification.
///
/// Separate from [ChatViewRepo.getConnectionsSync] (`chat-service/connections/
/// sync`), which stays exactly as it is and keeps powering the Connect tab.
///
/// Unlike the chat-service sync (a bare JSON array with `isArrayReq`), these
/// endpoints take a JSON object — plain `postHTTP`, no `isArrayReq`.
class ContactRepo extends BaseService {
  /// Upload the device phonebook. Idempotent — safe to retry.
  Future<ResponseModel> syncContacts(Map<String, dynamic> params) async {
    return ApiBaseHelper().postHTTP(
      contactsSync,
      params: params,
      showProgress: false, // background operation, never block the UI
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> getContactsOnBlueEra(Map<String, dynamic> query) async {
    return ApiBaseHelper().getHTTP(
      contactsOnBlueEra,
      params: query,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> getSyncState() async {
    return ApiBaseHelper().getHTTP(
      contactsSyncState,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Re-check matches without an upload (pull-to-refresh). Max 10/hour per
  /// user, never notifies.
  Future<ResponseModel> rebuildMatches() async {
    return ApiBaseHelper().postHTTP(
      contactsRebuild,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// No body = delete everything. Called when contacts permission is revoked
  /// so the server drops the user's phonebook (soft-delete — re-granting
  /// restores history).
  Future<ResponseModel> deleteAllContacts() async {
    return ApiBaseHelper().deleteHTTP(
      contactsList,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}

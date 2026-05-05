import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Wraps the `rider-service/emergency-contacts` endpoints. Server caps the
/// list at 3 contacts per user — see `lib/docs/EMERGENCY_CONTACTS_FRONTEND_GUIDE.md`.
class EmergencyContactsRepo extends BaseService {
  /// GET /emergency-contacts → `{ contacts, count, limit }`.
  Future<ResponseModel> list() {
    return ApiBaseHelper().getHTTP(
      emergencyContacts,
      showProgress: false,
    );
  }

  /// GET /emergency-contacts/count → `{ count, limit, remaining }`.
  Future<ResponseModel> count() {
    return ApiBaseHelper().getHTTP(
      '$emergencyContacts/count',
      showProgress: false,
    );
  }

  /// POST /emergency-contacts → 201 with the new contact, 400 when capped,
  /// 409 on duplicate phone for this user.
  Future<ResponseModel> create({
    required String name,
    required String contactNo,
    String? relation,
    int? priority,
  }) {
    final params = <String, dynamic>{
      'name': name,
      'contactNo': contactNo,
      if (relation != null && relation.isNotEmpty) 'relation': relation,
      if (priority != null) 'priority': priority,
    };
    return ApiBaseHelper().postHTTP(
      emergencyContacts,
      params: params,
      showProgress: false,
    );
  }

  /// PUT /emergency-contacts/bulk → atomic replace-all (max 3, send `[]` to
  /// clear). Use when editing the whole list at once.
  Future<ResponseModel> bulkReplace(List<Map<String, dynamic>> contacts) {
    return ApiBaseHelper().putHTTP(
      '$emergencyContacts/bulk',
      params: {'contacts': contacts},
      showProgress: false,
    );
  }

  /// PATCH /emergency-contacts/:id → partial update. Send `priority: null`
  /// to clear the priority field.
  Future<ResponseModel> update({
    required String id,
    String? name,
    String? contactNo,
    String? relation,
    int? priority,
  }) {
    final params = <String, dynamic>{};
    if (name != null) params['name'] = name;
    if (contactNo != null) params['contactNo'] = contactNo;
    if (relation != null) params['relation'] = relation;
    if (priority != null) params['priority'] = priority;
    return ApiBaseHelper().patchHTTP(
      '$emergencyContacts/$id',
      params: params,
      showProgress: false,
    );
  }

  /// DELETE /emergency-contacts/:id.
  Future<ResponseModel> deleteOne(String id) {
    return ApiBaseHelper().deleteHTTP(
      '$emergencyContacts/$id',
      showProgress: false,
    );
  }
}

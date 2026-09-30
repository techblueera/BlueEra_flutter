import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/rental/model/property_model.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:dio/dio.dart' as dio;

/// The outcome of an owner's edit to a property listing.
///
/// [ok] is whether the server accepted the edit. [property] is the listing as
/// re-read afterwards (null when that read failed — the edit still stands), and
/// [message] is the server's reason when it refused.
typedef PropertyEditResult = ({
  bool ok,
  PropertyModel? property,
  String? message,
});

/// The owner's in-place edits on the property details screen: field updates
/// and photo uploads. Each writes, then re-reads the listing so the screen
/// shows what the server now holds.
class PropertyEditService {
  PropertyEditService({PropertyRepo? repo}) : _repo = repo ?? PropertyRepo();

  final PropertyRepo _repo;

  /// Applies [updates] to property [id].
  Future<PropertyEditResult> updateFields(
          String id, Map<String, dynamic> updates) =>
      _writeThenReread(id, () => _repo.updateProperty(id, updates));

  /// Uploads the photos at [localPaths] to property [id].
  Future<PropertyEditResult> uploadImages(
      String id, List<String> localPaths) async {
    final images = <dio.MultipartFile>[
      for (final path in localPaths) await dio.MultipartFile.fromFile(path),
    ];
    return _writeThenReread(
      id,
      () => _repo.updateProperty(id, {'propertyImages': images},
          isMultipart: true),
    );
  }

  /// Deletes property [id]. Null on success, else the server's message (''
  /// when it gave none).
  Future<String?> delete(String id) async {
    final res = await _repo.deleteProperty(id);
    return res.isSuccess ? null : (res.message?.toString() ?? '');
  }

  Future<PropertyEditResult> _writeThenReread(
      String id, Future<ResponseModel> Function() write) async {
    final response = await write();
    if (!response.isSuccess) {
      return (ok: false, property: null, message: response.message?.toString());
    }
    final fetched = await _repo.getPropertyById(id);
    final data = fetched.isSuccess ? fetched.data : null;
    return (
      ok: true,
      property: data is Map
          ? PropertyModel.fromJson(Map<String, dynamic>.from(data))
          : null,
      message: null,
    );
  }
}

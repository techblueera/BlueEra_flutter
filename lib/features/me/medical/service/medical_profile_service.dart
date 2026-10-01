import 'package:BlueEra/features/me/medical/model/medical_home_response_model.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:flutter/foundation.dart';

/// A pharmacy's public medical profile (cover, gallery, testimonials,
/// contact), for the medical home and pharmacy detail screens.
class MedicalProfileService {
  MedicalProfileService({MedicalRepo? repo}) : _repo = repo ?? MedicalRepo();

  final MedicalRepo _repo;

  /// The profile of [businessId], with the raw `gallery` list the home
  /// screens hand to their gallery controller. Null when it couldn't be
  /// loaded.
  Future<({MedicalHomeResponseModel profile, dynamic gallery})?> fetch(
      String businessId) async {
    try {
      final res = await _repo.fetchMedicalProfileFd(businessId: businessId);
      if (!res.isSuccess || res.response?.data == null) return null;
      final data = res.getExtraData('data') ?? res.response?.data;
      if (data is! Map<String, dynamic>) return null;
      return (
        profile: MedicalHomeResponseModel.fromJson(data),
        gallery: data['gallery'],
      );
    } catch (e) {
      debugPrint("Error fetching medical profile: $e");
      return null;
    }
  }
}

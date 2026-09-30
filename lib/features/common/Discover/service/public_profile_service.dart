import 'package:BlueEra/features/me/doctor/model/doctor_profile_model.dart';
import 'package:BlueEra/features/me/doctor/repo/doctor_profile_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';

/// The provider profiles Discover's detail screens show alongside the
/// business profile: an earn profile (home services, home-made food stores)
/// or a doctor's professional profile.
///
/// Both return null rather than failing: a provider who hasn't filled the
/// profile in is a normal state, and the screens hide those sections.
class PublicProfileService {
  PublicProfileService(
      {EarnProfileRepo? earnRepo, DoctorProfileRepo? doctorRepo})
      : _earnRepo = earnRepo ?? EarnProfileRepo(),
        _doctorRepo = doctorRepo ?? DoctorProfileRepo();

  final EarnProfileRepo _earnRepo;
  final DoctorProfileRepo _doctorRepo;

  /// [userId]'s earn profile of [profileType]. The by-userId endpoint returns
  /// a SINGLE object: `{ success, data: {…} }`.
  Future<EarnProfileModel?> earnProfile(String userId,
      {required String profileType}) async {
    try {
      final res = await _earnRepo.fetchEarnProfileByUserId(
        userId: userId,
        queryParams: {'profileType': profileType},
      );
      final body = res.response?.data;
      if (!res.isSuccess || body is! Map || body['data'] is! Map) return null;
      return EarnProfileModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map));
    } catch (_) {
      return null;
    }
  }

  /// [ownerUserId]'s doctor profile. `/doctors/full/:userId` 404s for any
  /// doctor who registered but hasn't filled in their profile yet.
  Future<DoctorProfile?> doctorProfile(String ownerUserId) async {
    try {
      final res = await _doctorRepo.getPublicProfile(ownerUserId: ownerUserId);
      if (!res.isSuccess) return null;
      final data = res.response?.data;
      final profile = data is Map ? data['data'] : null;
      return profile is Map
          ? DoctorProfile.fromJson(Map<String, dynamic>.from(profile))
          : null;
    } catch (_) {
      return null;
    }
  }
}

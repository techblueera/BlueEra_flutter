import 'dart:developer';

import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';

/// Star ratings left on a profile: a customer rating the business they
/// ordered from, or a rider rating the customer after a ride.
class ProfileRatingService {
  ProfileRatingService({BusinessProfileRepo? repo})
      : _repo = repo ?? BusinessProfileRepo();

  final BusinessProfileRepo _repo;

  /// Rates business [businessId]. Null on success, else the server's message
  /// ('' when it gave none, or the call threw).
  Future<String?> rateBusiness(String businessId,
      {required int stars, String comment = ''}) async {
    try {
      final res = await _repo.submitRatingToBusinessAccount(
          businessId, {'rating': stars, 'comment': comment.trim()});
      return res.isSuccess ? null : (res.message ?? '');
    } catch (e) {
      log('business rating failed — business=$businessId: $e');
      return '';
    }
  }

  /// Rates person [userId]. Returns whether the server accepted it; a failure
  /// is only logged, since nothing the caller does depends on it.
  Future<bool> ratePerson(String userId,
      {required int stars, String comment = ''}) async {
    try {
      final res = await _repo.submitRatingToPersonal(
          userId, {'rating': stars, 'comment': comment.trim()});
      return res.isSuccess;
    } catch (e) {
      log('personal rating failed — user=$userId: $e');
      return false;
    }
  }
}

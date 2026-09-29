import 'dart:developer';

import 'package:BlueEra/features/ride_booking/model/ride_booking_models.dart';
import 'package:BlueEra/features/ride_booking/repo/ride_booking_repo.dart';

/// The customer's feedback on a finished ride: the star rating and the
/// one-tap report, for RideCompletedScreen.
///
/// Both fail soft — they return null rather than throw — because a customer
/// must never be held on a finished ride over feedback.
class RideFeedbackService {
  RideFeedbackService({RideBookingRepo? repo})
      : _repo = repo ?? RideBookingRepo();

  final RideBookingRepo _repo;

  /// Rates the ride. Null when there is no order id or the call failed.
  Future<RideRatingResult?> rate({
    required String orderId,
    required int rating,
    required List<String> tags,
    String? comment,
  }) async {
    if (orderId.isEmpty) return null;
    try {
      return await _repo.rateRide(
        orderId: orderId,
        rating: rating,
        tags: tags,
        comment: comment,
      );
    } catch (e) {
      log('ride rating failed — order=$orderId: $e');
      return null;
    }
  }

  /// Reports the ride with [reasonSlug] (the API value, not the label shown).
  /// Null when there is no order id or the call failed.
  Future<RideReportResult?> report({
    required String orderId,
    required String reasonSlug,
  }) async {
    if (orderId.isEmpty) return null;
    try {
      return await _repo.reportRide(orderId: orderId, reason: reasonSlug);
    } catch (e) {
      log('ride report failed — order=$orderId reason=$reasonSlug: $e');
      return null;
    }
  }
}

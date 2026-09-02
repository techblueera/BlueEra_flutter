import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// `other-service/ads` — the promo creative bundle.
///
/// Public: no token, no headers, so it can be fetched before login. Always
/// `showProgress: false` — the promo is decorative and must never put a modal
/// spinner over a screen the user is already using.
class PromoAdsRepo extends BaseService {
  /// [placement] / [campaign] / [limit] map to the documented query filters.
  /// The app fetches everything once and filters client-side, so they're here
  /// for one-off callers rather than the normal path.
  Future<ResponseModel> getAds({
    String? placement,
    String? campaign,
    int? limit,
  }) async {
    final params = <String, dynamic>{
      if (placement != null && placement.isNotEmpty) 'placement': placement,
      if (campaign != null && campaign.isNotEmpty) 'campaign': campaign,
      if (limit != null && limit > 0) 'limit': limit,
    };
    return await ApiBaseHelper().getHTTP(
      promoAds,
      params: params.isEmpty ? null : params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
  }
}

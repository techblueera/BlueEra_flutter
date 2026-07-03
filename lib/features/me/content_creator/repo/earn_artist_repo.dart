import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Repository for the Earn-Artist (content-creator) vertical.
///
/// Mirrors [ReferralRepoNew]: extends [BaseService] to inherit the
/// `earn-service/*` endpoint constants, and issues every call through
/// [ApiBaseHelper] so it shares the same Dio client, `Bearer` auth interceptor
/// and 401 handling as the rest of the app. No new HTTP client is created here.
class EarnArtistRepo extends BaseService {
  /// `GET earn-service/earn-artists` (all omitted) → the caller's OWN newest
  /// artist profile as a single object (or a null/empty body when they have
  /// none yet). Controller decides whether to show the "create profile" CTA.
  Future<ResponseModel> getMyArtistProfile() {
    return ApiBaseHelper().getHTTP(
      earnArtists,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET earn-service/earn-artists/{id}` → full profile detail (`user`
  /// populated, media as presigned download URLs).
  Future<ResponseModel> getArtistById(String id) {
    return ApiBaseHelper().getHTTP(
      earnArtistById(id),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET earn-service/earn-artists/any/check` → `{ exists, artistId }`.
  /// Used to gate the "Create your creator profile" CTA.
  Future<ResponseModel> checkArtistExists() {
    return ApiBaseHelper().getHTTP(
      earnArtistCheck,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `POST earn-service/earn-artists` — creates a minimal artist/content-creator
  /// profile. Per the guide's field mapping the parent group (ARTIST /
  /// CONTENT_CREATOR) is sent as [type] and the picked subcategory as [category]
  /// (only `category` is strictly required; owner is taken from the token).
  Future<ResponseModel> createArtistProfile({
    required String? type,
    required String? category,
  }) {
    return ApiBaseHelper().postHTTP(
      earnArtists,
      params: {
        if (type != null && type.isNotEmpty) 'type': type,
        if (category != null && category.isNotEmpty) 'category': category,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}

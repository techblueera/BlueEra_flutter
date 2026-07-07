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

  /// `PUT earn-service/earn-artists/{id}` — edit the profile (owner only).
  /// Arrays like `expertise`/`gallery`/`channels` REPLACE; `contactUs`/`booking`
  /// MERGE. Backs every inline "Edit" sheet on the Overview tab.
  Future<ResponseModel> updateArtistProfile({
    required String id,
    required Map<String, dynamic> params,
  }) {
    return ApiBaseHelper().putHTTP(
      earnArtistById(id),
      params: params,
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `POST earn-service/earn-artists/{id}/gallery/{galleryIndex}/images` — mints
  /// one S3 presigned PUT url per entry in [contentTypes] for the gallery group
  /// at [galleryIndex]. Response carries `uploadUrls: [PUT urls]`; the caller
  /// PUTs each file's bytes to its url (same `Content-Type`) then refetches.
  Future<ResponseModel> mintGalleryUploadUrls({
    required String id,
    required int galleryIndex,
    required List<String> contentTypes,
  }) {
    return ApiBaseHelper().postHTTP(
      earnArtistGalleryImages(id, galleryIndex),
      params: {'contentTypes': contentTypes},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `DELETE earn-service/earn-artists/{id}/gallery/{galleryIndex}/images` —
  /// removes [imageUrls] from the gallery group at [galleryIndex]. Body is
  /// `{ image_urls: [...] }` (guide §2d/2f). Refetch after to refresh the strip.
  Future<ResponseModel> deleteGalleryImages({
    required String id,
    required int galleryIndex,
    required List<String> imageUrls,
  }) {
    return ApiBaseHelper().deleteHTTP(
      earnArtistGalleryImages(id, galleryIndex),
      params: {'image_urls': imageUrls},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET user-service/business/search` — free-text + geo business search that
  /// backs the "Add associate brands" picker. [q] is the text query; [lat]/[lng]
  /// centre the geo filter and [radius] (km) bounds it. Paged via [page]/[limit].
  /// Response is the standard `{ success, data:[…business…], pagination }` shape
  /// parsed by [BusinessFilterResModel].
  Future<ResponseModel> searchBusinesses({
    required String q,
    double? lat,
    double? lng,
    int radius = 10,
    int page = 1,
    int limit = 10,
  }) {
    return ApiBaseHelper().getHTTP(
      businessSearch,
      params: {
        'q': q,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'radius': radius,
        'page': page,
        'limit': limit,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET earn-service/predefined-artist-expertise/{category}?type={type}` → the
  /// suggested `expertise[]` for the profile's category. Drives the API-fed
  /// multi-select in the Expertise edit sheet.
  Future<ResponseModel> getExpertiseSuggestions({
    required String category,
    required String type,
  }) {
    return ApiBaseHelper().getHTTP(
      predefinedArtistExpertiseByCategory(category),
      params: {if (type.isNotEmpty) 'type': type},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/content_creator/model/earn_artist_model.dart';
import 'package:BlueEra/features/me/content_creator/repo/earn_artist_repo.dart';
import 'package:get/get.dart';

/// Drives the content-creator "Overview" tab. Loads the logged-in creator's own
/// artist profile (`GET earn-service/earn-artists`) and exposes it as reactive
/// state. Mirrors [ReferralController]'s structure (Rx<ApiResponse> status +
/// parsed Rxn model).
class EarnArtistController extends GetxController {
  final EarnArtistRepo _repo = EarnArtistRepo();

  /// Async status for the profile fetch — drives loading/error/data in the UI.
  final Rx<ApiResponse> artistResponse = ApiResponse.initial('Initial').obs;

  /// The caller's own artist profile (null until loaded / when none exists).
  final Rxn<EarnArtist> artist = Rxn<EarnArtist>();

  /// Whether the caller has an artist profile — set from either the profile
  /// fetch or the `/any/check` gate. Defaults false so the create CTA shows.
  final RxBool hasProfile = false.obs;

  /// Testimonials have no field in the EarnArtist model yet. This list defaults
  /// empty and drives a clean empty state; wire it to a real endpoint later.
  // TODO(earn-artist): populate from a testimonials endpoint once the backend
  //  ships it. For now it stays [] and the Testimonials section empty-states.
  final RxList<ArtistTestimonial> testimonials = <ArtistTestimonial>[].obs;

  /// True while the "create profile" POST is in flight (drives the CTA spinner).
  final RxBool isCreatingProfile = false.obs;

  bool get isLoading => artistResponse.value.status == Status.LOADING;

  /// `POST earn-service/earn-artists` — creates a minimal profile with just the
  /// parent group + subcategory. Per the guide's field mapping: [type] is the
  /// parent (ARTIST / CONTENT_CREATOR) and [category] is the picked subcategory.
  ///
  /// Called at onboarding (when the chosen profession is CONTENT_CREATOR/ARTIST)
  /// and from the Overview "Create profile" CTA. Returns true on success (or a
  /// 409 "already exists", after which the existing profile is re-fetched).
  Future<bool> createMinimalArtistProfile({
    required String? type,
    required String? category,
  }) async {
    if (isCreatingProfile.value) return false;
    isCreatingProfile.value = true;
    try {
      final res = await _repo.createArtistProfile(
        type: type,
        category: category,
      );
      if (res.isSuccess) {
        final body = res.response?.data;
        final map = _extractArtistMap(body);
        if (map != null && map.isNotEmpty) {
          artist.value = EarnArtist.fromJson(map);
        }
        hasProfile.value = true;
        artistResponse.value = ApiResponse.complete(body);
        return true;
      }
      // 409 → a profile already exists; treat as success and pull it in.
      if (res.statusCode == 409) {
        await fetchMyArtistProfile();
        return true;
      }
      commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong.tr);
      return false;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    } finally {
      isCreatingProfile.value = false;
    }
  }

  /// Fetches the profile; if the user has none yet, silently creates a minimal
  /// one (type/category) so the Overview always has an artist doc to read the
  /// expertise/pricing/certificate/brands/gallery sections from.
  Future<void> ensureArtistProfile(
      {required String? type, required String? category}) async {
    await fetchMyArtistProfile();
    if (!hasProfile.value) {
      await createMinimalArtistProfile(type: type, category: category);
    }
  }

  /// Loads the caller's own newest artist profile. Tolerant to the earn-service
  /// returning the object bare, wrapped in `data`, or under `artist`.
  Future<void> fetchMyArtistProfile() async {
    artistResponse.value = ApiResponse.loading('loading');
    try {
      final res = await _repo.getMyArtistProfile();
      if (res.isSuccess) {
        final body = res.response?.data;
        final map = _extractArtistMap(body);
        if (map != null && map.isNotEmpty) {
          artist.value = EarnArtist.fromJson(map);
          hasProfile.value = true;
        } else {
          artist.value = null;
          hasProfile.value = false;
        }
        artistResponse.value = ApiResponse.complete(body);
      } else {
        // A 404 here just means "no profile yet" — surface as an empty state,
        // not an error, so the create CTA can render.
        if (res.statusCode == 404) {
          artist.value = null;
          hasProfile.value = false;
          artistResponse.value = ApiResponse.complete(null);
        } else {
          artistResponse.value = ApiResponse.error(
              res.message ?? AppStrings.somethingWentWrong.tr);
        }
      }
    } catch (e) {
      artistResponse.value = ApiResponse.error(e.toString());
    }
  }

  /// `GET .../any/check` → `{ exists, artistId }`. Cheap gate used before the
  /// create CTA is shown (the profile fetch already sets [hasProfile], so this
  /// is a secondary confirmation the UI can call if desired).
  Future<void> checkArtistExists() async {
    try {
      final res = await _repo.checkArtistExists();
      if (res.isSuccess) {
        final body = res.response?.data;
        final map = body is Map
            ? body.map((k, v) => MapEntry(k.toString(), v))
            : const <String, dynamic>{};
        hasProfile.value = map['exists'] == true;
      }
    } catch (_) {
      // Non-fatal — leave hasProfile as-is.
    }
  }

  /// Pulls the artist JSON object out of whatever envelope the backend used.
  Map<String, dynamic>? _extractArtistMap(dynamic body) {
    if (body is List) {
      // Discover/list mode shape — take the first entry defensively.
      final first = body.isNotEmpty ? body.first : null;
      return first is Map
          ? first.map((k, v) => MapEntry(k.toString(), v))
          : null;
    }
    if (body is Map) {
      final m = body.map((k, v) => MapEntry(k.toString(), v));
      // Unwrap common envelopes if the actual profile is nested.
      for (final key in ['data', 'artist']) {
        final inner = m[key];
        if (inner is Map) {
          return inner.map((k, v) => MapEntry(k.toString(), v));
        }
      }
      // Bare object — treat as the profile only if it looks like one.
      if (m.containsKey('_id') || m.containsKey('category') ||
          m.containsKey('title')) {
        return m;
      }
    }
    return null;
  }
}

/// Lightweight testimonial model for the Overview "Testimonials" carousel.
/// Not part of the EarnArtist API contract yet — kept here so the section has a
/// typed shape to render once a backend feed exists.
class ArtistTestimonial {
  final String quote;
  final String author;
  final String designation;

  const ArtistTestimonial({
    required this.quote,
    required this.author,
    required this.designation,
  });
}

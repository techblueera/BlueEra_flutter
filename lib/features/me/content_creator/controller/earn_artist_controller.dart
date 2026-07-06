import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/content_creator/model/earn_artist_model.dart';
import 'package:BlueEra/features/me/content_creator/repo/earn_artist_repo.dart';
import 'package:flutter/material.dart';
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

  // ─── EDIT-SHEET STATE ─────────────────────────────────────────────────────
  // The Overview sections each open an inline bottom sheet to edit ONE field
  // (mirrors the self-profession service screen). Every save funnels through
  // [updateArtist] → `PUT earn-service/earn-artists/{id}` → refetch.

  /// True while any inline edit `PUT` is in flight (drives every sheet's CTA).
  final RxBool isUpdating = false.obs;

  /// True while gallery photos are being minted + uploaded to S3 (drives the
  /// Gallery section's inline "Uploading…" state).
  final RxBool isGalleryUploading = false.obs;

  // Expertise picker — the suggestion list is fetched from the predefined
  // catalog (`predefined-artist-expertise/{category}?type=`) and [selectedExpertise]
  // holds the working selection while the sheet is open.
  final RxList<String> expertiseSuggestions = <String>[].obs;
  final RxList<String> selectedExpertise = <String>[].obs;
  final RxBool isExpertiseLoading = false.obs;

  // Pricing / engagement inputs.
  final TextEditingController priceController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController bookingTypeController = TextEditingController();
  final RxString selectedPriceType = 'perHour'.obs;

  // Certificate & award inputs.
  final TextEditingController certNameController = TextEditingController();
  final TextEditingController certDescController = TextEditingController();

  /// Local image paths the user picked for the new certificate's media, held
  /// while the Add-certificate sheet is open (uploaded to S3 on save).
  final RxList<String> certMediaPaths = <String>[].obs;

  // Contact-us inputs.
  final TextEditingController contactDescController = TextEditingController();
  final TextEditingController contactWebsiteController = TextEditingController();
  final TextEditingController contactEmailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();

  /// Valid `booking.priceType` values (mirrors the guide: `perHour` | `perVisit`).
  static const List<String> priceTypeOptions = ['perHour', 'perVisit'];

  @override
  void onClose() {
    priceController.dispose();
    minPriceController.dispose();
    bookingTypeController.dispose();
    certNameController.dispose();
    certDescController.dispose();
    contactDescController.dispose();
    contactWebsiteController.dispose();
    contactEmailController.dispose();
    contactNumberController.dispose();
    super.onClose();
  }

  // ─── EXPERTISE SUGGESTIONS ────────────────────────────────────────────────
  /// Loads the suggested `expertise[]` for the profile's own type/category and
  /// seeds [selectedExpertise] with what the profile already has. Called each
  /// time the Expertise edit sheet opens. Skips the network hit when the
  /// suggestions are already hydrated.
  Future<void> loadExpertiseSuggestions() async {
    final a = artist.value;
    selectedExpertise.assignAll(a?.expertise ?? const <String>[]);

    final category = a?.category ?? '';
    final type = a?.type ?? '';
    if (category.isEmpty) return;
    if (expertiseSuggestions.isNotEmpty) return;

    try {
      isExpertiseLoading.value = true;
      final res =
          await _repo.getExpertiseSuggestions(category: category, type: type);
      if (res.isSuccess) {
        // The single-object variant nests the list under `data.expertise`; the
        // both-types array variant returns `data: [ {expertise}, … ]`.
        final data = res.response?.data is Map
            ? (res.response?.data as Map)['data']
            : res.response?.data;
        final list = <String>[];
        if (data is Map && data['expertise'] is List) {
          list.addAll((data['expertise'] as List).map((e) => e.toString()));
        } else if (data is List) {
          for (final entry in data) {
            if (entry is Map && entry['expertise'] is List) {
              list.addAll((entry['expertise'] as List).map((e) => e.toString()));
            }
          }
        }
        expertiseSuggestions
            .assignAll(list.where((e) => e.trim().isNotEmpty).toList());
      }
    } catch (_) {
      // Non-fatal — the sheet still lets the user keep their current picks and
      // add custom entries.
    } finally {
      isExpertiseLoading.value = false;
    }
  }

  // ─── SEED HELPERS (called on each sheet open so abandoned edits reset) ─────
  void seedPricingInputs() {
    final b = artist.value?.booking;
    priceController.text = b?.priceLabel ?? '';
    minPriceController.text = (b?.minimumPrice != null)
        ? (b!.minimumPrice == b.minimumPrice!.roundToDouble()
            ? b.minimumPrice!.toInt().toString()
            : b.minimumPrice.toString())
        : '';
    bookingTypeController.text = b?.bookingType ?? '';
    final pt = b?.priceType ?? '';
    selectedPriceType.value = priceTypeOptions.contains(pt) ? pt : 'perHour';
  }

  void seedContactInputs() {
    final c = artist.value?.contactUs;
    contactDescController.text = c?.description ?? '';
    contactWebsiteController.text = c?.website ?? '';
    contactEmailController.text = c?.email ?? '';
    contactNumberController.text = c?.number ?? '';
  }

  void seedCertificateInputs() {
    certNameController.clear();
    certDescController.clear();
    certMediaPaths.clear();
  }

  // ─── THE ONE WRITE PATH ───────────────────────────────────────────────────
  /// `PUT earn-service/earn-artists/{id}` with [params]. On success it swaps in
  /// the returned profile (falling back to a refetch), pops the sheet and
  /// returns true. Guards against a missing profile id.
  Future<bool> updateArtist(Map<String, dynamic> params) async {
    final id = artist.value?.id ?? '';
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    }
    try {
      isUpdating.value = true;
      final res = await _repo.updateArtistProfile(id: id, params: params);
      if (res.isSuccess) {
        final map = _extractArtistMap(res.response?.data);
        if (map != null && map.isNotEmpty) {
          artist.value = EarnArtist.fromJson(map);
        } else {
          await fetchMyArtistProfile();
        }
        return true;
      }
      commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong.tr);
      return false;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // ─── GALLERY UPLOAD ───────────────────────────────────────────────────────
  /// Adds local image [paths] to the profile's gallery. The gallery *group*
  /// must exist before images can be minted, so a default "Gallery" group is
  /// created when none exists. Then mints one presigned S3 PUT url per file
  /// (`POST .../gallery/{i}/images`), uploads each file's bytes with the same
  /// `Content-Type`, and refetches the profile so the new URLs render.
  Future<bool> addGalleryImages(List<String> paths) async {
    final id = artist.value?.id ?? '';
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    }
    final files =
        paths.where((p) => p.trim().isNotEmpty).toList(growable: false);
    if (files.isEmpty) return false;

    try {
      isGalleryUploading.value = true;

      // Ensure a gallery group exists; append into the first group (index 0).
      const galleryIndex = 0;
      if ((artist.value?.gallery ?? const <ArtistGallery>[]).isEmpty) {
        final created = await updateArtist({
          'gallery': [
            {'name': 'Gallery', 'images': const <String>[]},
          ],
        });
        if (!created) return false;
      }

      // Mint one presigned PUT url per file (content-type declared per file).
      final contentTypes = files.map(_imageContentType).toList(growable: false);
      final mintRes = await _repo.mintGalleryUploadUrls(
        id: id,
        galleryIndex: galleryIndex,
        contentTypes: contentTypes,
      );
      if (!mintRes.isSuccess) {
        commonSnackBar(
            message: mintRes.message ?? AppStrings.somethingWentWrong.tr);
        return false;
      }
      final body = mintRes.response?.data;
      final urls = <String>[];
      if (body is Map && body['uploadUrls'] is List) {
        urls.addAll((body['uploadUrls'] as List).map((e) => e.toString()));
      }
      if (urls.isEmpty) {
        commonSnackBar(message: AppStrings.somethingWentWrong.tr);
        return false;
      }

      // PUT each file's bytes to its presigned url with the matching type.
      final count = urls.length < files.length ? urls.length : files.length;
      var allOk = true;
      for (var i = 0; i < count; i++) {
        final res = await ChannelRepo().uploadVideoToS3(
          file: File(files[i]),
          fileType: contentTypes[i],
          preSignedUrl: urls[i],
          onProgress: (_) {},
        );
        if (res?.statusCode != 200) allOk = false;
      }

      await fetchMyArtistProfile();
      if (!allOk) {
        commonSnackBar(message: 'Some photos could not be uploaded');
      }
      return allOk;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    } finally {
      isGalleryUploading.value = false;
    }
  }

  // ─── CERTIFICATE (text + media) ───────────────────────────────────────────
  /// Appends a certificate/award. `certificatesAndAwards` REPLACES on PUT, so
  /// the whole [existing] list is re-sent (media preserved as bare keys) plus
  /// the new entry. Media for the new entry is minted server-side via a
  /// `certificateUploads` array on the same PUT (guide §2d): the response
  /// returns presigned PUT urls under `uploadUrls.certificates`, we upload the
  /// bytes to each, then refetch so the download URLs come back on `media[].key`.
  Future<bool> addCertificate({
    required String name,
    required String description,
    required List<ArtistCertificate> existing,
  }) async {
    if (name.trim().isEmpty) {
      commonSnackBar(message: 'Please enter a title');
      return false;
    }
    final id = artist.value?.id ?? '';
    if (id.isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    }
    try {
      isUpdating.value = true;

      final paths = certMediaPaths.toList();
      final newIndex = existing.length; // the new cert is appended last

      // Full replace list — preserve existing certs (media re-sent as bare keys
      // so the backend re-presigns them correctly), then the new one with an
      // empty media list (its media is minted via certificateUploads below).
      final certList = <Map<String, dynamic>>[
        for (final c in existing)
          {
            'name': c.name,
            'description': c.description,
            'media': [
              for (final m in c.media) {'type': 'image', 'key': _bareKey(m)},
            ],
          },
        {
          'name': name.trim(),
          'description': description.trim(),
          'media': const <dynamic>[],
        },
      ];

      final params = <String, dynamic>{'certificatesAndAwards': certList};
      if (paths.isNotEmpty) {
        params['certificateUploads'] = [
          {
            'certificateIndex': newIndex,
            'media': [
              for (final p in paths)
                {'type': 'image', 'contentType': _imageContentType(p)},
            ],
          },
        ];
      }

      final res = await _repo.updateArtistProfile(id: id, params: params);
      if (!res.isSuccess) {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong.tr);
        return false;
      }

      // PUT each picked file's bytes to its minted presigned url (same order).
      if (paths.isNotEmpty) {
        final urls = _certificateUploadUrls(res.response?.data, newIndex);
        final count = urls.length < paths.length ? urls.length : paths.length;
        for (var i = 0; i < count; i++) {
          await ChannelRepo().uploadVideoToS3(
            file: File(paths[i]),
            fileType: _imageContentType(paths[i]),
            preSignedUrl: urls[i],
            onProgress: (_) {},
          );
        }
      }

      await fetchMyArtistProfile();
      return true;
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Pulls the presigned PUT urls minted for the certificate at [certificateIndex]
  /// out of a PUT response's `uploadUrls.certificates[]` (each entry is
  /// `{ certificateIndex, media: [{ type, url }] }`).
  List<String> _certificateUploadUrls(dynamic body, int certificateIndex) {
    final urls = <String>[];
    if (body is! Map) return urls;
    final uploadUrls = body['uploadUrls'];
    final certs = uploadUrls is Map ? uploadUrls['certificates'] : null;
    if (certs is! List) return urls;
    for (final entry in certs) {
      if (entry is Map && entry['certificateIndex'] == certificateIndex) {
        final media = entry['media'];
        if (media is List) {
          for (final m in media) {
            if (m is Map) {
              final u = (m['url'] ?? m['key'])?.toString() ?? '';
              if (u.isNotEmpty) urls.add(u);
            }
          }
        }
      }
    }
    return urls;
  }

  /// Reduces a media value to a bare S3 object key: strips the host/query from a
  /// presigned download URL (leaving `services-service/…`) so the backend can
  /// re-presign it. Non-URL values pass through unchanged.
  String _bareKey(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return value;
    var key = uri.path;
    if (key.startsWith('/')) key = key.substring(1);
    return key.isNotEmpty ? key : value;
  }

  // ─── CHANNELS / SOCIALS ───────────────────────────────────────────────────
  /// Appends a social channel. `channels` REPLACES on PUT, so the existing list
  /// is re-sent plus the new `{ name, url }` entry.
  Future<bool> addChannel({
    required String platform,
    required String url,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      commonSnackBar(message: 'Please paste a link');
      return false;
    }
    final list = <Map<String, dynamic>>[
      ..._existingChannelMaps(),
      {'name': platform, 'url': trimmed},
    ];
    return await updateArtist({'channels': list});
  }

  /// Removes the channel at [index] (replace-PUT with it filtered out).
  Future<bool> removeChannel(int index) async {
    final channels = artist.value?.channels ?? const <ArtistChannel>[];
    if (index < 0 || index >= channels.length) return false;
    final list = <Map<String, dynamic>>[
      for (var i = 0; i < channels.length; i++)
        if (i != index) _channelMap(channels[i]),
    ];
    return await updateArtist({'channels': list});
  }

  List<Map<String, dynamic>> _existingChannelMaps() => [
        for (final c in (artist.value?.channels ?? const <ArtistChannel>[]))
          _channelMap(c),
      ];

  Map<String, dynamic> _channelMap(ArtistChannel c) => {
        'name': c.name,
        if (c.url.isNotEmpty) 'url': c.url,
        if (c.channelId.isNotEmpty) 'channelId': c.channelId,
      };

  /// Image MIME type from a file path's extension (S3 presign wants a concrete
  /// `Content-Type`; defaults to jpeg for anything unexpected).
  String _imageContentType(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

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

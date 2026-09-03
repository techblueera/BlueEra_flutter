import 'dart:io';

import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';

/// Makes a gallery upload run **once** — one S3 object per file, one POST per
/// submit.
///
/// ## The bug this exists to prevent
///
/// The upload screens call their controller's `buildRequestBody()` straight
/// from a button's `onTap`, unawaited, with nothing disabling the button while
/// the work runs. The controllers also held their url list in a FIELD and
/// cleared it at the top of each run. Together that meant a second tap (or a
/// rebuild re-firing the tap) started a second, concurrent run which:
///
///   * re-uploaded every already-picked file — and since [S3UploadService]
///     mints a fresh timestamped key per call, a retry never overwrites, it
///     ACCUMULATES; and
///   * appended into the same shared list the first run was still filling, so
///     each run's POST carried whatever had piled up at that instant.
///
/// Production showed the shape of it exactly: 4 distinct photos landed as 41
/// S3 objects inside a 6-second window, and `POST /other-service/gallery` fired
/// 7 times in 4 seconds with cumulative lists (13, 25, 34, 36, 37, 30, 41 urls
/// — non-monotonic because a later run's clear() reset the list mid-flight).
///
/// ## The three guarantees
///
/// 1. [guardGalleryUpload] serialises submits: while one is in flight, another
///    is dropped rather than queued — a second tap of Submit is the user
///    repeating themselves, not asking for a second album.
/// 2. [uploadGalleryFilesOnce] uploads each file path at most once per form,
///    remembering the url it got. A retry after a partial failure re-sends only
///    what actually still needs sending.
/// 3. The caller builds its POST body from the returned list, which is LOCAL to
///    the run, so nothing can accumulate across runs.
///
/// Callers must also clear the cache when the form resets
/// ([clearGalleryUploadCache]) and disable their submit control while
/// [isGalleryUploadInFlight] is true, so the guard is a backstop rather than
/// the only thing standing between a double tap and a duplicate album.
mixin GalleryUploadGuard {
  bool _uploadInFlight = false;

  /// S3 url keyed by the local file path that produced it, for this form.
  final Map<String, String> _uploadedUrls = <String, String>{};

  /// Whether a submit is running. Bind the submit button's enabled state to
  /// this (via the controller's own loading flag) so the user sees why a second
  /// tap does nothing.
  bool get isGalleryUploadInFlight => _uploadInFlight;

  /// Runs [action] unless a gallery upload is already in flight, in which case
  /// it returns null without starting anything.
  Future<T?> guardGalleryUpload<T>(Future<T> Function() action) async {
    if (_uploadInFlight) return null;
    _uploadInFlight = true;
    try {
      return await action();
    } finally {
      _uploadInFlight = false;
    }
  }

  /// Uploads [paths] to S3, skipping any file already uploaded by this form,
  /// and returns the urls in the order given.
  ///
  /// A file whose upload fails is simply absent from the result and stays out
  /// of the cache, so the next submit retries just that one.
  Future<List<String>> uploadGalleryFilesOnce(List<String> paths) async {
    final urls = <String>[];
    for (final path in paths) {
      final cached = _uploadedUrls[path];
      if (cached != null) {
        urls.add(cached);
        continue;
      }
      final UploadResult result = await S3UploadService.uploadFile(File(path));
      if (result.isSuccess) {
        _uploadedUrls[path] = result.url;
        urls.add(result.url);
      }
    }
    return urls;
  }

  /// Forgets the uploaded-url cache. Call from the form's reset so the next
  /// album starts clean — otherwise re-picking the same file from the gallery
  /// would file the previous album's url under the new category.
  void clearGalleryUploadCache() => _uploadedUrls.clear();
}

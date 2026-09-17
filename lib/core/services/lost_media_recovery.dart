import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

/// Recovers picker results that Android dropped when it destroyed the host
/// activity while the camera / gallery app was in the foreground.
///
/// ## The failure this exists for
///
/// Launching the system camera or gallery pushes `MainActivity` to the
/// background, where Android is free to destroy it — routinely on low-RAM
/// devices, on aggressive OEM ROMs (MIUI / ColorOS / FuntouchOS / realme UI),
/// and always when "Don't keep activities" is on in Developer Options. When the
/// user comes back, the native result is delivered to an activity that no
/// longer exists, so the `Future` returned by `pickImage` / `pickVideo` /
/// `pickMultiImage` **never completes**. Every caller awaiting it hangs, and
/// whatever dialog or spinner was on screen stays there forever.
///
/// That is why the freeze looks device-specific: a phone with memory headroom
/// never destroys the activity and never reproduces it.
///
/// `ImagePicker.retrieveLostData()` is the platform's prescribed recovery — it
/// returns the result that was cached for the dead activity. This class wires
/// it to the app lifecycle so a pick that was in flight across the death can be
/// completed with the recovered file instead of hanging.
///
/// ## Guarantee
///
/// A guarded pick ALWAYS completes. Recovery can legitimately come back empty
/// (the activity died *and* the user cancelled, so there is nothing to
/// recover); in that case the pick resolves as a cancellation rather than
/// hanging. See [_recover] for the two-stage timing that keeps this from
/// cutting a slow-but-healthy pick short.
class LostMediaRecovery with WidgetsBindingObserver {
  LostMediaRecovery._();

  static final LostMediaRecovery instance = LostMediaRecovery._();

  /// Grace period after `resumed` before we ask the plugin for lost data. On a
  /// healthy return the real result lands within a few frames of the resume, so
  /// waiting first keeps us from racing it.
  static const _firstProbeDelay = Duration(milliseconds: 1200);

  /// Total budget after `resumed` before an unanswered pick is treated as
  /// cancelled. The app is already visible by then; a result that has not
  /// arrived is not going to.
  static const _giveUpDelay = Duration(seconds: 4);

  static bool _initialised = false;

  /// Registers the lifecycle observer. Safe to call more than once.
  static void init() {
    if (_initialised) return;
    _initialised = true;
    WidgetsBinding.instance.addObserver(instance);
  }

  Completer<List<XFile>>? _pending;

  /// True while a [guard] call is in flight. Nested guards (a guarded helper
  /// called from inside another guarded block) must not register a second
  /// pending slot — doing so would resolve the outer one as a cancellation the
  /// instant the inner one started, turning every such pick into an immediate
  /// no-op. The outer guard already covers the inner pick, so nesting just
  /// passes through.
  bool _inGuard = false;

  /// Runs [pick] with lost-data recovery attached.
  ///
  /// [pick] must be the raw `image_picker` call. Its result is passed straight
  /// through on the healthy path; only an activity death diverts to recovery.
  /// Errors from [pick] propagate to the caller unchanged.
  Future<List<XFile>> guard(Future<List<XFile>> Function() pick) async {
    // iOS keeps the picker in-process, so there is nothing to lose and
    // `retrieveLostData` is a documented no-op there.
    //
    // `_inGuard` also catches the CONCURRENT case, not just the nested one it
    // was written for — the flag cannot tell them apart. A second tap while
    // the first pick is still awaited lands here and calls the platform
    // again, which is why `_pickOrEmpty` and not `pick` directly.
    if (!Platform.isAndroid || _inGuard) return _pickOrEmpty(pick);

    final completer = Completer<List<XFile>>();
    final previous = _pending;
    _pending = completer;

    // A pick starting while another is still outstanding means the earlier one
    // can no longer be recovered (retrieveLostData is single-slot). Release it
    // as a cancellation so its caller unblocks instead of leaking.
    if (previous != null && !previous.isCompleted) {
      previous.complete(const <XFile>[]);
    }

    unawaited(_pickOrEmpty(pick).then(
      (files) {
        if (!completer.isCompleted) completer.complete(files);
      },
      onError: (Object error, StackTrace stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
    ));

    _inGuard = true;
    try {
      return await completer.future;
    } finally {
      _inGuard = false;
      if (identical(_pending, completer)) _pending = null;
    }
  }

  /// Runs [pick], resolving the platform's refusal of a second concurrent
  /// pick as "nothing selected" rather than an error.
  ///
  /// Android allows exactly one picker at a time and answers a second request
  /// with `PlatformException(already_active)`. That is a double tap, or a tap
  /// while the previous picker is still opening — the picker the user wanted
  /// is already on its way up, so the second request has nothing to add. No
  /// call site in this app catches PlatformException, so it arrived instead as
  /// a fatal out of whichever controller happened to make the second call.
  Future<List<XFile>> _pickOrEmpty(Future<List<XFile>> Function() pick) async {
    try {
      return await pick();
    } on PlatformException catch (e) {
      if (e.code == 'already_active') return const <XFile>[];
      rethrow;
    }
  }

  /// Convenience wrapper for the single-file pickers, which return `XFile?`.
  Future<XFile?> guardSingle(Future<XFile?> Function() pick) async {
    final files = await guard(() async {
      final file = await pick();
      return file != null ? <XFile>[file] : <XFile>[];
    });
    return files.isEmpty ? null : files.first;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    unawaited(_recover(pending));
  }

  /// Two-stage resolution of a pick that was in flight across a resume.
  ///
  /// Stage 1 (after [_firstProbeDelay]) asks for lost data. A non-empty answer
  /// only ever means the activity really was destroyed and the platform cached
  /// the result, so completing with it is unambiguous.
  ///
  /// An empty answer is ambiguous — either the healthy path is still in flight
  /// (result imminent) or the activity died and the user cancelled (nothing is
  /// coming). Stage 2 waits out the rest of [_giveUpDelay], probes once more,
  /// and only then resolves as a cancellation. That is what converts the
  /// permanent freeze into a normal "user backed out".
  Future<void> _recover(Completer<List<XFile>> pending) async {
    await Future<void>.delayed(_firstProbeDelay);
    if (pending.isCompleted) return;

    if (await _probe(pending)) return;

    await Future<void>.delayed(_giveUpDelay - _firstProbeDelay);
    if (pending.isCompleted) return;

    if (await _probe(pending)) return;
    if (!pending.isCompleted) pending.complete(const <XFile>[]);
  }

  /// Asks the platform for a dropped result. Returns true when [pending] was
  /// completed (recovered data, or an error the platform recorded).
  Future<bool> _probe(Completer<List<XFile>> pending) async {
    final LostDataResponse lost;
    try {
      lost = await ImagePicker().retrieveLostData();
    } catch (_) {
      // The platform channel itself failed. Leave `pending` alone so the
      // give-up stage can still resolve it.
      return false;
    }
    if (pending.isCompleted) return true;
    if (lost.isEmpty) return false;

    final files = lost.files;
    if (files != null && files.isNotEmpty) {
      pending.complete(files);
      return true;
    }
    if (lost.file != null) {
      pending.complete(<XFile>[lost.file!]);
      return true;
    }
    if (lost.exception != null) {
      pending.completeError(lost.exception!, StackTrace.current);
      return true;
    }
    return false;
  }
}

/// Drop-in replacement for [ImagePicker] with lost-data recovery attached.
///
/// Every pick in the app goes through this instead of constructing an
/// [ImagePicker] directly, so no call site can accidentally be left exposed to
/// the activity-death hang described on [LostMediaRecovery]. The signatures
/// mirror the plugin's, so swapping `ImagePicker()` for `SafeImagePicker()` is
/// the whole change at a call site.
class SafeImagePicker {
  const SafeImagePicker();

  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) {
    return LostMediaRecovery.instance.guardSingle(
      () => ImagePicker().pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
        requestFullMetadata: requestFullMetadata,
      ),
    );
  }

  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) {
    return LostMediaRecovery.instance.guardSingle(
      () => ImagePicker().pickVideo(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxDuration: maxDuration,
      ),
    );
  }

  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    bool requestFullMetadata = true,
    int? limit,
  }) {
    return LostMediaRecovery.instance.guard(
      () => ImagePicker().pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        requestFullMetadata: requestFullMetadata,
        limit: limit,
      ),
    );
  }
}

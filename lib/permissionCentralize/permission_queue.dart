import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Serializes every OS permission request in the app.
///
/// `permission_handler` holds ONE process-global lock, not one per permission.
/// A second `request()` that starts while any other is still in flight throws
///
///   PlatformException(PermissionHandler.PermissionManager,
///     A request for permissions is already running, please wait for it to
///     finish before doing another request ...)
///
/// which reaches the global handler in main.dart as a fatal. The races were
/// never within one screen — they were between unrelated flows that happen to
/// overlap: the cold-start location fetch from main()'s deferred init still
/// running when the user lands on Connect and it asks for contacts; a call
/// arriving mid-boot and asking for mic while the notification prompt is up.
/// Guarding each site individually cannot fix that, because the two racers
/// live in different files and neither knows about the other.
///
/// So every request goes through one queue here. Callers await their turn
/// instead of colliding, and the OS shows the prompts back to back rather than
/// dropping the second one.
///
/// Use [request] / [requestAll] in place of `permission.request()` and
/// `[a, b].request()`. Reading `.status` needs no queue — it takes no lock.
class PermissionQueue {
  PermissionQueue._();

  /// Tail of the serialized chain. Every enqueued action appends to it, so an
  /// action starts only once the previous one has finished. Errors are caught
  /// inside the link (see [_enqueue]), so the chain itself never completes with
  /// an error and can never stall the queue.
  static Future<void> _tail = Future<void>.value();

  /// A native request that never delivers a result would wedge the queue for
  /// the rest of the process — every later prompt silently lost. That happens
  /// when the activity is destroyed mid-request (rotation, background kill),
  /// where `onRequestPermissionsResult` never fires. Past this we give up on
  /// the answer and let the next caller through. Generous on purpose: a real
  /// user reading a permission dialog can easily take half a minute.
  static const Duration _wedgeTimeout = Duration(seconds: 90);

  /// Appends [action] to the chain and hands back its result.
  static Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  /// Requests a single [permission], waiting for any in-flight request first.
  static Future<PermissionStatus> request(Permission permission) {
    return _enqueue(() async {
      try {
        return await permission.request().timeout(_wedgeTimeout);
      } on TimeoutException {
        return permission.status;
      } on PlatformException {
        // Serialization means this should not fire. It still can, because
        // other plugins (image_picker, geolocator) request permissions on
        // their own channels, outside this queue. Falling back to the current
        // status keeps a lost race from surfacing as a crash: the caller sees
        // "not granted" and takes its existing denied path.
        return permission.status;
      }
    });
  }

  /// Requests [permissions] as one OS prompt, waiting for its turn first.
  /// A single native call for several permissions takes the lock once, so this
  /// stays one queue entry rather than N.
  static Future<Map<Permission, PermissionStatus>> requestAll(
    List<Permission> permissions,
  ) {
    return _enqueue(() async {
      try {
        return await permissions.request().timeout(_wedgeTimeout);
      } on TimeoutException {
        return _currentStatuses(permissions);
      } on PlatformException {
        return _currentStatuses(permissions);
      }
    });
  }

  static Future<Map<Permission, PermissionStatus>> _currentStatuses(
    List<Permission> permissions,
  ) async {
    final result = <Permission, PermissionStatus>{};
    for (final permission in permissions) {
      result[permission] = await permission.status;
    }
    return result;
  }
}

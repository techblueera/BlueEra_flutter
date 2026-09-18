import 'package:BlueEra/features/chat/auth/service/location_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The decision behind `LiveLocationService.verifyKillModeCoverage`.
///
/// Context: `RiderLocationForegroundService` is forbidden from crashing when
/// Android 14+ refuses to promote a `location` foreground service (that refusal
/// WAS the production `SecurityException` out of `onStartCommand`). Every
/// refusal is therefore a silent no-op that only leaves a breadcrumb in
/// SharedPreferences. This is the logic that turns that breadcrumb back into
/// something the rider hears about — and both ways of getting it wrong are
/// invisible in testing:
///
///  * warning a rider who has already granted "Allow all the time" is noise
///    about a problem that no longer exists;
///  * staying quiet for one who hasn't means they show as LIVE, stop publishing
///    the moment the app is killed, and lose a shift's orders.
void main() {
  group('killModeActionFor', () {
    test('still refused → warn, breadcrumb or not', () {
      // The rider downgraded to "While using the app" and the service has
      // already failed once.
      expect(
        LiveLocationService.killModeActionFor(
          canRunInBackground: false,
          hasBreadcrumb: true,
          allowRestart: true,
        ),
        KillModeAction.warn,
      );
      // Same grant missing, but nothing has tried to start yet — going live for
      // the first time. There is no breadcrumb to read, and the rider still
      // needs telling.
      expect(
        LiveLocationService.killModeActionFor(
          canRunInBackground: false,
          hasBreadcrumb: false,
          allowRestart: true,
        ),
        KillModeAction.warn,
      );
    });

    test('a refusal that has since been permitted is repaired, not reported',
        () {
      // This is the case the breadcrumb alone gets wrong: it records that
      // coverage WAS lost, which says nothing about whether it still is. The
      // rider fixed the permission in Settings; nothing restarted the service.
      expect(
        LiveLocationService.killModeActionFor(
          canRunInBackground: true,
          hasBreadcrumb: true,
          allowRestart: true,
        ),
        KillModeAction.restart,
      );
    });

    test('never-refused and currently allowed → clear', () {
      expect(
        LiveLocationService.killModeActionFor(
          canRunInBackground: true,
          hasBreadcrumb: false,
          allowRestart: true,
        ),
        KillModeAction.clear,
      );
    });

    test('allowRestart:false never restarts, but still warns when refused', () {
      // The call right after start(): a start is already in flight, so a second
      // one would race it. A stale breadcrumb must not trigger one...
      expect(
        LiveLocationService.killModeActionFor(
          canRunInBackground: true,
          hasBreadcrumb: true,
          allowRestart: false,
        ),
        KillModeAction.clear,
      );
      // ...but suppressing the restart must NOT suppress the warning, which is
      // the whole point of checking right after going live.
      expect(
        LiveLocationService.killModeActionFor(
          canRunInBackground: false,
          hasBreadcrumb: true,
          allowRestart: false,
        ),
        KillModeAction.warn,
      );
    });

    test('warn is reachable only when the platform currently refuses', () {
      // Guards the direction of the first branch: no combination with
      // canRunInBackground == true may warn.
      for (final breadcrumb in [true, false]) {
        for (final restart in [true, false]) {
          expect(
            LiveLocationService.killModeActionFor(
              canRunInBackground: true,
              hasBreadcrumb: breadcrumb,
              allowRestart: restart,
            ),
            isNot(KillModeAction.warn),
            reason: 'breadcrumb=$breadcrumb allowRestart=$restart',
          );
        }
      }
    });
  });
}

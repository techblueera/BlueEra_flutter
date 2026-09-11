import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/model/location_data_model.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/services/location_permission_handler.dart';
import 'package:BlueEra/widgets/location_help_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// The location-access path, end to end: what the handler reports, what the
/// sheet says about it, and what the retry loop does with the answer.
///
/// The regression at the centre of this file is the one that got users stuck:
/// `getCurrentLocation` requested the permission and then re-read the status
/// from BEFORE the request, so someone who had just tapped Allow was still
/// treated as denied — and the dialog it then raised had no back button, no
/// scrim dismiss and no cancel. Every assertion about "granted after the
/// prompt" below exists to keep that from coming back.

// ── Platform-channel doubles ────────────────────────────────────────────────
//
// Both plugins fall back to their MethodChannel implementation in a test
// binding (no plugin registers itself), so the channels are the seam.

const _permissionChannel =
    MethodChannel('flutter.baseflow.com/permissions/methods');
const _geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');

/// `PermissionStatus` travels over the channel as its ordinal.
const int _denied = 0;
const int _granted = 1;
const int _restricted = 2;
const int _limited = 3;
const int _permanentlyDenied = 4;

/// Every method call either plugin received, in order, so a test can assert on
/// what was NOT asked as well as what was.
late List<String> _calls;

/// Installs the doubles. [statusBeforeRequest] is what a status check reports,
/// [statusAfterRequest] what the prompt resolves to — the pair the regression
/// is about.
void _mockPlatform({
  bool serviceEnabled = true,
  int statusBeforeRequest = _granted,
  int? statusAfterRequest,
  Map<String, dynamic>? position = const {
    'latitude': 21.1702,
    'longitude': 72.8311,
  },
}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(_permissionChannel, (call) async {
    _calls.add(call.method);
    switch (call.method) {
      case 'checkPermissionStatus':
        return statusBeforeRequest;
      case 'requestPermissions':
        // The plugin decodes this as Map<int permission, int status>.
        final requested = (call.arguments as List).cast<int>();
        return {
          for (final p in requested)
            p: statusAfterRequest ?? statusBeforeRequest,
        };
      case 'openAppSettings':
        return true;
    }
    return null;
  });

  messenger.setMockMethodCallHandler(_geolocatorChannel, (call) async {
    _calls.add(call.method);
    switch (call.method) {
      case 'isLocationServiceEnabled':
        return serviceEnabled;
      case 'getCurrentPosition':
        if (position == null) {
          throw PlatformException(code: 'LOCATION_SERVICES_DISABLED');
        }
        return position;
      case 'openLocationSettings':
        return true;
    }
    return null;
  });
}

void _clearMocks() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_permissionChannel, null);
  messenger.setMockMethodCallHandler(_geolocatorChannel, null);
}

// ── Test doubles for the retry loop ─────────────────────────────────────────

/// A [LocationController] that returns a scripted sequence of results instead
/// of touching GPS, so the loop's own behaviour can be tested.
class _ScriptedLocationController extends LocationController {
  _ScriptedLocationController(this.script);

  /// One entry per attempt; null means "failed with [failWith]". The last
  /// entry repeats if the loop asks for more.
  final List<LocationDataModel?> script;
  LocationErrorType failWith = LocationErrorType.permissionDenied;
  int attempts = 0;

  @override
  Future<LocationDataModel?> checkPermissionAndSetData({
    bool preferNativeGeocoding = false,
  }) async {
    final result = script[attempts.clamp(0, script.length - 1)];
    attempts++;
    lastErrorType = result == null ? failWith : LocationErrorType.none;
    return result;
  }
}

LocationDataModel _location() => LocationDataModel(
      fullAddress: 'Ring Road, Surat, Gujarat, 395002, India',
      city: 'Surat',
      pinCode: '395002',
      lat: '21.1702',
      long: '72.8311',
    );

// ── Harness ────────────────────────────────────────────────────────────────

/// The real English copy, read straight off the asset the app ships. Loading
/// it here rather than hard-coding strings means these tests also fail if a
/// key is ever dropped from the bundle — which would otherwise surface as the
/// raw key rendered to the user.
late Map<String, String> _en;

class _AssetTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en': _en};
}

String _t(String key) => _en[key]!;

/// Scrolls [finder] into view before tapping it.
///
/// The sheet scrolls on a short handset, so a button can legitimately start
/// below the fold — a plain tap would silently miss. This is what a user does
/// too: scroll down, then press.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Simulates the user leaving for a settings screen and coming back, which is
/// what drives the sheet's on-return check.
Future<void> _returnToApp(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

/// Pumps a host inside a GetMaterialApp with SizeConfig initialised and the
/// English bundle loaded, as the real app does at startup.
///
/// The surface is a phone (390x844 logical), not the 800x600 default: this
/// sheet is tall enough that the default desktop-ish surface is not a fair
/// test of it, and a phone is the only place it ever renders.
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  late BuildContext hostContext;
  await tester.pumpWidget(
    GetMaterialApp(
      translations: _AssetTranslations(),
      locale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        hostContext = context;
        return const Scaffold(body: SizedBox.expand());
      }),
    ),
  );
  await tester.pump();
  return hostContext;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final raw = File('assets/translations/en.json').readAsStringSync();
    _en = (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
  });

  setUp(() {
    _calls = [];
    Get.testMode = true;
  });

  tearDown(() {
    _clearMocks();
    Get.reset();
  });

  // ── 1. What the handler reports ──────────────────────────────────────────

  group('LocationPermissionHandler reports the reason, not just failure', () {
    test('device location switched off is its own answer', () async {
      _mockPlatform(serviceEnabled: false);

      final result = await LocationPermissionHandler().getCurrentLocation();

      expect(result.isSuccess, isFalse);
      expect(result.errorType, LocationErrorType.serviceDisabled);
      expect(result.shouldOpenSettings, isTrue);
      // The app permission is irrelevant while the master switch is off, and
      // prompting for it would send the user to fix the wrong thing.
      expect(_calls, isNot(contains('checkPermissionStatus')));
      expect(_calls, isNot(contains('requestPermissions')));
    });

    test('granted at the prompt is a SUCCESS, not a denial', () async {
      // THE regression. The old code re-read the pre-request status here and
      // declared a denial at someone who had just tapped Allow.
      _mockPlatform(
        statusBeforeRequest: _denied,
        statusAfterRequest: _granted,
      );

      final result = await LocationPermissionHandler().getCurrentLocation();

      expect(result.isSuccess, isTrue);
      expect(result.errorType, LocationErrorType.none);
      expect(result.position?.latitude, 21.1702);
      expect(_calls, contains('requestPermissions'));
      expect(_calls, contains('getCurrentPosition'));
    });

    test('already granted skips the prompt entirely', () async {
      _mockPlatform(statusBeforeRequest: _granted);

      final result = await LocationPermissionHandler().getCurrentLocation();

      expect(result.isSuccess, isTrue);
      expect(_calls, isNot(contains('requestPermissions')));
      expect(_calls, contains('getCurrentPosition'));
    });

    test('refused at the prompt is a re-askable denial', () async {
      _mockPlatform(
        statusBeforeRequest: _denied,
        statusAfterRequest: _denied,
      );

      final result = await LocationPermissionHandler().getCurrentLocation();

      expect(result.errorType, LocationErrorType.permissionDenied);
      // Not a settings trip — the OS will still show the prompt next time.
      expect(result.shouldOpenSettings, isFalse);
      expect(_calls, isNot(contains('getCurrentPosition')));
    });

    test('Android reports a permanent denial only from the request', () async {
      // Android's `status` says `denied` for a permanently denied permission;
      // only the request resolves to `permanentlyDenied`, without a prompt.
      _mockPlatform(
        statusBeforeRequest: _denied,
        statusAfterRequest: _permanentlyDenied,
      );

      final result = await LocationPermissionHandler().getCurrentLocation();

      expect(result.errorType, LocationErrorType.permissionPermanentlyDenied);
      expect(result.shouldOpenSettings, isTrue);
      expect(_calls, isNot(contains('getCurrentPosition')));
    });

    test('iOS reports it up front, and is not asked again', () async {
      _mockPlatform(statusBeforeRequest: _permanentlyDenied);

      final result = await LocationPermissionHandler().getCurrentLocation();

      expect(result.errorType, LocationErrorType.permissionPermanentlyDenied);
      // Requesting a permanently denied permission shows nothing; the only
      // way back is the app's settings page.
      expect(_calls, isNot(contains('requestPermissions')));
    });

    test('restricted (parental controls) is treated as blocked', () async {
      _mockPlatform(statusBeforeRequest: _restricted);

      final result = await LocationPermissionHandler().getCurrentLocation();

      expect(result.errorType, LocationErrorType.permissionPermanentlyDenied);
    });

    test('a fix that fails after permission is not a permission problem',
        () async {
      _mockPlatform(statusBeforeRequest: _granted, position: null);

      final result = await LocationPermissionHandler().getCurrentLocation();

      expect(result.isSuccess, isFalse);
      // The platform reported the service off mid-fix; it must not be
      // reported as a permission refusal, which sends the user to the wrong
      // settings screen.
      expect(result.errorType, LocationErrorType.serviceDisabled);
    });
  });

  // ── 2. What the sheet says about each reason ─────────────────────────────

  group('the guidance sheet names the failure it was given', () {
    testWidgets('GPS off asks for the device toggle', (tester) async {
      final context = await _pumpHost(tester);
      unawaitedSheet(context, LocationErrorType.serviceDisabled);
      await tester.pumpAndSettle();

      expect(find.text(_t('locationGpsOffTitle')), findsOneWidget);
      expect(find.text(_t('locationTurnOnGps')), findsOneWidget);
      expect(find.text(_t('locationGpsStep1')), findsOneWidget);
      expect(find.text(_t('locationGpsStep3')), findsOneWidget);
      // Not the app's own settings page — the GPS switch isn't on it.
      expect(find.text(_t('openSettings')), findsNothing);
    });

    testWidgets('a re-askable denial offers the prompt, not settings',
        (tester) async {
      final context = await _pumpHost(tester);
      unawaitedSheet(context, LocationErrorType.permissionDenied);
      await tester.pumpAndSettle();

      expect(find.text(_t('locationAllowTitle')), findsOneWidget);
      expect(find.text(_t('locationAllowAction')), findsOneWidget);
      expect(find.text(_t('openSettings')), findsNothing);
      expect(find.text(_t('locationTurnOnGps')), findsNothing);
    });

    testWidgets('a blocked permission sends the user to app settings',
        (tester) async {
      final context = await _pumpHost(tester);
      unawaitedSheet(context, LocationErrorType.permissionPermanentlyDenied);
      await tester.pumpAndSettle();

      expect(find.text(_t('locationBlockedTitle')), findsOneWidget);
      expect(find.text(_t('openSettings')), findsOneWidget);
      // Four steps here, not three: this is the one that needs the extra
      // "open Permissions, then Location" hop.
      expect(find.text(_t('locationBlockedStep2')), findsOneWidget);
      expect(find.text(_t('locationBlockedStep4')), findsOneWidget);
    });

    testWidgets('a failed fix asks for a retry, not a permission change',
        (tester) async {
      final context = await _pumpHost(tester);
      unawaitedSheet(context, LocationErrorType.addressLookupFailed);
      await tester.pumpAndSettle();

      expect(find.text(_t('locationNotFoundTitle')), findsOneWidget);
      expect(find.text(_t('locationTryAgain')), findsOneWidget);
      expect(find.text(_t('openSettings')), findsNothing);
      expect(find.text(_t('locationTurnOnGps')), findsNothing);
    });

    testWidgets('timeout gets the same retry advice as a failed lookup',
        (tester) async {
      final context = await _pumpHost(tester);
      unawaitedSheet(context, LocationErrorType.timeout);
      await tester.pumpAndSettle();

      expect(find.text(_t('locationNotFoundTitle')), findsOneWidget);
      expect(find.text(_t('locationRetryStep1')), findsOneWidget);
    });

    testWidgets('the caller\'s reason replaces the generic one',
        (tester) async {
      final context = await _pumpHost(tester);
      unawaitedSheet(context, LocationErrorType.permissionDenied,
          purpose: _t('locationWhyBusinessSetup'));
      await tester.pumpAndSettle();

      expect(find.text(_t('locationWhyBusinessSetup')), findsOneWidget);
      expect(find.text(_t('locationWhyGeneric')), findsNothing);
    });

    testWidgets('with no reason given it still says why', (tester) async {
      final context = await _pumpHost(tester);
      unawaitedSheet(context, LocationErrorType.permissionDenied);
      await tester.pumpAndSettle();

      expect(find.text(_t('locationWhyGeneric')), findsOneWidget);
    });
  });

  // ── 3. What the sheet's buttons do ───────────────────────────────────────

  group('the sheet always has a way out', () {
    testWidgets('Not now answers "no retry"', (tester) async {
      _mockPlatform();
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.permissionPermanentlyDenied,
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.text(_t('notNow')));

      expect(await answer, isFalse);
      expect(_calls, isNot(contains('openAppSettings')));
    });

    testWidgets('tapping the scrim dismisses it', (tester) async {
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.permissionPermanentlyDenied,
      );
      await tester.pumpAndSettle();

      // The old dialog was barrierDismissible: false with back blocked; this
      // one must never be a trap.
      await tester.tapAt(const Offset(195, 5));
      await tester.pumpAndSettle();

      expect(await answer, isFalse);
      expect(find.text(_t('locationBlockedTitle')), findsNothing);
    });

    testWidgets('Allow location closes and asks for a retry', (tester) async {
      _mockPlatform();
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.permissionDenied,
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.text(_t('locationAllowAction')));

      expect(await answer, isTrue);
      // No settings trip: the OS prompt IS the next attempt.
      expect(_calls, isNot(contains('openAppSettings')));
    });

    testWidgets('Open Settings opens them and keeps the sheet up',
        (tester) async {
      _mockPlatform();
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.permissionPermanentlyDenied,
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.text(_t('openSettings')));

      expect(_calls, contains('openAppSettings'));
      // Still open: the app was backgrounded, so it cannot know whether
      // anything was changed. Retrying now would fail and re-open this sheet
      // behind the user's back.
      expect(find.text(_t('locationBlockedTitle')), findsOneWidget);
      expect(find.text(_t('locationTryAgain')), findsOneWidget);

      await _tap(tester, find.text(_t('locationTryAgain')));
      expect(await answer, isTrue);
    });

    testWidgets('Turn on GPS opens device settings, not app settings',
        (tester) async {
      _mockPlatform();
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.serviceDisabled,
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.text(_t('locationTurnOnGps')));

      expect(_calls, contains('openLocationSettings'));
      expect(_calls, isNot(contains('openAppSettings')));

      await _tap(tester, find.text(_t('locationTryAgain')));
      expect(await answer, isTrue);
    });
  });

  // ── 4. Coming back from the settings screen ──────────────────────────────

  group('returning to the app after fixing it needs no second tap', () {
    testWidgets('GPS switched on closes the sheet by itself', (tester) async {
      _mockPlatform(serviceEnabled: false);
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.serviceDisabled,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text(_t('locationTurnOnGps')));

      // The user flips the toggle and comes back.
      _mockPlatform(serviceEnabled: true);
      await _returnToApp(tester);

      expect(await answer, isTrue);
      expect(find.text(_t('locationGpsOffTitle')), findsNothing);
    });

    testWidgets('permission granted in settings closes the sheet by itself',
        (tester) async {
      _mockPlatform(statusBeforeRequest: _permanentlyDenied);
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.permissionPermanentlyDenied,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text(_t('openSettings')));

      _mockPlatform(statusBeforeRequest: _granted);
      await _returnToApp(tester);

      expect(await answer, isTrue);
    });

    testWidgets('iOS approximate location counts as fixed', (tester) async {
      _mockPlatform(statusBeforeRequest: _permanentlyDenied);
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.permissionPermanentlyDenied,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text(_t('openSettings')));

      _mockPlatform(statusBeforeRequest: _limited);
      await _returnToApp(tester);

      expect(await answer, isTrue);
    });

    testWidgets('coming back without fixing it leaves the sheet up',
        (tester) async {
      _mockPlatform(serviceEnabled: false);
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.serviceDisabled,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text(_t('locationTurnOnGps')));

      // Back, still off — never close on a guess.
      await _returnToApp(tester);

      expect(find.text(_t('locationGpsOffTitle')), findsOneWidget);
      expect(find.text(_t('locationTryAgain')), findsOneWidget);

      await _tap(tester, find.text(_t('notNow')));
      expect(await answer, isFalse);
    });

    testWidgets('a platform that will not answer leaves the sheet up',
        (tester) async {
      _mockPlatform(serviceEnabled: false);
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.permissionPermanentlyDenied,
      );
      await tester.pumpAndSettle();

      // No handlers at all: every check throws MissingPluginException.
      _clearMocks();
      await _returnToApp(tester);

      expect(find.text(_t('locationBlockedTitle')), findsOneWidget);

      _mockPlatform(statusBeforeRequest: _granted);
      await _tap(tester, find.text(_t('notNow')));
      expect(await answer, isFalse);
    });

    testWidgets('a failed fix has nothing to re-read, so it stays put',
        (tester) async {
      _mockPlatform();
      final context = await _pumpHost(tester);
      final answer = showLocationHelpSheet(
        context: context,
        reason: LocationErrorType.addressLookupFailed,
      );
      await tester.pumpAndSettle();

      // Permission and GPS are both fine here — returning to the app proves
      // nothing about whether a fix will work, so it must not self-close.
      await _returnToApp(tester);

      expect(find.text(_t('locationNotFoundTitle')), findsOneWidget);

      await _tap(tester, find.text(_t('locationTryAgain')));
      expect(await answer, isTrue);
    });

    testWidgets('the submit carries on by itself once GPS comes back',
        (tester) async {
      // End to end: the loop fails on a dead GPS, the user switches it on,
      // and the location arrives without them touching the sheet again.
      _mockPlatform(serviceEnabled: false);
      final controller = _ScriptedLocationController([null, _location()])
        ..failWith = LocationErrorType.serviceDisabled;
      final context = await _pumpHost(tester);

      final result = resolveLocationWithGuidance(
        context: context,
        controller: controller,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text(_t('locationTurnOnGps')));

      _mockPlatform(serviceEnabled: true);
      await _returnToApp(tester);

      expect((await result)?.pinCode, '395002');
      expect(controller.attempts, 2);
    });
  });

  // ── 5. What the retry loop does with the answer ──────────────────────────

  group('resolveLocationWithGuidance', () {
    testWidgets('a location on the first try shows nothing', (tester) async {
      final controller = _ScriptedLocationController([_location()]);
      final context = await _pumpHost(tester);
      final busy = <bool>[];

      final result = resolveLocationWithGuidance(
        context: context,
        controller: controller,
        onBusyChanged: busy.add,
      );
      await tester.pumpAndSettle();

      expect((await result)?.pinCode, '395002');
      expect(controller.attempts, 1);
      expect(busy, [true, false]);
      expect(find.text(_t('locationAllowTitle')), findsNothing);
    });

    testWidgets('a retry runs the fetch again and returns the location',
        (tester) async {
      // Refused, then allowed — the ordinary recovery.
      final controller = _ScriptedLocationController([null, _location()]);
      final context = await _pumpHost(tester);
      final busy = <bool>[];

      final result = resolveLocationWithGuidance(
        context: context,
        controller: controller,
        onBusyChanged: busy.add,
      );
      await tester.pumpAndSettle();

      expect(find.text(_t('locationAllowTitle')), findsOneWidget);
      await _tap(tester, find.text(_t('locationAllowAction')));

      expect((await result)?.city, 'Surat');
      expect(controller.attempts, 2);
      // Spins for the work, stops while the user is reading.
      expect(busy, [true, false, true, false]);
    });

    testWidgets('giving up returns null without another fetch',
        (tester) async {
      final controller = _ScriptedLocationController([null]);
      final context = await _pumpHost(tester);

      final result = resolveLocationWithGuidance(
        context: context,
        controller: controller,
      );
      await tester.pumpAndSettle();

      await _tap(tester, find.text(_t('notNow')));

      expect(await result, isNull);
      expect(controller.attempts, 1);
    });

    testWidgets('the sheet follows the reason the controller recorded',
        (tester) async {
      final controller = _ScriptedLocationController([null])
        ..failWith = LocationErrorType.serviceDisabled;
      final context = await _pumpHost(tester);

      final result = resolveLocationWithGuidance(
        context: context,
        controller: controller,
      );
      await tester.pumpAndSettle();

      expect(find.text(_t('locationGpsOffTitle')), findsOneWidget);

      await _tap(tester, find.text(_t('notNow')));
      expect(await result, isNull);
    });

    testWidgets('it keeps offering the fix for as long as the user tries',
        (tester) async {
      // Three refusals, then success: the loop must not give up on its own.
      final controller =
          _ScriptedLocationController([null, null, null, _location()]);
      final context = await _pumpHost(tester);

      final result = resolveLocationWithGuidance(
        context: context,
        controller: controller,
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        expect(find.text(_t('locationAllowTitle')), findsOneWidget);
        await _tap(tester, find.text(_t('locationAllowAction')));
      }

      expect((await result)?.pinCode, '395002');
      expect(controller.attempts, 4);
    });
  });
}

/// Opens the sheet without awaiting it — for the render-only tests, which
/// assert on what is on screen and then let the teardown dispose it.
void unawaitedSheet(
  BuildContext context,
  LocationErrorType reason, {
  String? purpose,
}) {
  showLocationHelpSheet(context: context, reason: reason, purpose: purpose);
}

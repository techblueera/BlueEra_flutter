# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BlueEra is a multi-service Flutter platform (social feed, chat, video calling, jobs, food/grocery ordering, medical services, hotel booking, ride services, payments). Version 13.40.191+135, Dart SDK >=3.3.3 <4.0.0.

## Build & Development Commands

```bash
# Get dependencies
flutter pub get

# Run code generation (Hive adapters, envied env vars)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test
flutter test test/facility_controller_test.dart   # single test
```

## Architecture

**State Management:** GetX (`get: ^4.7.2`). Controllers extend `GetxController`, use `.obs` reactive variables, and are registered via `Get.put()`.

**Feature-based module structure** under `lib/features/`:
```
feature/
├── binding/       # GetX Bindings passed to the route (_getRoute(binding:)); create the screen's controllers
├── controller/    # GetX controllers (business logic)
├── model/         # Data models & API response models
├── repo/          # API repository layer (Dio-based)
├── view/          # UI screens
├── widget/        # Feature-specific widgets
└── service/       # Feature-specific services
```

**Feature domains:**
- `common/` — Auth, Home, Feed, Chat, Jobs, Food, Bottom Nav
- `personal/` — Personal profile & resume
- `business/` — Business account management
- `chat/` — Messaging, calling (WebRTC + CallKit)
- `me/` — User services (food, grocery, medical, hotel, etc.)
- `rider_order_collect/` — Delivery partner features
- `subscription/` — Subscription management
- `journey/` — Journey planning

**Core layer** (`lib/core/`):
- `api/apiService/api_base_helper.dart` — Dio HTTP client with interceptors
- `routes/route_helper.dart` — GetX route generation (100+ named routes)
- `routes/route_constant.dart` — Route name constants
- `services/` — Firebase, notifications, location services
- `constants/` — Colors, strings, enums, utilities
- `theme/themes.dart` — App theme
- `controller/` — Global controllers (navigation, etc.)

**Navigation:** GetX `GetMaterialApp` with named routes defined in `RouteHelper.generateRoute()`.

## Conventions

**Views don't touch repositories.** A screen or widget never constructs a `*Repo()`. Data calls go through a controller or a class in the feature's `service/` folder. Views keep UI state, navigation and snackbars.

**Repositories are injected.** Controllers and services take their repos as optional constructor params with a default:
```dart
class FooService {
  FooService({FooRepo? repo}) : _repo = repo ?? FooRepo();
  final FooRepo _repo;
}
```
Services return plain results (a model, a `bool`, a record, or `String?` where null means success and a string is the error message) rather than showing UI themselves. The exception is one-off action services like `VideoActions`, which show their own snackbar.

**Controller lifetime — pick one:**
- **Route-scoped:** register it in a `Bindings` class and pass that to the route: `_getRoute(() => Screen(), binding: FooBinding())` in `route_helper.dart`, or `GetPageRoute(page:, binding:)` for a `Navigator.push`. GetX deletes the controller when the route closes.
- **Session-wide:** give the class a permanent accessor, use it everywhere, and drop it in `LogoutHelper` (`lib/core/constants/logout_helper.dart`) so the next account starts clean:
  ```dart
  static FooController get to => Get.isRegistered<FooController>()
      ? Get.find<FooController>()
      : Get.put(FooController(), permanent: true);
  ```
  In `LogoutHelper`, call it as `_drop(() => deleteIfRegistered<FooController>());`. Always wrap it in a closure; a bare generic tear-off breaks release builds.
- **Per-entity:** use a tag, e.g. `Get.put(X(), tag: businessId)`, and delete it with the same tag.

Don't register the same class as permanent in one place and non-permanent in another. The first screen to register it would then decide whether GetX deletes it. Helpers live in `lib/core/constants/getx_utils.dart`: `getOrPut` (find or put), `putLazy` (avoids building a throwaway instance in `build`), and `deleteIfRegistered` (force delete).

A plain `MaterialPageRoute` never frees the controllers registered under it. Only use one when something outside the screen still needs those controllers, as with the shell, call screens and sign-up flow.

**Tests** fake a repo by extending the real one and overriding only the methods under test. They build responses with:
```dart
ResponseModel(statusCode: 200, response: Response(requestOptions: RequestOptions(), statusCode: 200, data: {...}))
```
Import dio with `show RequestOptions, Response` and get with `hide Response`. Call `Get.reset` in `setUp`/`tearDown`, and `Hive.init(Directory.systemTemp.createTempSync().path)` in `setUpAll` for anything that opens a box.

## Key Services & Integrations

- **API:** Dio HTTP client (`lib/core/api/apiService/`)
- **WebSockets:** socket_io_client for chat (`wss://chat.beapp.in`) and live tracking (`https://map.beapp.in/`)
- **Firebase:** FCM push notifications, Crashlytics
- **Video Calling:** flutter_webrtc + flutter_callkit_incoming
- **Local Storage:** Hive (with adapters generated via build_runner) + flutter_secure_storage
- **Payments:** Razorpay
- **AI:** Google Generative AI (Gemini)
- **Maps:** google_maps_flutter + geolocator

## Environment Configuration

- `lib/environment_config.dart` — Sets base URLs and API keys per environment (PROD/DEV)
- `lib/env.dart` — Uses `envied` package for obfuscated env vars from `.env`
- Environment is set in `main()` via `projectKeys(environmentType: AppConstants.prod)`

## Global State

Key global variables in `main.dart`: `authTokenGlobal`, `userIdGlobal`, `userIDFromServer`, `deviceOsVersionGlobal`, `appVersion`.

Permanent controllers: `AuthController`, `CallController` (permanent), `NavigationHelperController`, `GlobalMessageService`.

## App Initialization Flow (main.dart)

Firebase init → device info → Hive init → localization → auth controller registration → login status check → user data load → call controller setup → overlay listener → cache init → `runApp(MyApp())`. Background FCM handler and CallKit listener handle incoming calls from killed state.

## Lint Configuration

Uses `package:flutter_lints/flutter.yaml` with `constant_identifier_names` errors ignored. See `analysis_options.yaml`.
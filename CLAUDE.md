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
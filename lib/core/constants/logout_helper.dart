import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/controller/app_background_controller.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/address_cache_service.dart';
import 'package:BlueEra/core/services/analytics_service.dart';
import 'package:BlueEra/core/services/business_profile_cache.dart';
import 'package:BlueEra/core/services/chat_storage_paths.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/home_cache_service.dart';
import 'package:BlueEra/core/services/personal_profile_cache.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/account_plan/controller/account_plan_controller.dart';
import 'package:BlueEra/features/account_plan/controller/account_plan_entitlement.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_product_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_v3_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/location_update_service.dart';
import 'package:BlueEra/features/me/automotive_products/service/automotive_local_store.dart';
import 'package:BlueEra/features/me/food/service/food_local_store.dart';
import 'package:BlueEra/features/me/medical/service/medical_local_store.dart';
import 'package:BlueEra/features/me/manufacturer/service/manufacturer_local_store.dart';
import 'package:BlueEra/features/me/product/service/product_local_store.dart';
import 'package:BlueEra/features/me/vehicle/v3/service/vehicle_local_store.dart';
import 'package:BlueEra/features/me/grocery/service/grocery_local_store.dart';
import 'package:BlueEra/features/me/grocery/service/grocery_order_local_store.dart';
import 'package:BlueEra/core/services/other_profile_dirty.dart';
// The `me/others` and `me/automotive_service` forks are line-for-line twins,
// so the two halves below collide on every name they did NOT prefix — most
// of all `DayTiming`, which both timing controllers declare. Unprefixed, the
// pair compiles only for as long as nobody writes `DayTiming` in this file;
// the day someone does it becomes an ambiguous-import error with no obvious
// cause. Each import is therefore narrowed to the one controller this file
// actually drops, which is all it ever wanted from them.
import 'package:BlueEra/features/me/automotive_service/controller/business_profile_full_controller.dart'
    show AutomotiveBusinessProfileFullController;
import 'package:BlueEra/features/me/automotive_service/controller/management_controller.dart'
    show AutomotiveManagementController;
import 'package:BlueEra/features/me/automotive_service/controller/other_service_photo_controller.dart'
    show AutomotiveServicePhotoController;
import 'package:BlueEra/features/me/automotive_service/controller/timing_controller.dart'
    show AutomotiveTimingController;
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart'
    show BusinessProfileFullController;
import 'package:BlueEra/features/me/others/controller/management_controller.dart'
    show ManagementController;
import 'package:BlueEra/features/me/others/controller/other_service_photo_controller.dart'
    show OtherServicePhotoPhotoController;
import 'package:BlueEra/features/me/others/controller/timing_controller.dart'
    show TimingController;
import 'package:BlueEra/features/me/others/service/other_profile_local_store.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class LogoutHelper {
  LogoutHelper._();

  /// Shows a refined logout confirmation dialog. The dialog leans
  /// into a "soft farewell" tone — floating waving-hand disc, a
  /// brief reassuring message, and a clear stay/sign-out action
  /// pair — so the moment of leaving feels like a polite handshake
  /// rather than a system alert.
  static Future<void> showLogoutDialog(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'logout',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        // Soft scale-in (0.92 → 1.0) with the standard ease-out-back
        // curve, paired with a fade. Snappy enough to feel responsive
        // but loose enough to read as a moment of pause.
        final eased = Curves.easeOutBack.transform(
          anim.value.clamp(0.0, 1.0),
        );
        final scale = 0.92 + (eased.clamp(0.0, 1.0)) * 0.08;
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: scale,
            child: _LogoutDialog(
              onConfirm: () async {
                Navigator.of(ctx, rootNavigator: true).pop();
                await _performLogout();
              },
              onCancel: () =>
                  Navigator.of(ctx, rootNavigator: true).pop(),
            ),
          ),
        );
      },
    );
  }

  /// Two-phase logout: phase 1 wipes data while the source screen is still
  /// mounted under the loader (no Rx writes → no Obx rebuilds → no orphan
  /// controller re-creations via getOrPut). Phase 2 runs after navigation
  /// when reactive writes are safe.
  static Future<void> _performLogout() async {
    if (Get.isDialogOpen ?? false) Get.back();
    AppLoader.showLogout();

    // Detach the GA4 identity BEFORE the wipe, so nothing logged during the
    // teardown is still attributed to the account signing out. Not awaited —
    // analytics must never delay or fail a logout.
    unawaited(AnalyticsService.I.setUser(null));

    // Phase 1 — non-reactive bulk wipe.
    try {
      await SharedPreferenceUtils.clearPreferenceDataOnly();
      LiveLocationService().stop();
      await clearAllLocalData();
    } catch (_) {}

    Get.offAllNamed(RouteHelper.getMobileNumberLoginRoute());
    await WidgetsBinding.instance.endOfFrame;

    // Phase 2 — reactive cleanup.
    try {
      _resetSessionControllers();
      await SharedPreferenceUtils.clearPreferenceReactive();
      if (Get.isRegistered<LanguageControllerNew>()) {
        await Get.find<LanguageControllerNew>().reset();
      }
    } catch (_) {}
  }

  /// Force-deletes the controllers that survive `Get.offAllNamed` and
  /// would otherwise leak the previous session's `.obs` data:
  /// - `ViewPersonalDetailsController`: registered `permanent:true`.
  /// - `ViewBusinessDetailsController`: not flagged permanent, but several
  ///   `Get.put` calls happen from non-route contexts (AuthController,
  ///   drawer), so smart-management never auto-disposes them.
  /// - `ChatViewController`: owns chat sockets/listeners.
  static void _resetSessionControllers() {
    _drop(() => deleteIfRegistered<ChatViewController>());
    _drop(() => deleteIfRegistered<ViewPersonalDetailsController>());
    _drop(() => deleteIfRegistered<ViewBusinessDetailsController>());
    _resetMeSectionControllers();
  }

  /// Deletes one controller, absorbing whatever its `onClose` does.
  ///
  /// `Get.delete(force: true)` runs the controller's own teardown — disposing
  /// text controllers, tickers, sockets, a Razorpay instance. One of those
  /// throwing used to abort the whole reset AND the two steps that follow it in
  /// phase 2 (the reactive preference wipe and the language reset), because
  /// they share a try/catch. Each drop now stands alone.
  ///
  /// Callers MUST wrap the call in a closure — `_drop(() =>
  /// deleteIfRegistered<T>())` — and never pass the generic tear-off
  /// `_drop(deleteIfRegistered<T>)`. A tear-off carrying an explicit type
  /// argument compiles to a const `InstantiationConstant` holding a bare
  /// reference to `T`. If nothing reachable from `main` ever CONSTRUCTS a `T`,
  /// the AOT tree shaker drops the class, that constant is left pointing at a
  /// class which no longer exists, and the release build dies before it links:
  ///
  /// ```
  /// Error: Lookup failed: AutomotiveTimingController in package:BlueEra/...
  /// Dart snapshot generator failed with exit code 254
  /// ConstFinder failure: Reference to ... is not bound to an AST node
  /// ```
  ///
  /// That is exactly what a dead screen looks like from here: this file is
  /// often the LAST reference to a controller, so it is the file that pays for
  /// the shaking. Debug and profile builds do not tree shake, so it only ever
  /// surfaces on a release build. Inside a closure the type argument sits in
  /// ordinary retained code, which keeps the class declaration alive and bound.
  static void _drop(void Function() delete) {
    try {
      delete();
    } catch (e) {
      debugPrint('⚠️ logout: controller teardown failed — $e');
    }
  }

  /// Drops the me-section merchant controllers and the plan entitlement.
  ///
  /// Wiping the boxes is only half of "clear on logout". Each of these
  /// controllers holds the SAME data in memory — the Products-tab lists, the
  /// category trees, and the `FetchCache` stamp that says "this is fresh, don't
  /// refetch" — and they are deliberately kept for the whole session
  /// (`MedicalScreen` / `GroceryScreen` document why they are not disposed on
  /// tab exit). A logout that only cleared the disk therefore left the previous
  /// merchant's catalogue on screen for the next account signing in without an
  /// app restart, and the stamp stopped anything from refetching it.
  ///
  /// [AccountPlanEntitlement] is the one that matters most: it is registered
  /// `permanent: true`, it caches `hasActivePlan`, and it is the GO-LIVE GATE.
  /// Left behind, the next account inherits the previous one's paid plan.
  ///
  /// Safe here because this runs after `Get.offAllNamed` — every screen that
  /// held one of these is gone, and each is re-created by `getOrPut` on the
  /// next open.
  /// Only controllers whose state IS the previous account's data. Anything the
  /// login screen or the next sign-in still needs — `AuthController`, the
  /// language controller, the app-background statics — is deliberately left
  /// registered, exactly as the preserved halves of Hive (business categories,
  /// profession types) and SharedPreferences (base URL, the per-account
  /// one-time flags) are deliberately left on disk.
  static void _resetMeSectionControllers() {
    _drop(() => deleteIfRegistered<AccountPlanEntitlement>());
    _drop(() => deleteIfRegistered<AccountPlanController>());
    _drop(() => deleteIfRegistered<GroceryController>());
    _drop(() => deleteIfRegistered<RestaurantController>());
    _drop(() => deleteIfRegistered<FoodServiceController>());
    _drop(() => deleteIfRegistered<InventoryController>());
    _drop(() => deleteIfRegistered<ProductController>());
    _drop(() => deleteIfRegistered<MedicalController>());
    _drop(() => deleteIfRegistered<AutomotiveInventoryController>());
    _drop(() => deleteIfRegistered<AutomotiveProductController>());
    _drop(() => deleteIfRegistered<ManufacturerInventoryController>());
    _drop(() => deleteIfRegistered<ManufacturerProductController>());
    _drop(() => deleteIfRegistered<VehicleV3Controller>());
    _resetOtherServiceControllers();
  }

  /// Drops the "other service" business-profile controllers.
  ///
  /// These are the reason `GET other-service/business-profile` stopped firing
  /// after a logout followed by a login. The lookup is reached from
  /// `BusinessProfileFullController.getBusinessProfileFull()`, and the screen
  /// only calls that when its cached profile is null:
  ///
  /// ```dart
  /// if (_otherController.businessProfile.value == null) {
  ///   _otherController.getBusinessProfileFull();
  /// }
  /// ```
  ///
  /// Logout wipes secure storage and the globals, but NOT the GetX registry —
  /// `Get.deleteAll()` is never called anywhere — and this controller is a
  /// plain `Get.put` singleton created by `getOrPut`. So it survived the
  /// logout still holding the previous account's profile, the null guard saw
  /// non-null, and the whole fetch was skipped: no id lookup, no
  /// `/business-profile/<id>/full`, and the Overview tab rendered the PREVIOUS
  /// account's management, gallery and timings to the account that just signed
  /// in. Dropping the controller restores the null that makes the screen fetch.
  ///
  /// The section controllers alongside it leak the same way — each holds its
  /// own copy of that profile's data — and [OtherProfileDirty] is cleared for
  /// the same reason: a pending "gallery changed" flag from the previous
  /// account would otherwise spend itself on the next account's first visit.
  ///
  /// Each fork is listed separately because they are now separately
  /// addressable. The automotive controllers used to be declared under the
  /// SAME simple names as their me/others originals, and GetX keys its registry
  /// by the simple class name — so the two forks shared one slot, only one
  /// could be registered at a time, and `Get.find<T>()` on the other one threw
  /// on the cast. They carry an `Automotive` prefix now.
  static void _resetOtherServiceControllers() {
    _drop(() => deleteIfRegistered<BusinessProfileFullController>());
    _drop(() => deleteIfRegistered<OtherServicePhotoPhotoController>());
    _drop(() => deleteIfRegistered<ManagementController>());
    _drop(() => deleteIfRegistered<TimingController>());

    _drop(() => deleteIfRegistered<AutomotiveBusinessProfileFullController>());
    _drop(() => deleteIfRegistered<AutomotiveServicePhotoController>());
    _drop(() => deleteIfRegistered<AutomotiveManagementController>());
    _drop(() => deleteIfRegistered<AutomotiveTimingController>());

    _drop(OtherProfileDirty.clear);
  }

  /// Logout's local-storage step, in two halves.
  ///
  /// Everything the app keeps on disk is one of two things, and which one it is
  /// is a property of the DATA, not of the call site that happens to write it:
  ///
  /// * **[clearAccountLocalData]** — belongs to the account signing out
  ///   (profiles, chats, feeds, orders, its own store's catalog). Wiped.
  /// * **[readSharedLocalData] / [restoreSharedLocalData]** — identical for
  ///   every account, because it is the platform's own reference data. Kept.
  ///
  /// This orchestrates the pair: lift the shared half out, wipe, put it back.
  /// The wipe itself stays wholesale — `Hive.deleteFromDisk()` also catches
  /// boxes that no registry knows about, and narrowing it to an allow-list is
  /// how a future feature's box quietly starts leaking between accounts.
  ///
  /// Public so the API 401 handler can reuse it. Non-reactive.
  static Future<void> clearAllLocalData() async {
    final shared = await readSharedLocalData();
    await clearAccountLocalData();
    await restoreSharedLocalData(shared);
  }

  /// The SHARED half — read it BEFORE the wipe.
  ///
  /// Today this is the onboarding catalog: the BUSINESS categories and the
  /// INDIVIDUAL profession types. **Neither is cleared on logout.** They are
  /// the same list for every user in the country, and they are also the two
  /// lists the account-type screen cannot draw without — so dropping them costs
  /// the next user two API calls and a shimmer, and costs anyone who signs out
  /// without a connection the ability to sign in at all.
  ///
  /// The in-memory copies survive too: `AuthController` holds both catalogs in
  /// its onboarding buckets and is deliberately NOT in
  /// [_resetMeSectionControllers], so the next sign-in reads them without
  /// touching Hive at all (see `loadCategoriesCacheFirstThenRefresh`).
  ///
  /// Add to this only data that is genuinely account-agnostic. Anything keyed
  /// to a user, a business, or a device's session belongs in the other half.
  static Future<Map<String, dynamic>> readSharedLocalData() =>
      HiveServices.readSharedCatalogSnapshot();

  /// Writes the shared half back once the boxes have been reopened.
  static Future<void> restoreSharedLocalData(
          Map<String, dynamic> snapshot) async =>
      HiveServices.restoreSharedCatalogSnapshot(snapshot);

  /// The ACCOUNT half — wipes Hive, the per-feature caches, the chat history
  /// and the app docs dir, then reopens the boxes the app needs to keep
  /// running in this same process.
  ///
  /// Call [clearAllLocalData] rather than this directly: on its own this also
  /// takes the shared half with it, which is exactly what the pairing exists
  /// to prevent.
  static Future<void> clearAccountLocalData() async {
    // Each clear is INDEPENDENTLY guarded. They used to share one try/catch,
    // which meant the first one to throw silently skipped every clear after it
    // — a locked box or a half-initialised cache would leave six merchant
    // snapshots on disk, and the only thing standing between that and the next
    // account reading them was `deleteFromDisk()` in the next block, which can
    // fail for exactly the same reasons.
    await _clearEach(<Future<void> Function()>[
      BusinessProfileCache.clear,
      PersonalProfileCache.clear,
      // The per-feature merchant stores: grocery (top-selling, category
      // inventory, catalog tree), food (home menu, Offer Dish rail, category
      // tree), product / automotive / manufacturer (top-selling, category
      // inventory, super-category list), medical (Top Selling, my-categories,
      // category tree) and vehicle v3 (seller category tree only).
      //
      // `deleteFromDisk()` below takes them too — they are named here for the
      // same reason the profile caches are: each store owns account data, so
      // the place that drops account data names it, and a new vertical's box
      // going missing from this list is an obvious omission.
      GroceryLocalStore.clearAll,
      // The "other service" full-profile snapshot. Same reason as the rest:
      // it is one account's profile, and the Overview tab is served from it
      // rather than from the network, so leaving it behind would show the
      // previous merchant's management, gallery and timings to the next one.
      OtherProfileLocalStore.clearAll,
      // The locally-persisted order ids. There is no server order list for
      // self-pickup (ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md §7), so this box is
      // the only record the device has — and for exactly that reason it must
      // not survive into the next account.
      GroceryOrderLocalStore.clearAll,
      FoodLocalStore.clearAll,
      ProductLocalStore.clearAll,
      MedicalLocalStore.clearAll,
      AutomotiveLocalStore.clearAll,
      ManufacturerLocalStore.clearAll,
      VehicleLocalStore.clearAll,
    ]);
    try {
      await Hive.deleteFromDisk();
      final dir = await getApplicationDocumentsDirectory();
      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (_) {}

    // The relocated chat-history stores live under the external
    // `Chat History/` folder, outside the default Hive dir wiped above —
    // clear them explicitly so the next user can't read the previous user's
    // cached chats.
    try {
      await ChatStoragePaths.clearHistory();
    } catch (_) {}

    // `Hive.deleteFromDisk()` closes AND deletes every box, and the directory
    // delete above removes the storage folder. Without reopening, the next
    // login in the SAME app session (no restart) throws
    //   HiveError: Box not found. Did you forget to call Hive.openBox()?
    // on every cached read (business categories, professions, home feed,
    // address…). Recreate the storage dir and reopen exactly the boxes that
    // `main()` opens at startup so the fresh session is fully functional.
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (!dir.existsSync()) await dir.create(recursive: true);
      await Future.wait<void>([
        HiveServices.init(),
        HomeCacheService.init(),
        AddressCacheService.init(),
        AppBackgroundController.preload(),
        Hive.openBox('languageBox'),
        Hive.openBox('localizationBox'),
      ]);
    } catch (_) {}

    // Hive on disk is wiped above, but the live app-background statics would
    // linger until restart — reset them so the next user starts on defaults.
    AppBackgroundController.resetInMemory();
  }

  /// Runs every clear, whatever any single one does.
  ///
  /// Concurrent AND individually guarded, which is the whole point: they are
  /// independent boxes, so waiting for each in turn only makes the logout
  /// spinner longer, and one failure must not take the others with it.
  ///
  /// `Future.wait` with a per-item catch rather than a bare `Future.wait`: the
  /// latter reports the FIRST error and abandons the rest, which is the same
  /// trap the single try/catch was.
  static Future<void> _clearEach(List<Future<void> Function()> clears) {
    return Future.wait<void>(
      clears.map((clear) async {
        try {
          await clear();
        } catch (e) {
          debugPrint('⚠️ logout: a local-store clear failed — $e');
        }
      }),
    );
  }
}

// ─────────────────────────────────────────────
// LOGOUT DIALOG — refined card with a soft-farewell tone.
// Floating waving-hand disc bleeds above the card edge; tracked
// "SIGN OUT" eyebrow over a display headline + 28-px accent rule;
// reassuring two-line body; ghost-vs-filled action pair where the
// safer "Stay" is the prominent (filled) action and the destructive
// "Sign me out" is the deliberate ghost button.
// ─────────────────────────────────────────────
class _LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _LogoutDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFEDEFF4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Floating waving-hand disc — overflows above the card so
                // the eye lands on the icon first (the "human" cue),
                // then the headline.
                Positioned(
                  top: -32,
                  left: 0,
                  right: 0,
                  child: Center(child: _IconDisc()),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tracked eyebrow.
                      Text(
                        AppStrings.signOutEyebrow.tr,
                        style: TextStyle(
                          fontFamily: AppConstants.OpenSans,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Display headline — bigger, slightly negative
                      // tracking for a refined feel.
                      Text(
                        AppStrings.signingOffTitle.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppConstants.OpenSans,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Accent rule — tiny brand stroke that anchors
                      // the headline like an editorial flourish.
                      Container(
                        width: 28,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Reassuring body copy. Two short lines that say
                      // "we'll be here when you come back".
                      Text(
                        AppStrings.signOutDialogBody.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Action pair — filled "Stay" leads (safer path),
                      // ghost "Sign me out" is the deliberate exit.
                      Row(
                        children: [
                          Expanded(
                            child: _GhostButton(
                              label: AppStrings.signMeOut.tr,
                              onTap: onConfirm,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PrimaryButton(
                              label: AppStrings.stay.tr,
                              onTap: onCancel,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconDisc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withValues(alpha: 0.78),
              ],
            ),
          ),
          child: const Icon(
            Icons.waving_hand_rounded,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withValues(alpha: 0.82),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

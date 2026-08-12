import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/controller/app_background_controller.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/address_cache_service.dart';
import 'package:BlueEra/core/services/business_profile_cache.dart';
import 'package:BlueEra/core/services/chat_storage_paths.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/home_cache_service.dart';
import 'package:BlueEra/core/services/personal_profile_cache.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/location_update_service.dart';
import 'package:BlueEra/features/me/grocery/service/grocery_local_store.dart';
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
    deleteIfRegistered<ChatViewController>();
    deleteIfRegistered<ViewPersonalDetailsController>();
    deleteIfRegistered<ViewBusinessDetailsController>();
  }

  /// Wipes Hive (all boxes), per-feature caches, and the app docs dir.
  /// Public so the API 401 handler can reuse it. Non-reactive.
  static Future<void> clearAllLocalData() async {
    try {
      await BusinessProfileCache.clear();
      await PersonalProfileCache.clear();
      // The grocery admin snapshot (top-selling, category inventory, catalog
      // tree). `deleteFromDisk()` below takes it too — this is here for the
      // same reason the profile caches are: the store owns account data, so the
      // place that drops account data names it explicitly.
      await GroceryLocalStore.clearAll();
    } catch (_) {}
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

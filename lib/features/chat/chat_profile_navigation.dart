import 'dart:async';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/navigation/profile_taxonomy.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/user_by_phone_model.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A lookup that lands inside this window opens the profile with no loading UI
/// at all — below it a dialog would only flash.
const Duration _spinnerAfter = Duration(milliseconds: 250);

/// Hard ceiling on how long a profile tap may block. Past this we open from the
/// ids the caller already had; the lookup still finishes into the cache.
const Duration _maxLookupWait = Duration(seconds: 3);

/// ONE entry point for every profile tap in chat — the name/avatar in a chat
/// screen's app bar, an @mention inside a group message, and the "Visit
/// profile" CTA on the sheet a tapped 10-digit number opens.
///
/// All of them end at [openVisitProfile], the app-wide visit resolver, so a
/// chat with a lab / pharmacy / restaurant opens THAT business's screen rather
/// than the generic business profile every chat surface used to push.
///
/// ## Why the phone lookup
///
/// A chat screen only holds what the chat list gave it — name, avatar, contact
/// number, conversation type. It has no `type_of_business`, no
/// sub-category, and often no business id, which is exactly what the visit
/// routing keys on. `user-service/user/by-phone/{phone}` returns all of it, and
/// the app already calls it (that's the sheet behind a tapped number). So when
/// a contact number is at hand, [openChatProfile] resolves the profile through
/// that same endpoint first and routes on the real record.
///
/// Without a usable number — or when the lookup finds nobody — it falls back to
/// the ids the caller already had, which is exactly the old behaviour.
///
/// ## Why the tap feels instant
///
/// The lookup is cache-first ([ChatViewController.phoneUserCache]), so a number
/// already resolved this session — by an inline preview, an earlier tap, or a
/// [ChatViewController.ensurePhoneUserLoaded] prefetch fired when the member
/// sheet opened — navigates with no network wait and no dialog at all.
///
/// On a cold number the spinner is only raised after [_spinnerAfter]; a fast
/// response never flashes a dialog. And the wait is bounded by [_maxLookupWait]
/// — past that we open from the ids the caller already had rather than leaving
/// the user staring at a spinner. The lookup keeps running and lands in the
/// cache, so the next tap on that person is instant.
Future<void> openChatProfile({
  /// The other participant's number. When present and 10 digits, this is what
  /// gets the full profile.
  String? contactNo,

  /// Fallbacks used when the lookup can't run or finds nobody.
  String? userId,
  String? businessId,

  /// `INDIVIDUAL` / `BUSINESS` — the conversation's account type, as the chat
  /// list reported it.
  String? accountType,
}) async {
  final String? number = _tenDigits(contactNo);
  if (number != null) {
    final controller = getOrPut(() => ChatViewController());

    // ── Fast path: already resolved (cached or prefetched) ──────────────────
    if (controller.isPhoneChecked(number)) {
      final cached = controller.cachedPhoneUser(number);
      if (cached != null) {
        await openPhoneUserProfile(cached);
        return;
      }
      // Checked, no BlueEra account → straight to the id fallback below.
    } else {
      // Concurrent callers for the same number share this one future, so a
      // double tap costs one request instead of dropping the second tap.
      final Future<UserByPhoneModel?> lookup =
          controller.resolveBlueEraUserByPhone(number);

      UserByPhoneModel? user;
      bool settled = false;
      try {
        user = await lookup.timeout(_spinnerAfter);
        settled = true;
      } on TimeoutException {
        // Slow network — fall through and put the spinner up.
      } catch (e) {
        settled = true;
        logs('openChatProfile: by-phone lookup failed — $e');
      }

      if (!settled) {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        try {
          user = await lookup.timeout(_maxLookupWait);
        } on TimeoutException {
          logs('openChatProfile: by-phone lookup too slow — opening from ids');
        } catch (e) {
          logs('openChatProfile: by-phone lookup failed — $e');
        } finally {
          if (Get.isDialogOpen ?? false) Get.back();
        }
      }

      if (user != null) {
        await openPhoneUserProfile(user);
        return;
      }
    }
    // Not a BlueEra user / lookup failed or timed out → fall through to the ids.
  }

  await openVisitProfile(
    accountType: accountType,
    businessId: businessId,
    userId: userId,
    screenFrom: AppConstants.chatScreen,
  );
}

/// Routes an already-resolved `by-phone` record — used by the sheet a tapped
/// number opens, which holds the very same model.
Future<void> openPhoneUserProfile(UserByPhoneModel user) {
  return openVisitProfile(
    accountType: user.accountType,
    typeOfBusiness: user.businessType,
    // `category_Of_Business` is the tag; `category_details.name` is its display
    // name. Either resolves — the visit resolver normalises both.
    categoryOfBusiness:
        cleanTaxonomyValue(user.categoryOfBusiness) ?? user.categoryName,
    // Individuals arrive with a designation and no `profile_type`; the resolver
    // maps it back to one, so a self-employed plumber opens their service
    // profile rather than the generic one.
    profession: user.designation,
    businessId: user.businessId,
    userId: user.id,
    screenFrom: AppConstants.chatScreen,
  );
}

/// The last 10 digits of [raw], or `null` when there aren't 10 — the shape the
/// by-phone endpoint takes. Checked here rather than in the controller so a
/// tap on a chat with no number just falls back quietly instead of raising the
/// controller's "Invalid mobile number" snackbar.
String? _tenDigits(String? raw) {
  final digits = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 10) return null;
  return digits.substring(digits.length - 10);
}

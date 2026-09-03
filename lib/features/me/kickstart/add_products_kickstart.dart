// ADD-PRODUCTS KICKSTART — the app-open page for a merchant whose shelves are
// still empty.
//
// A shop with no catalogue is invisible: it can't be ordered from, it earns
// nothing, and nothing else the merchant does in the app matters until it has
// stock. So on launch, a catalogue business (grocery, restaurant, product shop,
// manufacturer, auto-parts shop) that has published nothing opens straight onto
// its own add-products screen — the same screen its "Add product" button leads
// to, not a marketing page about it, so the first tap can already be a product.
//
// It is a PAGE, not a dialog: adding stock is a multi-step flow (pick →
// variants → publish) that a dismissible sheet cannot host. The close (✕) in
// the top-left is the escape hatch — one tap and the merchant is in the app.
//
// Shown once per APP OPEN — every launch the catalogue is still empty, and at
// most once within a launch however many times the home shell is rebuilt. No
// "seen" flag is persisted: an empty shop is a problem every day it stays
// empty, and the page stops appearing by itself the moment the merchant
// publishes anything, because the emptiness check is the only thing gating it.

import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/automotive_products/controller/automotive_inventory_controller.dart';
import 'package:BlueEra/features/me/automotive_products/view/admin/automotive_product_super_category_screen.dart';
import 'package:BlueEra/features/me/food/controller/restaurant_controller.dart';
import 'package:BlueEra/features/me/food/view/admin/food_category_menu_screen.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_super_category_screen.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_inventory_controller.dart';
import 'package:BlueEra/features/me/manufacturer/view/admin/manufacturer_add_product_via_ai_step1.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/view/admin/product_super_category_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Burned once the page has been shown (or is being decided) this launch.
/// Static because the host screen can be rebuilt / re-mounted by navigation
/// while the process lives on.
bool _shownThisLaunch = false;

/// Guards two callers racing the async checks below into two pushes.
bool _decisionInFlight = false;

/// How long to wait for the business profile before giving up. The catalogue
/// can't be picked without [businessTypeGlobal], and that arrives with the
/// profile fetch this same launch kicked off.
const Duration _profileWait = Duration(seconds: 8);

/// Opens the kickstart page when this account is a catalogue business with an
/// empty catalogue. Safe to call on every launch from anywhere — every reason
/// not to show is checked here.
///
/// Fails CLOSED (shows nothing) on every uncertainty: no profile, an unknown
/// business type, a catalogue lookup that errored or never resolved. A page
/// thrown in the merchant's face on a flaky network would be worse than a
/// missed nudge, and the Products tab still carries its own empty state.
Future<void> showAddProductsKickstartIfNeeded(BuildContext context) async {
  if (_shownThisLaunch || _decisionInFlight) {
    logs('KICKSTART: skip — already handled this launch');
    return;
  }
  logs('KICKSTART: checking…');
  if (isGuestUser() || !isBusinessUser()) {
    logs('KICKSTART: skip — not a business account '
        '(accountType=$accountTypeGlobal)');
    return;
  }
  _decisionInFlight = true;
  try {
    final businessCtrl =
        getOrPut(() => ViewBusinessDetailsController(), permanent: true);
    await _awaitBusinessProfile(businessCtrl);
    if (!context.mounted) return;

    logs("KICKSTART: businessType='$businessTypeGlobal' "
        "category='$businessCategoryGlobal' businessId='$businessId'");
    final probe = _CatalogueProbe.forBusinessType(businessTypeGlobal);
    if (probe == null) {
      // Not a catalogue business (or the profile never resolved) — nothing to
      // add, so nothing to open.
      logs("KICKSTART: skip — no catalogue for businessType "
          "'$businessTypeGlobal'");
      return;
    }
    if (!await probe.isKnownEmpty()) {
      logs('KICKSTART: skip — ${probe.label} catalogue is not known-empty '
          '(hasItems=${probe.hasItems()}, loaded=${probe.isLoaded()})');
      return;
    }
    if (_shownThisLaunch) return;

    // Something is on top — the joining-bonus card (which pops on this same
    // post-frame for a new merchant), a live-photo sheet, a notification deep
    // link. Pushing over it would bury it, so WAIT for it to clear rather than
    // giving up: a first-launch collision with the bonus card used to cost the
    // whole showing, and this page only gets one.
    //
    // Dialogs and modal sheets are routes too, so `isCurrent` sees them —
    // GetX's `isDialogOpen` / `isBottomSheetOpen` flags are not consulted
    // because they only track sheets opened through Get and go stale when one
    // is dismissed with `Navigator.pop`, which most of this app's sheets do.
    if (!await _waitUntilHostIsOnTop(context)) {
      logs('KICKSTART: skip — another route stayed on top');
      return;
    }
    if (!context.mounted || _shownThisLaunch) return;

    _shownThisLaunch = true;
    logs('KICKSTART: empty ${probe.label} catalogue — opening Quick Upload');
    Navigator.of(context).push(_kickstartRoute(probe.buildScreen()));
  } finally {
    _decisionInFlight = false;
  }
}

/// Polls until the calling screen is the top route again, giving whatever is
/// above it (a dialog, a sheet) a chance to be dismissed. ~12s, then gives up:
/// past that the merchant has navigated somewhere on purpose and this page
/// would be an interruption rather than a start.
Future<bool> _waitUntilHostIsOnTop(BuildContext context) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    if (!context.mounted) return false;
    // `isCurrent` is false only while something sits ON TOP of this route; a
    // null ModalRoute (no enclosing route) is not a reason to block.
    if (ModalRoute.of(context)?.isCurrent != false) return true;
    if (attempt == 0) {
      logs('KICKSTART: waiting — another route is on top');
    }
    await Future.delayed(const Duration(milliseconds: 1500));
  }
  return false;
}

/// Waits for the profile that resolves [businessTypeGlobal]. Returns as soon as
/// it is known — the launch fetch is usually already in flight, and this only
/// bridges the gap. Same completer pattern as the live-photo sheet's gate.
Future<void> _awaitBusinessProfile(
    ViewBusinessDetailsController controller) async {
  if (businessTypeGlobal.isNotEmpty) return;
  if (controller.viewBusinessResponse.status != Status.COMPLETE) {
    // Ask for it ourselves rather than waiting on a fetch that may never have
    // started (deferred/deep-link open).
    //
    // NOT `silent: true`, and no "is one already in flight?" guard of our own.
    // Both were wrong here:
    //
    //  * `silent` skips the coalescer outright
    //    (view_business_details_controller.dart:292) — that exemption exists so
    //    a post-update refresh can't be handed a pre-update in-flight response,
    //    which this is not.
    //  * the guard was `status != Status.LOADING`, but `viewBusinessResponse`
    //    is never assigned `ApiResponse.loading` anywhere in that controller —
    //    it goes INITIAL → COMPLETE/ERROR — so the guard could never be false
    //    and never suppressed anything.
    //
    // Together they fired a SECOND `GET user-service/business/<id>` alongside
    // the bottom-nav boot fetch on every fresh login, for a profile this
    // function then usually discards. Plain (non-silent) piggy-backs on the
    // in-flight fetch instead.
    unawaited(controller.viewBusinessProfile());
  }
  if (businessTypeGlobal.isNotEmpty) return;

  // Listen to the PROFILE, not to `isBusinessProfileReady`: that flag is a
  // latch on a permanent controller, so on a re-login it can already be true
  // and never fire again — this would then always wait out the timeout.
  final completer = Completer<void>();
  late final Worker worker;
  worker = ever(controller.businessProfileDetails, (_) {
    if (businessTypeGlobal.isNotEmpty && !completer.isCompleted) {
      completer.complete();
    }
  });
  try {
    await completer.future.timeout(_profileWait);
  } on TimeoutException {
    // Falls through with an empty type — the caller then finds no probe and
    // shows nothing, which is the intended fail-closed behaviour.
  } finally {
    worker.dispose();
  }
}

/// Rises from the bottom of the screen over 450ms, fading and scaling up as it
/// arrives, and sinks back down on close.
///
/// A full bottom-to-top travel, not a nudge: this page appears on its own, so
/// the motion has to read as "something new has arrived on top of the app" —
/// the same grammar as a sheet, which is exactly the promise the ✕ keeps. A
/// short slide would read as an ordinary push the merchant had asked for.
///
/// The scale is slight (0.94 → 1.0) and rides the same curve, so the page grows
/// into place rather than sliding under the finger.
Route<void> _kickstartRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          // Fades in over the FIRST HALF of the travel: by the time the page is
          // halfway up it is fully opaque, so the arrival lands solidly instead
          // of the last frames looking like a still image.
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: curved, curve: const Interval(0, 0.5)),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Which catalogue a business type owns, how to ask whether it is empty, and
/// which Quick Upload screen to open.
///
/// The three services are separate — asking the grocery catalogue about a
/// restaurant returns a clean, wrong `0` — so the type picks all three pieces
/// together. Anything not listed here (services, hotels, schools, …) has no
/// product catalogue and never sees this page.
class _CatalogueProbe {
  final String label;

  /// The screen's own `*IfNeeded()` fetch — a no-op when already loaded.
  final Future<void> Function() ensureLoaded;

  /// Anything at all in the catalogue: the products list OR the
  /// categories-with-inventory list, either one proving stock exists.
  final bool Function() hasItems;

  /// Whether a catalogue fetch has actually COMPLETED. Separates "empty" from
  /// "unknown"; only the former counts.
  final bool Function() isLoaded;

  /// The Quick Upload screen this merchant adds stock on.
  final Widget Function() buildScreen;

  const _CatalogueProbe({
    required this.label,
    required this.ensureLoaded,
    required this.hasItems,
    required this.isLoaded,
    required this.buildScreen,
  });

  /// True only when a completed fetch says there is nothing published.
  Future<bool> isKnownEmpty() async {
    try {
      await ensureLoaded();
    } catch (e) {
      logs('KICKSTART: $label catalogue load threw — $e');
      return false;
    }
    if (hasItems()) return false;
    return isLoaded();
  }

  /// Null for every business type without a product catalogue.
  ///
  /// NOTE: the "what counts as stock" expressions below intentionally match the
  /// go-live gates on the same three home screens (see
  /// `ensureCatalogueBeforeGoLive`) — change one, change the other.
  static _CatalogueProbe? forBusinessType(String type) {
    final t = type.toUpperCase();
    if (t == BusinessType.Grocery.name.toUpperCase()) {
      final c = getOrPut(() => GroceryController());
      return _CatalogueProbe(
        label: 'grocery',
        ensureLoaded: () =>
            c.fetchAllGroceryDataIfNeeded(businessId, otherStore: false),
        hasItems: () =>
            c.groceryCategoryList.isNotEmpty ||
            c.groceryBusinessProductsList.isNotEmpty,
        isLoaded: () =>
            c.fetchMyGroceryCategoryResponse.value.status == Status.COMPLETE,
        buildScreen: () => const GrocerySuperCategoryScreen(
          isAvailBulkUpload: true,
          isKickstart: true,
        ),
      );
    }
    if (t == BusinessType.Food.name.toUpperCase()) {
      final c = getOrPut(() => RestaurantController());
      return _CatalogueProbe(
        label: 'food',
        ensureLoaded: () async {
          if (businessId.isEmpty) return;
          await c.fetchHomeAndDiscountIfNeeded(businessId: businessId);
        },
        hasItems: () =>
            c.foodMenuNestedCategory.isNotEmpty ||
            c.allFoodItems.isNotEmpty ||
            c.restaurantSpecials.isNotEmpty,
        isLoaded: () => c.foodHomeDataResponse.value.status == Status.COMPLETE,
        buildScreen: () => const FoodCategoryMenuScreen(isKickstart: true),
      );
    }
    if (t == BusinessType.Product.name.toUpperCase()) {
      final c = getOrPut(() => InventoryController());
      return _CatalogueProbe(
        label: 'product',
        ensureLoaded: () => c.fetchAllProductDataIfNeeded(),
        hasItems: () =>
            c.allProducts.isNotEmpty || c.productNestedCategoryList.isNotEmpty,
        isLoaded: () =>
            c.fetchProductCategoryResponse.value.status == Status.COMPLETE,
        buildScreen: () => ProductSuperCategoryScreen(
          ownerID: businessId,
          providerType: ProviderType.business,
          isKickstart: true,
        ),
      );
    }
    if (t == BusinessType.Manufacturing.name.toUpperCase()) {
      final c = getOrPut(() => ManufacturerInventoryController());
      return _CatalogueProbe(
        label: 'manufacturer',
        ensureLoaded: () => c.fetchAllProductDataIfNeeded(),
        hasItems: () =>
            c.allProducts.isNotEmpty || c.productNestedCategoryList.isNotEmpty,
        isLoaded: () =>
            c.fetchProductCategoryResponse.value.status == Status.COMPLETE,
        // Manufacturing has no Quick Upload rails — its add flow is the AI
        // product form, which is what its own "Add Product" button opens.
        buildScreen: () => ManufacturerAddProductViaAiStep1(
          id: businessId,
          providerType: ProviderType.business,
          isKickstart: true,
        ),
      );
    }
    // Automotive covers three different shops. Only AUTO PARTS keeps a product
    // catalogue; vehicle SALES sells listings out of the vehicle service and
    // vehicle SERVICE sells no goods at all, so neither has anything this page
    // could help them add. Same category test the Me tab routes on
    // (`_isSpecificProductAutomotive`).
    if (t == BusinessType.Automotive.name.toUpperCase() &&
        businessCategoryGlobal.toUpperCase().contains('AUTO PARTS')) {
      final c = getOrPut(() => AutomotiveInventoryController());
      return _CatalogueProbe(
        label: 'auto parts',
        ensureLoaded: () => c.fetchAllProductDataIfNeeded(),
        hasItems: () =>
            c.allProducts.isNotEmpty || c.productNestedCategoryList.isNotEmpty,
        isLoaded: () =>
            c.fetchProductCategoryResponse.value.status == Status.COMPLETE,
        buildScreen: () => AutomotiveProductSuperCategoryScreen(
          ownerID: businessId,
          providerType: ProviderType.business,
          isKickstart: true,
        ),
      );
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared chrome the three Quick Upload screens render when hosted here.
// ─────────────────────────────────────────────────────────────────────────────

/// The ✕ that replaces the back arrow. Same slot, opposite promise: this page
/// was not navigated to, so "back" would be a lie — it is dismissed.
class KickstartCloseButton extends StatelessWidget {
  const KickstartCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      tooltip: AppStrings.close.tr,
      onPressed: () => Navigator.of(context).maybePop(),
      icon: Icon(
        Icons.close_rounded,
        size: SizeConfig.size24,
        color: AppColors.mainTextColor,
      ),
    );
  }
}

/// One line above the rails saying why this page opened. Without it the screen
/// is indistinguishable from the merchant having tapped "Add product" — and a
/// screen that appears unbidden with no explanation reads as a bug.
class KickstartIntroBanner extends StatelessWidget {
  const KickstartIntroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
          SizeConfig.size8, SizeConfig.size12, SizeConfig.size8, 0),
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: SizeConfig.size40,
            height: SizeConfig.size40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: SizeConfig.size22,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  AppStrings.kickstartTitle.tr,
                  fontSize: SizeConfig.medium15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size2),
                CustomText(
                  AppStrings.kickstartSubtitle.tr,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

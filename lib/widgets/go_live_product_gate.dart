import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/add_product_prompt_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// EMPTY-CATALOGUE gate for the Go-Live pill on the catalogue business homes
/// (product, manufacturer, auto parts, grocery, food, medical, vehicle).
///
/// A shop that is live with nothing on its shelves is worse than one that is
/// offline: it takes a slot in every near-by list and every search result, and
/// the customer who taps it lands on an empty store. So the pill asks for one
/// item before it asks for anything else — this runs BEFORE
/// `toggleLiveNow()`, which is where the plan / security-deposit gate lives.
/// Being told to add a product is a step the merchant can take on the spot;
/// being sent to a payment screen first and *then* told the shop is empty is
/// two dead ends in a row.
///
/// Deliberately **fails open**. It blocks only when the catalogue is known to
/// be empty — a fetch that completed and returned nothing. A request that
/// failed, never ran, or is still in flight allows the toggle through, because
/// a merchant who has stocked their shop must never be locked offline by a
/// flaky lookup. The backend enforces nothing here; this is a UX gate.
///
/// Reuses [AddProductPromptSpec] so the sheet names what this merchant
/// actually sells ("Add your dishes" / "Add your vehicles") and its CTA
/// matches the one on the once-a-day nudge.
///
/// Callers pass their own catalogue accessors because each me-section module
/// owns a different controller and a different service:
/// * [ensureLoaded] — the screen's `*IfNeeded()` fetch. A no-op when the data
///   is already loaded and fresh, which it is on every normal tap (the Products
///   tab is the landing tab and fetches on `initState`).
/// * [hasItems] — anything in the catalogue at all: the products list OR the
///   categories-with-inventory list, either one proving stock exists.
/// * [isLoaded] — whether a catalogue fetch has actually COMPLETED. This is
///   what separates "empty" from "unknown", and only the former blocks.
/// * [onAddItems] — fired when the merchant taps the CTA, after the sheet pops.
///
/// Returns true when the pill may proceed to [toggleLiveNow].
Future<bool> ensureCatalogueBeforeGoLive({
  required BuildContext context,
  required AddProductPromptSpec spec,
  required Future<void> Function() ensureLoaded,
  required bool Function() hasItems,
  required bool Function() isLoaded,
  required VoidCallback onAddItems,
}) async {
  // Load first, THEN read. The controllers behind these lists are shared with
  // the visited-store screens, so reading before the self-scoped fetch settles
  // can answer with the last store the merchant browsed.
  try {
    await ensureLoaded();
  } catch (_) {
    // Fetchers here swallow their own errors; this is belt-and-braces. An
    // unknown catalogue is not an empty one.
    return true;
  }

  if (hasItems()) return true;
  // Empty and unresolved are different things — only the first one blocks.
  if (!isLoaded()) return true;

  if (!context.mounted) return false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EmptyCatalogueGoLiveSheet(
      spec: spec,
      onAddItems: onAddItems,
    ),
  );
  return false;
}

/// The blocking sheet itself. Same visual language as the once-a-day
/// add-product nudge ([AddProductPromptSpec]'s sheet) so the two read as one
/// flow, with copy that says why the shop did not go live.
class _EmptyCatalogueGoLiveSheet extends StatelessWidget {
  final AddProductPromptSpec spec;
  final VoidCallback onAddItems;

  const _EmptyCatalogueGoLiveSheet({
    required this.spec,
    required this.onAddItems,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: SizeConfig.size16,
        right: SizeConfig.size16,
        top: SizeConfig.size12,
        bottom: MediaQuery.of(context).padding.bottom + SizeConfig.size16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: SizeConfig.size16),
              decoration: BoxDecoration(
                color: AppColors.greyE5,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(spec.icon, size: 30, color: AppColors.primaryColor),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomText(
            spec.titleKey.tr,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            AppStrings.goLiveEmptyCatalogueSubtitle.tr,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size20),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onAddItems();
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue5CAF, AppColors.primaryColor],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CustomText(
                spec.ctaKey.tr,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: CustomText(
              AppStrings.addPromptNotNow.tr,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

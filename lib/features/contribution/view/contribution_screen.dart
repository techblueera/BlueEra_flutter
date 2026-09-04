import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/account_plan/controller/account_plan_controller.dart';
import 'package:BlueEra/features/account_plan/controller/account_plan_tag.dart';
import 'package:BlueEra/features/account_plan/view/account_plan_catalog_view.dart';
import 'package:BlueEra/features/account_plan/view/account_plan_screen.dart'
    show hydrateAccountPlanBuyer;
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/contribution/controller/explainer_videos_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One Time Contribution Plans — the **Account Plan** catalog.
///
/// This screen used to sell the refundable Security Deposit. It now sells what
/// the account actually gets — visibility radius, gig call types, service
/// area, lead/booking tier — off `GET /account-plan/plans`, per
/// docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
///
/// The screen is fully dynamic: it never names one of the 138 account types.
/// It asks the backend what *this* user can buy and renders whatever comes
/// back — labels, feature bullets and per-plan T&C all arrive from the API and
/// are rendered verbatim, so a new account type needs no change in this file.
///
/// Layout follows assets/subscription_1.png / assets/subscription_2.png: the
/// explainer video, then the plan cards on a light-blue sheet, then a single
/// pinned "Kindly Contribute Us" bar that buys the selected card.
///
/// ## The security deposit is gone
/// The deposit feature — catalog, checkout, refunds and the go-live gate that
/// keyed off it — was removed from the product. Go-live is now gated on an
/// Account Plan (or the free-first waiver), which is what THIS screen sells.
///
/// The only survivor is the explainer videos at the top, which are served from
/// `/security-deposit/videos` and are not deposit-specific; they come from
/// [ExplainerVideosController], all that is left of the old
/// `SecurityDepositController`.
/// The supported way to open [ContributionScreen] — **use this instead of
/// `Get.to(() => const ContributionScreen())`.**
///
/// A guest account has nothing to buy a plan FOR: the catalog is scoped to the
/// buyer's account type and entity tag ([AccountPlanTag.resolve]), and a guest
/// has neither, so the screen would come back empty and any purchase would fail
/// at `initiate`. Guests are sent to profile creation instead — the step that
/// actually unblocks them.
///
/// Returns the navigation future either way, so callers that `await` the return
/// (to refresh entitlements after a purchase) keep working unchanged; for a
/// guest that future completes as soon as the create-profile route is pushed
/// and the refresh that follows is a harmless no-op.
Future<dynamic> openContributionScreen() {
  if (isGuestUser()) return createProfileScreen();
  return Get.to(() => const ContributionScreen()) ?? Future<dynamic>.value();
}

class ContributionScreen extends StatefulWidget {
  const ContributionScreen({super.key});

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  late final AccountPlanController _plans;

  /// Videos only — see the class doc.
  late final ExplainerVideosController _videos;

  @override
  void initState() {
    super.initState();
    _videos = getOrPut(() => ExplainerVideosController());
    _plans = getOrPut(() => AccountPlanController());
    _applyBuyerContext();
    _plans.fetchPlans();
  }

  /// Re-reads who is buying, then fetches.
  ///
  /// Bound to pull-to-refresh as well as first build for two reasons: the
  /// controller is a `getOrPut` singleton, so it can arrive carrying the
  /// previous screen's inputs; and [_hasGst] depends on a business profile that
  /// may still have been in flight on the first pass — a refresh is then the
  /// user's way to correct a catalog that came back on the wrong GST track.
  Future<void> _refresh() async {
    _applyBuyerContext();
    await _plans.fetchPlans();
  }

  void _applyBuyerContext() {
    _plans
      ..tagId = _tagId
      // Individuals deliberately send NO has_gst: the flag selects the shop
      // radius track, and an explicit `false` is a different statement from
      // "not applicable" if the backend ever branches on it.
      ..hasGst = _isBusiness ? _hasGst : null
      ..accountType = _isBusiness ? 'BUSINESS' : 'INDIVIDUAL'
      // Only overwrite from the profile when the profile HAS one. A GSTIN the
      // user typed into the sheet this session would otherwise be wiped by the
      // pull-to-refresh that re-runs this, sending them back through the sheet
      // for the plan they are part-way through buying.
      ..buyerGstin.value = _profileGstin ?? _plans.buyerGstin.value;
    hydrateAccountPlanBuyer(_plans);
  }

  bool get _isBusiness => isBusinessUser();

  /// Entity tag the catalog is scoped to.
  ///
  /// NOT `businessCategoryGlobal` directly: that holds the display name
  /// ("General Store") while the catalog keys on the tag id
  /// ("GENERAL_STORE"). [AccountPlanTag] resolves one to the other — see it
  /// for why the gig catalog worked and the shop one did not.
  String get _tagId => AccountPlanTag.resolve();

  /// Whether the business is GST-registered — it selects the GST vs no-GST
  /// radius track.
  ///
  /// False is the safe default when the profile has not loaded: it shows the
  /// no-GST track, which is the smaller set, rather than offering plans the
  /// account cannot actually buy and only failing at `initiate`.
  bool get _hasGst {
    if (!_isBusiness) return false;
    try {
      return Get.find<ViewBusinessDetailsController>()
              .businessProfileDetails
              .value
              ?.data
              ?.gst
              ?.have ==
          true;
    } catch (_) {
      return false;
    }
  }

  /// The GSTIN already on the business profile, or null.
  ///
  /// `Gst.number` is typed `dynamic` on the model (the backend has sent both a
  /// string and null), so it is stringified and emptiness-checked rather than
  /// cast. Requires `have == true`: a number sitting behind a false flag is
  /// stale data, not a GST registration, and sending it to `initiate` would
  /// fail in a way that reads as the payment breaking.
  ///
  /// Individuals have no business profile and therefore no GSTIN here — they
  /// only reach the sheet if they somehow select a GST-track plan.
  String? get _profileGstin {
    if (!_isBusiness) return null;
    try {
      final gst = Get.find<ViewBusinessDetailsController>()
          .businessProfileDetails
          .value
          ?.data
          ?.gst;
      if (gst?.have != true) return null;
      final number = gst?.number?.toString().trim() ?? '';
      return number.isEmpty ? null : number.toUpperCase();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AccountPlanPalette.canvas,
      appBar: CommonBackAppBar(
        title: AppStrings.oneTimeContributionPlans.tr,
        isLeading: true,
        showElevation: 0,
      ),
      // The pay bar is pinned outside the scroll view: one CTA for the whole
      // catalog, buying whichever card is selected. Cards carry no Buy button
      // of their own.
      bottomNavigationBar: AccountPlanPayBar(controller: _plans),
      body: SafeArea(
        child: AccountPlanBackdrop(
          // The whole page scrolls as one — explainer video then the catalog.
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ExplainerVideoSection(controller: _videos),
                  AccountPlanCatalogView(controller: _plans),
                  SizedBox(height: SizeConfig.size12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EXPLAINER VIDEO (top of screen)
// ─────────────────────────────────────────────
/// Explainer video shown above the catalog. Hidden entirely until the videos
/// API returns at least one active video.
///
/// Reuses the shared [HorizontalVideoPlayer] (network streaming,
/// tap-to-play/pause, pause-on-scroll-away, multi-video paging) instead of a
/// bespoke player. Served by the videos endpoint — see the note on
/// [ContributionScreen].
class _ExplainerVideoSection extends StatelessWidget {
  const _ExplainerVideoSection({required this.controller});

  final ExplainerVideosController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final videos = controller.videos;
      if (videos.isEmpty) return const SizedBox.shrink();
      final urls = videos.map((v) => v.fileUrl).toList();
      final first = videos.first;
      // Only caption a single video — with multiple, the player pages between
      // them and a fixed title/description would no longer match the visible
      // one.
      final showCaption = videos.length == 1 &&
          (first.title.isNotEmpty || first.description.isNotEmpty);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size12,
          SizeConfig.size12,
          SizeConfig.size12,
          0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E8EE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14001120),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Keyed by the URL set so a changed list rebuilds the player.
              // Auto-height: the box adopts each video's own aspect ratio once
              // it loads, so portrait/landscape clips render at their real
              // proportions instead of being forced into a fixed box. The 1:1
              // ratio is just the placeholder height while the clip initializes.
              HorizontalVideoPlayer(
                key: ValueKey(urls.join(',')),
                videoUrls: urls,
                isNetworkUrl: true,
                aspectRatio: 1,
                useVideoAspectRatio: true,
                isAutoPlay: true,
                showMuteButton: true,
              ),
              if (showCaption)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    SizeConfig.size14,
                    SizeConfig.size12,
                    SizeConfig.size14,
                    SizeConfig.size14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (first.title.isNotEmpty)
                        CustomText(
                          first.title,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (first.description.isNotEmpty) ...[
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          first.description,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryTextColor,
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

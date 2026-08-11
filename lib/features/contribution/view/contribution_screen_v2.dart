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
import 'package:BlueEra/features/contribution/controller/security_deposit_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Contribution flow **v2** — now the **Account Plan** catalog.
///
/// This screen used to sell the refundable Security Deposit. It now sells what
/// the account actually gets — visibility radius, gig call types, service
/// area, lead/booking tier — off `GET /account-plan/plans`, per
/// docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md. The deposit catalog,
/// its pinned pay bar and the active-deposit panel are gone from here.
///
/// The screen is fully dynamic: it never names one of the 138 account types.
/// It asks the backend what *this* user can buy and renders whatever comes
/// back, so a new account type needs no change in this file.
///
/// ## What is still deposit-shaped
/// [SecurityDepositController] is still constructed, for ONE reason: the
/// explainer videos at the top come from `/security-deposit/videos`, which is
/// the only endpoint that serves them. Nothing else on this screen reads it.
///
/// > **Note for whoever wires enforcement:** the security deposit remains the
/// > go-live gate for riders and self-employed accounts, and there is no
/// > longer a way to PAY it from this screen. Those gates have to move onto
/// > `/account-plan/my-plans` — see `docs/DEPOSIT_TO_PAID_PLAN_REDESIGN.txt`
/// > §7–8.
class ContributionScreenV2 extends StatefulWidget {
  const ContributionScreenV2({super.key});

  @override
  State<ContributionScreenV2> createState() => _ContributionScreenV2State();
}

class _ContributionScreenV2State extends State<ContributionScreenV2> {
  late final AccountPlanController _plans;

  /// Videos only — see the class doc.
  late final SecurityDepositController _videos;

  @override
  void initState() {
    super.initState();
    _videos = getOrPut(() => SecurityDepositController());
    _plans = getOrPut(() => AccountPlanController())
      ..tagId = _tagId
      ..hasGst = _hasGst
      ..accountType = _isBusiness ? 'BUSINESS' : 'INDIVIDUAL';
    hydrateAccountPlanBuyer(_plans);
    _plans.fetchPlans();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: CommonBackAppBar(
        title: AppStrings.chooseYourPlan.tr,
        isLeading: true,
        showElevation: 0,
      ),
      body: SafeArea(
        // The whole page scrolls as one — explainer video then the catalog.
        // The catalog is a plain column for exactly this reason; there is no
        // pinned CTA any more because each card carries its own Buy button.
        child: RefreshIndicator(
          onRefresh: _plans.fetchPlans,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExplainerVideoSection(controller: _videos),
                AccountPlanCatalogView(controller: _plans),
                SizedBox(height: SizeConfig.size24),
              ],
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
/// bespoke player. Still served by the security-deposit videos endpoint — see
/// the note on [ContributionScreenV2].
class _ExplainerVideoSection extends StatelessWidget {
  const _ExplainerVideoSection({required this.controller});

  final SecurityDepositController controller;

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

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/navigation/profile_taxonomy.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
// `openMeOverview` — the own-profile destination — already lives beside the
// author header; imported rather than duplicated so there is still one of it.
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/features/common/visit_profile_config.dart';

/// ONE entry point for every profile tap in the feed — the author header on a
/// post, the reposted author, the business card, the product card's seller,
/// the uploader row on a video card.
///
/// Each of those used to inline its own `accountType == BUSINESS ?
/// VisitBusinessProfileNew : NewVisitProfileScreen`, so a tapped restaurant,
/// lab or pharmacy landed on the generic business profile instead of its own
/// store/lab/pharmacy screen — and every new visit screen had to be wired into
/// five places. They now all funnel into [openVisitProfile], the app-wide visit
/// resolver, which picks the screen from the profile's type + sub-category.
///
/// What the feed can hand it is thinner than what a profile endpoint returns —
/// `/feed`'s author is only:
///
/// ```json
/// {"_id":"…","account_type":"BUSINESS","designation":"Diagnostic",
///  "business_id":"…","business_name":"Mohan Raj Lab","categoryOfBusiness":"Diagnostic"}
/// ```
///
/// no `type_of_business`, no `profile_type`. [openVisitProfile] recovers both
/// from the category/designation (see `profile_taxonomy.dart`), so that lab
/// opens `LabDetailScreen` and a `"Cloud kitchen mess"` opens the food store.
void openFeedProfile(
  User? user, {
  /// Business feed items are the business — their own `_id` is the business id
  /// and is the only one present when the user service couldn't resolve the
  /// author ("Unknown User", guide §4.1).
  String? fallbackBusinessId,
  String screenFrom = AppConstants.feedScreen,
}) {
  // The feed writes absent relations as the string "null"
  // (`"business_id":"null"` on every individual), so clean before deciding
  // anything — an un-cleaned value reads as a real id.
  final String? authorId = cleanTaxonomyValue(user?.id);
  final String? authorBusinessId =
      cleanTaxonomyValue(user?.business_id) ?? cleanTaxonomyValue(fallbackBusinessId);
  final String account = normalizeTaxonomyKey(user?.accountType);
  final bool isBusiness = account == normalizeTaxonomyKey(AppConstants.business);

  if (authorId == null && authorBusinessId == null) {
    logs('openFeedProfile: author carries no id — ignoring tap');
    return;
  }

  // Own profile → the Me tab, not a visit screen. Checked on the id that
  // identifies THIS account kind: a business account posts under its business
  // id while `userId` still holds the owner, so comparing the wrong one sends
  // you to a read-only view of yourself.
  final bool isSelf = isBusiness
      ? (authorBusinessId != null && authorBusinessId == businessId)
      : (authorId != null && authorId == userId);
  if (isSelf) {
    openMeOverview();
    return;
  }

  openVisitProfile(
    accountType: user?.accountType,
    // Individuals: the feed's `designation` is the profession's display name
    // ("Bike Rider", "Business Finance Consultant"), which is what the
    // resolver maps to a profile type.
    profession: isBusiness ? null : cleanTaxonomyValue(user?.designation),
    // Businesses: `categoryOfBusiness` is the sub-category; `designation`
    // repeats it on most payloads and stands in when it's missing.
    categoryOfBusiness: isBusiness
        ? (cleanTaxonomyValue(user?.categoryOfBusiness) ??
            cleanTaxonomyValue(user?.designation))
        : null,
    businessId: authorBusinessId,
    userId: authorId,
    screenFrom: screenFrom,
  );
}

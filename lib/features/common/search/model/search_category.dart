import 'package:BlueEra/core/constants/app_strings.dart';

/// The `category` scopes accepted by `GET search-service/search`.
///
/// One endpoint serves every search screen in the app; this parameter is the
/// only thing that changes between them, and the server fixes the scope — a
/// `grocery` search can never return a video no matter what is in the query.
///
/// Sending anything not in this list is a `400`, which is why the app names
/// them once here instead of spelling strings at each call site. Mirrors
/// `docs/SEARCH_API_INTEGRATION.md` §1.
enum SearchCategory {
  /// Everything. The server default, so it is NOT sent on the wire.
  all('all', AppStrings.searchCatAll),

  // ── Content ────────────────────────────────────────────────────────
  content('content', AppStrings.searchCatContent),
  video('video', AppStrings.searchCatVideos),

  /// `post` is an accepted server alias for this same scope, so the UI offers
  /// one chip rather than two identical ones.
  userfeed('userfeed', AppStrings.searchCatPosts),

  // ── Commerce ───────────────────────────────────────────────────────
  grocery('grocery', AppStrings.searchCatGrocery),
  food('food', AppStrings.searchCatFood),
  shopping('shopping', AppStrings.searchCatShopping),
  healthcare('healthcare', AppStrings.searchCatHealthcare),
  automotive('automotive', AppStrings.searchCatAutomotive),

  // ── Stay ───────────────────────────────────────────────────────────
  stay('stay', AppStrings.searchCatStay),

  // ── Earn with BlueEra ──────────────────────────────────────────────
  homemadeFood('homemade_food', AppStrings.searchCatHomemadeFood),
  homemadeProducts('homemade_products', AppStrings.searchCatHomemadeProducts),

  /// Serves both "Book Home Services" and "Home Services" — the backend does
  /// not distinguish them; they are the same providers.
  homeServices('home_services', AppStrings.searchCatHomeServices),
  consultants('consultants', AppStrings.searchCatConsultants),

  // ── Standalone verticals ───────────────────────────────────────────
  services('services', AppStrings.searchCatServices),
  rentals('rentals', AppStrings.searchCatRentals),
  finance('finance', AppStrings.searchCatFinance),
  jobs('jobs', AppStrings.searchCatJobs),
  education('education', AppStrings.searchCatEducation),

  /// Every business of every vertical, and never their stock.
  shops('shops', AppStrings.searchCatShops);

  const SearchCategory(this.value, this.labelKey);

  /// The wire value of the `category` query parameter.
  final String value;

  /// Translation key for the chip label — resolve with `.tr` at render time.
  /// Deliberately separate from [value]: the label is localised, the wire value
  /// never is.
  final String labelKey;

  /// Parse a wire value back to a category, `null` when unknown. `post` maps to
  /// [userfeed] — the server treats them as the same scope.
  static SearchCategory? fromValue(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value == 'post') return SearchCategory.userfeed;
    for (final c in SearchCategory.values) {
      if (c.value == value) return c;
    }
    return null;
  }
}

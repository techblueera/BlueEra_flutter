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
  all('all'),

  // ── Content ────────────────────────────────────────────────────────
  content('content'),
  video('video'),
  userfeed('userfeed'),

  // ── Commerce ───────────────────────────────────────────────────────
  grocery('grocery'),
  food('food'),
  shopping('shopping'),
  healthcare('healthcare'),
  automotive('automotive'),

  // ── Stay ───────────────────────────────────────────────────────────
  stay('stay'),

  // ── Earn with BlueEra ──────────────────────────────────────────────
  homemadeFood('homemade_food'),
  homemadeProducts('homemade_products'),

  /// Serves both "Book Home Services" and "Home Services" — the backend does
  /// not distinguish them; they are the same providers.
  homeServices('home_services'),
  consultants('consultants'),

  // ── Standalone verticals ───────────────────────────────────────────
  services('services'),
  rentals('rentals'),
  finance('finance'),
  jobs('jobs'),
  education('education'),

  /// Every business of every vertical, and never their stock.
  shops('shops');

  const SearchCategory(this.value);

  /// The wire value of the `category` query parameter.
  final String value;
}

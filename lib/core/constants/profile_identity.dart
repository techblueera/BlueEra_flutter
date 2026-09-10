import 'package:BlueEra/core/constants/app_constant.dart';

/// Reconciles the two vocabularies for an individual's `profileType`.
///
/// The app compares against SCREAMING_SNAKE constants — [GIG_WORKER],
/// [SELF_EMPLOYED], [PROFESSIONAL], [SOCIAL_PROFILE] — in the drawer label,
/// contribution type, gig-work gating and profile setup. The backend
/// profession catalog stores the same four as display strings: `"GigWork"`,
/// `"Self Employed"`, `"Professional"`, `"Social Profile"`.
///
/// While the only writer was onboarding (which stored the app's own constant)
/// the mismatch was invisible. The profile-category change endpoint DERIVES
/// `User.profileType` from the catalog entry and overwrites whatever was
/// there, so from the moment that ships, `"GigWork"` can arrive in a global
/// that a dozen `==` comparisons expect to read `"GIG_WORKER"` — each one
/// failing silently into the wrong UI.
///
/// Normalizing at the few places the globals are WRITTEN (login, app start,
/// `applyProfileGlobals`) fixes every one of those comparisons at once. The
/// alternative — normalizing at each comparison — is a bigger surface where
/// missing one site is a silent regression.
///
/// Safe to apply unconditionally: a value that is already the app constant
/// comes back unchanged, so this stays correct whichever way the backend
/// contract lands.
String normalizeProfileType(String? raw) {
  final key = _squash(raw);
  if (key.isEmpty) return '';

  final alias = kProfileTypeAliases[key];
  if (alias != null) return alias;

  // Unknown — a profileType the backend adds later. Return it in the app's
  // shape rather than blanking it: "Some New Type" becomes SOME_NEW_TYPE, so
  // whatever constant is added for it will match without this needing an edit.
  return _screamingSnake(raw!);
}

/// The one alias table, keyed by [_squash]ed input (letters and digits only,
/// uppercased) so every spelling of a value collapses to one key.
///
/// Shared with `individualProfileTypeFor()` in
/// `lib/core/navigation/profile_taxonomy.dart`, which resolves OTHER people's
/// profiles and used to carry its own copy of this map. Two tables for one
/// vocabulary is how the two halves of the app end up disagreeing about what
/// "GigWork" means, so the table lives here — with no imports beyond the
/// constants — and the taxonomy reads it.
///
/// `SKILL_WORKER` maps to [SELF_EMPLOYED] deliberately: that is how the
/// professions catalog buckets it (`individualOnboardingSkillWorkList` holds
/// the `"Self Employed"` professions), and the app has no SKILL_WORKER screen
/// of its own — leaving it unmapped drops those accounts on the
/// unknown-profile fallback.
const Map<String, String> kProfileTypeAliases = {
  'SELFEMPLOYED': SELF_EMPLOYED,
  'SKILLWORK': SELF_EMPLOYED,
  'SKILLWORKER': SELF_EMPLOYED,
  'SKILLEDWORKER': SELF_EMPLOYED,
  'PROFESSIONAL': PROFESSIONAL,
  'CONSULTANT': PROFESSIONAL,
  'GIGWORK': GIG_WORKER,
  'GIGWORKER': GIG_WORKER,
  'SOCIALPROFILE': SOCIAL_PROFILE,
  'SOCIAL': SOCIAL_PROFILE,
};

/// Letters and digits only, uppercased: `"Self Employed"`, `"self_employed"`
/// and `"SELF-EMPLOYED"` all collapse to `SELFEMPLOYED`, which is what makes
/// the switch above independent of the server's spacing and punctuation.
String _squash(String? value) =>
    (value ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// `"Some New Type"` → `SOME_NEW_TYPE`.
String _screamingSnake(String value) => value
    .trim()
    .toUpperCase()
    .replaceAll(RegExp(r'[\s\-/]+'), '_')
    .replaceAll(RegExp(r'_+'), '_');

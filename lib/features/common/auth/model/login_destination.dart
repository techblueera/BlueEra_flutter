import 'package:BlueEra/core/constants/app_constant.dart';

/// Where a `verify-otp` response sends the user.
///
/// Pulled out of [AuthController.verifyOTP] as a pure function so the one
/// decision that broke 40% of logins is testable without Dio, GetX
/// navigation or secure storage — see test/login_destination_test.dart, which
/// walks the case table in
/// lib/docs/FLUTTER_LOGIN_EXISTING_USER_FIX_GUIDE.md §6.
enum LoginDestination {
  /// Business home shell + business profile controller.
  business,

  /// A real, signed-in guest account: session persisted, lands on the home
  /// shell, and finishes signup later from inside the app.
  guest,

  /// Individual home shell — AND every account type this build does not
  /// recognise, which is the whole point of the fallback.
  individual,

  /// No account exists for this number yet.
  signup,
}

/// Resolves the login path for a `verify-otp` response.
///
/// The rules, in the order they matter:
///
/// 1. **`userExists` (`user` in the response) is the only existence check.**
///    It answers "is there an account for this number?" and nothing else. It
///    is never a statement about the account type — reading it as one is what
///    made guests look like new installs.
/// 2. **`accountType` is a label, never a gate.** It picks a profile screen.
///    An unrecognised value still logs in, via [LoginDestination.individual].
///    Production holds values outside the backend's enum (`Admin`, and the
///    literal string `NULL`) alongside `BLUEFLY`, which the enum has and
///    production does not — all of them must log in.
/// 3. **`needsOnboarding` is the only onboarding signal**, and it is never
///    inferred from the account type. It does not override a type the backend
///    has already stated: a `BUSINESS` or `INDIVIDUAL` keeps its own path
///    rather than being demoted to a guest locally, where it would pick up
///    every guest restriction in the app.
/// 4. [hasToken] only matters when the account is reported as NOT existing:
///    a backend still running the pre-September
///    `user: [INDIVIDUAL, BUSINESS].includes(...)` whitelist reports a guest
///    as `user: false` while still handing over a token. That is a login, not
///    a signup. Without a token there is no session to build, so it is a
///    genuinely new number.
LoginDestination resolveLoginDestination({
  required bool userExists,
  String? accountType,
  bool needsOnboarding = false,
  bool hasToken = false,
}) {
  final type = (accountType ?? '').trim().toUpperCase();

  if (!userExists) {
    if (type == AppConstants.guest && hasToken) return LoginDestination.guest;
    return LoginDestination.signup;
  }

  if (type == AppConstants.business) return LoginDestination.business;
  if (type == AppConstants.guest) return LoginDestination.guest;
  if (type == AppConstants.individual) return LoginDestination.individual;

  // An account type this build has never heard of, which the backend says
  // has not finished signup.
  if (needsOnboarding) return LoginDestination.guest;

  // `BLUEFLY`, `Admin`, the literal `"NULL"`, and whatever the backend adds
  // next: a normal logged-in user, NOT an error. Keeping this a real fallback
  // instead of a whitelist is the difference between the next new account
  // type shipping quietly and locking its users out.
  return LoginDestination.individual;
}

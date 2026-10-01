import 'package:BlueEra/core/api/model/user_profile_res.dart' as profile_res;
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';

/// What the customer does, for the ongoing ride card's customer row.
///
/// One type for both account kinds because the row renders them identically —
/// only the icon differs — and the card should not have to know which lookup
/// produced the text.
class CustomerIdentity {
  /// `Plumber`, or `Restaurant · Bakery` for a business with a sub-category.
  final String label;
  final bool isBusiness;

  const CustomerIdentity({required this.label, required this.isBusiness});

  /// Builds an identity from values that are routinely null or blank, returning
  /// null when there is nothing worth showing. [secondary] narrows [primary]
  /// (sub-category under category) and is dropped when it merely repeats it.
  ///
  /// [isBusiness] is passed explicitly rather than inferred from [secondary]
  /// being present: a business that never set a sub-category still has to read
  /// as a business.
  static CustomerIdentity? of(
    String? primary, {
    String? secondary,
    bool isBusiness = false,
  }) {
    final head = primary?.trim() ?? '';
    final tail = secondary?.trim() ?? '';
    if (head.isEmpty) {
      return tail.isEmpty
          ? null
          : CustomerIdentity(label: tail, isBusiness: isBusiness);
    }
    final sameThing = tail.isEmpty || tail.toLowerCase() == head.toLowerCase();
    return CustomerIdentity(
      label: sameThing ? head : '$head · $tail',
      isBusiness: isBusiness,
    );
  }
}

/// Looks up a customer's profession / business category for the rider's
/// order cards.
///
/// The order payload's `user` carries only id / name / profile_image /
/// contact_no, so this has to be fetched. Results are cached per user id for
/// the process lifetime (a customer's profession does not change mid-ride),
/// and concurrent lookups for the same customer share one request — several
/// cards in one list can belong to the same customer, and they all build at
/// once.
class CustomerIdentityService {
  CustomerIdentityService(
      {UserRepo? userRepo, BusinessProfileRepo? businessRepo})
      : _userRepo = userRepo ?? UserRepo(),
        _businessRepo = businessRepo ?? BusinessProfileRepo();

  final UserRepo _userRepo;
  final BusinessProfileRepo _businessRepo;

  /// Keyed by user id, shared by every card.
  static final Map<String, CustomerIdentity> _cache = {};
  static final Map<String, Future<CustomerIdentity?>> _inFlight = {};

  /// The identity already looked up for [userId], if any.
  static CustomerIdentity? cached(String userId) => _cache[userId];

  /// Forgets every cached identity (tests).
  static void clearCache() {
    _cache.clear();
    _inFlight.clear();
  }

  /// Fetches [userId]'s identity, or null when there is nothing to show or
  /// the lookup failed (fail soft — the row still has the name and number,
  /// which is what the rider actually needs at the kerb).
  Future<CustomerIdentity?> fetch(String userId) {
    final cachedIdentity = _cache[userId];
    if (cachedIdentity != null) return Future.value(cachedIdentity);
    return _inFlight.putIfAbsent(userId, () async {
      try {
        final response = await _userRepo.getUserById(userId: userId);
        if (!response.isSuccess || response.response?.data == null) return null;

        final user =
            profile_res.UserProfileRes.fromJson(response.response?.data).user;
        final isBusiness =
            (user?.accountType ?? '').toUpperCase().contains('BUSINESS');

        final identity = isBusiness
            ? await _fetchBusinessIdentity(userId)
            // Individual: profession is the headline; designation is the
            // fallback for profiles that only filled the job title in.
            : CustomerIdentity.of(user?.profession ?? user?.designation);

        if (identity != null) _cache[userId] = identity;
        return identity;
      } catch (_) {
        return null;
      } finally {
        _inFlight.remove(userId);
      }
    });
  }

  /// Business customers: category, narrowed by sub-category when both are set.
  /// Only the resolved `*_details.name` values are used — the bare
  /// `category_Of_Business` fields are ids, which would render as a hash.
  Future<CustomerIdentity?> _fetchBusinessIdentity(String userId) async {
    final response = await _businessRepo.viewBusinessProfileById(userId);
    if (!response.isSuccess || response.response?.data == null) return null;

    final details =
        ViewBusinessProfileModel.fromJson(response.response?.data).data;
    return CustomerIdentity.of(
      details?.categoryDetails?.name,
      secondary: details?.subCategoryDetails?.name,
      isBusiness: true,
    );
  }
}

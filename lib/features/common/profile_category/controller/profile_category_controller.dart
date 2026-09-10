import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/profile_category/model/profile_category_models.dart';
import 'package:BlueEra/features/common/profile_category/repo/profile_category_repo.dart';
import 'package:get/get.dart';

/// Owns the one-time profile-category change — the Settings row's state, the
/// change itself, and the local cleanup that has to follow it.
///
/// See `docs/backend/FLUTTER_PROFILE_CATEGORY_CHANGE_GUIDE.md`. The rule that
/// shapes this class is §9: a successful change is NOT "pop the sheet". The
/// user's profession, profile type and designation have all moved on the
/// server, and a dozen screens gate on cached copies of exactly those, so the
/// change is only really finished once [SharedPreferenceUtils.applyProfileGlobals]
/// has run. That is why [changeCategory] returns the result rather than the
/// caller talking to the repo directly.
class ProfileCategoryController extends GetxController {
  ProfileCategoryController({ProfileCategoryRepo? repo})
      : _repo = repo ?? ProfileCategoryRepo();

  final ProfileCategoryRepo _repo;

  /// Current state of the allowance. Starts as [ProfileCategoryState.unknown],
  /// which reports `supported == false` — so the Settings row stays hidden
  /// until the GET actually says otherwise, rather than flashing in and out.
  final Rx<ProfileCategoryState> state =
      Rx<ProfileCategoryState>(ProfileCategoryState.unknown);

  /// The §5 read. Separate from [isChanging] so the row can show a subtle
  /// placeholder while it loads without the confirm button spinning.
  final RxBool isLoading = false.obs;

  /// The §7 write — drives the confirm button's spinner.
  final RxBool isChanging = false.obs;

  /// Last failure code, for the retry affordance. Empty when the last attempt
  /// succeeded or none has been made.
  final RxString lastErrorCode = ''.obs;

  /// True once a fetch has settled, so the UI can tell "not asked yet" from
  /// "asked and this account has no category".
  final RxBool hasFetched = false.obs;

  /// Whether to show the Settings row at all (§5). GUEST and BLUEFLY have no
  /// category and get nothing — not a disabled row, no row.
  bool get isVisible => state.value.supported;

  /// Whether the row is tappable. False once the single allowance is spent;
  /// the row stays visible with the contact-support line.
  bool get canChange => state.value.canChange;

  /// Subtitle under the row — "Grocery Store".
  String get currentName => state.value.current?.name ?? '';

  /// Canonical tag of the current category, for pre-selecting (and disabling)
  /// it in the picker. Always the catalog `tag_id`, never the display-name
  /// form that `User.profession` sometimes holds.
  String get currentTagId => state.value.current?.tagId ?? '';

  /// §5 — call when the Settings screen loads.
  ///
  /// Never throws: a failure here must not take the Settings screen down with
  /// it. The row simply stays hidden, which is the same outcome as an account
  /// that genuinely has no category.
  Future<void> loadState() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      state.value = await _repo.fetchState();
      lastErrorCode.value = '';
    } on ProfileCategoryException catch (e) {
      logs('[ProfileCategory] state fetch failed: $e');
      lastErrorCode.value = e.code;
      state.value = ProfileCategoryState.unknown;
    } finally {
      hasFetched.value = true;
      isLoading.value = false;
    }
  }

  /// §7 — perform the change, then §9.2 — refresh the cached globals.
  ///
  /// Returns the result on success, or null when it failed; read
  /// [lastErrorCode] for the reason and [isRetryable] for whether to offer a
  /// Retry button. The caller still owns the rest of §9 — re-fetching the
  /// profile and rebuilding whatever branches on the globals — because those
  /// live in controllers this one has no business reaching into.
  ///
  /// The globals are written HERE rather than left to the caller because
  /// forgetting them is the single most likely way for this feature to ship
  /// broken: the change succeeds, the profile screen updates, and the rider
  /// tab keeps serving the old profession until the next reinstall.
  Future<ProfileCategoryChangeResult?> changeCategory({
    required String tagId,
    String? designation,
    String? subCategoryId,
    String? licenseNumber,
  }) async {
    if (isChanging.value) return null;
    isChanging.value = true;
    lastErrorCode.value = '';
    try {
      final result = await _repo.changeCategory(
        tagId: tagId,
        designation: designation,
        subCategoryId: subCategoryId,
        licenseNumber: licenseNumber,
      );

      // Reflect the new allowance immediately — §7 hands back the same state
      // shape the GET does precisely so the row doesn't need a second call.
      state.value = state.value.afterChange(result);

      await _applyGlobals(result);
      return result;
    } on ProfileCategoryException catch (e) {
      logs('[ProfileCategory] change failed: $e');
      lastErrorCode.value = e.code;

      // A first attempt that comes back "already used" means the change really
      // did happen — on another device, or support did it. Re-read rather than
      // showing an error about something the user didn't do.
      if (e.code == ProfileCategoryErrorCode.changeLimitReached) {
        await loadState();
      }
      return null;
    } finally {
      isChanging.value = false;
    }
  }

  /// True when the last failure is worth offering a Retry for — the allowance
  /// is claimed before the backend does any work and handed back if that work
  /// fails, so a 5xx or a dead connection costs the user nothing.
  bool get isRetryable =>
      ProfileCategoryErrorCode.retryable.contains(lastErrorCode.value);

  /// §9.2 — the mandatory globals refresh.
  ///
  /// Only meaningful for individuals: [SharedPreferenceUtils.applyProfileGlobals]
  /// writes the profession / profile-type / designation trio, and a business
  /// account has none of them (its category lives in the business globals,
  /// which the profile re-fetch in §9.1 rebuilds).
  ///
  /// `designation` is passed as `''` rather than skipped when the response
  /// doesn't carry one: the backend CLEARS it on a change that didn't re-send
  /// it, and leaving the old value in storage would resurrect a designation
  /// that belongs to the profession the user just left.
  Future<void> _applyGlobals(ProfileCategoryChangeResult result) async {
    final current = result.current;
    if (current == null) return;
    if (current.profileType == null && current.designation == null) {
      // A business change — nothing in this trio applies to it.
      return;
    }

    await SharedPreferenceUtils.applyProfileGlobals(
      professionTagId: current.tagId,
      // Stored normalized by applyProfileGlobals: the backend derives this from
      // the catalog, so it arrives as "GigWork" rather than GIG_WORKER.
      profileType: current.profileType,
      designation: current.designation ?? '',
    );
  }
}

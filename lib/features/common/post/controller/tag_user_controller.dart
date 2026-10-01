import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/get_all_users.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/debug_log.dart';

class TagUserController extends GetxController {
  /// [initialTaggedIds] are the users an edited post already tags; they are
  /// selected as their page of users loads.
  TagUserController(
      {UserRepo? repo, Iterable<String> initialTaggedIds = const []})
      : _repo = repo ?? UserRepo(),
        _initialTaggedIds = initialTaggedIds.toSet();

  final UserRepo _repo;
  final Set<String> _initialTaggedIds;

  final RxList<UsersData> allUsers = <UsersData>[].obs;
  final RxList<UsersData> filteredUsers = <UsersData>[].obs;
  final RxList<UsersData> selectedUsers = <UsersData>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final int maxTagLimit = 6;
  int page = 1;
  int limit = 50;
  RxBool isLoadingMore = false.obs;
  RxBool isHasMoreData = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers(isInitialLoad: true);
    debounce(
      searchQuery,
      (_) => filterUsers(),
      time: const Duration(milliseconds: 500),
    );
  }

  void fetchUsers({bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      page = 1;
      isHasMoreData.value = true;
      isLoadingMore.value = true;
      isLoadingMore.value = false;
    }

    Map<String, dynamic> params = {
      ApiKeys.page: page,
      ApiKeys.limit: limit,
    };

    if (isHasMoreData.isFalse || isLoadingMore.isTrue) return;

    isLoadingMore.value = true;

    try {
      debugLog('api call');
      ResponseModel response = await _repo.getAllUsers(params: params);

      if (response.statusCode == 200) {
        GetAllUsers getAllUsers = GetAllUsers.fromJson(response.response?.data);
        List<UsersData> data = getAllUsers.data;

        if (page == 1) {
          allUsers.value = data;
          filteredUsers.value = data;
        } else {
          allUsers.addAll(data);
          // allUsers.addAll(data);
        }

        if (data.length < limit) {
          isHasMoreData.value = false;
        } else {
          page++;
        }

        // Only this page: re-selecting across all pages would undo a tag the
        // user removed from an earlier page.
        for (final user in data) {
          if (_initialTaggedIds.contains(user.id) &&
              !selectedUsers.any((selected) => selected.id == user.id)) {
            user.isSelected.value = true;
            selectedUsers.add(user);
          }
        }

        filterUsers();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      debugLog('Error fetching users: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void filterUsers() {
    if (searchQuery.value.isEmpty) {
      filteredUsers.value = allUsers;
    } else {
      filteredUsers.value = allUsers.where((user) {
        final query = searchQuery.value.toLowerCase();
        final name = user.name?.toLowerCase() ?? '';
        final businessName = user.businessName?.toLowerCase() ?? '';
        final username = user.username?.toLowerCase() ?? '';

        return name.contains(query) ||
            businessName.contains(query) ||
            username.contains(query);
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  bool canAddMoreUsers() {
    return selectedUsers.length < maxTagLimit;
  }

  void toggleUserSelection(UsersData user) {
    if (user.isSelected.value) {
      user.isSelected.value = false;
      selectedUsers.remove(user);
    } else {
      if (canAddMoreUsers()) {
        user.isSelected.value = true;
        selectedUsers.add(user);
      } else {
        // Show a message that max limit reached

        commonSnackBar(
          message: 'You can tag maximum $maxTagLimit people',
        );
      }
    }
  }

  void removeSelectedUser(UsersData user) {
    user.isSelected.value = false;
    selectedUsers.remove(user);
  }

  void clearAllSelections() {
    for (var user in selectedUsers) {
      user.isSelected.value = false;
    }
    selectedUsers.clear();
  }
}

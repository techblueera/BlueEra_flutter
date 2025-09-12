import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/photo_post_controller.dart';
import 'package:BlueEra/features/common/reel/models/get_all_users.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

class TagUserController extends GetxController {
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
    final photoPostController = Get.isRegistered<PhotoPostController>()
        ? Get.find<PhotoPostController>()
        : Get.put(PhotoPostController());

    final messagePostController = Get.isRegistered<MessagePostController>()
        ? Get.find<MessagePostController>()
        : Get.put(MessagePostController());

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
      print('api call');
      ResponseModel response = await UserRepo().getAllUsers(params: params);

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

        if (photoPostController.isPhotoPostEdit) {
          if (photoPostController.postData?.value.taggedUsers?.isNotEmpty ??
              false) {
            // final taggedIds =
            //     photoPostController.postData?.value.taggedUsers ?? [];
            final List<String> taggedIds
                = photoPostController.postData?.value.taggedUsers?.map((user) => user.id as String).toList()??[];


            selectedUsers.value = allUsers.where((user) {
              final isTagged = taggedIds.contains(user.id);
              user.isSelected.value =
                  isTagged; // set isSelected based on tagged
              return isTagged;
            }).toList();
            logs(" tagUserController.selectedUsers.value====${selectedUsers}");
            // setState(() {});
          }
        }
        if (messagePostController.isMsgPostEdit) {
          if (messagePostController.taggedSelectedUsersList?.isNotEmpty ??
              false) {
            final List<String> taggedIds = messagePostController.taggedSelectedUsersList?.map((user) => user.id as String).toList()??[];
            selectedUsers.value = allUsers.where((user) {
              final isTagged = taggedIds.contains(user.id);
              user.isSelected.value =
                  isTagged; // set isSelected based on tagged
              return isTagged;
            }).toList();
          }
        }

        filterUsers();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      print('Error fetching users: $e');
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

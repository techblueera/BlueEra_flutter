import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/get_all_users.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:get/get.dart';

class TagPeopleController extends GetxController{
  Rx<ApiResponse> allUsersResponse = ApiResponse.initial('Initial').obs;
  final RxList<UsersData> usersData = <UsersData>[].obs;
  RxList<UsersData> filteredUsers = <UsersData>[].obs;
  RxBool isLoading = true.obs;
  final int maxTagLimit = 6;
  var selectedItems = <String, String>{}.obs;
  var validate = false.obs;
  int page = 1;
  int limit = 50;
  RxBool isLoadingMore = false.obs;
  RxBool isHasMoreData = true.obs;

  ///GET ALL USERS...
  Future<void> getAllKindOfUsers({bool isInitialLoad = false}) async {
    if(isInitialLoad){
      page = 1;
      isHasMoreData.value = true;
      isLoadingMore.value = false;
    }

    Map<String, dynamic> params = {
      ApiKeys.page: page,
      ApiKeys.limit: limit,
    };

    if (isHasMoreData.isFalse || isLoadingMore.isTrue) return;

    isLoadingMore.value = true;

    try {

      ResponseModel response = await UserRepo().getAllUsers(params: params);

      if (response.statusCode == 200) {
        allUsersResponse.value = ApiResponse.complete(response);
        commonSnackBar(message: response.message ?? AppStrings.success);
        GetAllUsers getAllUsers = GetAllUsers.fromJson(response.response?.data);
        List<UsersData> data = getAllUsers.data;

        if (page == 1) {
          usersData.value = data;
          filteredUsers.value = data;
        }else{
          usersData.addAll(data);
          usersData.addAll(data);
        }

        if (data.length < limit) {
          isHasMoreData.value = false;
        } else {
          page++;
        }

      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e, s) {
      allUsersResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally{
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }


  void toggleSelection(String id, String name) {
    if (selectedItems.containsKey(id)) {
      selectedItems.remove(id);
    } else {
      if(selectedItems.length >= maxTagLimit){
        commonSnackBar(
          message: 'You can tag maximum $maxTagLimit people',
        );
        return;
      }
      selectedItems[id] = name;
    }
    validateForm();
  }

  void removeSelected(String id) {
    selectedItems.remove(id);
    validateForm();
  }

  void setPreviouslySelected(Map<String, String>? items) {
    if (items != null) {
      selectedItems.assignAll(items);
      validateForm();
    }
  }

  void validateForm() {
    validate.value = selectedItems.isNotEmpty;
  }

}
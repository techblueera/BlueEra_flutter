import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/get_all_users.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:get/get.dart';

class TagPeopleController extends GetxController{
  ApiResponse allUsersResponse = ApiResponse.initial('Initial');
  RxList<UsersData> usersData = <UsersData>[].obs;
  final RxList<UsersData> filteredUsers = <UsersData>[].obs;
  RxBool isLoading = true.obs;

  onInit(){
    super.onInit();
    getAllKindOfUsers();
  }

  ///GET ALL USERS...
  Future<void> getAllKindOfUsers() async {
    try {
      ResponseModel response = await ChannelRepo().getAllUsers();

      if (response.statusCode == 200) {
        commonSnackBar(message: response.message ?? AppStrings.success);
        GetAllUsers getAllUsers = GetAllUsers.fromJson(response.response?.data);
        usersData.value = getAllUsers.data;
        filteredUsers.value = usersData;
        allUsersResponse = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      allUsersResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally{
      isLoading.value = false;
    }
  }

}
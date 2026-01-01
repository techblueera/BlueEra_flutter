import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/notice_news_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:get/get.dart';

class NoticeController extends GetxController {
  Rx<ApiResponse> getNoticeNewsResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addNoticeNewsResponse = ApiResponse.initial('Initial').obs;

  ///GET BRANCH CONTACT DETAILS...
  RxList<NoticeNewsData> noticeNewsDataList = <NoticeNewsData>[].obs;

  Future<void> getSchoolNoticeNewsController() async {
    noticeNewsDataList.clear();
    try {
      ResponseModel response = await SchoolRepo().getSchoolNoticesRepo();
      NoticeNewsModel noticeNewsModel =
          NoticeNewsModel.fromJson(response.response?.data);
      noticeNewsDataList.value = noticeNewsModel.data ?? [];
      if (response.isSuccess) {
        getNoticeNewsResponse.value = ApiResponse.complete(noticeNewsModel);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getNoticeNewsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
      getNoticeNewsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }
}

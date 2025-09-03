
import 'package:BlueEra/features/common/reelsModule/model/fetch_reels_model.dart';
import 'package:get/get.dart';

class ReelsController extends GetxController {
  RxList<String>? KeyWordList = <String>[].obs;
  bool isLoadingReels = false;

  ///ADD USER TAG REELS

  bool isPaginationLoading = false;

  List<GetReelsData> mainReels = [];

  int currentPageIndex = 0;

  void onChangePage(int index) async {
    currentPageIndex = index;
    update(["onChangePage"]);
  }
}

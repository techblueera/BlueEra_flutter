import 'dart:developer';
import 'package:BlueEra/features/chat/auth/repo/symbol_repo.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:get/get.dart';

class SymbolFeedController extends GetxController {
  final RxList<SymbolFeedItem> symbols = <SymbolFeedItem>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSymbolFeed();
  }

  Future<void> fetchSymbolFeed() async {
    try {
      isLoading.value = true;
      final response = await SymbolRepo().fetchSymbolFeed(
        params: {'page': 1, 'limit': 20, 'populate': true},
      );

      if (response.isSuccess) {
        final parsed = SymbolFeedResponse.fromJson(response.response?.data);
        symbols.assignAll(parsed.data?.symbols ?? []);
      }
    } catch (e, s) {
      log('fetchSymbolFeed error: $e\n$s');
    } finally {
      isLoading.value = false;
    }
  }
}

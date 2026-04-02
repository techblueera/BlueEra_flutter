import 'dart:developer';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/chat/auth/repo/symbol_repo.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:BlueEra/features/common/reel/models/follow_following_res_model.dart';
import 'package:BlueEra/features/common/reel/repo/follower_repo.dart';
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

      // Fetch following list
      final followingResponse = await FollowerRepo().getFollowingList(userId: userId);
      Set<String> followedUserIds = {};
      if (followingResponse.isSuccess && followingResponse.response?.data != null) {
        final followingResModel = FollowingResModel.fromJson(followingResponse.response!.data);
        followedUserIds = followingResModel.data?.map((e) => e.following?.id ?? '').where((id) => id.isNotEmpty).toSet() ?? {};
      }

      final response = await SymbolRepo().fetchSymbolFeed(
        params: {'page': 1, 'limit': 20, 'populate': true},
      );

      if (response.isSuccess) {
        final parsed = SymbolFeedResponse.fromJson(response.response?.data);
        // Filter symbols to only include those from followed users
        final filteredSymbols = parsed.data?.symbols?.where((symbol) {
          return followedUserIds.contains(symbol.userId);
        }).toList() ?? [];
        symbols.assignAll(filteredSymbols);
      }
    } catch (e, s) {
      log('fetchSymbolFeed error: $e\n$s');
    } finally {
      isLoading.value = false;
    }
  }
}

import 'dart:async';
import 'package:BlueEra/features/common/ott/view/search_channel_res_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
// Import your model and repo files here

class SearchChannelController extends GetxController {
  // UI State
  var isLoading = false.obs;
  var searchList = <ChannelSearchData>[].obs;
  TextEditingController searchController = TextEditingController();

  // Debounce Timer to prevent too many API calls while typing
  Timer? _debounce;

  // Function called when text field changes
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Wait for 500ms after user stops typing to call API
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        getChannels(query);
      } else {
        searchList.clear(); // Clear list if text is empty
      }
    });
  }

  Future<void> getChannels(String query) async {
    isLoading.value = true;
    try {
      // Call your updated Repo
      final response = await ChannelRepo().getSearchChannelRepo(
          query: query,
          page: 1,
          limit: 10
      );

      if (response.statusCode == 200) {
        // Parse the JSON using the model
        ChannelSearchResponse searchResponse =
        ChannelSearchResponse.fromJson(response.response?.data);

        if (searchResponse.data != null) {
          searchList.value = searchResponse.data!;
        }
      }
    } catch (e) {
      print("Error fetching channels: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
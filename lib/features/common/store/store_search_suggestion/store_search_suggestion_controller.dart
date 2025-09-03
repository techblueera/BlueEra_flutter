import 'dart:async';

import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreSearchSuggestionController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final StoreRepo _storeRepo = StoreRepo();
  RxList<GetAllStoreResModel> searchResults = <GetAllStoreResModel>[].obs;
  RxBool isLoading = false.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  void searchBusinesses(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      clearSearchResults();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    isLoading.value = true;
    try {
      final response = await _storeRepo.searchStores(query: query);

      if (response.isSuccess) {
        // final List<dynamic> data = response.data;
        searchResults.value = List<GetAllStoreResModel>.from(
          (response.response!.data as List)
              .map((e) => GetAllStoreResModel.fromJson(e)),
        );
      } else {
        searchResults.clear();
      }
    } catch (e) {
      print('Error searching businesses: $e');
      searchResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearchResults() {
    searchResults.clear();
  }

  void onBusinessSelected(GetAllStoreResModel business, BuildContext context) {
    // Navigate to search screen with the selected business
    if (businessId == business.id) {
      navigatePushTo(context, BusinessOwnProfileScreen());
    } else {
      Get.to(() => VisitBusinessProfile(
          businessId: business.id?? ""));
    }    // Get.to(() => StoreSearchScreen(initialQuery: business.businessName));
  }
}

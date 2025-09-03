import 'dart:async';

import 'package:BlueEra/core/api/model/category_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/map/repo/add_place_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  // final RxString searchText = ''.obs;
   Rx<ValueNotifier<String>> searchText = ValueNotifier('').obs;

  RxList<CategoryModel> allCategories = <CategoryModel>[].obs;
  RxList<CategoryModel> filteredCategories = <CategoryModel>[].obs;
  RxSet<String> selectedCategoryIds = <String>{}.obs;

  RxBool isLoading = true.obs;
  RxBool validate = false.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    searchController.addListener(() {
      searchText.value.value = searchController.text;
      onSearchChanged(searchController.text);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await AddPlaceRepo().fetchCategories();
      if (response.isSuccess) {
        final categoryResponse =
            CategoryResponseModel.fromJson(response.response?.data);
        allCategories.value = categoryResponse.data;
        filteredCategories.value = List.from(allCategories);
        isLoading.value = false;
      } else {
        isLoading.value = false;
        commonSnackBar(
            message: response.message ?? 'Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      isLoading.value = false;
      commonSnackBar(message: 'Error loading categories');
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isEmpty) {
        filteredCategories.value = List.from(allCategories);
      } else {
        filteredCategories.value = allCategories
            .where(
                (cat) => cat.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void toggleCategory(String categoryId) {
    if (selectedCategoryIds.contains(categoryId)) {
      selectedCategoryIds.remove(categoryId);
    } else {
      selectedCategoryIds.add(categoryId);
    }
    validateForm();
  }

  void validateForm() {
    validate.value = selectedCategoryIds.isNotEmpty;
  }

  void clearSearch() {
    // searchText.value = '';
    searchController.clear();
    filteredCategories.value = List.from(allCategories);
  }
}

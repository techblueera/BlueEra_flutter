import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/store/models/get_channel_product_model.dart';
import 'package:BlueEra/features/common/store/repo/product_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelProductController extends GetxController {
  ApiResponse channelAllProductResponse = ApiResponse.initial('Initial');
  ApiResponse deleteChannelProductResponse = ApiResponse.initial('Initial');

  /// All Channel Product
  RxList<ProductData> allChannelProducts = <ProductData>[].obs;
  int allChannelProductsPage = 1;
  RxBool allChannelProductsFirstLoading = true.obs;
  RxBool allChannelProductsIsLoadingMore = false.obs;
  bool allChannelProductsHasMore = true;


  ///GET ALL Channel Product...
  Future<void> getAllChannelProduct({required String channelId, bool isInitialLoad = false, bool refresh = false}) async {
    if (isInitialLoad) {
      allChannelProductsPage = 1;
      allChannelProductsHasMore = true;
      allChannelProductsIsLoadingMore.value = false;
    }

    if (!allChannelProductsHasMore || allChannelProductsIsLoadingMore.isTrue) return;

    try {
      final response = await ProductRepo().getProduct(channelId: channelId);

      if (response.isSuccess) {
        channelAllProductResponse = ApiResponse.complete(response);
        final getProductResponse = GetProductResponse.fromJson(response.response?.data);
        allChannelProducts.value = getProductResponse.data ?? [];
        // if (videos.isNotEmpty) {
        //   // allChannelProductsPage.value.addAll(videos);
        //   allChannelProductsPage++;
        // } else {
        //   allChannelProductsHasMore = false;
        // }
      } else {
        channelAllProductResponse = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      channelAllProductResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      allChannelProductsFirstLoading.value = false;
      allChannelProductsIsLoadingMore.value = false;
    }
  }

  ///GET ALL Feed Personalized(In Shorts)...
  Future<void> deleteChannelProduct({required String productId}) async {
    final list = allChannelProducts;
    final index = list.indexWhere((p) => p.sId == productId);

    try {
      final response = await ProductRepo().deleteProduct(productId: productId);
      if (response.isSuccess) {
        deleteChannelProductResponse = ApiResponse.complete(response);
        if (index != -1) list.removeAt(index);
        Navigator.pop(navigator!.context);
        commonSnackBar(message: response.message);
      } else {
        deleteChannelProductResponse = ApiResponse.error('error');
      }
    } catch (_) {
      deleteChannelProductResponse = ApiResponse.error('error');
    }
  }

}
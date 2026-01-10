import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/food/model/grocery_available_item_model.dart';
import 'package:BlueEra/features/common/food/model/grocery_order_model.dart';
import 'package:BlueEra/features/common/food/repo/grocery_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyGroceryOrdersController extends GetxController{
  Rx<ApiResponse> myGroceryOrdersResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> submitCustomerOrderResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> customerOrderAvailableItemResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> submitOrderToRiderResponse =
      ApiResponse.initial('Initial').obs;

  final List<MyGroceryOrdersTab> groceryOrdersTabs =
      MyGroceryOrdersTab.values;
  Rx<MyGroceryOrdersTab> groceryOrderStatus = MyGroceryOrdersTab.pending.obs;
  RxList<GroceryOrdersModel> groceryPendingOrders = <GroceryOrdersModel>[].obs;

  /// Bill Details
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final groceryAvailableItemModel = Rxn<GroceryAvailableItemModel>();
  final netPaymentController = TextEditingController();
  var selectedPaymentMode = GroceryPaymentMode.cash.obs;
  void selectMode(GroceryPaymentMode mode) {
    selectedPaymentMode.value = mode;
  }


  var selectedGroceryIds = <String>{}.obs;
  void toggleSelection(GroceryItem item) {
    final String? id = item.id;

    // Safety check for null ID
    if (id == null) return;

    // 2. Simple Add/Remove logic for Set
    if (selectedGroceryIds.contains(id)) {
      selectedGroceryIds.remove(id);
    } else {
      selectedGroceryIds.add(id);
    }
  }

 // 3. Helper to check status (Use this in your UI)
  bool isItemSelected(String? id) => selectedGroceryIds.contains(id);


  @override
  void onClose() {
    netPaymentController.dispose();
    super.onClose();
  }

  RxBool isGroceryOrdersLoading = false.obs;
  Future<void> fetchGroceryOrders({required String groceryOrderStatus}) async {
    try {
      isGroceryOrdersLoading.value = true;

      final response = await GroceryRepo().fetchGroceryOrdersRepo(
        queryParm: {
            ApiKeys.businessId : businessId,
            ApiKeys.status : groceryOrderStatus, /// inprogress, complete, cancelled
          },
      );

      if (response.isSuccess) {
        myGroceryOrdersResponse.value = ApiResponse.complete(response);
        if (response.response?.data != null && response.response?.data is List) {
          groceryPendingOrders.value = groceryOrdersModelFromList(response.response?.data);
        }
      } else {
        myGroceryOrdersResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      myGroceryOrdersResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isGroceryOrdersLoading.value = false;
    }
  }

  RxBool isGroceryItemAvailabilityLoading = false.obs;
  Future<void> submitCustomerOrderForItemAvailability({required String groceryOrderId}) async {
    try {
      isGroceryItemAvailabilityLoading.value = true;

      final response = await GroceryRepo().groceryOrderItemAvailabilityRepo(
        params: {
          ApiKeys.groceryOrderId : groceryOrderId,
          ApiKeys.businessId : businessId,
          ApiKeys.availableInventoryIds : selectedGroceryIds.toList(),
        },
      );

      if (response.isSuccess) {
        submitCustomerOrderResponse.value = ApiResponse.complete(response);
        selectedGroceryIds.clear();
        Get.back();
        fetchGroceryOrders(
            groceryOrderStatus: 'inprogress'
        );
      } else {
        submitCustomerOrderResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      submitCustomerOrderResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isGroceryItemAvailabilityLoading.value = false;
    }
  }

  RxBool isBillLoading = false.obs;
  Future<void> getCustomerGroceryOrderAvailableItem({required String groceryOrderId}) async {
    try {
      isBillLoading.value = true;

      final response = await GroceryRepo().groceryOrderAvailableItemRepo(
        queryParams: {
          ApiKeys.businessId : businessId,
          ApiKeys.groceryOrderId : groceryOrderId,
        },
      );

      if (response.isSuccess) {
        customerOrderAvailableItemResponse.value = ApiResponse.complete(response);
        groceryAvailableItemModel.value = GroceryAvailableItemModel.fromJson(response.response?.data);
      } else {
        customerOrderAvailableItemResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      customerOrderAvailableItemResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isBillLoading.value = false;
    }
  }

  RxBool isSubmitOrderToRiderLoading = false.obs;
  Future<void> submitOrderToRider({
    required String riderOrderId,
    required String groceryOrderId,
  }) async{
    if(formKey.currentState!.validate()){
      try {
        isSubmitOrderToRiderLoading.value = true;

        final response = await GroceryRepo().submitGroceryOrderToRiderRepo(
          params: {
            ApiKeys.businessId : businessId,
            ApiKeys.rideOrderId : riderOrderId,
            ApiKeys.groceryOrderId : groceryOrderId,
            ApiKeys.paymentStatus : true,
            ApiKeys.paymentMode : selectedPaymentMode.value.apiValue,  // enum: ['cash', 'upi', 'pending'],
            ApiKeys.amountPaid : netPaymentController.text.trim(),
          },
        );

        if (response.isSuccess) {
          submitOrderToRiderResponse.value = ApiResponse.complete(response);
          Get.back();
          groceryPendingOrders.clear();
          fetchGroceryOrders(
              groceryOrderStatus: 'inprogress'
          );
        } else {
          submitOrderToRiderResponse.value = ApiResponse.error('error');
        }
      } catch (e, s) {
        submitOrderToRiderResponse.value = ApiResponse.error('error');
        print("stack trace: $s");
      } finally {
        isSubmitOrderToRiderLoading.value = false;
      }
    }
  }


}
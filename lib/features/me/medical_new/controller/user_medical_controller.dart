import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/model/GetBlueeraPiolotModel.dart';
import 'package:BlueEra/features/me/medical_new/model/add_medical_order_response.dart';
import 'package:BlueEra/features/me/medical_new/repo/medical_repo.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical_new/stream/rider_medical_stream.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/medical_product_model.dart';

class UserMedicalController extends GetxController{
  Rx<ApiResponse> userMedicalCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addMedicalOrderResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> updateMedicalOrderResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> nearByRidersResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> sendOrderReqToRiderResponse =
      ApiResponse.initial('Initial').obs;

  final selectedMedicalData = Rxn<MedicalNestedCategoryModel>();

  RxList<VariantsData> selectedMedicalProductVariants = <VariantsData>[].obs;

  // Map to store quantity for each variant ID: { "variant_id": quantity }
  var cartQuantities = <String, int>{}.obs;

  // --- Actions ---
  void addToCart(VariantsData variant) {
    if (variant.sId == null) return;

    if (cartQuantities.containsKey(variant.sId)) {
      cartQuantities[variant.sId!] = cartQuantities[variant.sId]! + 1;
    } else {
      selectedMedicalProductVariants.add(variant);
      cartQuantities[variant.sId!] = 1;
    }
  }

  void removeFromCart(VariantsData variant) {
    if (variant.sId == null || !cartQuantities.containsKey(variant.sId)) return;

    int currentQty = cartQuantities[variant.sId]!;

    if (currentQty > 1) {
      cartQuantities[variant.sId!] = currentQty - 1;
    } else {
      // Quantity is 1, so remove completely
      cartQuantities.remove(variant.sId);
      selectedMedicalProductVariants.removeWhere((v) => v.sId == variant.sId);
    }
  }

  int getQuantity(String? variantId) {
    if (variantId == null) return 0;
    return cartQuantities[variantId] ?? 0;
  }

  // --- Computed Bill Details ---

  double get totalMRP {
    double total = 0;
    for (var variant in selectedMedicalProductVariants) {
      int qty = cartQuantities[variant.sId] ?? 0;
      double mrp = double.tryParse(variant.pricing?.first.mrp.toString() ?? '0') ?? 0;
      total += (mrp * qty);
    }
    return total;
  }

  double get totalSellingPrice {
    double total = 0;
    for (var variant in selectedMedicalProductVariants) {
      int qty = cartQuantities[variant.sId] ?? 0;
      double sp = double.tryParse(variant.pricing?.first.sellingPrice.toString() ?? '0') ?? 0;
      total += (sp * qty);
    }
    return total;
  }

  double get totalSavings => totalMRP - totalSellingPrice;
  double get totalDiscountPercentage {
    if (totalMRP == 0) return 0.0;

    double percentage = (totalSavings / totalMRP) * 100;
    return percentage;
  }

  int get totalItemsCount {
    int count = 0;
    cartQuantities.forEach((key, value) {
      count += value;
    });
    return count;
  }

  RxList<Riders> arrRiders = <Riders>[].obs;

  // Track riders we have successfully assigned to the order (Step 1)
  var assignedRiderIds = <String>{}.obs;

  // Track riders we have successfully sent requests to (Step 2)
  var sentRiderIds = <String>{}.obs;

  late Stream<dynamic> stream;
  StreamSubscription? subscription;

  RxBool isUserMedicalLoading = false.obs;
  RxList<MedicalProductData> arrUserMedicalProducts = <MedicalProductData>[].obs;
  RxBool isUserMedicalLoadingMore = false.obs;
  int userMedicalPage = 1;
  bool userMedicalHasMore = true;
  int pageLimit = 20;

  Future<void> fetchUserGroceries({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isUserMedicalLoadingMore.value = true;
      } else {
        arrUserMedicalProducts.clear();
        isUserMedicalLoading.value = true;
        userMedicalPage = 1;
        userMedicalHasMore = true;
      }


      String postalCode = LocationService.userCurrentAddress.value.postalCode;
      if(postalCode.isEmpty) return;

      // log('current tab key-- $currentTabKey');
      Map<String, dynamic> queryParams = {
        ApiKeys.pincode: postalCode,
        ApiKeys.page: userMedicalPage,
        ApiKeys.limit: pageLimit
      };

      final response = await MedicalRepo()
          .userSearchGroceryCategoryRepo(queryParam: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      userMedicalCategoryResponse.value = ApiResponse.complete(response);

      final groceryProductModel = MedicalProductModel.fromJson(response.response?.data);
      List<MedicalProductData> newItems = groceryProductModel.data ?? [];

      if (newItems.isNotEmpty) {
        if (isLoadMore) {
          arrUserMedicalProducts.addAll(newItems);
        } else {
          arrUserMedicalProducts.assignAll(newItems);
        }

        userMedicalPage++;
      } else {
        userMedicalHasMore = false;
      }

      log('total grocery-- ${arrUserMedicalProducts.length}');
    } catch (e, s) {
      userMedicalCategoryResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isUserMedicalLoadingMore.value = false;
      } else {
        isUserMedicalLoading.value = false;
      }
    }
  }

  void showCircularLoader() {
    Get.dialog(
      Center(
        child: Container(
          width: SizeConfig.size90,
          height: SizeConfig.size90,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
          ),
          child: staggeredDotsWaveLoading(
            color: AppColors.primaryColor,
          ),
        ),
      ),

      barrierDismissible: false, // Prevent closing by tapping outside

    );
  }

  void show({required String text}) {
    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppColors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content
              children: [
                Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                  ),
                  child: staggeredDotsWaveLoading(
                    color: AppColors.primaryColor,
                  ),
                ),
                CustomText(
                    text,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void hide() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  List<Map<String, dynamic>> buildOrderItems() {
    List<Map<String, dynamic>> items = [];

    for (var variant in selectedMedicalProductVariants) {
      int qty = cartQuantities[variant.sId] ?? 0;

      // Only add items that actually have a quantity
      if (qty > 0) {
        items.add({
          "productVariant": variant.sId ?? "",
          "quantity": qty,
          "mrp": totalMRP.toStringAsFixed(2),
          "sellingPrice": totalSellingPrice.toStringAsFixed(2)
        });
      }
    }

    return items;
  }

  RxBool isAddMedicalOrderLoading = false.obs;
  Future<void> addMedicalOrderApi() async {
    try {
      isAddMedicalOrderLoading.value = true;
      showCircularLoader();

      final itemsList = buildOrderItems();


      // 2. Create the Final Request Body
      final Map<String, dynamic> requestBody = {
        "items": itemsList,
        "deliveryType": "rider", ///self-pickup
        "discount": totalSavings.toStringAsFixed(2),
      };

      // print("Request Body: ${jsonEncode(requestBody)}");

      final response = await MedicalRepo().
                        groceryOrderRepo(params: requestBody);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      addMedicalOrderResponse.value = ApiResponse.complete(response);

      final addGroceryOrderResponseModel = AddMedicalOrderResponseModel.fromJson(response.response?.data);
      String orderId = addGroceryOrderResponseModel.id ?? '';
      hide();
      Get.toNamed(
          RouteHelper.getMedicalConfirmScreenRoute(),
          arguments: {ApiKeys.argOrderId: orderId}
      );

    } catch (e) {
      hide();
      addMedicalOrderResponse.value = ApiResponse.error('error');
    } finally {
      isAddMedicalOrderLoading.value = false;
    }
  }

  RxBool isNearByRidersLoading = false.obs;
  Future<void> fetchNearByRidersApi() async {
    try {
      isNearByRidersLoading.value = true;
      arrRiders.clear();
      assignedRiderIds.clear();
      sentRiderIds.clear();

      double lat = LocationService.lat;
      double lng = LocationService.lng;

      Map<String, dynamic> queryParams = {
        ApiKeys.latitude: lat,
        ApiKeys.longitude: lng,
        ApiKeys.range_in_km: 10000,
      };

      final response = await MedicalRepo().fetchNearByRidersRepo(queryParams: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      nearByRidersResponse.value = ApiResponse.complete(response);

      final data = response.response?.data;

      GetBlueeraPiolotModel getBlueeraPiolotModel = GetBlueeraPiolotModel.fromJson(data);
      arrRiders.value = getBlueeraPiolotModel.users ?? [];

      log('arrRiders length-- ${arrRiders.length}');
      update();
    } catch (e, s) {
      nearByRidersResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {
      isNearByRidersLoading.value = false;
    }
  }

  Future<void> executeOrderProcess({required String orderId, required String riderId}) async {

    show(text: AppStrings.medicalWaitingForRiderResponse.tr);

    // Quick Check: If BOTH steps are already done for this rider, just restart stream.
    if (assignedRiderIds.contains(riderId) &&
        sentRiderIds.contains(riderId)) {

      log("All steps completed for rider $riderId. Restarting stream.");
      await groceryRiderStreamApi();
      return;
    }


    try {
      // ---------------- STEP 1: Update Order Status ---------------- //
      // CHECK: Have we already updated the order for THIS rider?
      if (!assignedRiderIds.contains(riderId)) {
        log("Step 1: Updating Order with Rider $riderId...");

        await updateMedicalOrderApi(
            orderId: orderId,
            riderId: riderId
        );

        if (updateMedicalOrderResponse.value.status == Status.ERROR) {
          return; // Stop if Step 1 fails
        }

        // SUCCESS Step 1: Add to 'assigned' set so we don't do this again for this rider
        assignedRiderIds.add(riderId);

      } else {
        log("Skipping Step 1: Order already assigned to Rider $riderId");
      }

      // ---------------- STEP 2: Send Request to Rider ---------------- //
      // CHECK: Have we already sent the notification to THIS rider?
      if (!sentRiderIds.contains(riderId)) {
        log("Step 2: Sending Notification to Rider $riderId...");

        await sendOrderReqToRiderApi(
            orderId: orderId,
            riderId: riderId
        );

        if (sendOrderReqToRiderResponse.value.status == Status.ERROR) {
          return; // Stop if Step 2 fails
        }

        // SUCCESS Step 2: Add to 'sent' set
        sentRiderIds.add(riderId);

      } else {
        log("Skipping Step 2: Request already sent to Rider $riderId");
      }

      // ---------------- STEP 3: Start Stream ---------------- //
      await groceryRiderStreamApi();

    } catch (e) {
      log("Process Error: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
      hide();
    }
  }

  Future<void> updateMedicalOrderApi({
    required String orderId,
    required String riderId}) async {
    try {

      Map<String, dynamic> params = {
        'orderStatus': 'placed',
        'rider': riderId,
      };

      final response = await MedicalRepo().updateGroceryOrderRepo(
          params: params,
          orderId: orderId
      );

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      updateMedicalOrderResponse.value = ApiResponse.complete(response);

    } catch (e, s) {
      updateMedicalOrderResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {
    }
  }

  Future<void> sendOrderReqToRiderApi({
    required String orderId,
    required String riderId}) async {
    try {

      double lat = LocationService.lat;
      double lng = LocationService.lng;
      String dropLocation = LocationService.userCurrentAddress.value.formattedAddress;

      Map<String, dynamic> params = {
        ApiKeys.selectedRiders: [riderId],
        ApiKeys.dropLocation: {
          ApiKeys.address: dropLocation,
          ApiKeys.latitude: lat,
          ApiKeys.longitude: lng
        },
        ApiKeys.orderId: orderId,
        ApiKeys.receiverUserId: userId,
        ApiKeys.orderFor: AppConstants.grocery,
        ApiKeys.modeOfPayment: AppConstants.postpaid
      };
      log("Request Body: $params");

      final response = await MedicalRepo()
          .orderReqToRiderRepo(params: params);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      sendOrderReqToRiderResponse.value = ApiResponse.complete(response);

    } catch (e, s) {
      sendOrderReqToRiderResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {

    }
  }

  Future<void> groceryRiderStreamApi() async {
      stream = await medicalRiderOrderStream();
      subscription = stream.listen((event) {
        log('Event received: $event'); // Good for debugging

        // Case 1: It's a List (e.g., [], or [{status: '...'}, {status: '...'}])
        if (event is List) {
          if (event.isEmpty) {
            hide();
            log('Received empty list - no active orders or updates.');
            return;
          }

          // Loop through the items in the list
          for (var item in event) {
            _handleStatusUpdate(item); // Create a helper method for clean code
          }
        }

        // // Case 2: It's a Map (e.g., {status: 'payment-pending'})
        // else if (event is Map) {
        //   _handleStatusUpdate(event);
        // }

      }, onError: (error) {
        print('❌ Stream error: $error');
      }, onDone: () {
        print('ℹ️ Stream closed');
      });
  }

  void _handleStatusUpdate(dynamic item) {
    final status = item['status'];
    log('Processing status: $status');

    if (status == 'pending') {
      // Your dialog logic here

    } else if(status == 'accepted') {
      hide(); // TERMINAL STATE: Hide loader
      commonSnackBar(message: AppStrings.medicalRiderAcceptedRequest.tr);

    } else if(status == 'rejected' || status == 'cancelled'){
      hide(); // TERMINAL STATE: Hide loader
      commonSnackBar(message: AppStrings.medicalRiderRejectedRequest.tr);
      // Cancel stream and redirect to home
      _cleanupAndNavigateHome();
    } else if(status == 'completed' || status == 'delivered'){
      hide();
      commonSnackBar(message: 'Your medical order has been delivered successfully!');
      // Cancel stream and redirect to home
      _cleanupAndNavigateHome();
    } else{

    }
  }

  void _cleanupAndNavigateHome() {
    subscription?.cancel();
    subscription = null;
    // Navigate back to bottom navigation bar (home)
    Get.until((route) =>
        route.settings.name == '/BottomNavigationBarScreen' ||
        route.isFirst);
  }

  @override
  void onClose() {
    subscription?.cancel();
    subscription = null;
    super.onClose();
  }

}
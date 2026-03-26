import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/chat/auth/model/GetBlueeraPiolotModel.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/rider_lookuo_dialog.dart';
import 'package:BlueEra/features/me/grocery/model/add_grocery_order_response.dart';
import 'package:BlueEra/features/me/grocery/model/children_of_grocery_category_response.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/grocery/stream/rider_grocery_stream.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

class GroceryRiderConsumerController extends GetxController{
  Rx<ApiResponse> fetchNestedGroceryCategoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addGroceryOrderResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> updateGroceryOrderResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> sendOrderReqToRiderResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> nearByRidersResponse =
      ApiResponse.initial('Initial').obs;

  final List<Map<String, String>> grocerySnapSearchConfig = [
    {
      'title': 'Upload Grocery List',
      'icon': AppIconAssets.cameraAddOutlineIcon,
      'image': AppImageAssets.groceryImageFirst,
    },
    {
      'title': 'Search Manually',
      'icon': AppIconAssets.search,
      'image': AppImageAssets.groceryImageSecond,
    },
  ];

  // ── Snap Search ────────────────────────────────────────────────────────────
  Rx<ApiResponse> riderSnapSearchResponse = ApiResponse.initial('Initial').obs;
  Rxn<ProductSnapSearchData> riderSnapSearchData = Rxn<ProductSnapSearchData>();
  final RxMap<String, File?> riderSnapSearchImagesMap = <String, File?>{}.obs;

  Future<void> addRiderImageBySlot(String title) async {
    if (riderSnapSearchImagesMap.values.any((v) => v != null)) {
      commonSnackBar(message: "Please remove the current image before selecting another.");
      return;
    }
    final List<String>? selected =
        await SelectProductImageDialog.showLogoDialog(Get.context!, title);
    if (selected == null || selected.isEmpty) return;

    riderSnapSearchImagesMap[title] = File(selected.first);
    fetchRiderGrocerySnapSearchApi();
  }

  void removeRiderImageBySlot(String title) {
    riderSnapSearchImagesMap[title] = null;
    riderSnapSearchImagesMap.refresh();
  }

  Future<void> fetchRiderGrocerySnapSearchApi() async {
    final List<File> activeImages = riderSnapSearchImagesMap.values
        .where((f) => f != null)
        .cast<File>()
        .toList();

    if (activeImages.isEmpty) {
      commonSnackBar(message: "Please upload at least 1 photo");
      return;
    }

    try {
      riderSnapSearchResponse.value = ApiResponse.loading('Loading');
      riderSnapSearchData.value = null;

      List<dio.MultipartFile> imageParts = [];
      for (final image in activeImages) {
        final fileName = image.path.split('/').last;
        imageParts.add(
          await dio.MultipartFile.fromFile(image.path, filename: fileName),
        );
      }

      String postalCode = LocationService.userCurrentAddress.value.postalCode;
      if (postalCode.isEmpty) return;

      Map<String, dynamic> params = {
        ApiKeys.images: imageParts,
        ApiKeys.pincode: postalCode,
      };

      final response = await GroceryRepo().fetchGrocerySnapSearchWithInventoryRepo(
        params: params,
      );

      if (response.isSuccess) {
        riderSnapSearchResponse.value = ApiResponse.complete(response);
        final model =
            GrocerySnapSearchResponseModel.fromJson(response.response?.data);
        riderSnapSearchData.value = model.data;
      } else {
        riderSnapSearchResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      riderSnapSearchResponse.value = ApiResponse.error('error');
      log('fetchRiderGrocerySnapSearchApi error: $s');
    }
  }

  final selectedGroceryData = Rxn<GroceryNestedCategoryModel>();
  RxInt selectedTabIndex = 0.obs;

  String get currentTabKey => selectedTabIndex.value == 0
      ? (selectedGroceryData.value?.key ?? '')
      : groceryChildrenWithInventoryCat[selectedTabIndex.value - 1]
      .key ??
      '';

  String get currentTabName => selectedTabIndex.value == 0
      ? (selectedGroceryData.value?.name ?? 'All Items')
      : (groceryChildrenWithInventoryCat[selectedTabIndex.value - 1]
      .name ??
      '');

  RxList<ProductVariants> selectedGroceriesVariants = <ProductVariants>[].obs;

  RxList<Riders> arrRiders = <Riders>[].obs;

  // Track riders we have successfully assigned to the order (Step 1)
  var assignedRiderIds = <String>{}.obs;

  // Track riders we have successfully sent requests to (Step 2)
  var sentRiderIds = <String>{}.obs;

  late Stream<dynamic> stream;
  StreamSubscription? subscription;

  // Map to store quantity for each variant ID: { "variant_id": quantity }
  var cartQuantities = <String, int>{}.obs;

  // Map to store product ID for each variant ID: { "variant_id": "product_id" }
  var cartProductIds = <String, String>{}.obs;

  // --- Actions ---
  void addToCart(
      ProductVariants variant,
      {String? productId, String? inventoryId,
        String? businessId, String? businessName, String? businessLogo, String? businessAddress,
        // String? deliveryType
      }) {
    if (variant.sId == null) return;

    if (cartQuantities.containsKey(variant.sId)) {
      cartQuantities[variant.sId!] = cartQuantities[variant.sId]! + 1;
    } else {
      selectedGroceriesVariants.add(variant);
      cartQuantities[variant.sId!] = 1;
      if (productId != null) {
        cartProductIds[variant.sId!] = productId;
      }
    }
  }

  void removeFromCart(ProductVariants variant) {
    if (variant.sId == null || !cartQuantities.containsKey(variant.sId)) return;

    int currentQty = cartQuantities[variant.sId]!;

    if (currentQty > 1) {
      cartQuantities[variant.sId!] = currentQty - 1;
    } else {
      // Quantity is 1, so remove completely
      cartQuantities.remove(variant.sId);
      cartProductIds.remove(variant.sId);
      selectedGroceriesVariants.removeWhere((v) => v.sId == variant.sId);
    }
  }

  String? getProductId(String? variantId) {
    if (variantId == null) return null;
    return cartProductIds[variantId];
  }

  int getQuantity(String? variantId) {
    if (variantId == null) return 0;
    return cartQuantities[variantId] ?? 0;
  }

  // --- Computed Bill Details ---

  double get totalMRP {
    double total = 0;
    for (var variant in selectedGroceriesVariants) {
      int qty = cartQuantities[variant.sId] ?? 0;
      double mrp =
          double.tryParse(variant.pricing?.first.mrp.toString() ?? '0') ?? 0;
      total += (mrp * qty);
    }
    return total;
  }

  double get totalSellingPrice {
    double total = 0;
    for (var variant in selectedGroceriesVariants) {
      int qty = cartQuantities[variant.sId] ?? 0;
      double sp = double.tryParse(
          variant.pricing?.first.sellingPrice.toString() ?? '0') ??
          0;
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


  RxBool isUserGroceryLoading = false.obs;
  RxList<GroceryProductData> arrUserGrocery = <GroceryProductData>[].obs;
  RxBool isUserGroceryLoadingMore = false.obs;
  int userGroceryPage = 1;
  bool userGroceryHasMore = true;
  int pageLimit = 20;

  Future<void> fetchUserGroceries({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isUserGroceryLoadingMore.value = true;
      } else {
        arrUserGrocery.clear();
        isUserGroceryLoading.value = true;
        userGroceryPage = 1;
        userGroceryHasMore = true;
      }

      // final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();
      // final businessData = viewBusinessDetailsController.businessProfileDetails?.data;
      //
      // print("Pincode (Profile): ${businessData?.pincode}");

      double lat = LocationService.lat;
      double lng = LocationService.lng;
      String postalCode = LocationService.userCurrentAddress.value.postalCode;
      if (postalCode.isEmpty) return;

      // log('current tab key-- $currentTabKey');
      Map<String, dynamic> queryParams = {
        ApiKeys.pincode: postalCode,
        ApiKeys.lat: lat,
        ApiKeys.lng: lng,
        ApiKeys.range: kmRadius1500,
        ApiKeys.key: currentTabKey,
        ApiKeys.page: userGroceryPage,
        ApiKeys.limit: pageLimit
      };

      final response = await GroceryRepo()
          .userSearchGroceryCategoryRepo(queryParam: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }


      final groceryProductModel =
      GroceryProductModel.fromJson(response.response?.data);
      List<GroceryProductData> newItems = groceryProductModel.data ?? [];

      if (newItems.isNotEmpty) {
        if (isLoadMore) {
          arrUserGrocery.addAll(newItems);
        } else {
          arrUserGrocery.assignAll(newItems);
        }

        userGroceryPage++;
      } else {
        userGroceryHasMore = false;
      }

      log('total grocery-- ${arrUserGrocery.length}');
    } catch (e, s) {
      log('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isUserGroceryLoadingMore.value = false;
      } else {
        isUserGroceryLoading.value = false;
      }
    }
  }

  RxBool isGroceryCategoryOfChildrenLoading = false.obs;
  RxList<ChildrenOfGroceryCategoryResponse>
  groceryChildrenWithInventoryCat = <ChildrenOfGroceryCategoryResponse>[].obs;

  Future<void> fetchChildrenOfGroceryCategory() async {
    try {
      isGroceryCategoryOfChildrenLoading.value = true;
      final response = await GroceryRepo()
          .groceryCategoryOfChildWithInventoryRepo(key: currentTabKey);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      groceryChildrenWithInventoryCat.value =
          ChildrenOfGroceryCategoryResponse.fromJsonList(jsonData);
    } catch (e) {
    } finally {
      isGroceryCategoryOfChildrenLoading.value = false;
    }
  }

  RxBool isAddGroceryOrderLoading = false.obs;

  Future<void> addGroceryOrderApi() async {
    try {
      isAddGroceryOrderLoading.value = true;
      AppLoader.show();

      final itemsList = buildOrderItems();

      // 2. Create the Final Request Body
      final Map<String, dynamic> requestBody = {
        "items": itemsList,
        "deliveryType": "rider",

        ///self-pickup
        "discount": totalSavings.toStringAsFixed(2),
      };

      // print("Request Body: ${jsonEncode(requestBody)}");

      final response =
      await GroceryRepo().groceryOrderRepo(params: requestBody);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      addGroceryOrderResponse.value = ApiResponse.complete(response);

      final addGroceryOrderResponseModel =
      AddGroceryOrderResponseModel.fromJson(response.response?.data);
      String orderId = addGroceryOrderResponseModel.id ?? '';
      AppLoader.hide();
      Get.toNamed(
          RouteHelper.getGroceryConfirmScreenRoute(),
          arguments: {ApiKeys.argOrderId: orderId}
      );

    } catch (e) {
      AppLoader.hide();
      addGroceryOrderResponse.value = ApiResponse.error('error');
    } finally {
      isAddGroceryOrderLoading.value = false;
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
        // ApiKeys.latitude: 21.817693,
        // ApiKeys.longitude: 80.181220,
        ApiKeys.range_in_km: 10000,
      };

      final response =
      await GroceryRepo().fetchNearByRidersRepo(queryParams: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      nearByRidersResponse.value = ApiResponse.complete(response);

      final data = response.response?.data;

      GetBlueeraPiolotModel getBlueeraPiolotModel =
      GetBlueeraPiolotModel.fromJson(data);
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

  List<Map<String, dynamic>> buildOrderItems() {
    List<Map<String, dynamic>> items = [];

    for (var variant in selectedGroceriesVariants) {
      int qty = cartQuantities[variant.sId] ?? 0;

      // Only add items that actually have a quantity
      if (qty > 0) {
        items.add({
          "productVariant": variant.sId ?? "",
          "product": cartProductIds[variant.sId] ?? variant.product ?? "",
          "quantity": qty,
          "mrp": totalMRP.toStringAsFixed(2),
          "sellingPrice": totalSellingPrice.toStringAsFixed(2)
        });
      }
    }

    return items;
  }

  Future<void> executeOrderProcess(
      {required String orderId, required String riderId}) async {
    RiderLookupDialog.show(text: 'Waiting for rider response...');

    // Quick Check: If BOTH steps are already done for this rider, just restart stream.
    if (assignedRiderIds.contains(riderId) && sentRiderIds.contains(riderId)) {
      log("All steps completed for rider $riderId. Restarting stream.");
      await groceryRiderStreamApi();
      return;
    }

    try {
      // ---------------- STEP 1: Update Order Status ---------------- //
      // CHECK: Have we already updated the order for THIS rider?
      if (!assignedRiderIds.contains(riderId)) {
        log("Step 1: Updating Order with Rider $riderId...");

        await updateGroceryOrderApi(orderId: orderId, riderId: riderId);

        if (updateGroceryOrderResponse.value.status == Status.ERROR) {
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

        await sendOrderReqToRiderApi(orderId: orderId, riderId: riderId);

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
      AppLoader.hide();
    }
  }

  Future<void> updateGroceryOrderApi(
      {required String orderId, required String riderId}) async {
    try {
      Map<String, dynamic> params = {
        'orderStatus': 'placed',
        'rider': riderId,
      };

      final response = await GroceryRepo()
          .updateGroceryOrderRepo(params: params, orderId: orderId);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      updateGroceryOrderResponse.value = ApiResponse.complete(response);
    } catch (e, s) {
      updateGroceryOrderResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {}
  }



  Future<void> sendOrderReqToRiderApi(
      {required String orderId, required String riderId}) async {
    try {
      double lat = LocationService.lat;
      double lng = LocationService.lng;
      String dropLocation =
          LocationService.userCurrentAddress.value.formattedAddress;

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

      final response = await GroceryRepo().orderReqToRiderRepo(params: params);

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
    } finally {}
  }

  Future<void> groceryRiderStreamApi() async {
    stream = await groceryRiderOrderStream();
    subscription = stream.listen((event) {
      log('Event received: $event'); // Good for debugging

      // Case 1: It's a List (e.g., [], or [{status: '...'}, {status: '...'}])
      if (event is List) {
        if (event.isEmpty) {
          AppLoader.hide();
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
    } else if (status == 'accepted') {
      AppLoader.hide(); // TERMINAL STATE: Hide loader
      commonSnackBar(message: "Rider $status the request");
    } else if (status == 'rejected' || status == 'cancelled') {
      AppLoader.hide();// TERMINAL STATE: Hide loader
      commonSnackBar(message: "Rider $status the request");
    } else {}
  }

}
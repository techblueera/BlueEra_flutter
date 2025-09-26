import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreScreenController extends GetxController {
  Rx<ApiResponse> getAllStoreResponse = ApiResponse.initial('Initial').obs;

  RxList<GetAllStoreResModel> getAllStore = <GetAllStoreResModel>[].obs;
  RxBool isLoading=false.obs;
  Future<void> getAllStoreNearBy(
   BuildContext context) async {
    try {
      isLoading.value=true;
      await LocationService.fetchLocation();

      final response = await StoreRepo()
          .getStore(lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "", long:  LocationService.lng != 0.0 ? "${LocationService.lng}" : ""); // Make sure repo uses params
      if (response.statusCode == 200) {
        final List<GetAllStoreResModel> places = List<GetAllStoreResModel>.from(
          (response.response!.data as List)
              .map((e) => GetAllStoreResModel.fromJson(e)),
        );

        getAllStore.value = places;
        getAllStoreResponse.value = ApiResponse.complete(response);
        isLoading.value=false;

      } else {
        isLoading.value=false;

        getAllStoreResponse.value = ApiResponse.error('error');

        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      isLoading.value=false;

      print("Error: $e");

      getAllStoreResponse.value = ApiResponse.error('error');
    }
  }

  // Scroll and Header Management
  final GlobalKey headerKey = GlobalKey();
  final ScrollController scrollController = ScrollController();
  final RxDouble headerHeight = 0.0.obs;
  final RxBool isHeaderVisible = true.obs;

  // Search Management
  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;

  // Categories Data
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;

  // Stores Data
  final RxList<Map<String, dynamic>> stores = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupListeners();
    _calculateHeaderHeight();
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _initializeData() {
    // Initialize categories data
    categories.value = [
      {"title": "Plumber", "icon": AppIconAssets.plumber, "color": Colors.teal},
      {
        "title": "Electrician",
        "icon": AppIconAssets.electrician,
        "color": Colors.purple
      },
      {
        "title": "Teacher",
        "icon": AppIconAssets.teacher,
        "color": Colors.lightBlue
      },
      {"title": "Painter", "icon": AppIconAssets.painter, "color": Colors.pink},
      {"title": "Driver", "icon": AppIconAssets.driver, "color": Colors.green},
    ];

    // Initialize stores data
    stores.value = [
      {
        "name": "Burger King",
        "category": "Restaurant",
        "rating": "4.8",
        "reviews": "6.2K",
        "cuisine": "Fast Food",
        "status": "Open - Closes 12 am",
        "address": "Ground Floor, Sahu Theatre Building Uttar Pradesh 226001",
        "image": AppImageAssets.dummy_burger_king,
      },
      {
        "name": "Pizza Hut",
        "category": "Restaurant",
        "rating": "4.6",
        "reviews": "4.8K",
        "cuisine": "Italian",
        "status": "Open - Closes 11 pm",
        "address": "First Floor, Mall Complex Uttar Pradesh 226001",
        "image": AppImageAssets.dummy_burger_king,
      },
      {
        "name": "KFC",
        "category": "Restaurant",
        "rating": "4.7",
        "reviews": "5.1K",
        "cuisine": "Fast Food",
        "status": "Open - Closes 12 am",
        "address": "Ground Floor, Shopping Center Uttar Pradesh 226001",
        "image": AppImageAssets.dummy_burger_king,
      },
      {
        "name": "McDonald's",
        "category": "Restaurant",
        "rating": "4.5",
        "reviews": "3.9K",
        "cuisine": "Fast Food",
        "status": "Open - Closes 11 pm",
        "address": "Second Floor, Food Court Uttar Pradesh 226001",
        "image": AppImageAssets.dummy_burger_king,
      },
      {
        "name": "Domino's",
        "category": "Restaurant",
        "rating": "4.4",
        "reviews": "4.2K",
        "cuisine": "Pizza",
        "status": "Open - Closes 12 am",
        "address": "Ground Floor, Commercial Complex Uttar Pradesh 226001",
        "image": AppImageAssets.dummy_burger_king,
      },
    ];
  }

  void _setupListeners() {
    // Search controller listener
    searchController.addListener(() {
      searchText.value = searchController.text;
    });

    // Scroll controller listener
    scrollController.addListener(_onScroll);
  }

  void _calculateHeaderHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        headerHeight.value = renderBox.size.height;
      }
    });
  }

  void _onScroll() {
    if (scrollController.offset > 50 && isHeaderVisible.value) {
      toggleAppBarAndBottomNav(false);
    } else if (scrollController.offset <= 50 && !isHeaderVisible.value) {
      toggleAppBarAndBottomNav(true);
    }
  }

  void toggleAppBarAndBottomNav(bool visible) {
    if (isHeaderVisible.value != visible) {
      isHeaderVisible.value = visible;
      // Notify parent about visibility change
      Get.find<StoreScreenController>()
          .onHeaderVisibilityChanged
          ?.call(visible);
    }
  }

  // Callback for header visibility changes
  Function(bool isVisible)? onHeaderVisibilityChanged;

  // Methods for user interactions
  void onSearchChanged(String value) {
    searchText.value = value;
    // Add search logic here if needed
  }

  void onCategoryTap(int index) {
    // Handle category selection
    print('Category tapped: ${categories[index]['title']}');
  }

  void onStoreTap(int index) {
    // Handle store selection
    print('Store tapped: ${stores[index]['name']}');
  }

  void onSeeAllCategories() {
    // Navigate to all categories screen
    print('See all categories tapped');
  }

  void onSeeAllStores() {
    // Navigate to all stores screen
    print('See all stores tapped');
  }

  void onNotificationTap() {
    // Handle notification tap
    print('Notification tapped');
  }

  void onCartTap() {
    // Handle cart tap
    print('Cart tapped');
  }
}

import 'dart:convert';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/food/model/children_of_grocery_category_response.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/model/grocery_product_model.dart';
import 'package:BlueEra/features/common/food/model/my_grocery_products_reponse.dart';
import 'package:BlueEra/features/common/food/model/my_grocery_super_category_model.dart';
import 'package:BlueEra/features/common/food/repo/grocery_repo.dart';
import 'package:BlueEra/features/common/food/view/grocery/edit_grocery_varient_dialog.dart';
import 'package:BlueEra/features/common/food/view/grocery/grocery_varient_dialog.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PriceResult {
  final String sellingRange;
  final String mrpRange;
  final String discountRange;

  PriceResult({
    required this.sellingRange,
    required this.mrpRange,
    required this.discountRange,
  });
}

class GroceryController extends GetxController {
  Rx<ApiResponse> groceryCategoryResponse =
    ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> groceryCategoryOfChildrenResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createNewGroceryProductNewVariantResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> addGroceryProductVariantResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchMyGroceryProductsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> fetchMyGroceryCategoryResponse =
      ApiResponse.initial('Initial').obs;

  Rx<CollapsibleGridModel> selectedGroceryData = CollapsibleGridModel(
      icon: "chips.png",
      label: "Chips &\nNamkeens",
      tagId: CHIPS_NAMKEEN
  ).obs;

  RxList<GroceryProductData> selectedGroceries = <GroceryProductData>[].obs;

  RxInt selectedTabIndex = 0.obs;
  String get currentTabKey =>
      selectedTabIndex.value == 0                    // “All” tab
          ? selectedGroceryData.value.tagId                    // top-level key
          : arrChildrenOfGroceryCategory[selectedTabIndex.value - 1].key ?? '';

  int maxLimit = 10;

  bool get isMaxLimitHit => selectedGroceries.length == maxLimit;

  Map<String, List<VariantsData>> selectedProductVariants = {};


  // BAKERY_BREAD_ITEMS
  final List<CollapsibleGridModel> bakery = [
    CollapsibleGridModel(
        icon: "freshfruits.png",
        label: "Puffs",
        tagId: FRESH_FRUITS),
    CollapsibleGridModel(
        icon: "basicveg.png",
        label: "Patties",
        tagId: BASIC_VEGETABLES),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Sandwiches",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Croissants",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Garlic Bread",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Rolls / Wraps",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Mini Pizzas",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Cheese Sticks",
        tagId: PREMIUM_FV),
  ];
  final List<CollapsibleGridModel> bread = [
    CollapsibleGridModel(
        icon: "freshfruits.png",
        label: "White Bread",
        tagId: FRESH_FRUITS),
    CollapsibleGridModel(
        icon: "basicveg.png",
        label: "Brown Bread",
        tagId: BASIC_VEGETABLES),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Multigrain Bread",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Milk Bread",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Sandwich Bread",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Garlic Bread Loaf",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Buns & Pav",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Artisan Bread",
        tagId: PREMIUM_FV),

  ];
  final List<CollapsibleGridModel> cakesNdMuffins = [
    CollapsibleGridModel(
        icon: "freshfruits.png",
        label: "Cupcakes",
        tagId: FRESH_FRUITS),
    CollapsibleGridModel(
        icon: "basicveg.png",
        label: "Muffins",
        tagId: BASIC_VEGETABLES),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Slice Cakes",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Pastries",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Pound Cake",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Plum Cake",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Mini Cakes",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Celebration Cake",
        tagId: PREMIUM_FV),
  ];
  final List<CollapsibleGridModel> cookiesNdBiscuit = [
    CollapsibleGridModel(
        icon: "freshfruits.png",
        label: "Butter Cookies",
        tagId: FRESH_FRUITS),
    CollapsibleGridModel(
        icon: "basicveg.png",
        label: "Choco Chip\nCookies",
        tagId: BASIC_VEGETABLES),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Oats Cookies",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Shortbread",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Jeera Biscuits",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Digestive Cookies",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Dry Cake Rusks",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Assorted Cookies",
        tagId: PREMIUM_FV),
  ];
  final List<CollapsibleGridModel> desertSweets = [
    CollapsibleGridModel(
        icon: "freshfruits.png",
        label: "Donuts",
        tagId: FRESH_FRUITS),
    CollapsibleGridModel(
        icon: "basicveg.png",
        label: "Brownies",
        tagId: BASIC_VEGETABLES),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Cheesecake Slices",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Tarts",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Tarts",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Eclairs",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Puddings",
        tagId: PREMIUM_FV),
    CollapsibleGridModel(
        icon: "premiumveg.png",
        label: "Dessert Jars",
        tagId: PREMIUM_FV),
  ];

  // DAIRY_PRODUCTS
  final List<CollapsibleGridModel> milkProduct = [
    CollapsibleGridModel(
        icon: "milk.png",
        label: "Milk & Milk\nProducts",
        tagId: MILK_PRODUCTS),
    CollapsibleGridModel(
        icon: "paneer.png",
        label: "Cheese,\nPaneer & Tofu",
        tagId: CHEESE_PANEER_TOFU),
    CollapsibleGridModel(
        icon: "batter.png",
        label: "Batter\n& Chutney",
        tagId: BUTTER_CHUTNEY),
    CollapsibleGridModel(
        icon: "toast.png",
        label: "Toast\n& Khari",
        tagId: TOAST_KHARI),
    CollapsibleGridModel(
        icon: "cakes.png",
        label: "Cakes &\nMuffins",
        tagId: CAKES_MUFFINS),
    CollapsibleGridModel(
        icon: "breads.png",
        label: "Breads\n& Chapatis",
        tagId: BREADS_CHAPATIS),
    CollapsibleGridModel(
        icon: "bakery_snacks_items.png",
        label: "Bakery\n& Snacks",
        tagId: BAKERY_SNACKS),
  ];
  final List<CollapsibleGridModel> curdNdYogurt = [
    CollapsibleGridModel(
        icon: "milk.png",
        label: "Milk & Milk\nProducts",
        tagId: MILK_PRODUCTS),
    CollapsibleGridModel(
        icon: "paneer.png",
        label: "Cheese,\nPaneer & Tofu",
        tagId: CHEESE_PANEER_TOFU),
    CollapsibleGridModel(
        icon: "batter.png",
        label: "Batter\n& Chutney",
        tagId: BUTTER_CHUTNEY),
    CollapsibleGridModel(
        icon: "toast.png",
        label: "Toast\n& Khari",
        tagId: TOAST_KHARI),
    CollapsibleGridModel(
        icon: "cakes.png",
        label: "Cakes &\nMuffins",
        tagId: CAKES_MUFFINS),
    CollapsibleGridModel(
        icon: "breads.png",
        label: "Breads\n& Chapatis",
        tagId: BREADS_CHAPATIS),
    CollapsibleGridModel(
        icon: "bakery_snacks_items.png",
        label: "Bakery\n& Snacks",
        tagId: BAKERY_SNACKS),
  ];
  final List<CollapsibleGridModel> cheeseNdPaneer = [
    CollapsibleGridModel(
        icon: "milk.png",
        label: "Milk & Milk\nProducts",
        tagId: MILK_PRODUCTS),
    CollapsibleGridModel(
        icon: "paneer.png",
        label: "Cheese,\nPaneer & Tofu",
        tagId: CHEESE_PANEER_TOFU),
    CollapsibleGridModel(
        icon: "batter.png",
        label: "Batter\n& Chutney",
        tagId: BUTTER_CHUTNEY),
    CollapsibleGridModel(
        icon: "toast.png",
        label: "Toast\n& Khari",
        tagId: TOAST_KHARI),
    CollapsibleGridModel(
        icon: "cakes.png",
        label: "Cakes &\nMuffins",
        tagId: CAKES_MUFFINS),
    CollapsibleGridModel(
        icon: "breads.png",
        label: "Breads\n& Chapatis",
        tagId: BREADS_CHAPATIS),
    CollapsibleGridModel(
        icon: "bakery_snacks_items.png",
        label: "Bakery\n& Snacks",
        tagId: BAKERY_SNACKS),
  ];
  final List<CollapsibleGridModel> butterNdGhee = [
    CollapsibleGridModel(
        icon: "milk.png",
        label: "Milk & Milk\nProducts",
        tagId: MILK_PRODUCTS),
    CollapsibleGridModel(
        icon: "paneer.png",
        label: "Cheese,\nPaneer & Tofu",
        tagId: CHEESE_PANEER_TOFU),
    CollapsibleGridModel(
        icon: "batter.png",
        label: "Batter\n& Chutney",
        tagId: BUTTER_CHUTNEY),
    CollapsibleGridModel(
        icon: "toast.png",
        label: "Toast\n& Khari",
        tagId: TOAST_KHARI),
    CollapsibleGridModel(
        icon: "cakes.png",
        label: "Cakes &\nMuffins",
        tagId: CAKES_MUFFINS),
    CollapsibleGridModel(
        icon: "breads.png",
        label: "Breads\n& Chapatis",
        tagId: BREADS_CHAPATIS),
    CollapsibleGridModel(
        icon: "bakery_snacks_items.png",
        label: "Bakery\n& Snacks",
        tagId: BAKERY_SNACKS),
  ];
  final List<CollapsibleGridModel> iceCreamNdFrozen = [
    CollapsibleGridModel(
        icon: "milk.png",
        label: "Milk & Milk\nProducts",
        tagId: MILK_PRODUCTS),
    CollapsibleGridModel(
        icon: "paneer.png",
        label: "Cheese,\nPaneer & Tofu",
        tagId: CHEESE_PANEER_TOFU),
    CollapsibleGridModel(
        icon: "batter.png",
        label: "Batter\n& Chutney",
        tagId: BUTTER_CHUTNEY),
    CollapsibleGridModel(
        icon: "toast.png",
        label: "Toast\n& Khari",
        tagId: TOAST_KHARI),
    CollapsibleGridModel(
        icon: "cakes.png",
        label: "Cakes &\nMuffins",
        tagId: CAKES_MUFFINS),
    CollapsibleGridModel(
        icon: "breads.png",
        label: "Breads\n& Chapatis",
        tagId: BREADS_CHAPATIS),
    CollapsibleGridModel(
        icon: "bakery_snacks_items.png",
        label: "Bakery\n& Snacks",
        tagId: BAKERY_SNACKS),
  ];

  // HOME_ESSENTIALS
  final List<CollapsibleGridModel> momBabyCare = [
    CollapsibleGridModel(
        icon: "food.png",
        label: "Food\n& Feeding",
        tagId: BABY_FOOD),
    CollapsibleGridModel(
        icon: "bath.png",
        label: "Bath, Hygiene\n& Grooming",
        tagId: BABY_HYGIENE),
    CollapsibleGridModel(
        icon: "bedding.png",
        label: "Bedding, Toys\n& Accessories",
        tagId: BABY_TOYS),
    CollapsibleGridModel(
        icon: "health.png",
        label: "Health\n& Wellness",
        tagId: BABY_HEALTH),
    CollapsibleGridModel(
        icon: "diapers.png",
        label: "Diapers\n& Wipes",
        tagId: DIAPERS_WIPES),
  ];
  final List<CollapsibleGridModel> kitchenware = [
    CollapsibleGridModel(
        icon: "gas.png",
        label: "Gas Stove",
        tagId: GAS_STOVE),
    CollapsibleGridModel(
        icon: "storage.png",
        label: "Containers &\nStorage",
        tagId: STORAGE_CONTAINERS),
    CollapsibleGridModel(
        icon: "flask.png",
        label: "Flask, Bottle\n& Tiffin Boxes",
        tagId: BOTTLES_FLASKS),
    CollapsibleGridModel(
        icon: "cutting.png",
        label: "Cutting\n& Chopping",
        tagId: CUTTING_CHOPPING),
    CollapsibleGridModel(
        icon: "tools.png",
        label: "Kitchen Tools",
        tagId: KITCHEN_TOOLS),
    CollapsibleGridModel(
        icon: "bakeware.png",
        label: "Bakeware",
        tagId: BAKEWARE),
  ];
  final List<CollapsibleGridModel> tableware = [
    CollapsibleGridModel(
        icon: "dining.png",
        label: "Dining",
        tagId: DINING),
    CollapsibleGridModel(
        icon: "serveware.png",
        label: "Serveware",
        tagId: SERVEWARE),
    CollapsibleGridModel(
        icon: "barware.png",
        label: "Barware",
        tagId: BARWARE),
    CollapsibleGridModel(
        icon: "tableacc.png",
        label: "Table Accessories",
        tagId: TABLE_ACCESSORIES),
    CollapsibleGridModel(
        icon: "mugs.png",
        label: "Cups, Mugs &\nMore",
        tagId: CUPS_MUGS),
    CollapsibleGridModel(
        icon: "drinkware.png",
        label: "Glassware &\nDrinkware",
        tagId: GLASSWARE),
  ];
  final List<CollapsibleGridModel> homeCare = [
    CollapsibleGridModel(
        icon: "detergents.png",
        label: "Detergents\n& Cleaners",
        tagId: DETERGENTS),
    CollapsibleGridModel(
        icon: "fresheners.png",
        label: "Fresheners\n& Repellents",
        tagId: FRESHENERS),
    CollapsibleGridModel(
        icon: "homecleaning.png",
        label: "Home &\nCleaning Tools",
        tagId: CLEANING_TOOLS),
    CollapsibleGridModel(
        icon: "furnishing.png",
        label: "Furnishing &\nPersonal Wear",
        tagId: FURNISHING),
    CollapsibleGridModel(
        icon: "dishwash.png",
        label: "Dishwash",
        tagId: DISHWASH),
    CollapsibleGridModel(
        icon: "pooja.png",
        label: "Pooja Needs",
        tagId: POOJA_NEEDS),
    CollapsibleGridModel(
        icon: "electricals.png",
        label: "Basic Electricals",
        tagId: ELECTRICALS),
    CollapsibleGridModel(
        icon: "shoecare.png",
        label: "Shoe Care",
        tagId: SHOE_CARE),
    CollapsibleGridModel(
        icon: "furniture.png",
        label: "Furniture",
        tagId: FURNITURE),
    CollapsibleGridModel(
        icon: "bags_luggage.png",
        label: "Bags &\nTravel Luggage",
        tagId: BAGS_TRAVEL),
  ];

  // PACKED_SWEETS_NAMKEENS
  final List<CollapsibleGridModel> indianSweets = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> milkBasedSweets = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> DryNdPremiumSweets = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> namkeens = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];

  // CROCKERY
  final List<CollapsibleGridModel> platesNdDinnerWare = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> bowsNdServiceWare = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> cupsNdGlassWare = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> servingNdTableAccessories = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];

  // MEDICAL_ITEMS
  final List<CollapsibleGridModel> firstAidCare = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> commonMedicines = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> healthNdHygieneEsse = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> digestiveNdWellnessProducts = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];

  // BEAUTY_BODY_CARE
  final List<CollapsibleGridModel> bathNdBodyCare = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> hairCare = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> oralNdPersonalHygiene = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> skinCareNdDailyBeauty = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];

  // STATIONARY
  final List<CollapsibleGridModel> writingEsse = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> paperProduct = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> schoolNdStudyEsse = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> officeNdDeskEsse = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];
  final List<CollapsibleGridModel> artNdCraft = [
    CollapsibleGridModel(
        icon: "tea.png",
        label: "Tea Gifts",
        tagId: TEA_GIFTS),
    CollapsibleGridModel(
        icon: "chocogift.png",
        label: "Chocolate Gifts",
        tagId: CHOCOLATE_GIFTS),
    CollapsibleGridModel(
        icon: "gourmet.png",
        label: "Gourmet Gifts",
        tagId: GOURMET_GIFTS),
  ];

  void toggleSelection(GroceryProductData p) {
    if (selectedGroceries.contains(p)) {
      selectedGroceries.remove(p);
    } else {
      if (selectedGroceries.length >= 10) {
        commonSnackBar(
            message: 'You can’t select more than 10 products at a time.');
        return;
      }
      selectedGroceries.add(p);
    }
  }

  void toggleVariant(String productId, VariantsData variant) {
    selectedProductVariants.putIfAbsent(productId, () => []);

    final selectedList = selectedProductVariants[productId]!;

    // Check if variant already exists (compare by sId)
    final exists = selectedList.any((v) => v.sId == variant.sId);

    if (exists) {
      // REMOVE variant
      selectedList.removeWhere((v) => v.sId == variant.sId);
    } else {
      // ADD variant
      selectedList.add(variant);
    }

    update(); // refresh UI
  }

  bool isVariantSelected(String productId, String variantId) {
    return selectedProductVariants[productId]?.any((v) => v.sId == variantId) ??
        false;
  }

  bool get canSubmitProducts {
    for (final p in selectedGroceries) {
      final variants = selectedProductVariants[p.sId];

      // If no entry OR empty variants list → invalid
      if (variants == null || variants.isEmpty) {
        return false;
      }
    }
    return true;
  }

  PriceResult getPriceDetails(List<Pricing>? v) {
    final pricingList = v;

    if (pricingList==null) {
      return PriceResult(
        sellingRange: "0",
        mrpRange: "0",
        discountRange: "0%",
      );
    }

    // Safely map → remove null → convert to double
    final sellingPrices = pricingList
        .map((e) => e.sellingPrice)
        .where((p) => p != null)
        .map((p) => p!.toDouble())
        .toList();

    final mrpPrices = pricingList
        .map((e) => e.mrp)
        .where((p) => p != null)
        .map((p) => p!.toDouble())
        .toList();

    if (sellingPrices.isEmpty || mrpPrices.isEmpty) {
      return PriceResult(
        sellingRange: "0",
        mrpRange: "0",
        discountRange: "0%",
      );
    }

    // Find MIN/MAX
    final minSelling = sellingPrices.reduce((a, b) => a < b ? a : b);
    final maxSelling = sellingPrices.reduce((a, b) => a > b ? a : b);

    final minMrp = mrpPrices.reduce((a, b) => a < b ? a : b);
    final maxMrp = mrpPrices.reduce((a, b) => a > b ? a : b);

    // Discount %
    double discount(num mrp, num selling) {
      if (mrp == 0) return 0;
      final d = ((mrp - selling) / mrp) * 100;
      return d < 0 ? 0 : d;
    }

    final minDiscount = discount(minMrp, minSelling);
    final maxDiscount = discount(maxMrp, maxSelling);

    // Format ranges
    final sellingRange = minSelling == maxSelling
        ? "₹$minSelling"
        : "₹$minSelling - ₹$maxSelling";

    final mrpRange = minMrp == maxMrp ? "₹$minMrp" : "₹$minMrp - ₹$maxMrp";

    final discountRange = minDiscount == maxDiscount
        ? "${minDiscount.toStringAsFixed(0)}% ${AppStrings.offCaps.tr}"
        : "${minDiscount.toStringAsFixed(0)}% - ${maxDiscount.toStringAsFixed(0)}% ${AppStrings.offCaps.tr}";

    return PriceResult(
      sellingRange: sellingRange,
      mrpRange: mrpRange,
      discountRange: discountRange,
    );
  }

  void openEditVariantDialog({
    required BuildContext context,
    required String title,
    required VariantsData variant,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return EditGroceryVarientDialog(
          title: title,
          mrp: variant.pricing?[0].mrp?.toString() ?? "",
          selling: variant.pricing?[0].sellingPrice?.toString() ?? "",
          onSubmit: (mrp, sellingPrice) {
            variant.pricing?[0].mrp = int.tryParse(mrp);
            variant.pricing?[0].sellingPrice = int.tryParse(sellingPrice);
            update();
            Get.back();
          },
        );
      },
    );
  }

  void openAddVariantDialog({
    required BuildContext context,
    required GroceryProductData groceryItem,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isCreateNewGroceryProductNewVariantLoading.value,
      builder: (_) {
        return GroceryVariantDialog(
          title: "Add More Variant",
          onSubmit: (weight, unit, mrp, sellingPrice) {
            createNewGroceryProductNewVariant(
                groceryItem: groceryItem,
                productId: groceryItem.sId ?? '',
                weight: weight,
                unit: unit,
                mrp: mrp,
                sellingPrice: sellingPrice);
          },
          isAddGroceryProductNewVariantLoading: isCreateNewGroceryProductNewVariantLoading.value,
        );
      },
    );
  }

  RxBool isInitialLoading = false.obs;

  Future<void> fetchBoth() async {
    try {
      isInitialLoading.value = true;
      await Future.wait([
        fetchChildrenOfGroceryCategory(),
        fetchGroceryCategoryProducts(),
      ]);
     } catch (e) {
    } finally {
      isInitialLoading.value = false;
    }
  }

  RxBool isGroceryCategoryOfChildrenLoading = false.obs;
  RxList<ChildrenOfGroceryCategoryResponse> arrChildrenOfGroceryCategory =
      <ChildrenOfGroceryCategoryResponse>[].obs;

  Future<void> fetchChildrenOfGroceryCategory() async {
    try {

      isGroceryCategoryOfChildrenLoading.value = true;
      final response =
      await GroceryRepo().groceryCategoryOfChildrenRepo(key: currentTabKey);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      arrChildrenOfGroceryCategory.value =
          ChildrenOfGroceryCategoryResponse.fromJsonList(jsonData);
      groceryCategoryOfChildrenResponse.value = ApiResponse.complete(response);
      update();
    } catch (e) {
      groceryCategoryOfChildrenResponse.value = ApiResponse.error('error');
      update();
    } finally {
      isGroceryCategoryOfChildrenLoading.value = false;
    }
  }

  RxBool isGroceryCategoryProductsLoading = false.obs;
  RxList<GroceryProductData> arrGroceryCategoryProducts = <GroceryProductData>[].obs;
  RxBool isGroceryCategoryProductsLoadingMore = false.obs;
  int groceryCategoryProductsPage = 1;
  bool groceryCategoryProductsHasMore = true;

  Future<void> fetchGroceryCategoryProducts({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        // if (isGroceryCategoryProductsLoadingMore.value || !groceryCategoryProductsHasMore) return;
        isGroceryCategoryProductsLoadingMore.value = true;
      } else {
        arrGroceryCategoryProducts.clear();
        isGroceryCategoryProductsLoading.value = true;
        groceryCategoryProductsPage = 1;
        groceryCategoryProductsHasMore = true;
      }

      // log('current tab key-- $currentTabKey');
      Map<String, dynamic> queryParams = {
        ApiKeys.key: currentTabKey,
        ApiKeys.page: groceryCategoryProductsPage,
        ApiKeys.limit: pageLimit
      };

      final response = await GroceryRepo()
          .searchGroceryCategoryRepo(queryParam: queryParams);

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      groceryCategoryResponse.value = ApiResponse.complete(response);

      final groceryProductModel = GroceryProductModel.fromJson(response.response?.data);
      List<GroceryProductData> newItems = groceryProductModel.data ?? [];

      if (newItems.isNotEmpty) {
          if (isLoadMore) {
            arrGroceryCategoryProducts.addAll(newItems);
          } else {
            arrGroceryCategoryProducts.assignAll(newItems);
          }

          groceryCategoryProductsPage++;
      } else {
        groceryCategoryProductsHasMore = false;
      }

      log('total grocery-- ${arrGroceryCategoryProducts.length}');
      update();
    } catch (e, s) {
      groceryCategoryResponse.value = ApiResponse.error('error');
      log('stack trace-- $s');
    } finally {
      if (isLoadMore) {
        isGroceryCategoryProductsLoadingMore.value = false;
      } else {
        isGroceryCategoryProductsLoading.value = false;
      }
    }
  }

  RxBool isCreateNewGroceryProductNewVariantLoading = false.obs;
  Future<void> createNewGroceryProductNewVariant(
      {required GroceryProductData groceryItem,
      required String productId,
      required String weight,
      required String unit,
      required String mrp,
      required String sellingPrice}) async {
    try {
      isCreateNewGroceryProductNewVariantLoading.value = true;
      Map<String, dynamic> data = {
        ApiKeys.variantData: jsonEncode({
          ApiKeys.weight: int.parse(weight),
          ApiKeys.unit: unit,
          ApiKeys.pricing: [
            {
              ApiKeys.mrp: int.tryParse(mrp),
              ApiKeys.sellingPrice: int.tryParse(sellingPrice),
            }
          ]
        })
      };

      final response = await GroceryRepo().createNewGroceryProductVariantRepo(
        productId: productId,
        params: data,
      );

      if (!response.isSuccess) {
        createNewGroceryProductNewVariantResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      createNewGroceryProductNewVariantResponse.value = ApiResponse.complete(response);
      final jsonData = response.response?.data;
      log('id-- > ${jsonData['_id']}');
      final newVariant = VariantsData(
        weight: int.tryParse(weight),
        sId: jsonData['_id'],
        product: productId,
        unit: unit,
        variantName: "${weight}${unit}",
        pricing: [
          Pricing(
            mrp: int.tryParse(mrp),
            sellingPrice: int.tryParse(sellingPrice),
          )
        ],
        images: [],
        sku: null,
        barcode: null,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
        iV: 0,
      );

      groceryItem.variants?.insert(
        groceryItem.variants!.length,
        newVariant,
      );
      update();
      Get.back();
    } catch (e) {
      createNewGroceryProductNewVariantResponse.value = ApiResponse.error('error');
    } finally {
      isCreateNewGroceryProductNewVariantLoading.value = false;
    }
  }

  RxBool isAddGroceryProductsLoading = false.obs;
  Future<void> addGroceryProductNewVariant() async {
    try {
      isAddGroceryProductsLoading.value = true;

      final payload = buildInventoryPayload();

      print(jsonEncode(payload));

      final response = await GroceryRepo().addGroceryProductVariantRepo(
        params: payload,
      );

      if (!response.isSuccess) {
        addGroceryProductVariantResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      addGroceryProductVariantResponse.value = ApiResponse.complete(response);
      // final jsonData = response.response?.data;

      Get.until((route) =>
                  route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
      commonSnackBar(
        message: response.message ?? AppStrings.somethingWentWrong,
      );
      log('success-- ${response.isSuccess}');
    } catch (e) {
      addGroceryProductVariantResponse.value = ApiResponse.error('error');
    } finally {
      isAddGroceryProductsLoading.value = false;
    }
  }

  List<Map<String, dynamic>> buildInventoryPayload() {
    List<Map<String, dynamic>> payload = [];

    String city = LocationService.userCurrentAddress[2];
    String postalCode = LocationService.currentPostCode;

    selectedProductVariants.forEach((productId, variants) {
      for (final variant in variants) {
        payload.add({
          "productVariant": variant.sId ?? "",
          "pincode": postalCode,
          "cityName": city,

          "batches": [
            {
              "quantity": variant.weight,
              "mrp": variant.pricing?[0].mrp,
              "sellingPrice": variant.pricing?[0].sellingPrice,
            }
          ],
        });
      }
    });

    return payload;
  }

  /// Fetch Grocery Products
  RxBool myGroceryCategoryLoading = true.obs;
  RxList<MyGrocerySuperCategoryModel> myGroceryCategoryList = <MyGrocerySuperCategoryModel>[].obs;

  Future<void> fetchMyGroceryCategory() async {
    try {
      myGroceryCategoryLoading.value = true;
      ResponseModel responseModel = await GroceryRepo().fetchGroceryCategoryRepo();
      if (responseModel.isSuccess) {
        fetchMyGroceryCategoryResponse.value = ApiResponse.complete(responseModel);
        final List listData = responseModel.response?.data ?? [];

        myGroceryCategoryList.value = listData
            .map((e) => MyGrocerySuperCategoryModel.fromJson(e))
            .toList();

        log("Loaded ${myGroceryCategoryList.length}");
      } else {
        fetchMyGroceryCategoryResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      fetchMyGroceryCategoryResponse.value = ApiResponse.error('error');
      log("ERROR===== $e");
    } finally{
      myGroceryCategoryLoading.value = false;
    }
  }


  /// Fetch Grocery Products
  RxList<MyGroceryProductsData> myGroceryProductsList = <MyGroceryProductsData>[].obs;
  RxList<Variants> myGroceryProductsVariantsList = <Variants>[].obs;
  RxBool isMyGroceryDataFirstLoading = false.obs;
  RxBool isMyGroceryDataLoadingMore = false.obs;
  int myGroceryDataPage = 1;
  bool myGroceryDataHasMore = true;
  int pageLimit = 20;

  Future<void> fetchMyGroceryProducts({
    required String categoryId,
    required bool isSubCategoryProducts,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      if (isMyGroceryDataLoadingMore.value || !myGroceryDataHasMore) return;
      isMyGroceryDataLoadingMore.value = true;
    } else {
      isMyGroceryDataFirstLoading.value = true;
      myGroceryDataPage = 1;
      myGroceryDataHasMore = true;
    }

    try {
      Map<String, dynamic> params = {
        ApiKeys.page: myGroceryDataPage,
        ApiKeys.limit: pageLimit,
        ApiKeys.categoryId: categoryId
      };

      ResponseModel responseModel = await GroceryRepo().fetchMyGroceryProductsRepo(queryParam: params);
      if (responseModel.isSuccess) {
        fetchMyGroceryProductsResponse.value = ApiResponse.complete(responseModel);
        final data = responseModel.response?.data;
        MyGroceryProductsModel myGroceryProductsModel = MyGroceryProductsModel.fromJson(data);
        List<MyGroceryProductsData> newItems = myGroceryProductsModel.data ?? [];

        if (newItems.isNotEmpty) {
          if(!isSubCategoryProducts){
            if (isLoadMore) {
              myGroceryProductsList.addAll(newItems);
            } else {
              myGroceryProductsList.clear();
              myGroceryProductsList.assignAll(newItems);
            }
          }else{
            extractAllVariantsFromResponse(
                newItems,
                isLoadMore: isLoadMore,
            );
          }


          myGroceryDataPage++;
        } else {
          myGroceryDataHasMore = false;
        }

        log("Loaded ${newItems.length} items | Total: ${(!isSubCategoryProducts)
            ? myGroceryProductsList.length
        : myGroceryProductsVariantsList.length}");
      } else {
        fetchMyGroceryProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      fetchMyGroceryProductsResponse.value = ApiResponse.error('error');
      log("ERROR===== $e");
    } finally{
      if (isLoadMore) {
        isMyGroceryDataLoadingMore.value = false;
      } else {
        isMyGroceryDataFirstLoading.value = false;
      }
    }
  }

  void extractAllVariantsFromResponse(
      List<MyGroceryProductsData> groceryProductData,
      {bool isLoadMore = false}
      ) {
    if (!isLoadMore) {
      myGroceryProductsVariantsList.clear();
    }

    for (final data in groceryProductData) {
      final category = data.category;
      if (category == null) continue;

      final products = category.products ?? [];
      for (final product in products) {
        final variants = product.variants ?? [];
        myGroceryProductsVariantsList.addAll(variants);
      }
    }
  }



}

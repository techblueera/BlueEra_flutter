import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/food/model/children_of_grocery_category_response.dart';
import 'package:BlueEra/features/common/food/model/grocery_category_model.dart';
import 'package:BlueEra/features/common/food/model/grocery_product_model.dart';
import 'package:BlueEra/features/common/food/repo/grocery_repo.dart';
import 'package:BlueEra/features/common/food/view/grocery/grocery_subcategory_screen.dart';
import 'package:get/get.dart';

class GroceryController extends GetxController {
  ApiResponse groceryCategoryResponse = ApiResponse.initial('Initial');

  RxString selectedGrocery = ''.obs;

  RxList<GroceryProductData> selectedGroceries = <GroceryProductData>[].obs;

  RxInt selectedTabIndex = 0.obs;
  int maxLimit = 10;

  int? selectedDay, selectedMonth, selectedYear;
  
  /// Main Grocery Categories
  final List<GroceryCategoryModel> biscuitFoods = [
    GroceryCategoryModel(icon: "chips.png", label: "Chips &\nNamkeens", tagId: CHIPS_NAMKEEN),
    GroceryCategoryModel(icon: "biscuits.png", label: "Biscuits\n& Cookies", tagId: BISCUITS_COOKIES),
    GroceryCategoryModel(icon: "chocolate.png", label: "Chocolates\n& Candies", tagId: CHOCOLATES_CANDIES),
    GroceryCategoryModel(icon: "indiansweets.png", label: "Indian\nSweets", tagId: INDIAN_SWEETS),
    GroceryCategoryModel(icon: "drinks.png", label: "Drinks\n& Juices", tagId: DRINKS_JUICES),
    GroceryCategoryModel(icon: "cereals.png", label: "Breakfast\nCereals", tagId: BREAKFAST_CEREALS),
    GroceryCategoryModel(icon: "noodles.png", label: "Noodles, Pasta\n& Vermicelli", tagId: NOODLES_PASTA),
    GroceryCategoryModel(icon: "readytoeat.png", label: "Ready To\nCook & Eat", tagId: READY_TO_COOK),
    GroceryCategoryModel(icon: "ketup_Tomato_Sauce.png", label: "Spread, Sauces\n& Ketchup", tagId: SPREAD),
    GroceryCategoryModel(icon: "pickles_chutney.png", label: "Pickles, Chutney\n& Flavouring", tagId: PICKLES),
    GroceryCategoryModel(icon: "tea_and_coffee.png", label: "Tea & Coffee", tagId: TEA),
  ];

  final List<GroceryCategoryModel> fruitsVeg = [
    GroceryCategoryModel(icon: "freshfruits.png", label: "Fresh Fruits", tagId: FRESH_FRUITS),
    GroceryCategoryModel(icon: "basicveg.png", label: "Basic\nVegetables", tagId: BASIC_VEGETABLES),
    GroceryCategoryModel(icon: "premiumveg.png", label: "Premium Fruits\n& Vegetables", tagId: PREMIUM_FV),
  ];

  final List<GroceryCategoryModel> cookingEssentials = [
    GroceryCategoryModel(icon: "rice.png", label: "Rice", tagId: RICE),
    GroceryCategoryModel(icon: "dals.png", label: "Dals & Pulses", tagId: DALS_PULSES),
    GroceryCategoryModel(icon: "ghee.png", label: "Ghee", tagId: GHEE),
    GroceryCategoryModel(icon: "wheat.png", label: "Wheat & Soya", tagId: WHEAT_SOYA),
    GroceryCategoryModel(icon: "sugar.png", label: "Salt, Sugar\n& Jaggery", tagId: SALT_SUGAR_JAGGERY),
    GroceryCategoryModel(icon: "poha.png", label: "Sabudana, Poha\n& Murmura", tagId: SNACK_BASES),
    GroceryCategoryModel(icon: "atta.png", label: "Atta, Flours\n& Sooji", tagId: ATTA_FLOURS),
    GroceryCategoryModel(icon: "dryfruits.png", label: "Dry Fruits\n& Nuts", tagId: DRY_FRUITS),
    GroceryCategoryModel(icon: "millets_and_organic.png", label: "Edible Oils", tagId: EDIBLE_OILS),
    GroceryCategoryModel(icon: "edible_oil.png", label: "Millets\n& Organic", tagId: MILLET_ORGANIC),
  ];

  final List<GroceryCategoryModel> dairyBakery = [
    GroceryCategoryModel(icon: "milk.png", label: "Milk & Milk\nProducts", tagId: MILK_PRODUCTS),
    GroceryCategoryModel(icon: "paneer.png", label: "Cheese,\nPaneer & Tofu", tagId: CHEESE_PANEER_TOFU),
    GroceryCategoryModel(icon: "batter.png", label: "Batter\n& Chutney", tagId: BUTTER_CHUTNEY),
    GroceryCategoryModel(icon: "tasto.png", label: "Toast\n& Khari", tagId: TOAST_KHARI),
    GroceryCategoryModel(icon: "cakes.png", label: "Cakes &\nMuffins", tagId: CAKES_MUFFINS),
    GroceryCategoryModel(icon: "breads.png", label: "Breads\n& Chapatis", tagId: BREADS_CHAPATIS),
    GroceryCategoryModel(icon: "snacks.png", label: "Bakery\n& Snacks", tagId: BAKERY_SNACKS),
  ];

  final List<GroceryCategoryModel> momBabyCare = [
    GroceryCategoryModel(icon: "food.png", label: "Food\n& Feeding", tagId: BABY_FOOD),
    GroceryCategoryModel(icon: "bath.png", label: "Bath, Hygiene\n& Grooming", tagId: BABY_HYGIENE),
    GroceryCategoryModel(icon: "bedding.png", label: "Bedding, Toys\n& Accessories", tagId: BABY_TOYS),
    GroceryCategoryModel(icon: "health.png", label: "Health\n& Wellness", tagId: BABY_HEALTH),
    GroceryCategoryModel(icon: "diapers.png", label: "Diapers\n& Wipes", tagId: DIAPERS_WIPES),
  ];

  final List<GroceryCategoryModel> kitchenware = [
    GroceryCategoryModel(icon: "gas.png", label: "Gas Stove", tagId: GAS_STOVE),
    GroceryCategoryModel(icon: "storage.png", label: "Containers &\nStorage", tagId: STORAGE_CONTAINERS),
    GroceryCategoryModel(icon: "flask.png", label: "Flask, Bottle\n& Tiffin Boxes", tagId: BOTTLES_FLASKS),
    GroceryCategoryModel(icon: "cutting.png", label: "Cutting\n& Chopping", tagId: CUTTING_CHOPPING),
    GroceryCategoryModel(icon: "tools.png", label: "Kitchen Tools", tagId: KITCHEN_TOOLS),
    GroceryCategoryModel(icon: "bakeware.png", label: "Bakeware", tagId: BAKEWARE),
  ];

  final List<GroceryCategoryModel> tableware = [
    GroceryCategoryModel(icon: "dining.png", label: "Dining", tagId: DINING),
    GroceryCategoryModel(icon: "serveware.png", label: "Serveware", tagId: SERVEWARE),
    GroceryCategoryModel(icon: "barware.png", label: "Barware", tagId: BARWARE),
    GroceryCategoryModel(icon: "tableacc.png", label: "Table Accessories", tagId: TABLE_ACCESSORIES),
    GroceryCategoryModel(icon: "mugs.png", label: "Cups, Mugs &\nMore", tagId: CUPS_MUGS),
    GroceryCategoryModel(icon: "drinkware.png", label: "Glassware &\nDrinkware", tagId: GLASSWARE),
  ];

  final List<GroceryCategoryModel> giftsHampers = [
    GroceryCategoryModel(icon: "tea.png", label: "Tea Gifts", tagId: TEA_GIFTS),
    GroceryCategoryModel(icon: "chocogift.png", label: "Chocolate Gifts", tagId: CHOCOLATE_GIFTS),
    GroceryCategoryModel(icon: "gourmet.png", label: "Gourmet Gifts", tagId: GOURMET_GIFTS),
  ];

  final List<GroceryCategoryModel> homeCategory = [
    GroceryCategoryModel(icon: "detergents.png", label: "Detergents\n& Cleaners", tagId: DETERGENTS),
    GroceryCategoryModel(icon: "fresheners.png", label: "Fresheners\n& Repellents", tagId: FRESHENERS),
    GroceryCategoryModel(icon: "homecleaning.png", label: "Home &\nCleaning Tools", tagId: CLEANING_TOOLS),
    GroceryCategoryModel(icon: "furnishing.png", label: "Furnishing &\nPersonal Wear", tagId: FURNISHING),
    GroceryCategoryModel(icon: "dishwash.png", label: "Dishwash", tagId: DISHWASH),
    GroceryCategoryModel(icon: "pooja.png", label: "Pooja Needs", tagId: POOJA_NEEDS),
    GroceryCategoryModel(icon: "electricals.png", label: "Basic Electricals", tagId: ELECTRICALS),
    GroceryCategoryModel(icon: "shoecare.png", label: "Shoe Care", tagId: SHOE_CARE),
    GroceryCategoryModel(icon: "furniture.png", label: "Furniture", tagId: FURNITURE),
    GroceryCategoryModel(icon: "bags_luggage.png", label: "Bags &\nTravel Luggage", tagId: BAGS_TRAVEL),
  ];


  /// TABS FOR EACH CATEGORY
  Map<String, List<String>> categoryTabs = {
    "Rice": [
      "All",
      "Basmati Rice",
      "Boiled Rice",
      "Idli Rice",
      "Raw Rice",
      "Kolam Rice",
      "Organic Rice"
    ],
    "Dals & Pulses": ["All", "Moong Dal", "Toor Dal", "Chana Dal", "Urad Dal"],
    "Ghee": ["All", "Cow Ghee", "Organic Ghee"],
    "Wheat & Soya": [
      "All",
      "Sharbati Sihore Wheat",
      "Soya Products",
      "Soyabean",
      "Whole Wheat",
    ],
    "Salt, Sugar": ["All","Jaggery", "Salt", "Sugar"],
    "Sabudana, Poha & Murmura": ["All", "Sabudana", "poha", "Murmura"],
    "Atta & Flour": [
      "All",
      "Atta",
      "Poha",
      "Besan",
      "Daliya",
      "Idli Rava",
      "Maida",
      "Other Atta",
      "Ragi Flour",
      "Rawa/Sooji",
      "Rice Atta",
      "Speciality Flour",
    ],
    "Dry Fruits & Nuts": [
      "All",
      "Almonds / Badam",
      "Anjeer / Dried Figs",
      "Apricots",
      "Cashews/Kaaju",
      "Chironji",
      "Dates",
      "Dried Seeds",
      "Dry Coconut",
      "Dry Dates",
      "Dry Fruits Gift Pack",
      "Makhana",
      "Mixed Dry Fruits",
      "Other Nuts",
      "Pistachios",
      "Raisins/Kishmish",
      "Walnuts/Akhrot",
    ],
    "Edible Oils": [
      "All",
      "Blended Oil",
      "Canola Oil",
      "Castor Oil",
      "Coconut Oil",
      "Combo Offer",
      "Cottonseed Oil",
      "Gingelly/Til/Sesame Oil",
      "Groundnut Oil",
      "Mustard Oil",
      "Olive Oil",
      "Others Oils",
      "Palm Oil",
      "Rice Bran Oil",
      "Soyabean Oil",
      "Sunflower Oil",
      "Vanaspati",
    ],
    "Millets & Organic": [
      "All",
      "Bajra",
      "Barley",
      "Cereal",
      "Jowar",
      "Millets",
      "Quinoa",
      "Ragi",
    ],


  };

  List<String> leftIcons = [
    "assets/category/rice.png",
    "assets/category/dals.png",
    "assets/category/ghee.png",
    "assets/category/wheat.png",
    "assets/category/sugar.png",
    "assets/category/poha.png",
    "assets/category/atta.png",
    "assets/category/dryfruits.png",
    "assets/category/dal/oil.png",
    "assets/category/dal/millet.png",
  ];

  void toggleSelection(GroceryProductData p) {
      if (selectedGroceries.contains(p)) {
        selectedGroceries.remove(p);
      } else {
        if (selectedGroceries.length >= 10) {
            commonSnackBar(message: 'You can’t select more than 10 products at a time.');
          return;
        }
        selectedGroceries.add(p);
      }
  }

  bool get isMaxLimitHit =>
      selectedGroceries.length == maxLimit;


  RxBool isInitialLoading = false.obs;
  Future<void> fetchBoth(String key) async {
    try{
      isInitialLoading.value = true;
      await Future.wait([
        fetchChildrenOfGroceryCategory(key: key),
        fetchGroceryCategories(key: key),
      ]);
    }catch(e){

    } finally{
      isInitialLoading.value = false;
    }
  }

  RxBool isGrocerySubCategoryLoading = false.obs;
  RxList<GroceryProductData> arrGroceryProducts = <GroceryProductData>[].obs;

  Future<void> fetchGroceryCategories({required String key}) async {
    try {
      isGrocerySubCategoryLoading.value = true;
      final response = await GroceryRepo().searchGroceryCategoryRepo(
          queryParam: {ApiKeys.key: key}
      );

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final groceryProductModel = GroceryProductModel.fromJson(response.response?.data) ;
      arrGroceryProducts.value = groceryProductModel.data ?? [];
      log('total grocery-- ${arrGroceryProducts.length}');
      groceryCategoryResponse = ApiResponse.complete(response);
      update();
    } catch (e, s) {
      groceryCategoryResponse = ApiResponse.error('error');
      log('stack trace-- $s');
    }finally{
      isGrocerySubCategoryLoading.value = false;
    }
  }

  RxBool isGroceryCategoryOfChildrenLoading = false.obs;
  RxList<ChildrenOfGroceryCategoryResponse> arrChildrenOfGroceryCategory = <ChildrenOfGroceryCategoryResponse>[].obs;
  Future<void> fetchChildrenOfGroceryCategory({required String key}) async {
    try {
      isGroceryCategoryOfChildrenLoading.value = true;
      final response = await GroceryRepo().groceryCategoryOfChildrenRepo(
        key: key
      );

      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
        return;
      }

      final jsonData = response.response?.data;
      arrChildrenOfGroceryCategory.value = ChildrenOfGroceryCategoryResponse.fromJsonList(jsonData);
      groceryCategoryResponse = ApiResponse.complete(response);
      update();
    } catch (e, s) {
      groceryCategoryResponse = ApiResponse.error('error');
      update();
    }finally{
      isGroceryCategoryOfChildrenLoading.value = false;
    }
  }

}
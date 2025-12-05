import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/food/view/grocery/cooking_esential_page.dart';
import 'package:get/get.dart';

class GroceryController extends GetxController {
  RxList<GroceryModel> selectedGroceries = <GroceryModel>[].obs;
  RxInt selectedIndex = 0.obs;
  RxInt selectedTabIndex = 0.obs;
  int maxLimit = 10;

  List<String> categories = [
    "Rice",
    "Dals & Pulses",
    "Ghee",
    "Wheat & Soya",
    "Salt, Sugar",
    "Sabudana, Poha & Murmura",
    "Atta & Flour",
    "Dry Fruits & Nuts",
    "Edible Oils",
    "Millets & Organic",
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

  /// PRODUCT LIST FOR EACH CATEGORY
  Map<String, List<GroceryModel>> categoryProducts = {
    "Rice": [
      GroceryModel(
          name: "Premium Basmati Rice",
          image: "assets/category/rice1.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      GroceryModel(
        name: "Boiled Rice Classic",
        image: "assets/category/rice2.png",
        weight: "5 KG",
        price: 230,
        oldPrice: 260,
        discount: "15%",
      ),
      GroceryModel(
          name: "Premium Basmati Rice",
          image: "assets/category/rice3.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      GroceryModel(
        name: "Boiled Rice Classic",
        image: "assets/category/rice2.png",
        weight: "5 KG",
        price: 230,
        oldPrice: 260,
        discount: "15%",
      ),
      GroceryModel(
          name: "Premium Basmati Rice",
          image: "assets/category/rice1.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      GroceryModel(
        name: "Boiled Rice Classic",
        image: "assets/category/rice2.png",
        weight: "5 KG",
        price: 230,
        oldPrice: 260,
        discount: "15%",
      ),
      GroceryModel(
          name: "Premium Basmati Rice",
          image: "assets/category/rice1.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      GroceryModel(
        name: "Boiled Rice Classic",
        image: "assets/category/rice2.png",
        weight: "5 KG",
        price: 230,
        oldPrice: 260,
        discount: "15%",
      ),
    ],
    "Dals & Pulses": [
      GroceryModel(
          name: "Chana Dal",
          image: "assets/category/dal/chana_dal.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Horse Gram",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Kabuli Chana",
          //  image: "assets/category/kabuli_chana.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Kala Chana",
          image: "assets/category/dal/chana_dal.png",

          //image: "assets/category/kala_chana.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Matar / Peas",
          // image: "assets/category/matar_peas.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Lobia",
          image: "assets/category/dal/chana_dal.png",

          // image: "assets/category/lobia.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Masoor Dal",
          //image: "assets/category/masoor_dal.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Matki / Moth Beans",
          image: "assets/category/dal/chana_dal.png",

          // image: "assets/category/matki_moth_beans.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Mixed Dal",
          // image: "assets/category/mixed_dal.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Moong Dal",
          image: "assets/category/dal/chana_dal.png",

          // image: "assets/category/moong_dal.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Other Pulses",
          // image: "assets/category/other_pulses.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Peanuts",
          image: "assets/category/dal/chana_dal.png",

          //  image: "assets/category/peanuts.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Rajma",
          // image: "assets/category/rajma.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Toor Dal",
          // image: "assets/category/toor_dal.png",
          image: "assets/category/dal/chana_dal.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Urad Dal",
          // image: "assets/category/urad_dal.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      GroceryModel(
          name: "Val Beans",
          image: "assets/category/dal/chana_dal.png",

          // image: "assets/category/val_beans.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
    ],
    "Ghee": [
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      GroceryModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
    ],
    "Wheat & Soya": [
      GroceryModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),GroceryModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),GroceryModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),GroceryModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),GroceryModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),GroceryModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),
    ],
    "Salt, Sugar": [
      GroceryModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),GroceryModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),GroceryModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),GroceryModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),GroceryModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),GroceryModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),
    ],
    "Sabudana, Poha & Murmura": [
      GroceryModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),GroceryModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),GroceryModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),GroceryModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),GroceryModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),GroceryModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),
    ],
    "Atta & Flour": [
      GroceryModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),GroceryModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),GroceryModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),GroceryModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),GroceryModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),GroceryModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),
    ],
    "Dry Fruits & Nuts": [
      GroceryModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"),GroceryModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"), GroceryModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"), GroceryModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"), GroceryModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"), GroceryModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"),
    ],
    "Edible Oils": [
      GroceryModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),

    ],
    "Millets & Organic": [
      GroceryModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),GroceryModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),

    ],
  };

  void toggleSelection(GroceryModel p) {
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

}
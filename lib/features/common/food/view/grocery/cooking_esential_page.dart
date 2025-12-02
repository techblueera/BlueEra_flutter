import 'package:flutter/material.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/local_assets.dart';
import '../../../../../widgets/common_back_app_bar.dart';

class ProductModel {
  final String name;
  final String image;
  final String weight;
  final int price;
  final int oldPrice;
  final String discount;

  ProductModel({
    required this.name,
    required this.image,
    required this.weight,
    required this.price,
    required this.oldPrice,
    required this.discount,
  });
}

class CookingEssentialsPage extends StatefulWidget {
  const CookingEssentialsPage({super.key});

  @override
  State<CookingEssentialsPage> createState() => _CookingEssentialsPageState();
}

class _CookingEssentialsPageState extends State<CookingEssentialsPage> {
  int selectedIndex = 0;
  int selectedTabIndex = 0;

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
  Map<String, List<ProductModel>> categoryProducts = {
    "Rice": [
      ProductModel(
          name: "Premium Basmati Rice",
          image: "assets/category/rice1.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      ProductModel(
        name: "Boiled Rice Classic",
        image: "assets/category/rice2.png",
        weight: "5 KG",
        price: 230,
        oldPrice: 260,
        discount: "15%",
      ),
      ProductModel(
          name: "Premium Basmati Rice",
          image: "assets/category/rice3.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      ProductModel(
        name: "Boiled Rice Classic",
        image: "assets/category/rice2.png",
        weight: "5 KG",
        price: 230,
        oldPrice: 260,
        discount: "15%",
      ),
      ProductModel(
          name: "Premium Basmati Rice",
          image: "assets/category/rice1.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      ProductModel(
        name: "Boiled Rice Classic",
        image: "assets/category/rice2.png",
        weight: "5 KG",
        price: 230,
        oldPrice: 260,
        discount: "15%",
      ),
      ProductModel(
          name: "Premium Basmati Rice",
          image: "assets/category/rice1.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      ProductModel(
        name: "Boiled Rice Classic",
        image: "assets/category/rice2.png",
        weight: "5 KG",
        price: 230,
        oldPrice: 260,
        discount: "15%",
      ),
    ],
    "Dals & Pulses": [
      ProductModel(
          name: "Chana Dal",
          image: "assets/category/dal/chana_dal.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Horse Gram",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Kabuli Chana",
          //  image: "assets/category/kabuli_chana.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Kala Chana",
          image: "assets/category/dal/chana_dal.png",

          //image: "assets/category/kala_chana.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Matar / Peas",
          // image: "assets/category/matar_peas.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Lobia",
          image: "assets/category/dal/chana_dal.png",

          // image: "assets/category/lobia.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Masoor Dal",
          //image: "assets/category/masoor_dal.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Matki / Moth Beans",
          image: "assets/category/dal/chana_dal.png",

          // image: "assets/category/matki_moth_beans.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Mixed Dal",
          // image: "assets/category/mixed_dal.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Moong Dal",
          image: "assets/category/dal/chana_dal.png",

          // image: "assets/category/moong_dal.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Other Pulses",
          // image: "assets/category/other_pulses.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Peanuts",
          image: "assets/category/dal/chana_dal.png",

          //  image: "assets/category/peanuts.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Rajma",
          // image: "assets/category/rajma.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Toor Dal",
          // image: "assets/category/toor_dal.png",
          image: "assets/category/dal/chana_dal.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Urad Dal",
          // image: "assets/category/urad_dal.png",
          image: "assets/category/dal/horse_gram.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
      ProductModel(
          name: "Val Beans",
          image: "assets/category/dal/chana_dal.png",

          // image: "assets/category/val_beans.png",
          weight: "1 KG",
          price: 0,
          oldPrice: 0,
          discount: "0%"),
    ],
    "Ghee": [
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
      ProductModel(
          name: "Tri Premium Cow Ghee..",
          image: "assets/category/dal/ghee.png",
          weight: "500 ML",
          price: 350,
          oldPrice: 420,
          discount: "15%"),
    ],
    "Wheat & Soya": [
      ProductModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),ProductModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),ProductModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),ProductModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),ProductModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),ProductModel(
          name: "Whole Wheat Grains",
          image: "assets/category/dal/wheat.png",
          weight: "1 KG",
          price: 55,
          oldPrice: 70,
          discount: "10%"),
    ],
    "Salt, Sugar": [
      ProductModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),ProductModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),ProductModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),ProductModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),ProductModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),ProductModel(
          name: "Iodized Salt",
          image: "assets/category/dal/jaggery.png",
          weight: "1 KG",
          price: 20,
          oldPrice: 25,
          discount: "8%"),
    ],
    "Sabudana, Poha & Murmura": [
      ProductModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),ProductModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),ProductModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),ProductModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),ProductModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),ProductModel(
          name: "Thick Poha",
          image: "assets/category/dal/murmura.png",
          weight: "500 GM",
          price: 35,
          oldPrice: 50,
          discount: "12%"),
    ],
    "Atta & Flour": [
      ProductModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),ProductModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),ProductModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),ProductModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),ProductModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),ProductModel(
          name: "Whole Wheat Atta",
          image: "assets/category/dal/atta.png",
          weight: "5 KG",
          price: 199,
          oldPrice: 260,
          discount: "20%"),
    ],
    "Dry Fruits & Nuts": [
      ProductModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"),ProductModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"), ProductModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"), ProductModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"), ProductModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"), ProductModel(
          name: "Premium Cashews",
          image: "assets/category/dal/almonds.png",
          weight: "500 GM",
          price: 520,
          oldPrice: 600,
          discount: "10%"),
    ],
    "Edible Oils": [
      ProductModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: " GroundNut Oil",
        image: "assets/category/dal/oilnew.png",
        weight: "2L",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),

    ],
    "Millets & Organic": [
      ProductModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),ProductModel(
        name: "Quinoa King Gluten",
        image: "assets/category/dal/ragi.png",
        weight: "1KG",
        price: 319,
        oldPrice: 999,
        discount: "68% Off",
      ),

    ],
  };

  @override
  Widget build(BuildContext context) {
    String currentCategory = categories[selectedIndex];
    List<String> tabs = categoryTabs[currentCategory]!;
    List<ProductModel> products = categoryProducts[currentCategory]!;

    return Scaffold(
      appBar: const CommonBackAppBar(
        title: "Cooking Essentials",
        isShadowShow: false,
        isGrocery: true,
      ),
      body: Row(
        children: [
          leftCategoryList(),
          Expanded(child: rightContent(tabs, products)),
        ],
      ),
    );
  }

  Widget leftCategoryList() {
    return Container(
      width: 94,
      color: AppColors.white,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _categoryItem(
            leftIcons[index],
            categories[index],
            selected: selectedIndex == index, // 👈 compare index
            onTap: () {
              setState(() {
                selectedIndex = index;
                selectedTabIndex = 0;
              });
            },
          );
        },
      ),
    );
  }

  Widget _categoryItem(String icon, String label,
      {bool selected = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: selected ? 11 : 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.skyBlueE4,
                AppColors.skyBlueE4.withOpacity(0.3),
              ],
            ),
            border: selected
                ? const Border(
                    left: BorderSide(
                        color: AppColors.primaryColor,
                        width: 3,
                        style: BorderStyle.solid))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // borderRadius: BorderRadius.circular(50),
                      color: selected ? null : AppColors.skyBlueE4),
                  padding: EdgeInsets.all(selected ? 0 : 6),
                  child: LocalAssets(
                    imagePath: icon,
                    // boxFix: BoxFit.cover,
                    height: 40,
                    width: 40,
                  )),
              const SizedBox(height: 6),
              CustomText(
                label,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.black : AppColors.grayText,
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget rightContent(List<String> tabs, List<ProductModel> products) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TABS
          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (_, i) {
                bool selected = selectedTabIndex == i;
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedTabIndex = i;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: i == 0 ? 0 : 3,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.primaryColor : AppColors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: selected
                          ? null
                          : Border.all(color: AppColors.greylite, width: 0.5),
                    ),
                    child: Center(
                      child: CustomText(
                        tabs[i],
                        color: selected
                            ? AppColors.white
                            : AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 8),

          // GRID
          Expanded(
            child: GridView.builder(
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.692,
              ),
              itemBuilder: (_, i) => productCard(products[i]),
            ),
          )
        ],
      ),
    );
  }

  Widget productCard(ProductModel p) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.white,
                    image: DecorationImage(
                        image: AssetImage(
                          p.image,
                        ),
                        fit: BoxFit.cover)),
              ),
              Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: AppColors.blackMite,
                        borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            border:
                                Border.all(width: 1, color: AppColors.white)),
                      ),
                    ),
                  ))
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 9.0, vertical: SizeConfig.size6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${p.name}",
                  fontSize: 10,
                  maxLines: 2,
                  color: Colors.black,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.green00, width: 1),
                          borderRadius: BorderRadius.circular(2)),
                      padding: EdgeInsets.all(3.5),
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: AppColors.green00),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(width: 0.5, color: AppColors.greyE5)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                      child: CustomText(
                        p.weight,
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    CustomText(
                      "₹${p.price.toString()}",
                      fontSize: 10,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(width: 4),
                    CustomText(
                      "₹${p.oldPrice.toString()}",
                      fontSize: 10,
                      color: AppColors.grayText,
                    ),
                    SizedBox(width: 4),
                    CustomText(
                      "${p.discount} Off",
                      fontSize: 10,
                      color: AppColors.green00,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class MilkAndDairyCategoryPage extends StatefulWidget {
  const MilkAndDairyCategoryPage({super.key});

  @override
  State<MilkAndDairyCategoryPage> createState() => _MilkAndDairyCategoryPageState();
}

class _MilkAndDairyCategoryPageState extends State<MilkAndDairyCategoryPage> {
  int selectedIndex = 0;
  int selectedTabIndex = 0;

  List<String> categories = [
    "Milk & Milk Products",
    "Cheese, Paneer & Tofu",
    "Batter & Chutney",
    "Toast & Khari",
    "Cakes & Muffins",
    "Breads & Chapatis",
    "Bakery & Snacks",
  ];

  /// TABS FOR EACH CATEGORY
  Map<String, List<String>> categoryTabs = {
    "Milk & Milk Products": [
      "All",
      "Butter & Margarine",
      "Videos",
      "Milk",
      "Shorts",
      "Milk Powder & Cream",
      "Learning",
      "Speciality Milk",
      "Yogurt & Shrikhand",
      "Channels",
    ],

    "Cheese, Paneer & Tofu": [
      "All",
      "Cheese",
      "Paneer",
      "Tofu",
    ],

    "Batter & Chutney": [

      "All",
      "Cheese",
      "Paneer",
      "Tofu",
    ],
    "Toast & Khari": [
      "All",
      "Cookies",
      "Rusk"

    ],"Cakes & Muffins": [
      "All",
      "Speciality & Other Cakes",

    ],
    "Breads & Chapatis": [
      "All",
      "Milk, Wheat & Multigrain Bread",

    ],
    "Bakery & Snacks": [

      "All",
      "Bakery Biscuits & Cookies",

    ],





  };
  List<String> leftIcons = [
    "assets/category/milk.png",
    "assets/category/paneer.png",
    "assets/category/batter.png",
    "assets/category/toast.png",
    "assets/category/cakes.png",
    "assets/category/breads.png",
    "assets/category/snacks.png",

  ];

  /// PRODUCT LIST FOR EACH CATEGORY
  Map<String, List<ProductModel>> categoryProducts = {
    "Milk & Milk Products": [
      ProductModel(
          name: "Milk Powder....",
          image: "assets/category/dal/milkpowder.png",
          weight: "1 ltr",
          price: 120,
          oldPrice: 160,
          discount: "25%"), ProductModel(
          name: "Milk Powder....",
          image: "assets/category/dal/milkpowder.png",
          weight: "1 ltr",
          price: 120,
          oldPrice: 160,
          discount: "25%"), ProductModel(
          name: "Milk Powder....",
          image: "assets/category/dal/milkpowder.png",
          weight: "1 ltr",
          price: 120,
          oldPrice: 160,
          discount: "25%"), ProductModel(
          name: "Milk Powder....",
          image: "assets/category/dal/milkpowder.png",
          weight: "1 ltr",
          price: 120,
          oldPrice: 160,
          discount: "25%"), ProductModel(
          name: "Milk Powder....",
          image: "assets/category/dal/milkpowder.png",
          weight: "1 ltr",
          price: 120,
          oldPrice: 160,
          discount: "25%"), ProductModel(
          name: "Milk Powder....",
          image: "assets/category/dal/milkpowder.png",
          weight: "1 ltr",
          price: 120,
          oldPrice: 160,
          discount: "25%"),





    ],
    "Cheese, Paneer & Tofu": [
      ProductModel(
          name: "Homemade Tofu Recipe",
          image: "assets/category/dal/paneer.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      ProductModel(
          name: "Homemade Tofu Recipe",
          image: "assets/category/dal/paneer.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      ProductModel(
          name: "Homemade Tofu Recipe",
          image: "assets/category/dal/paneer.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
      ProductModel(
          name: "Homemade Tofu Recipe",
          image: "assets/category/dal/paneer.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),


    ], "Batter & Chutney": [
      ProductModel(
          name: "Homemade Tofu Recipe",
          image: "assets/category/dal/paneer.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),


    ],"Toast & Khari": [
      ProductModel(
          name: "Suji Rusk",
          image: "assets/category/dal/rusk.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),
  ProductModel(
          name: "Suji Rusk",
          image: "assets/category/dal/rusk.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),



    ],"Cakes & Muffins": [
      ProductModel(
          name: "Brownie Rich Source.... ",
          image: "assets/category/dal/cakes.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"), ProductModel(
          name: "Brownie Rich Source.... ",
          image: "assets/category/dal/cakes.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),


    ],"Breads & Chapatis": [
      ProductModel(
          name: "Goat Milk Powder....",
          image: "assets/category/dal/milk.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),ProductModel(
          name: "Goat Milk Powder....",
          image: "assets/category/dal/milk.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),


    ],"Bakery & Snacks": [
      ProductModel(
          name: "FOODADO Premium Desi",
          image: "assets/category/dal/cookies.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"), ProductModel(
          name: "FOODADO Premium Desi",
          image: "assets/category/dal/cookies.png",
          weight: "1 KG",
          price: 120,
          oldPrice: 160,
          discount: "25%"),


    ],


  };

  @override
  Widget build(BuildContext context) {
    String currentCategory = categories[selectedIndex];
    List<String> tabs = categoryTabs[currentCategory]!;
    List<ProductModel> products = categoryProducts[currentCategory]!;

    return Scaffold(
      appBar: const CommonBackAppBar(
        title: "Dairy & Bakery",
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
                          : Border.all(color: AppColors.greyLite, width: 0.5),
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

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/store/widget/icon_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'baby_care.dart';
import 'cooking_esential_page.dart';
import 'diary.dart';
import 'fruits_veg.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController searchController = TextEditingController();
  final List<Tab> _tabs = [
    Tab(text: 'Grocery & Veg'),
    Tab(text: 'Home Essential'),
    Tab(text: 'Others')
  ];

  final List<Map<String, String>> biscuitFoods  = [
    {
      "icon": "chips.png",
      "label": "Chips &\nNamkeens",
    },
    {
      "icon": "biscuits.png",
      "label": "Biscuits\n& Cookies",
    },
    {
      "icon": "chocolate.png",
      "label": "Chocolates\n& Candies",
    },
    {
      "icon": "indiansweets.png",
      "label": "Indian\nSweets",
    },
    {
      "icon": "drinks.png",
      "label": "Drinks\n& Juices",
    },
    {
      "icon": "cereals.png",
      "label": "Breakfast\nCereals",
    },
    {
      "icon": "noodles.png",
      "label": "Noodles, Pasta\n& Vermicelli",
    },
    {
      "icon": "readytoeat.png",
      "label": "Ready To\ncook & Eat",
    },
  ];

  final List<Map<String, String>> fruitsVeg = [
    {"icon": "freshfruits.png", "label": "Fresh Fruits"},
    {"icon": "basicveg.png", "label": "Basic\nVegetables"},
    {"icon": "premiumveg.png", "label": "Premium Fruits\n& Vegetables"},
  ];

  final List<Map<String, String>> cookingEssentials = [
    {"icon": "rice.png", "label": "Rice"},
    {"icon": "dals.png", "label": "Dals & Pulses"},
    {"icon": "ghee.png", "label": "Ghee"},
    {"icon": "wheat.png", "label": "Wheat & Soya"},
    {"icon": "sugar.png", "label": "Salt, Sugar\n& Jaggery"},
    {"icon": "poha.png", "label": "Sabudana, Poha\n& Murmura"},
    {"icon": "atta.png", "label": "Atta, Flours\n& Sooji"},
    {"icon": "dryfruits.png", "label": "Dry Fruits\n& Nuts"},
    {"icon": "dryfruits.png", "label": "Edible Oils"},
    {"icon": "dryfruits.png", "label": "Millets\n& Organic"},
  ];

  final List<Map<String, String>> dairyBakery = [
    {"icon": "milk.png", "label": "Milk & Milk\nProducts"},
    {"icon": "paneer.png", "label": "Cheese,\nPaneer & Tofu"},
    {"icon": "batter.png", "label": "Batter\n& Chutney"},
    {"icon": "tasto.png", "label": "Toast\n& Khari"},
    {"icon": "cakes.png", "label": "Cakes &\nMuffins"},
    {"icon": "breads.png", "label": "Breads\n& Chapatis"},
    {"icon": "snacks.png", "label": "Bakery\n& Snacks"},
  ];

  final List<Map<String, String>> momBabyCare = [
    {"icon": "food.png", "label": "Food\n& Feeding"},
    {"icon": "bath.png", "label": "Bath, Hygiene\n& Grooming"},
    {"icon": "bedding.png", "label": "Bedding, Toys\n& Accessories"},
    {"icon": "health.png", "label": "Health\n& Wellness"},
    {"icon": "diapers.png", "label": "Diapers\n& Wipes"},
  ];

  final List<Map<String, String>> kitchenware = [
    {"icon": "gas.png", "label": "Gas Stove"},
    {"icon": "storage.png", "label": "Containers &\nStorage"},
    {"icon": "flask.png", "label": "Flask, Bottle\n& Tiffin Boxes"},
    {"icon": "cutting.png", "label": "Cutting\n& Chopping"},
    {"icon": "tools.png", "label": "Kitchen Tools"},
    {"icon": "bakeware.png", "label": "Bakeware"},
  ];

  final List<Map<String, String>> tableware = [
    {"icon": "dining.png", "label": "Dining"},
    {"icon": "serveware.png", "label": "Serveware"},
    {"icon": "barware.png", "label": "Barware"},
    {"icon": "tableacc.png", "label": "Table Accessories"},
    {"icon": "mugs.png", "label": "Cups, Mugs &\nMore"},
    {"icon": "drinkware.png", "label": "Glassware &\nDrinkware"},
  ];

  final List<Map<String, String>> giftsHampers = [
    {"icon": "tea.png", "label": "Tea Gifts"},
    {"icon": "chocogift.png", "label": "Chocolate Gifts"},
    {"icon": "gourmet.png", "label": "Gourmet Gifts"},
  ];

  final List<Map<String, String>> homeCategory = [
    {"icon": "detergents.png", "label": "Detergents\n& Cleaners"},
    {"icon": "fresheners.png", "label": "Fresheners\n& Repellents"},
    {"icon": "homecleaning.png", "label": "Home &\nCleaning Tools"},
    {"icon": "furnishing.png", "label": "Furnishing &\nPersonal Wear"},
    {"icon": "dishwash.png", "label": "Dishwash"},
    {"icon": "pooja.png", "label": "Pooja Needs"},
    {"icon": "electricals.png", "label": "Basic Electricals"},
    {"icon": "shoecare.png", "label": "Shoe Care"},
  ];



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: CommonBackAppBar(
          bottomWidget: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue,
            indicatorWeight: 2,
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            tabs: _tabs,
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [

            SingleChildScrollView(
              child: Column(
                children: [

                  _sectionWidget(
                    "Biscuits, Drinks & Packaged Foods",
                    arrCategory: biscuitFoods,
                    context: context,
                    onTap:(value){

                    }
                  ),

                  _sectionWidget(
                    "Fruits & Vegetables",
                    arrCategory: fruitsVeg,
                    context: context,
                      onTap:(value){
                        Get.to(()=> FruitsVegPage());
                      }
                  ),

                  _sectionWidget(
                    "Cooking Essentials",
                    arrCategory: cookingEssentials,
                    context: context,
                      onTap:(value){
                        Get.to(()=> CookingEssentialsPage());
                      }
                  ),

                  _sectionWidget(
                    "Dairy & Bakery",
                    arrCategory: dairyBakery,
                    context: context,
                      onTap:(value){
                        Get.to(()=> MilkAndDairyCategoryPage());

                      }
                  ),

                  _sectionWidget(
                    "Mom & Baby Care",
                    arrCategory: momBabyCare,
                    context: context,
                      onTap:(value){
                         Get.to(()=> MomBabyCarePage());
                      }
                  ),

                  _sectionWidget(
                    "Kitchenware",
                    arrCategory: kitchenware,
                    context: context,
                      onTap:(value){

                      }
                  ),

                  _sectionWidget(
                    "Tableware",
                    arrCategory: tableware,
                    context: context,
                      onTap:(value){

                      }
                  ),

                  _sectionWidget(
                    "Gifts & Hampers",
                    arrCategory: giftsHampers,
                    context: context,
                      onTap:(value){

                      }
                  ),

                  _sectionWidget(
                    "Home",
                    arrCategory: homeCategory,
                    context: context,
                      onTap:(value){

                      }
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            Center(child: CustomText(AppStrings.comingSoon)),

            Center(child: CustomText(AppStrings.comingSoon))

          ],
        ),
      ),
    );
  }

  Widget _sectionWidget(
      String title, {
        required List<Map<String, String>> arrCategory,
        required BuildContext context,
        void Function(Map<String, String> item)? onTap,
      }) {
    const int crossAxisCount = 4;
    const double mainAxisSpacing = 16.0;

    final firstEight = arrCategory.take(8).toList();
    final remaining = arrCategory.skip(8).toList();
    final bool hasMore = remaining.isNotEmpty;

    final isExpanded = false.obs;

    // list → rows-of-4
    List<Widget> _buildRows(List<Map<String, String>> source) {
      final rows = <List<Map<String, String>>>[];
      for (int i = 0; i < source.length; i += crossAxisCount) {
        rows.add(
          source.sublist(i, (i + crossAxisCount).clamp(0, source.length)),
        );
      }

      return rows.map((rowItems) {
        return Padding(
          padding: const EdgeInsets.only(bottom: mainAxisSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(crossAxisCount * 2 - 1, (i) {
              if (i.isEven) {
                final index = i ~/ 2;
                if (index < rowItems.length) {
                  final item = rowItems[index];
                  return Expanded(
                    child: IconGridItem(
                      label: item['label']!,
                      icon: 'assets/category/${item['icon']}',
                      onTap: () => onTap?.call(item),
                    ),
                  );
                }
              }
              return const Expanded(child: SizedBox());
            }),
          ),
        );
      }).toList();
    }

    return Obx(() {
      final visibleList = isExpanded.value ? arrCategory : firstEight;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomText(
                  title,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const Spacer(),
                if (hasMore)
                  InkWell(
                    onTap: () => isExpanded.toggle(),
                    child: CustomText(
                      isExpanded.value ? 'See Less'.tr : 'See More'.tr,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            /* grid */
            Column(children: _buildRows(visibleList)),
          ],
        ),
      );
    });
  }

  // Widget _iconItem(String img, String label) {
  //   return SizedBox(
  //     width: SizeConfig.size80,
  //     child: Column(
  //
  //       children: [
  //         Container(
  //
  //           padding:  EdgeInsets.all(SizeConfig.size6),
  //           decoration: BoxDecoration(
  //             color: AppColors.lightBlue,
  //             shape: BoxShape.circle,
  //           ),
  //           child: Image.asset(
  //             "assets/category/$img",
  //             height: SizeConfig.size40,
  //             width: SizeConfig.size40,
  //             fit: BoxFit.contain,
  //           ),
  //         ),
  //          SizedBox(height: SizeConfig.size6),
  //         CustomText(
  //           label,
  //           fontSize: 10,
  //           fontWeight: FontWeight.w600,
  //           color: AppColors.secondaryTextColor,
  //           textAlign: TextAlign.center,
  //
  //
  //         ),
  //
  //       ],
  //     ),
  //   );
  // }
}

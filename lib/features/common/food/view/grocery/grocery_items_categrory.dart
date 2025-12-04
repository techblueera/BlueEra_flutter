import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import 'baby_care.dart';
import 'cooking_esential_page.dart';
import 'diary.dart';
import 'fruits_veg.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              _topTabs(),

              const SizedBox(height: 10),

              _sectionWidget(
                "Biscuits, Drinks & Packaged Foods",
                showMore: true,
                icons: [
                  _iconItem("chips.png", "Chips &\nNamkeens"),


                  _iconItem("biscuits.png", "Biscuits\n& Cookies"),

                  _iconItem("chocolate.png", "Chocolates\n& Candies"),

                  _iconItem("indiansweets.png", "Indian\nSweets"),
                  _iconItem("drinks.png", "Drinks\n& Juices"),
                  _iconItem("cereals.png", "Breakfast\nCereals"),
                  _iconItem("noodles.png", "Noodles, Pasta\n& Vermicelli"),
                  _iconItem("readytoeat.png", "Ready To\ncook & Eat"),
                ], context: context,
              ),

              _sectionWidget(
                "Fruits & Vegetables",
                icons: [
                  _iconItem("freshfruits.png", "Fresh Fruits"),
                  _iconItem("basicveg.png", "Basic\nVegetables"),
                  _iconItem("premiumveg.png", "Premium Fruits\n& Vegetables"),
                ], context: context,
                seeMorePage: FruitsVegPage(),
                showMore: true

              ),

              _sectionWidget(
                "Cooking Essentials",
                icons: [
                  _iconItem("rice.png", "Rice"),
                  _iconItem("dals.png", "Dals & Pulses"),
                  _iconItem("ghee.png", "Ghee"),
                  _iconItem("wheat.png", "Wheat & Soya"),
                  _iconItem("sugar.png", "Salt, Sugar\n& Jaggery"),
                  _iconItem("poha.png", "Sabudana, Poha\n& Murmura"),
                  _iconItem("atta.png", "Atta, Flours\n& Sooji"),
                  _iconItem("dryfruits.png", "Dry Fruits\n& Nuts"),
                ], context: context,
                showMore: true,
                seeMorePage: CookingEssentialsPage(),


              ),

              _sectionWidget(
                "Dairy & Bakery",
                icons: [
                  _iconItem("milk.png", "Milk & Milk\nProducts"),
                  _iconItem("paneer.png", "Cheese,\nPaneer & Tofu"),
                  _iconItem("batter.png", "Batter\n& Chutney"),
                  _iconItem("tasto.png", "Toast\n& Khari"),
                  _iconItem("cakes.png", "Cakes &\nMuffins"),
                  _iconItem("breads.png", "Breads\n& Chapatis"),
                  _iconItem("snacks.png", "Bakery\n& Snacks"),
                ], context: context,
                showMore: true,
                seeMorePage: MilkAndDairyCategoryPage(),
              ),

              _sectionWidget(
                "Mom & Baby Care",
                icons: [
                  _iconItem("food.png", "Food\n& Feeding"),
                  _iconItem("bath.png", "Bath, Hygiene\n& Grooming"),
                  _iconItem("bedding.png", "Bedding, Toys\n& Accessories"),
                  _iconItem("health.png", "Health\n& Wellness"),
                  _iconItem("diapers.png", "Diapers\n& Wipes"),
                ], context: context,
                showMore: true,
                seeMorePage: MomBabyCarePage(),
              ),

              _sectionWidget(
                "Kitchenware",
                icons: [
                  _iconItem("gas.png", "Gas Stove"),
                  _iconItem("storage.png", "Containers &\nStorage"),
                  _iconItem("flask.png", "Flask, Bottle\n& Tiffin Boxes"),
                  _iconItem("cutting.png", "Cutting\n& Chopping"),
                  _iconItem("tools.png", "Kitchen Tools"),
                  _iconItem("bakeware.png", "Bakeware"),
                ], context: context,
              ),

              _sectionWidget(
                "Tableware",
                icons: [
                  _iconItem("dining.png", "Dining"),
                  _iconItem("serveware.png", "Serveware"),
                  _iconItem("barware.png", "Barware"),
                  _iconItem("tableacc.png", "Table Accessories"),
                  _iconItem("mugs.png", "Cups, Mugs &\nMore"),
                  _iconItem("drinkware.png", "Glassware &\nDrinkware"),
                ], context: context,
              ),

              _sectionWidget(
                "Gifts & Hampers",
                icons: [
                  _iconItem("tea.png", "Tea Gifts"),
                  _iconItem("chocogift.png", "Chocolate Gifts"),
                  _iconItem("gourmet.png", "Gourmet Gifts"),
                ], context: context,
              ),

              _sectionWidget(
                "Home",
                showMore: true,
                icons: [
                  _iconItem("detergents.png", "Detergents\n& Cleaners"),
                  _iconItem("fresheners.png", "Fresheners\n& Repellents"),
                  _iconItem("homecleaning.png", "Home &\nCleaning Tools"),
                  _iconItem("furnishing.png", "Furnishing &\nPersonal Wear"),
                  _iconItem("dishwash.png", "Dishwash"),
                  _iconItem("pooja.png", "Pooja Needs"),
                  _iconItem("electricals.png", "Basic Electricals"),
                  _iconItem("shoecare.png", "Shoe Care"),
                ], context: context,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _tabItem("Grocery & Veg", true),
        _tabItem("Home Essential", false),
        _tabItem("Others", false),
      ],
    );
  }

  Widget _tabItem(String text, bool active) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: active ? Colors.black : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        if (active)
          Container(
            height: 3,
            width: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              borderRadius: BorderRadius.circular(20),
            ),
          )
      ],
    );
  }

  Widget _sectionWidget(
      String title, {
        required List<Widget> icons,
        bool showMore = false,
        Widget? seeMorePage,
        required BuildContext context
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      padding: const EdgeInsets.all( 10),
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
              if (showMore && seeMorePage != null)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => seeMorePage,
                      ),
                    );
                  },
                  child: CustomText(
                    "See More",
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),

            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 10,

            runSpacing: 16,
            children: icons,
          ),
        ],
      ),
    );
  }

  Widget _iconItem(String img, String label) {
    return SizedBox(
      width: SizeConfig.size80,
      child: Column(

        children: [
          Container(

            padding:  EdgeInsets.all(SizeConfig.size6),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              "assets/category/$img",
              height: SizeConfig.size40,
              width: SizeConfig.size40,
              fit: BoxFit.contain,
            ),
          ),
           SizedBox(height: SizeConfig.size6),
          CustomText(
            label,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,


          ),

        ],
      ),
    );
  }
}

import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/custom_text_cm.dart';

class FoodCategoryPage extends StatefulWidget {
  const FoodCategoryPage({super.key});

  @override
  State<FoodCategoryPage> createState() => _FoodCategoryPageState();
}

class _FoodCategoryPageState extends State<FoodCategoryPage> with SingleTickerProviderStateMixin{
  late TabController tabController;

  @override
  void initState() {
    // TODO: implement initState
   tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,
    );
    super.initState();
  }
  int selectedSubTabIndex=0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 14),

              TabBar(
                labelPadding: EdgeInsets.symmetric(horizontal: 0,vertical: 0),
                controller: tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.lightBlue,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabAlignment: TabAlignment.fill,
                indicator:  UnderlineTabIndicator(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(style: BorderStyle.solid,width: 4, color: Colors.lightBlue),
                  insets: EdgeInsets.symmetric(horizontal: 2), // wider underline
                ),
                tabs: const [
                  Tab(text: "Foods"),
                  Tab(text: "Services"),
                  Tab(text: "Others"),
                ],
              ),

              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    LocalAssets(imagePath: AppIconAssets.toggol_buttons),
                    HorizontalTabSelector(horizontalMargin: 8,
                        tabs: [
                          'Veg',
                          'Non-Veg',
                          'Sweet & Dairy',
                          'Bakery',
                          'Others',
                        ],
                        selectedIndex: selectedSubTabIndex,
                        onTabSelected: (index, value){
                      setState(() {
                        selectedSubTabIndex=index;
                      });
                    },
                      labelBuilder: (label) => "$label",
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------------------
              // THALI & PARATHA
              // ---------------------------------------------------------
              _sectionWidget(
                "Thali & Paratha",
                icons: [
                  _iconItem("vegthali.png", "Veg Thali"),
                  _iconItem("dalRice.png", "Dal–Rice Combo"),
                  _iconItem("specialpaneerthali.png", "Special Paneer\nThali"),
                  _iconItem("parathaSabzi.png", "Paratha + Sabzi\nCombo"),
                  _iconItem("stuffedParatha.png", "Stuffed Paratha"),
                  _iconItem("malabarPack.png", "Lachha / Malabar\nParatha Pack"),
                  _iconItem("pooriAloo.png", "Poori + Aloo\nSabzi Pack"),
                  _iconItem("kichdiCurd.png", "Khichdi / Curd\nRice Meal"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // PANEER SPECIAL
              // ---------------------------------------------------------
              _sectionWidget(
                "Paneer Special",
                icons: [
                  _iconItem("paneerTikka.png", "Paneer Tikka"),
                  _iconItem("paneerNuggets.png", "Paneer Nuggets"),
                  _iconItem("paneerCubes.png", "Paneer Cubes"),
                  _iconItem("paneerPopcorn.png", "Paneer Popcorn"),
                  _iconItem("malaiPaneer.png", "Malai Paneer\nTikka"),
                  _iconItem("tandooriPaneer.png", "Tandoori Paneer\nMarinade"),
                  _iconItem("chilliPaneer.png", "Chilli Paneer\nPack"),
                  _iconItem("masalaPaneer.png", "Masala Paneer\nBits"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // CARRY & VEG
              // ---------------------------------------------------------
              _sectionWidget(
                "Carry & Veg",
                icons: [
                  _iconItem("paneerTikka.png", "Paneer Tikka"),
                  _iconItem("paneerNuggets.png", "Paneer Nuggets"),
                  _iconItem("paneerCubes.png", "Paneer Cubes"),
                  _iconItem("paneerPopcorn.png", "Paneer Popcorn"),
                  _iconItem("malaiPaneer.png", "Malai Paneer\nTikka"),
                  _iconItem("tandooriPaneer.png", "Tandoori Paneer\nMarinade"),
                  _iconItem("chilliPaneer.png", "Chilli Paneer\nPack"),
                  _iconItem("masalaPaneer.png", "Masala Paneer\nBits"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // RICE ITEMS
              // ---------------------------------------------------------
              _sectionWidget(
                "Rice Items",
                icons: [
                  _iconItem("vegBiryani.png", "Veg Biryani"),
                  _iconItem("friedRice.png", "Veg Fried Rice"),
                  _iconItem("vegNoodles.png", "Veg Noodles"),
                  _iconItem("pastaAlfredo.png", "Pasta Alfredo"),
                  _iconItem("arrabbiata.png", "Pasta Arrabbiata"),
                  _iconItem("vegMomos.png", "Veg Momos"),
                  _iconItem("vegBurger.png", "Veg Burger Patty"),
                  _iconItem("vegPizza.png", "Veg Pizza"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // FAST FOOD & BREAD
              // ---------------------------------------------------------
              _sectionWidget(
                "Fast Food & Bread Items",
                icons: [
                  _iconItem("vegBurger.png", "Veg / Paneer\nBurger"),
                  _iconItem("fries.png", "French Fries"),
                  _iconItem("pizzaSlices.png", "Veg Pizza Slices"),
                  _iconItem("garlicBread.png", "Garlic Bread"),
                  _iconItem("sandwich.png", "Sandwiches"),
                  _iconItem("breadPack.png", "White / Brown /\nMultigrain Bread"),
                  _iconItem("bunsPack.png", "Buns & Pav\nPack"),
                  _iconItem("toastRusk.png", "Toast / Rusk\nPack"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // BREAKFAST
              // ---------------------------------------------------------
              _sectionWidget(
                "Breakfast",
                icons: [
                  _iconItem("chole.png", "Chole Bhature"),
                  _iconItem("cornflakes.png", "Cornflakes"),
                  _iconItem("muesli.png", "Muesli"),
                  _iconItem("pooriSabzi.png", "Poori Sabzi"),
                  _iconItem("uttapam.png", "Uttapam"),
                  _iconItem("sprouts.png", "Sprouts"),
                  _iconItem("idli.png", "Idli"),
                  _iconItem("dosa.png", "Dosa"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // TANDOORI & GRILL
              // ---------------------------------------------------------
              _sectionWidget(
                "Tandoori & Grill Veg",
                icons: [
                  _iconItem("soyaChaap.png", "Tandoori Soya\nChaap"),
                  _iconItem("malaiSoya.png", "Malai Soya\nChaap"),
                  _iconItem("achariSoya.png", "Achari Soya\nChaap"),
                  _iconItem("periPeri.png", "Peri-Peri Soya\nStrips"),
                  _iconItem("vegSeekh.png", "Veg Seekh\nKebab"),
                  _iconItem("tandooriBroccoli.png", "Tandoori\nBroccoli"),
                  _iconItem("grilledMushroom.png", "Grilled\nMushroom Pack"),
                  _iconItem("bbqPlatter.png", "BBQ Veg\nPlatter Pack"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // INSTANT MEALS
              // ---------------------------------------------------------
              _sectionWidget(
                "Instant Meals",
                icons: [
                  _iconItem("instantPoha.png", "Instant Poha"),
                  _iconItem("upma.png", "Instant Upma"),
                  _iconItem("dalKhichdi.png", "Dal Khichdi"),
                  _iconItem("rajmaChawal.png", "Rajma Chawal"),
                  _iconItem("dalTadka.png", "Dal Tadka"),
                  _iconItem("paneerCurry.png", "Paneer Curry"),
                  _iconItem("noodlesCup.png", "Noodles Cup"),
                  _iconItem("pastaCup.png", "Pasta Cup"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // SHUP & OTHERS
              // ---------------------------------------------------------
              _sectionWidget(
                "Shup & Others",
                icons: [
                  _iconItem("instantPoha.png", "Instant Poha"),
                  _iconItem("upma.png", "Instant Upma"),
                  _iconItem("dalKhichdi.png", "Dal Khichdi"),
                  _iconItem("rajmaChawal.png", "Rajma Chawal"),
                  _iconItem("dalTadka.png", "Dal Tadka"),
                  _iconItem("paneerCurry.png", "Paneer Curry"),
                  _iconItem("noodlesCup.png", "Noodles Cup"),
                  _iconItem("pastaCup.png", "Pasta Cup"),
                ],
                context: context,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  Widget _topTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _tabItem("Foods", true),
        _tabItem("Services", false),
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
            width: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              borderRadius: BorderRadius.circular(20),
            ),
          )
      ],
    );
  }

  // ---------------------------------------------------------
  Widget _sectionWidget(
      String title, {
        required List<Widget> icons,
        required BuildContext context,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8,horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              CustomText(
                title,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
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

  // ---------------------------------------------------------
  Widget _iconItem(String img, String label) {
    return SizedBox(
      width: SizeConfig.size80,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size6),
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


import 'package:BlueEra/core/constants/app_image_assets.dart';
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
                  _iconItem(AppIconCategoryAssets.veg_thali, "Veg Thali"),
                  _iconItem(AppIconCategoryAssets.dalRice, "Dal–Rice Combo"),
                  _iconItem(AppIconCategoryAssets.specialpaneerthali, "Special Paneer\nThali"),
                  _iconItem(AppIconCategoryAssets.parathaSabzi, "Paratha + Sabzi\nCombo"),
                  _iconItem(AppIconCategoryAssets.stuffedParatha, "Stuffed Paratha"),
                  _iconItem(AppIconCategoryAssets.malabarPack, "Lachha / Malabar\nParatha Pack"),
                  _iconItem(AppIconCategoryAssets.pooriAloo, "Poori + Aloo\nSabzi Pack"),
                  _iconItem(AppIconCategoryAssets.kichdiCurd, "Khichdi / Curd\nRice Meal"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // PANEER SPECIAL
              // ---------------------------------------------------------
              _sectionWidget(
                "Paneer Special",
                icons: [
                  _iconItem(AppIconCategoryAssets.paneerTikka, "Paneer Tikka"),
                  _iconItem(AppIconCategoryAssets.paneerNuggets, "Paneer Nuggets"),
                  _iconItem(AppIconCategoryAssets.paneerCubes, "Paneer Cubes"),
                  _iconItem(AppIconCategoryAssets.paneerPopcorn, "Paneer Popcorn"),
                  _iconItem(AppIconCategoryAssets.malaiPaneer, "Malai Paneer\nTikka"),
                  _iconItem(AppIconCategoryAssets.tandooriPaneer, "Tandoori Paneer\nMarinade"),
                  _iconItem(AppIconCategoryAssets.chilliPaneer, "Chilli Paneer\nPack"),
                  _iconItem(AppIconCategoryAssets.masalaPaneer, "Masala Paneer\nBits"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // CARRY & VEG
              // ---------------------------------------------------------
              _sectionWidget(
                "Carry & Veg",
                icons: [
                  _iconItem(AppIconCategoryAssets.carryPaneerTikka, "Paneer Tikka"),
                  _iconItem(AppIconCategoryAssets.carryPaneerNuggets, "Paneer Nuggets"),
                  _iconItem(AppIconCategoryAssets.carryPaneerCubes, "Paneer Cubes"),
                  _iconItem(AppIconCategoryAssets.carryPaneerPopcorn, "Paneer Popcorn"),
                  _iconItem(AppIconCategoryAssets.carryMalaiPaneer, "Malai Paneer\nTikka"),
                  _iconItem(AppIconCategoryAssets.carryTandooriPaneer, "Tandoori Paneer\nMarinade"),
                  _iconItem(AppIconCategoryAssets.carryChilliPaneer, "Chilli Paneer\nPack"),
                  _iconItem(AppIconCategoryAssets.carryMasalaPaneer, "Masala Paneer\nBits"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // RICE ITEMS
              // ---------------------------------------------------------
              _sectionWidget(
                "Rice Items",
                icons: [
                  _iconItem(AppIconCategoryAssets.vegBiryani, "Veg Biryani"),
                  _iconItem(AppIconCategoryAssets.friedRice, "Veg Fried Rice"),
                  _iconItem(AppIconCategoryAssets.vegNoodles, "Veg Noodles"),
                  _iconItem(AppIconCategoryAssets.pastaAlfredo, "Pasta Alfredo"),
                  _iconItem(AppIconCategoryAssets.arrabbiata, "Pasta Arrabbiata"),
                  _iconItem(AppIconCategoryAssets.vegMomos, "Veg Momos"),
                  _iconItem(AppIconCategoryAssets.vegBurger, "Veg Burger Patty"),
                  _iconItem(AppIconCategoryAssets.vegPizza, "Veg Pizza"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // FAST FOOD & BREAD
              // ---------------------------------------------------------
              _sectionWidget(
                "Fast Food & Bread Items",
                icons: [
                  _iconItem(AppIconCategoryAssets.burger, "Veg / Paneer\nBurger"),
                  _iconItem(AppIconCategoryAssets.fries, "French Fries"),
                  _iconItem(AppIconCategoryAssets.pizzaSlices, "Veg Pizza Slices"),
                  _iconItem(AppIconCategoryAssets.garlicBread, "Garlic Bread"),
                  _iconItem(AppIconCategoryAssets.sandwich, "Sandwiches"),
                  _iconItem(AppIconCategoryAssets.breadPack, "White / Brown /\nMultigrain Bread"),
                  _iconItem(AppIconCategoryAssets.bunsPack, "Buns & Pav\nPack"),
                  _iconItem(AppIconCategoryAssets.toastRusk, "Toast / Rusk\nPack"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // BREAKFAST
              // ---------------------------------------------------------
              _sectionWidget(
                "Breakfast",
                icons: [
                  _iconItem(AppIconCategoryAssets.chole, "Chole Bhature"),
                  _iconItem(AppIconCategoryAssets.cornflakes, "Cornflakes"),
                  _iconItem(AppIconCategoryAssets.muesli, "Muesli"),
                  _iconItem(AppIconCategoryAssets.pooriSabzi, "Poori Sabzi"),
                  _iconItem(AppIconCategoryAssets.uttapam, "Uttapam"),
                  _iconItem(AppIconCategoryAssets.sprouts, "Sprouts"),
                  _iconItem(AppIconCategoryAssets.idli, "Idli"),
                  _iconItem(AppIconCategoryAssets.dosa, "Dosa"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // TANDOORI & GRILL
              // ---------------------------------------------------------
              _sectionWidget(
                "Tandoori & Grill Veg",
                icons: [
                  _iconItem(AppIconCategoryAssets.soyaChaap, "Tandoori Soya\nChaap"),
                  _iconItem(AppIconCategoryAssets.malaiSoya, "Malai Soya\nChaap"),
                  _iconItem(AppIconCategoryAssets.achariSoya, "Achari Soya\nChaap"),
                  _iconItem(AppIconCategoryAssets.periPeri, "Peri-Peri Soya\nStrips"),
                  _iconItem(AppIconCategoryAssets.vegSeekh, "Veg Seekh\nKebab"),
                  _iconItem(AppIconCategoryAssets.tandooriBroccoli, "Tandoori\nBroccoli"),
                  _iconItem(AppIconCategoryAssets.grilledMushroom, "Grilled\nMushroom Pack"),
                  _iconItem(AppIconCategoryAssets.bbqPlatter, "BBQ Veg\nPlatter Pack"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // INSTANT MEALS
              // ---------------------------------------------------------
              _sectionWidget(
                "Instant Meals",
                icons: [
                  _iconItem(AppIconCategoryAssets.instantPoha, "Instant Poha"),
                  _iconItem(AppIconCategoryAssets.upma, "Instant Upma"),
                  _iconItem(AppIconCategoryAssets.dalKhichdi, "Dal Khichdi"),
                  _iconItem(AppIconCategoryAssets.rajmaChawal, "Rajma Chawal"),
                  _iconItem(AppIconCategoryAssets.dalTadka, "Dal Tadka"),
                  _iconItem(AppIconCategoryAssets.paneerCurry, "Paneer Curry"),
                  _iconItem(AppIconCategoryAssets.noodlesCup, "Noodles Cup"),
                  _iconItem(AppIconCategoryAssets.pastaCup, "Pasta Cup"),
                ],
                context: context,
              ),

              // ---------------------------------------------------------
              // SOUP & OTHERS
              // ---------------------------------------------------------
              _sectionWidget(
                "Shup & Others",
                icons: [
                  _iconItem(AppIconCategoryAssets.shupInstantPoha, "Instant Poha"),
                  _iconItem(AppIconCategoryAssets.shupUpma, "Instant Upma"),
                  _iconItem(AppIconCategoryAssets.shupDalKhichdi, "Dal Khichdi"),
                  _iconItem(AppIconCategoryAssets.shupRajmaChawal, "Rajma Chawal"),
                  _iconItem(AppIconCategoryAssets.shupDalTadka, "Dal Tadka"),
                  _iconItem(AppIconCategoryAssets.shupPaneerCurry, "Paneer Curry"),
                  _iconItem(AppIconCategoryAssets.shupNoodlesCup, "Noodles Cup"),
                  _iconItem(AppIconCategoryAssets.shupPastaCup, "Pasta Cup"),
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
    // print("dsjkcnlsdkcml ${img}");
    return SizedBox(
      width: SizeConfig.size80,
      child: Column(
        children: [
          Container(
            height: SizeConfig.size50,
            width: SizeConfig.size50,
            padding: EdgeInsets.all(SizeConfig.size6),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: LocalAssets(imagePath: img),
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


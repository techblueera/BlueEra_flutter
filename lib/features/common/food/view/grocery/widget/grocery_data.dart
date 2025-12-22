import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_constant.dart';

class GroceryData {

  /// Super Grocery Categories
  static const List<CollapsibleGridModel> grocerySuperCategories = [
    CollapsibleGridModel(
        icon: "grocery_items.svg",
        label: "Grocery Items",
        tagId: GroceryConstant.GROCERY_ITEMS),
    CollapsibleGridModel(
        icon: "vegetable.svg",
        label: "Vegetable",
        tagId: GroceryConstant.VEGETABLE),
    CollapsibleGridModel(
        icon: "vegetable.svg",
        label: "Fruit",
        tagId: GroceryConstant.FRUIT),
    CollapsibleGridModel(
        icon: "bakery.svg",
        label: "Bakery & Bread Items",
        tagId: GroceryConstant.BAKERY_BREAD_ITEMS),
    CollapsibleGridModel(
        icon: "dairy_products.svg",
        label: "Dairy Products",
        tagId: GroceryConstant.DAIRY_PRODUCTS),
    CollapsibleGridModel(
        icon: "home_essentials.svg",
        label: "Home Essentials",
        tagId: GroceryConstant.HOME_ESSENTIALS),
    CollapsibleGridModel(
        icon: "packed_sweets.svg",
        label: "Packed Sweets & Namkeens",
        tagId: GroceryConstant.PACKED_SWEETS_NAMKEENS),
    CollapsibleGridModel(
        icon: "crockery.svg",
        label: "Crockery",
        tagId: GroceryConstant.CROCKERY),
    CollapsibleGridModel(
        icon: "medical_items.svg",
        label: "Medical Items",
        tagId: GroceryConstant.MEDICAL_ITEMS),
    CollapsibleGridModel(
        icon: "beauty_body_care.svg",
        label: "Beauty & Body Care",
        tagId: GroceryConstant.BEAUTY_BODY_CARE),
    CollapsibleGridModel(
        icon: "stationary.svg",
        label: "Stationary",
        tagId: GroceryConstant.STATIONARY),
  ];

  /// Grocery Item
  static const List<CollapsibleGridModel> riceProducts = [
    CollapsibleGridModel(
        icon: "grocery_items/basmati_rice.png",
        label: "Basmati Rice",
        tagId: GroceryConstant.RICE_BASMATI),
    CollapsibleGridModel(
        icon: "grocery_items/red_rice.png",
        label: "Red Rice",
        tagId: GroceryConstant.RICE_RED),
     CollapsibleGridModel(
        icon: "grocery_items/kolam_rice.png",
        label: "Kolam Rice",
        tagId: GroceryConstant.RICE_KOLAM),
    CollapsibleGridModel(
        icon: "grocery_items/ponni_rice.png",
        label: "Ponni Rice",
        tagId: GroceryConstant.RICE_PONNI),
    CollapsibleGridModel(
        icon: "grocery_items/parboiled_rice.png",
        label: "Parboiled Rice",
        tagId: GroceryConstant.RICE_PARBOILED),
    CollapsibleGridModel(
        icon: "grocery_items/brown_rice.png",
        label: "Brown Rice",
        tagId: GroceryConstant.RICE_BROWN),
    CollapsibleGridModel(
        icon: "grocery_items/sona_masoori.png",
        label: "Sona Masoori Rice",
        tagId: GroceryConstant.RICE_SONA_MASOORI),
    CollapsibleGridModel(
        icon: "grocery_items/black_rice.png",
        label: "Black Rice",
        tagId: GroceryConstant.RICE_BLACK),
  ];

  static const List<CollapsibleGridModel> wheatAndFlours = [
    CollapsibleGridModel(
        icon: "grocery_items/whole_wheat_atta.png",
        label: "Whole Wheat Atta",
        tagId: GroceryConstant.FLOUR_WHOLE_WHEAT),
    CollapsibleGridModel(
        icon: "grocery_items/chakki_atta.png",
        label: "Chakki Atta",
        tagId: GroceryConstant.FLOUR_CHAKKI_ATTA),
    CollapsibleGridModel(
        icon: "grocery_items/sharbati_atta.png",
        label: "Sharbati Atta",
        tagId: GroceryConstant.FLOUR_SHARBATI_ATTA),
    CollapsibleGridModel(
        icon: "grocery_items/multigrain_atta.png",
        label: "Multigrain Atta",
        tagId: GroceryConstant.FLOUR_MULTIGRAIN),
    CollapsibleGridModel(
        icon: "grocery_items/diabetic_atta.png",
        label: "Diabetic Friendly Atta",
        tagId: GroceryConstant.FLOUR_DIABETIC),
    CollapsibleGridModel(
        icon: "grocery_items/maida.png",
        label: "Maida",
        tagId: GroceryConstant.FLOUR_MAIDA),
    CollapsibleGridModel(
        icon: "grocery_items/besan.png",
        label: "Besan",
        tagId: GroceryConstant.FLOUR_BESAN),
    CollapsibleGridModel(
        icon: "grocery_items/rice_flour.png",
        label: "Rice Flour",
        tagId: GroceryConstant.FLOUR_RICE),
    CollapsibleGridModel(
        icon: "grocery_items/ragi_flour.png",
        label: "Ragi Flour",
        tagId: GroceryConstant.FLOUR_RAGI),
  ];

  static const List<CollapsibleGridModel> dalNdBeans = [
    CollapsibleGridModel(
        icon: "grocery_items/toor_dal.png",
        label: "Toor Dal",
        tagId: GroceryConstant.DAL_TOOR),
    CollapsibleGridModel(
        icon: "grocery_items/moong_dal.png",
        label: "Moong Dal",
        tagId: GroceryConstant.DAL_MOONG),
    CollapsibleGridModel(
        icon: "grocery_items/masoor_dal.png",
        label: "Masoor Dal",
        tagId: GroceryConstant.DAL_MASOOR),
    CollapsibleGridModel(
        icon: "grocery_items/urad_dal.png",
        label: "Urad Dal",
        tagId: GroceryConstant.DAL_URAD),
    CollapsibleGridModel(
        icon: "grocery_items/chana_dal.png",
        label: "Chana Dal",
        tagId: GroceryConstant.DAL_CHANA),
    CollapsibleGridModel(
        icon: "grocery_items/kabuli_chana.png",
        label: "Kabuli Chana",
        tagId: GroceryConstant.DAL_KABULI_CHANA),
    CollapsibleGridModel(
        icon: "grocery_items/kala_chana.png",
        label: "Kala Chana",
        tagId: GroceryConstant.DAL_KALA_CHANA),
    CollapsibleGridModel(
        icon: "grocery_items/rajma.png",
        label: "Rajma",
        tagId: GroceryConstant.DAL_RAJMA),
    CollapsibleGridModel(
        icon: "grocery_items/dry_green_peas.png",
        label: "Dry Green Peas",
        tagId: GroceryConstant.DAL_DRY_GREEN_PEAS),
  ];

  static const List<CollapsibleGridModel> milletsNdTraditionalGrains = [
    CollapsibleGridModel(
        icon: "grocery_items/ragi.png",
        label: "Ragi",
        tagId: GroceryConstant.MILLET_RAGI),
    CollapsibleGridModel(
        icon: "grocery_items/jowar.png",
        label: "Jowar",
        tagId: GroceryConstant.MILLET_JOWAR),
    CollapsibleGridModel(
        icon: "grocery_items/bajra.png",
        label: "Bajra",
        tagId: GroceryConstant.MILLET_BAJRA),
    CollapsibleGridModel(
        icon: "grocery_items/foxtail_millet.png",
        label: "Foxtail Millet",
        tagId: GroceryConstant.MILLET_FOXTAIL),
    CollapsibleGridModel(
        icon: "grocery_items/little_millet.png",
        label: "Little Millet",
        tagId: GroceryConstant.MILLET_LITTLE),
    CollapsibleGridModel(
        icon: "grocery_items/kodo_millet.png",
        label: "Kodo Millet",
        tagId: GroceryConstant.MILLET_KODO),
    CollapsibleGridModel(
        icon: "grocery_items/barnyard_millet.png",
        label: "Barnyard Millet",
        tagId: GroceryConstant.MILLET_BARNYARD),
    CollapsibleGridModel(
        icon: "grocery_items/samak_rice.png",
        label: "Samak Rice",
        tagId: GroceryConstant.RICE_SAMAK),
  ];

  static const List<CollapsibleGridModel> breakfastStaples = [
    CollapsibleGridModel(
        icon: "grocery_items/poha.png",
        label: "Poha",
        tagId: GroceryConstant.STAPLE_POHA),
    CollapsibleGridModel(
        icon: "grocery_items/aval.png",
        label: "Aval Rice Flakes",
        tagId: GroceryConstant.STAPLE_AVAL),
    CollapsibleGridModel(
        icon: "grocery_items/dalia.png",
        label: "Dalia Broken Wheat",
        tagId: GroceryConstant.STAPLE_DALIA),
    CollapsibleGridModel(
        icon: "grocery_items/oats.png",
        label: "Oats",
        tagId: GroceryConstant.STAPLE_OATS),
    CollapsibleGridModel(
        icon: "grocery_items/corn_grits.png",
        label: "Corn Grits",
        tagId: GroceryConstant.STAPLE_CORN_GRITS),
    CollapsibleGridModel(
        icon: "grocery_items/wheat_bran.png",
        label: "Wheat Bran",
        tagId: GroceryConstant.STAPLE_WHEAT_BRAN),
  ];

  static const List<CollapsibleGridModel> spicesAndMasala = [
    CollapsibleGridModel(
        icon: "grocery_items/cumin.png",
        label: "Cumin Seeds",
        tagId: GroceryConstant.SPICE_CUMIN_SEEDS),
    CollapsibleGridModel(
        icon: "grocery_items/coriander_seeds.png",
        label: "Coriander Seeds",
        tagId: GroceryConstant.SPICE_CORIANDER_SEEDS),
    CollapsibleGridModel(
        icon: "grocery_items/black_pepper.png",
        label: "Black Pepper",
        tagId: GroceryConstant.SPICE_BLACK_PEPPER),
    CollapsibleGridModel(
        icon: "grocery_items/green_cardamom.png",
        label: "Green Cardamom",
        tagId: GroceryConstant.SPICE_GREEN_CARDAMOM),
    CollapsibleGridModel(
        icon: "grocery_items/cloves.png",
        label: "Cloves",
        tagId: GroceryConstant.SPICE_CLOVES),
    CollapsibleGridModel(
        icon: "grocery_items/cinnamon.png",
        label: "Cinnamon",
        tagId: GroceryConstant.SPICE_CINNAMON),
    CollapsibleGridModel(
        icon: "grocery_items/turmeric.png",
        label: "Turmeric Powder",
        tagId: GroceryConstant.SPICE_TURMERIC_POWDER),
    CollapsibleGridModel(
        icon: "grocery_items/red_chilli.png",
        label: "Red Chilli Powder",
        tagId: GroceryConstant.SPICE_RED_CHILLI_POWDER),
    CollapsibleGridModel(
        icon: "grocery_items/coriander_powder.png",
        label: "Coriander Powder",
        tagId: GroceryConstant.SPICE_CORIANDER_POWDER),
    CollapsibleGridModel(
        icon: "grocery_items/garam_masala.png",
        label: "Garam Masala",
        tagId: GroceryConstant.MASALA_GARAM),
    CollapsibleGridModel(
        icon: "grocery_items/chaat_masala.png",
        label: "Chaat Masala",
        tagId: GroceryConstant.MASALA_CHAAT),
    CollapsibleGridModel(
        icon: "grocery_items/sambhar_masala.png",
        label: "Sambhar Masala",
        tagId: GroceryConstant.MASALA_SAMBHAR),
    CollapsibleGridModel(
        icon: "grocery_items/biryani_masala.png",
        label: "Biryani Masala",
        tagId: GroceryConstant.MASALA_BIRYANI),
    CollapsibleGridModel(
        icon: "grocery_items/chole_masala.png",
        label: "Chole Masala",
        tagId: GroceryConstant.MASALA_CHOLE),
  ];

  static const List<CollapsibleGridModel> saltNdSweeteners = [
    CollapsibleGridModel(
        icon: "grocery_items/iodized_salt.png",
        label: "Iodized Salt",
        tagId: GroceryConstant.SWEET_IODIZED_SALT),
    CollapsibleGridModel(
        icon: "grocery_items/rock_salt.png",
        label: "Rock Salt",
        tagId: GroceryConstant.SWEET_ROCK_SALT),
    CollapsibleGridModel(
        icon: "grocery_items/pink_salt.png",
        label: "Pink Salt",
        tagId: GroceryConstant.SWEET_PINK_SALT),
    CollapsibleGridModel(
        icon: "grocery_items/white_sugar.png",
        label: "White Sugar",
        tagId: GroceryConstant.SWEET_WHITE_SUGAR),
    CollapsibleGridModel(
        icon: "grocery_items/brown_sugar.png",
        label: "Brown Sugar",
        tagId: GroceryConstant.SWEET_BROWN_SUGAR),
    CollapsibleGridModel(
        icon: "grocery_items/jaggery.png",
        label: "Jaggery",
        tagId: GroceryConstant.SWEET_JAGGERY),
    CollapsibleGridModel(
        icon: "grocery_items/honey.png",
        label: "Honey",
        tagId: GroceryConstant.SWEET_HONEY),
    CollapsibleGridModel(
        icon: "grocery_items/sugar_free.png",
        label: "Sugar Free Sweetener",
        tagId: GroceryConstant.SWEET_SUGAR_FREE),
  ];

  static const List<CollapsibleGridModel> oilsAndFats = [
    CollapsibleGridModel(
        icon: "grocery_items/sunflower_oil.png",
        label: "Sunflower Oil",
        tagId: GroceryConstant.OIL_SUNFLOWER),
    CollapsibleGridModel(
        icon: "grocery_items/rice_bran_oil.png",
        label: "Rice Bran Oil",
        tagId: GroceryConstant.OIL_RICE_BRAN),
    CollapsibleGridModel(
        icon: "grocery_items/mustard_oil.png",
        label: "Mustard Oil",
        tagId: GroceryConstant.OIL_MUSTARD),
    CollapsibleGridModel(
        icon: "grocery_items/groundnut_oil.png",
        label: "Groundnut Oil",
        tagId: GroceryConstant.OIL_GROUNDNUT),
    CollapsibleGridModel(
        icon: "grocery_items/sesame_oil.png",
        label: "Sesame Oil",
        tagId: GroceryConstant.OIL_SESAME),
    CollapsibleGridModel(
        icon: "grocery_items/coconut_oil.png",
        label: "Coconut Oil",
        tagId: GroceryConstant.OIL_COCONUT),
    CollapsibleGridModel(
        icon: "grocery_items/olive_oil.png",
        label: "Olive Oil",
        tagId: GroceryConstant.OIL_OLIVE),
    CollapsibleGridModel(
        icon: "grocery_items/cow_ghee.png",
        label: "Cow Ghee",
        tagId: GroceryConstant.GHEE_COW),
    CollapsibleGridModel(
        icon: "grocery_items/desi_ghee.png",
        label: "Desi Ghee",
        tagId: GroceryConstant.GHEE_DESI),
    ];

  static const List<CollapsibleGridModel> teaCoffeeBeverages = [
    CollapsibleGridModel(
        icon: "grocery_items/assam_tea.png",
        label: "Assam Tea",
        tagId: GroceryConstant.BEV_ASSAM_TEA),
    CollapsibleGridModel(
        icon: "grocery_items/green_tea.png",
        label: "Green Tea",
        tagId: GroceryConstant.BEV_GREEN_TEA),
    CollapsibleGridModel(
        icon: "grocery_items/masala_tea.png",
        label: "Masala Tea",
        tagId: GroceryConstant.BEV_MASALA_TEA),
    CollapsibleGridModel(
        icon: "grocery_items/instant_coffee.png",
        label: "Instant Coffee",
        tagId: GroceryConstant.BEV_INSTANT_COFFEE),
    CollapsibleGridModel(
        icon: "grocery_items/filter_coffee.png",
        label: "Filter Coffee",
        tagId: GroceryConstant.BEV_FILTER_COFFEE),
    CollapsibleGridModel(
        icon: "grocery_items/malt_drink.png",
        label: "Malt Health Drink",
        tagId: GroceryConstant.BEV_MALT_HEALTH_DRINK),
    CollapsibleGridModel(
        icon: "grocery_items/glucose_powder.png",
        label: "Glucose Drink Powder",
        tagId: GroceryConstant.BEV_GLUCOSE_POWDER),
    CollapsibleGridModel(
        icon: "grocery_items/coconut_water.png",
        label: "Coconut Water",
        tagId: GroceryConstant.BEV_COCONUT_WATER),
    CollapsibleGridModel(
        icon: "grocery_items/drinking_water.png",
        label: "Packaged Drinking Water",
        tagId: GroceryConstant.BEV_DRINKING_WATER),
  ];

  static const List<CollapsibleGridModel> dryFruitsAndReadyFood = [
    // Dry Fruits & Seeds
    CollapsibleGridModel(icon: "grocery_items/almonds.png", label: "Almonds", tagId: GroceryConstant.DRY_ALMONDS),
    CollapsibleGridModel(icon: "grocery_items/cashews.png", label: "Cashew Nuts", tagId: GroceryConstant.DRY_CASHEWS),
    CollapsibleGridModel(icon: "grocery_items/raisins.png", label: "Raisins", tagId: GroceryConstant.DRY_RAISINS),
    CollapsibleGridModel(icon: "grocery_items/dates.png", label: "Dates", tagId: GroceryConstant.DRY_DATES),
    CollapsibleGridModel(icon: "grocery_items/dry_fig.png", label: "Dry Fig", tagId: GroceryConstant.DRY_FIG),
    CollapsibleGridModel(icon: "grocery_items/chia_seeds.png", label: "Chia Seeds", tagId: GroceryConstant.SEED_CHIA),
    CollapsibleGridModel(icon: "grocery_items/flax_seeds.png", label: "Flax Seeds", tagId: GroceryConstant.SEED_FLAX),
    CollapsibleGridModel(icon: "grocery_items/pumpkin_seeds.png", label: "Pumpkin Seeds", tagId: GroceryConstant.SEED_PUMPKIN),

    // Baby Food
    CollapsibleGridModel(icon: "grocery_items/baby_milk.png", label: "Baby Milk Powder", tagId: GroceryConstant.BABY_MILK_POWDER),
    CollapsibleGridModel(icon: "grocery_items/rice_cereal.png", label: "Rice Cereal", tagId: GroceryConstant.BABY_RICE_CEREAL),
    CollapsibleGridModel(icon: "grocery_items/khichdi_mix.png", label: "Khichdi Mix", tagId: GroceryConstant.BABY_KHICHDI_MIX),
    CollapsibleGridModel(icon: "grocery_items/baby_biscuits.png", label: "Baby Biscuits", tagId: GroceryConstant.BABY_BISCUITS),

    // Ready Food & Accompaniments
    CollapsibleGridModel(icon: "grocery_items/ready_poha.png", label: "Ready Poha", tagId: GroceryConstant.READY_POHA),
    CollapsibleGridModel(icon: "grocery_items/ready_upma.png", label: "Ready Upma", tagId: GroceryConstant.READY_UPMA),
    CollapsibleGridModel(icon: "grocery_items/ready_dal.png", label: "Ready Dal", tagId: GroceryConstant.READY_DAL),
    CollapsibleGridModel(icon: "grocery_items/papad.png", label: "Papad", tagId: GroceryConstant.ACC_PAPAD),
    CollapsibleGridModel(icon: "grocery_items/ketchup.png", label: "Tomato Ketchup", tagId: GroceryConstant.ACC_KETCHUP),
    CollapsibleGridModel(icon: "grocery_items/grocery_items/mango_pickle.png", label: "Mango Pickle", tagId: GroceryConstant.ACC_PICKLE_MANGO),
    CollapsibleGridModel(icon: "grocery_items/lemon_pickle.png", label: "Lemon Pickle", tagId: GroceryConstant.ACC_PICKLE_LEMON),
    CollapsibleGridModel(icon: "grocery_items/mixed_pickle.png", label: "Mixed Vegetable Pickle", tagId: GroceryConstant.ACC_PICKLE_MIXED),
  ];

  /// VEGETABLE
  static const List<CollapsibleGridModel> leafyVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/spinach.png",
        label: "Spinach",
        tagId: GroceryConstant.VEG_LEAFY_SPINACH),
    CollapsibleGridModel(
        icon: "vegetables/fenugreek.png",
        label: "Fenugreek",
        tagId: GroceryConstant.VEG_LEAFY_FENUGREEK),
    CollapsibleGridModel(
        icon: "vegetables/mustard_greens.png",
        label: "Mustard Greens",
        tagId: GroceryConstant.VEG_LEAFY_MUSTARD_GREENS),
    CollapsibleGridModel(
        icon: "vegetables/mint.png",
        label: "Mint",
        tagId: GroceryConstant.VEG_LEAFY_MINT),
    CollapsibleGridModel(
        icon: "vegetables/coriander.png",
        label: "Coriander Leaves",
        tagId: GroceryConstant.VEG_LEAFY_CORIANDER),
    CollapsibleGridModel(
        icon: "vegetables/amaranth.png",
        label: "Amaranth",
        tagId: GroceryConstant.VEG_LEAFY_AMARANTH),
    CollapsibleGridModel(
        icon: "vegetables/bathua.png",
        label: "Bathua",
        tagId: GroceryConstant.VEG_LEAFY_BATHUA),
    CollapsibleGridModel(
        icon: "vegetables/malabar_spinach.png",
        label: "Malabar Spinach",
        tagId: GroceryConstant.VEG_LEAFY_MALABAR_SPINACH),
    CollapsibleGridModel(
        icon: "vegetables/drumstick_leaves.png",
        label: "Drumstick Leaves",
        tagId: GroceryConstant.VEG_LEAFY_DRUMSTICK),
    CollapsibleGridModel(
        icon: "vegetables/dill_leaves.png",
        label: "Dill Leaves",
        tagId: GroceryConstant.VEG_LEAFY_DILL),
    CollapsibleGridModel(
        icon: "vegetables/taro_leaves.png",
        label: "Taro Leaves",
        tagId: GroceryConstant.VEG_LEAFY_TARO),
    CollapsibleGridModel(
        icon: "vegetables/curry_leaves.png",
        label: "Curry Leaves",
        tagId: GroceryConstant.VEG_LEAFY_CURRY),
    CollapsibleGridModel(
        icon: "vegetables/lettuce_indian.png",
        label: "Lettuce Indian",
        tagId: GroceryConstant.VEG_LEAFY_LETTUCE_INDIAN),
  ];

  static final List<CollapsibleGridModel> rootVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/potato.png",
        label: "Potato",
        tagId: GroceryConstant.VEG_ROOT_POTATO),
    CollapsibleGridModel(
        icon: "vegetables/sweet_potato.png",
        label: "Sweet Potato",
        tagId: GroceryConstant.VEG_ROOT_SWEET_POTATO),
    CollapsibleGridModel(
        icon: "vegetables/carrot.png",
        label: "Carrot",
        tagId: GroceryConstant.VEG_ROOT_CARROT),
    CollapsibleGridModel(
        icon: "vegetables/radish.png",
        label: "Radish",
        tagId: GroceryConstant.VEG_ROOT_RADISH),
    CollapsibleGridModel(
        icon: "vegetables/beetroot.png",
        label: "Beetroot",
        tagId: GroceryConstant.VEG_ROOT_BEETROOT),
    CollapsibleGridModel(
        icon: "vegetables/turnip.png",
        label: "Turnip",
        tagId: GroceryConstant.VEG_ROOT_TURNIP),
    CollapsibleGridModel(
        icon: "vegetables/yam.png",
        label: "Yam",
        tagId: GroceryConstant.VEG_ROOT_YAM),
    CollapsibleGridModel(
        icon: "vegetables/taro_root.png",
        label: "Taro Root",
        tagId: GroceryConstant.VEG_ROOT_TARO),
    CollapsibleGridModel(
        icon: "vegetables/elephant_foot_yam.png",
        label: "Elephant\nFoot Yam",
        tagId: GroceryConstant.VEG_ROOT_ELEPHANT_FOOT_YAM),
    CollapsibleGridModel(
        icon: "vegetables/cassava.png",
        label: "Cassava",
        tagId: GroceryConstant.VEG_ROOT_CASSAVA),
    CollapsibleGridModel(
        icon: "vegetables/lotus_root.png",
        label: "Lotus Root",
        tagId: GroceryConstant.VEG_ROOT_LOTUS_ROOT),
  ];

  static final List<CollapsibleGridModel> bulbNdStemVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/onion.png",
        label: "Onion",
        tagId: GroceryConstant.VEG_BULB_ONION),
    CollapsibleGridModel(
        icon: "vegetables/garlic.png",
        label: "Garlic",
        tagId: GroceryConstant.VEG_BULB_GARLIC),
    CollapsibleGridModel(
        icon: "vegetables/leek.png",
        label: "Leek",
        tagId: GroceryConstant.VEG_STEM_LEEK),
    CollapsibleGridModel(
        icon: "vegetables/spring_onion.png",
        label: "Spring Onion",
        tagId: GroceryConstant.VEG_STEM_SPRING_ONION),
    CollapsibleGridModel(
        icon: "vegetables/banana_stem.png",
        label: "Banana Stem",
        tagId: GroceryConstant.VEG_STEM_BANANA),
    CollapsibleGridModel(
        icon: "vegetables/colocasia_stem.png",
        label: "Colocasia Stem",
        tagId: GroceryConstant.VEG_STEM_COLOCASIA),
  ];

  static final List<CollapsibleGridModel> fruitVegetables = [
    CollapsibleGridModel(icon: "vegetables/tomato.png", label: "Tomato", tagId: GroceryConstant.VEG_FRUIT_TOMATO),
    CollapsibleGridModel(icon: "vegetables/brinjal.png", label: "Brinjal Eggplant", tagId: GroceryConstant.VEG_FRUIT_BRINJAL),
    CollapsibleGridModel(icon: "vegetables/bottle_gourd.png", label: "Bottle Gourd", tagId: GroceryConstant.VEG_GOURD_BOTTLE),
    CollapsibleGridModel(icon: "vegetables/bitter_gourd.png", label: "Bitter Gourd", tagId: GroceryConstant.VEG_GOURD_BITTER),
    CollapsibleGridModel(icon: "vegetables/ridge_gourd.png", label: "Ridge Gourd", tagId: GroceryConstant.VEG_GOURD_RIDGE),
    CollapsibleGridModel(icon: "vegetables/sponge_gourd.png", label: "Sponge Gourd", tagId: GroceryConstant.VEG_GOURD_SPONGE),
    CollapsibleGridModel(icon: "vegetables/snake_gourd.png", label: "Snake Gourd", tagId: GroceryConstant.VEG_GOURD_SNAKE),
    CollapsibleGridModel(icon: "vegetables/pumpkin.png", label: "Pumpkin", tagId: GroceryConstant.VEG_FRUIT_PUMPKIN),
    CollapsibleGridModel(icon: "vegetables/cucumber.png", label: "Cucumber", tagId: GroceryConstant.VEG_FRUIT_CUCUMBER),
    CollapsibleGridModel(icon: "vegetables/ash_gourd.png", label: "Ash Gourd", tagId: GroceryConstant.VEG_GOURD_ASH),
    CollapsibleGridModel(icon: "vegetables/pointed_gourd.png", label: "Pointed Gourd", tagId: GroceryConstant.VEG_GOURD_POINTED),
    CollapsibleGridModel(icon: "vegetables/ivy_gourd.png", label: "Ivy Gourd", tagId: GroceryConstant.VEG_GOURD_IVY),
    CollapsibleGridModel(icon: "vegetables/tinda.png", label: "Tinda", tagId: GroceryConstant.VEG_FRUIT_TINDA),
    CollapsibleGridModel(icon: "vegetables/chow_chow.png", label: "Chow Chow\nChayote", tagId: GroceryConstant.VEG_FRUIT_CHOW_CHOW),
    CollapsibleGridModel(icon: "vegetables/raw_banana.png", label: "Raw Banana", tagId: GroceryConstant.VEG_RAW_BANANA),
    CollapsibleGridModel(icon: "vegetables/raw_papaya.png", label: "Raw Papaya", tagId: GroceryConstant.VEG_RAW_PAPAYA),
    CollapsibleGridModel(icon: "vegetables/capsicum.png", label: "Capsicum Bell Pepper", tagId: GroceryConstant.VEG_FRUIT_CAPSICUM),
  ];

  static final List<CollapsibleGridModel> podNdBeansVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/green_peas.png",
        label: "Green Peas",
        tagId: GroceryConstant.VEG_POD_GREEN_PEAS),
    CollapsibleGridModel(
        icon: "vegetables/french_beans.png",
        label: "French Beans",
        tagId: GroceryConstant.VEG_BEAN_FRENCH),
    CollapsibleGridModel(
        icon: "vegetables/cluster_beans.png",
        label: "Cluster Beans",
        tagId: GroceryConstant.VEG_BEAN_CLUSTER),
    CollapsibleGridModel(
        icon: "vegetables/cowpea.png",
        label: "Cowpea",
        tagId: GroceryConstant.VEG_BEAN_COWPEA),
    CollapsibleGridModel(
        icon: "vegetables/hyacinth_beans.png",
        label: "Hyacinth Beans",
        tagId: GroceryConstant.VEG_BEAN_HYACINTH),
    CollapsibleGridModel(
        icon: "vegetables/broad_beans.png",
        label: "Broad Beans",
        tagId: GroceryConstant.VEG_BEAN_BROAD),
    CollapsibleGridModel(
        icon: "vegetables/winged_beans.png",
        label: "Winged Beans",
        tagId: GroceryConstant.VEG_BEAN_WINGED),
    CollapsibleGridModel(
        icon: "vegetables/yardlong_beans.png",
        label: "Yardlong Beans",
        tagId: GroceryConstant.VEG_BEAN_YARDLONG),
  ];

  static final List<CollapsibleGridModel> flowerVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/cauliflower.png",
        label: "Cauliflower",
        tagId: GroceryConstant.VEG_FLOWER_CAULIFLOWER),
    CollapsibleGridModel(
        icon: "vegetables/broccoli.png",
        label: "Broccoli",
        tagId: GroceryConstant.VEG_FLOWER_BROCCOLI),
    CollapsibleGridModel(
        icon: "vegetables/banana_flower.png",
        label: "Banana Flower",
        tagId: GroceryConstant.VEG_FLOWER_BANANA),
    CollapsibleGridModel(
        icon: "vegetables/pumpkin_flower.png",
        label: "Pumpkin Flower",
        tagId: GroceryConstant.VEG_FLOWER_PUMPKIN),
    CollapsibleGridModel(
        icon: "vegetables/drumstick_flower.png",
        label: "Drumstick Flower",
        tagId: GroceryConstant.VEG_FLOWER_DRUMSTICK),
  ];

  static final List<CollapsibleGridModel> fungiNdSpecialIndianItems = [
    CollapsibleGridModel(
        icon: "vegetables/mushroom.png",
        label: "Mushroom",
        tagId: GroceryConstant.VEG_FUNGI_MUSHROOM),
    CollapsibleGridModel(
        icon: "vegetables/green_chilli.png",
        label: "Green Chilli",
        tagId: GroceryConstant.VEG_SPECIAL_GREEN_CHILLI),
    CollapsibleGridModel(
        icon: "vegetables/ginger.png",
        label: "Ginger",
        tagId: GroceryConstant.VEG_SPECIAL_GINGER),
    CollapsibleGridModel(
        icon: "vegetables/turmeric_fresh.png",
        label: "Turmeric Fresh",
        tagId: GroceryConstant.VEG_SPECIAL_TURMERIC_FRESH),
    CollapsibleGridModel(
        icon: "vegetables/drumstick.png",
        label: "Drumstick",
        tagId: GroceryConstant.VEG_SPECIAL_DRUMSTICK),
    CollapsibleGridModel(
        icon: "vegetables/raw_jackfruit.png",
        label: "Raw Jackfruit",
        tagId: GroceryConstant.VEG_SPECIAL_RAW_JACKFRUIT),
    CollapsibleGridModel(
        icon: "vegetables/bamboo_shoot.png",
        label: "Bamboo Shoot",
        tagId: GroceryConstant.VEG_SPECIAL_BAMBOO_SHOOT),
    CollapsibleGridModel(
        icon: "vegetables/kokum.png",
        label: "Kokum",
        tagId: GroceryConstant.VEG_SPECIAL_KOKUM),
    CollapsibleGridModel(
        icon: "vegetables/sundakkai.png",
        label: "Sundakkai\nTurkey Berry",
        tagId: GroceryConstant.VEG_SPECIAL_SUNDAKKAI),
  ];

  static final List<CollapsibleGridModel> exoticAndSpecialty = [
    CollapsibleGridModel(
        icon: "vegetables/zucchini.png",
        label: "Zucchini",
        tagId: GroceryConstant.VEG_EXOTIC_ZUCCHINI),
    CollapsibleGridModel(
        icon: "vegetables/celery.png",
        label: "Celery",
        tagId: GroceryConstant.VEG_EXOTIC_CELERY),
    CollapsibleGridModel(
        icon: "vegetables/asparagus.png",
        label: "Asparagus",
        tagId: GroceryConstant.VEG_EXOTIC_ASPARAGUS),
    CollapsibleGridModel(
        icon: "vegetables/bok_choy.png",
        label: "Bok Choy",
        tagId: GroceryConstant.VEG_EXOTIC_BOK_CHOY),
    CollapsibleGridModel(
        icon: "vegetables/lettuce_iceberg.png",
        label: "Lettuce Iceberg\nRomaine",
        tagId: GroceryConstant.VEG_EXOTIC_LETTUCE_ICEBERG),
    CollapsibleGridModel(
        icon: "vegetables/kale.png",
        label: "Kale",
        tagId: GroceryConstant.VEG_EXOTIC_KALE),
    CollapsibleGridModel(
        icon: "vegetables/chinese_cabbage.png",
        label: "Chinese Cabbage",
        tagId: GroceryConstant.VEG_EXOTIC_CHINESE_CABBAGE),
  ];

  /// FRUIT
  static final List<CollapsibleGridModel> dailyFruits = [
    CollapsibleGridModel(
        icon: "fruits/apple.png",
        label: "Apple",
        tagId: GroceryConstant.FRUIT_DAILY_APPLE),
    CollapsibleGridModel(
        icon: "fruits/banana.png",
        label: "Banana",
        tagId: GroceryConstant.FRUIT_DAILY_BANANA),
    CollapsibleGridModel(
        icon: "fruits/orange.png",
        label: "Orange",
        tagId: GroceryConstant.FRUIT_DAILY_ORANGE),
    CollapsibleGridModel(
        icon: "fruits/mosambi.png",
        label: "Mosambi Sweet\nLime",
        tagId: GroceryConstant.FRUIT_DAILY_MOSAMBI),
    CollapsibleGridModel(
        icon: "fruits/grapes.png",
        label: "Grapes",
        tagId: GroceryConstant.FRUIT_DAILY_GRAPES),
    CollapsibleGridModel(
        icon: "fruits/papaya.png",
        label: "Papaya",
        tagId: GroceryConstant.FRUIT_DAILY_PAPAYA),
    CollapsibleGridModel(
        icon: "fruits/pomegranate.png",
        label: "Pomegranate",
        tagId: GroceryConstant.FRUIT_DAILY_POMEGRANATE),
    CollapsibleGridModel(
        icon: "fruits/guava.png",
        label: "Guava",
        tagId: GroceryConstant.FRUIT_DAILY_GUAVA),
    CollapsibleGridModel(
        icon: "fruits/pear.png",
        label: "Pear",
        tagId: GroceryConstant.FRUIT_DAILY_PEAR),
    CollapsibleGridModel(
        icon: "fruits/chikoo.png",
        label: "Chikoo Sapota",
        tagId: GroceryConstant.FRUIT_DAILY_CHIKOO),
    CollapsibleGridModel(
        icon: "fruits/pineapple.png",
        label: "Pineapple",
        tagId: GroceryConstant.FRUIT_DAILY_PINEAPPLE),
    CollapsibleGridModel(
        icon: "fruits/watermelon.png",
        label: "Watermelon",
        tagId: GroceryConstant.FRUIT_DAILY_WATERMELON),
    CollapsibleGridModel(
        icon: "fruits/muskmelon.png",
        label: "Muskmelon",
        tagId: GroceryConstant.FRUIT_DAILY_MUSKMELON),
  ];

  static final List<CollapsibleGridModel> desiFruits = [
    CollapsibleGridModel(
        icon: "fruits/mango.png",
        label: "Mango",
        tagId: GroceryConstant.FRUIT_DESI_MANGO),
    CollapsibleGridModel(
        icon: "fruits/jackfruit.png",
        label: "Jackfruit",
        tagId: GroceryConstant.FRUIT_DESI_JACKFRUIT),
    CollapsibleGridModel(
        icon: "fruits/jamun.png",
        label: "Jamun",
        tagId: GroceryConstant.FRUIT_DESI_JAMUN),
    CollapsibleGridModel(
        icon: "fruits/custard_apple.png",
        label: "Custard Apple",
        tagId: GroceryConstant.FRUIT_DESI_CUSTARD_APPLE),
    CollapsibleGridModel(
        icon: "fruits/ber.png",
        label: "Ber Indian Jujube",
        tagId: GroceryConstant.FRUIT_DESI_BER),
    CollapsibleGridModel(
        icon: "fruits/soursop.png",
        label: "Soursop",
        tagId: GroceryConstant.FRUIT_DESI_SOURSOP),
    CollapsibleGridModel(
        icon: "fruits/wood_apple.png",
        label: "Wood Apple Bael",
        tagId: GroceryConstant.FRUIT_DESI_WOOD_APPLE),
    CollapsibleGridModel(
        icon: "fruits/tamarind.png",
        label: "Tamarind",
        tagId: GroceryConstant.FRUIT_DESI_TAMARIND),
    CollapsibleGridModel(
        icon: "fruits/monkey_jack.png",
        label: "Monkey Jack",
        tagId: GroceryConstant.FRUIT_DESI_MONKEY_JACK),
    CollapsibleGridModel(
        icon: "fruits/fig.png",
        label: "Indian Fig Anjeer",
        tagId: GroceryConstant.FRUIT_DESI_FIG),
    CollapsibleGridModel(
        icon: "fruits/khirni.png",
        label: "Khirni Rayan",
        tagId: GroceryConstant.FRUIT_DESI_KHIRNI),
    CollapsibleGridModel(
        icon: "fruits/karonda.png",
        label: "Karonda",
        tagId: GroceryConstant.FRUIT_DESI_KARONDA),
    CollapsibleGridModel(
        icon: "fruits/amla.png",
        label: "Indian\nGooseberry Amla",
        tagId: GroceryConstant.FRUIT_DESI_AMLA),
  ];

  static final List<CollapsibleGridModel> sourAndStoneFruits = [
    CollapsibleGridModel(
        icon: "fruits/lemon.png",
        label: "Lemon",
        tagId: GroceryConstant.FRUIT_SOUR_LEMON),
    CollapsibleGridModel(
        icon: "fruits/lime.png",
        label: "Lime",
        tagId: GroceryConstant.FRUIT_SOUR_LIME),
    CollapsibleGridModel(
        icon: "fruits/kinnow.png",
        label: "Kinnow",
        tagId: GroceryConstant.FRUIT_SOUR_KINNOW),
    CollapsibleGridModel(
        icon: "fruits/pomelo.png",
        label: "Pomelo",
        tagId: GroceryConstant.FRUIT_SOUR_POMELO),
    CollapsibleGridModel(
        icon: "fruits/citron.png",
        label: "Citron",
        tagId: GroceryConstant.FRUIT_SOUR_CITRON),
    CollapsibleGridModel(
        icon: "fruits/galgal.png",
        label: "Galgal",
        tagId: GroceryConstant.FRUIT_SOUR_GALGAL),
    CollapsibleGridModel(
        icon: "fruits/peach.png",
        label: "Peach",
        tagId: GroceryConstant.FRUIT_STONE_PEACH),
    CollapsibleGridModel(
        icon: "fruits/plum.png",
        label: "Plum",
        tagId: GroceryConstant.FRUIT_STONE_PLUM),
    CollapsibleGridModel(
        icon: "fruits/apricot.png",
        label: "Apricot",
        tagId: GroceryConstant.FRUIT_STONE_APRICOT),
    CollapsibleGridModel(
        icon: "fruits/cherry.png",
        label: "Cherry",
        tagId: GroceryConstant.FRUIT_STONE_CHERRY),
  ];

  static final List<CollapsibleGridModel> smallNdSeasonalFruits = [
    CollapsibleGridModel(
        icon: "fruits/strawberry.png",
        label: "Strawberry",
        tagId: GroceryConstant.FRUIT_SEASONAL_STRAWBERRY),
    CollapsibleGridModel(
        icon: "fruits/mulberry.png",
        label: "Mulberry",
        tagId: GroceryConstant.FRUIT_SEASONAL_MULBERRY),
    CollapsibleGridModel(
        icon: "fruits/raspberry.png",
        label: "Raspberry",
        tagId: GroceryConstant.FRUIT_SEASONAL_RASPBERRY),
    CollapsibleGridModel(
        icon: "fruits/blueberry.png",
        label: "Blueberry",
        tagId: GroceryConstant.FRUIT_SEASONAL_BLUEBERRY),
    CollapsibleGridModel(
        icon: "fruits/phalsa.png",
        label: "Phalsa",
        tagId: GroceryConstant.FRUIT_SEASONAL_PHALSA),
    CollapsibleGridModel(
        icon: "fruits/litchi.png",
        label: "Litchi",
        tagId: GroceryConstant.FRUIT_SEASONAL_LITCHI),
    CollapsibleGridModel(
        icon: "fruits/loquat.png",
        label: "Loquat",
        tagId: GroceryConstant.FRUIT_SEASONAL_LOQUAT),
    CollapsibleGridModel(
        icon: "fruits/star_fruit.png",
        label: "Star Fruit\nCarambola",
        tagId: GroceryConstant.FRUIT_SEASONAL_STAR_FRUIT),
    CollapsibleGridModel(
        icon: "fruits/capsicum.png",
        label: "Capsicum Bell\nPepper",
        tagId: GroceryConstant.FRUIT_SEASONAL_Capsicum_Bell_PEPPER),
  ];

  static final List<CollapsibleGridModel> forestNdCoastalFruits = [
    CollapsibleGridModel(
        icon: "fruits/coconut.png",
        label: "Coconut",
        tagId: GroceryConstant.FRUIT_COASTAL_COCONUT),
    CollapsibleGridModel(
        icon: "fruits/tender_coconut.png",
        label: "Tender Coconut",
        tagId: GroceryConstant.FRUIT_COASTAL_TENDER_COCONUT),
    CollapsibleGridModel(
        icon: "fruits/ice_apple.png",
        label: "Palmyra Fruit\nIce Apple",
        tagId: GroceryConstant.FRUIT_COASTAL_ICE_APPLE),
    CollapsibleGridModel(
        icon: "fruits/toddy_palm.png",
        label: "Toddy Palm Fruit",
        tagId: GroceryConstant.FRUIT_COASTAL_TODDY_PALM),
    CollapsibleGridModel(
        icon: "fruits/nungu.png",
        label: "Nungu",
        tagId: GroceryConstant.FRUIT_COASTAL_NUNGU),
    CollapsibleGridModel(
        icon: "fruits/fresh_dates.png",
        label: "Date",
        tagId: GroceryConstant.FRUIT_FOREST_DATE),
    CollapsibleGridModel(
        icon: "fruits/mahua.png",
        label: "Mahua Fruit",
        tagId: GroceryConstant.FRUIT_FOREST_MAHUA),
    CollapsibleGridModel(
        icon: "fruits/chironji_fruit.png",
        label: "Chironji Fruit",
        tagId: GroceryConstant.FRUIT_FOREST_CHIRONJI),
    CollapsibleGridModel(
        icon: "fruits/tendu_fruit.png",
        label: "Tendu Fruit",
        tagId: GroceryConstant.FRUIT_FOREST_TENDU),
    CollapsibleGridModel(
        icon: "fruits/kaafal.png",
        label: "Kaafal",
        tagId: GroceryConstant.FRUIT_FOREST_KAAFAL),
    CollapsibleGridModel(
        icon: "fruits/wild_jamun.png",
        label: "Wild Jamun",
        tagId: GroceryConstant.FRUIT_FOREST_WILD_JAMUN),
    CollapsibleGridModel(
        icon: "fruits/wild_banana.png",
        label: "Wild Banana",
        tagId: GroceryConstant.FRUIT_FOREST_WILD_BANANA),
    CollapsibleGridModel(
        icon: "fruits/breadfruit.png",
        label: "Breadfruit",
        tagId: GroceryConstant.FRUIT_COASTAL_BREADFRUIT),
  ];

  static final List<CollapsibleGridModel> specialNdExoticFruits = [
    CollapsibleGridModel(
        icon: "fruits/kiwi.png",
        label: "Kiwi",
        tagId: GroceryConstant.FRUIT_EXOTIC_KIWI),
    CollapsibleGridModel(
        icon: "fruits/dragon_fruit.png",
        label: "Dragon Fruit",
        tagId: GroceryConstant.FRUIT_EXOTIC_DRAGON),
    CollapsibleGridModel(
        icon: "fruits/avocado.png",
        label: "Avocado",
        tagId: GroceryConstant.FRUIT_EXOTIC_AVOCADO),
    CollapsibleGridModel(
        icon: "fruits/passion_fruit.png",
        label: "Passion Fruit",
        tagId: GroceryConstant.FRUIT_EXOTIC_PASSION),
    CollapsibleGridModel(
        icon: "fruits/mangosteen.png",
        label: "Mangosteen",
        tagId: GroceryConstant.FRUIT_EXOTIC_MANGOSTEEN),
    CollapsibleGridModel(
        icon: "fruits/longan.png",
        label: "Longan",
        tagId: GroceryConstant.FRUIT_EXOTIC_LONGAN),
    CollapsibleGridModel(
        icon: "fruits/rambutan.png",
        label: "Rambutan",
        tagId: GroceryConstant.FRUIT_EXOTIC_RAMBUTAN),
    CollapsibleGridModel(
        icon: "fruits/durian.png",
        label: "Durian",
        tagId: GroceryConstant.FRUIT_EXOTIC_DURIAN),
  ];


  /// BAKERY & NAMKEEN ITEMS
  // Namkeen & Mixture List
  static final List<CollapsibleGridModel> namkeenAndMixture = [
    CollapsibleGridModel(icon: "bakery_snacks_items/aloo_bhujia.png", label: "Aloo Bhujia", tagId: GroceryConstant.SNACK_NAMKEEN_ALOO_BHUJIA),
    CollapsibleGridModel(icon: "bakery_snacks_items/sev.png", label: "Sev", tagId: GroceryConstant.SNACK_NAMKEEN_SEV),
    CollapsibleGridModel(icon: "bakery_snacks_items/mixture.png", label: "Mixture", tagId: GroceryConstant.SNACK_NAMKEEN_MIXTURE),
    CollapsibleGridModel(icon: "bakery_snacks_items/boondi.png", label: "Boondi", tagId: GroceryConstant.SNACK_NAMKEEN_BOONDI),
    CollapsibleGridModel(icon: "bakery_snacks_items/moong_dal.png", label: "Moong Dal\nNamkeen", tagId: GroceryConstant.SNACK_NAMKEEN_MOONG_DAL),
    CollapsibleGridModel(icon: "bakery_snacks_items/chana_dal.png", label: "Chana Dal\nNamkeen", tagId: GroceryConstant.SNACK_NAMKEEN_CHANA_DAL),
    CollapsibleGridModel(icon: "bakery_snacks_items/peanuts.png", label: "Peanuts\nNamkeen", tagId: GroceryConstant.SNACK_NAMKEEN_PEANUTS),
    CollapsibleGridModel(icon: "bakery_snacks_items/ghatiya.png", label: "Ghatiya", tagId: GroceryConstant.SNACK_GHATIYA),
    CollapsibleGridModel(icon: "bakery_snacks_items/farsan.png", label: "Farsan Mix", tagId: GroceryConstant.SNACK_NAMKEEN_FARSAN),
  ];

  // Chips, Papad & Fryums List
  static final List<CollapsibleGridModel> chipsPapadFryums = [
    CollapsibleGridModel(icon: "bakery_snacks_items/potato_chips.png", label: "Potato Chips", tagId: GroceryConstant.SNACK_CHIPS_POTATO),
    CollapsibleGridModel(icon: "bakery_snacks_items/banana_chips.png", label: "Banana Chips", tagId: GroceryConstant.SNACK_CHIPS_BANANA),
    CollapsibleGridModel(icon: "bakery_snacks_items/tapioca_chips.png", label: "Tapioca Chips", tagId: GroceryConstant.SNACK_CHIPS_TAPIOCA),
    CollapsibleGridModel(icon: "bakery_snacks_items/corn_chips.png", label: "Corn Chips", tagId: GroceryConstant.SNACK_CHIPS_CORN),
    CollapsibleGridModel(icon: "bakery_snacks_items/multigrain_chips.png", label: "Multigrain Chips", tagId: GroceryConstant.SNACK_CHIPS_MULTIGRAIN),
    CollapsibleGridModel(icon: "bakery_snacks_items/nacho_chips.png", label: "Nacho Chips", tagId: GroceryConstant.SNACK_CHIPS_NACHO),
    CollapsibleGridModel(icon: "bakery_snacks_items/urad_papad.png", label: "Urad Papad", tagId: GroceryConstant.SNACK_PAPAD_URAD),
    CollapsibleGridModel(icon: "bakery_snacks_items/rice_papad.png", label: "Rice Papad", tagId: GroceryConstant.SNACK_PAPAD_RICE),
    CollapsibleGridModel(icon: "bakery_snacks_items/sabudana_papad.png", label: "Sabudana Papad", tagId: GroceryConstant.SNACK_PAPAD_SABUDANA),
    CollapsibleGridModel(icon: "bakery_snacks_items/appalam.png", label: "Appalam", tagId: GroceryConstant.SNACK_PAPAD_APPALAM),
    CollapsibleGridModel(icon: "bakery_snacks_items/fryums.png", label: "Fryums", tagId: GroceryConstant.SNACK_FRYUMS),
  ];

  // Biscuits & Cookies
  static final List<CollapsibleGridModel> biscuitsCookies = [
    CollapsibleGridModel(icon: "bakery_snacks_items/glucose.png", label: "Glucose Biscuits", tagId: GroceryConstant.BISCUIT_GLUCOSE),
    CollapsibleGridModel(icon: "bakery_snacks_items/marie.png", label: "Marie Biscuits", tagId: GroceryConstant.BISCUIT_MARIE),
    CollapsibleGridModel(icon: "bakery_snacks_items/milk.png", label: "Milk Biscuits", tagId: GroceryConstant.BISCUIT_MILK),
    CollapsibleGridModel(icon: "bakery_snacks_items/cream.png", label: "Cream Biscuits", tagId: GroceryConstant.BISCUIT_CREAM),
    CollapsibleGridModel(icon: "bakery_snacks_items/arrowroot.png", label: "Arrowroot\nBiscuits", tagId: GroceryConstant.BISCUIT_ARROWROOT),
    CollapsibleGridModel(icon: "bakery_snacks_items/sandwich.png", label: "Sandwich\nBiscuits", tagId: GroceryConstant.BISCUIT_SANDWICH),
    CollapsibleGridModel(icon: "bakery_snacks_items/multigrain.png", label: "Multigrain\nBiscuits", tagId: GroceryConstant.BISCUIT_MULTIGRAIN),
    CollapsibleGridModel(icon: "bakery_snacks_items/digestive.png", label: "Digestive\nBiscuits", tagId: GroceryConstant.BISCUIT_DIGESTIVE),
    CollapsibleGridModel(icon: "bakery_snacks_items/jeera.png", label: "Jeera Biscuits", tagId: GroceryConstant.BISCUIT_JEERA),
    CollapsibleGridModel(icon: "bakery_snacks_items/butter.png", label: "Butter Biscuits", tagId: GroceryConstant.BISCUIT_BUTTER),
    CollapsibleGridModel(icon: "bakery_snacks_items/jam.png", label: "Jam Biscuits", tagId: GroceryConstant.BISCUIT_JAM),
  ];

  // Bread, Bakery & Sweet Items
  static final List<CollapsibleGridModel> bakeryItems = [
    CollapsibleGridModel(icon: "bakery_snacks_items/white_bread.png", label: "White Bread", tagId: GroceryConstant.BAKERY_WHITE_BREAD),
    CollapsibleGridModel(icon: "bakery_snacks_items/brown_bread.png", label: "Brown Bread", tagId: GroceryConstant.BAKERY_BROWN_BREAD),
    CollapsibleGridModel(icon: "bakery_snacks_items/multigrain_bread.png", label: "Multigrain Bread", tagId: GroceryConstant.BAKERY_MULTIGRAIN_BREAD),
    CollapsibleGridModel(icon: "bakery_snacks_items/pav.png", label: "Pav Bread", tagId: GroceryConstant.BAKERY_PAV),
    CollapsibleGridModel(icon: "bakery_snacks_items/burger_buns.png", label: "Burger Buns", tagId: GroceryConstant.BAKERY_BURGER_BUNS),
    CollapsibleGridModel(icon: "bakery_snacks_items/pizza_base.png", label: "Pizza Base", tagId: GroceryConstant.BAKERY_PIZZA_BASE),
    CollapsibleGridModel(icon: "bakery_snacks_items/bread_crumbs.png", label: "Bread Crumbs", tagId: GroceryConstant.BAKERY_BREAD_CRUMBS),
    CollapsibleGridModel(icon: "bakery_snacks_items/khari.png", label: "Khari Biscuit", tagId: GroceryConstant.BAKERY_KHARI),
    CollapsibleGridModel(icon: "bakery_snacks_items/rusk.png", label: "Rusk", tagId: GroceryConstant.BAKERY_RUSK),
    CollapsibleGridModel(icon: "bakery_snacks_items/cake.png", label: "Cake", tagId: GroceryConstant.BAKERY_CAKE),
    CollapsibleGridModel(icon: "bakery_snacks_items/cup_cake.png", label: "Cup Cake", tagId: GroceryConstant.BAKERY_CUP_CAKE),
    CollapsibleGridModel(icon: "bakery_snacks_items/muffins.png", label: "Muffins", tagId: GroceryConstant.BAKERY_MUFFINS),
    CollapsibleGridModel(icon: "bakery_snacks_items/swiss_roll.png", label: "Swiss Roll", tagId: GroceryConstant.BAKERY_SWISS_ROLL),
  ];

  // Fried & Hot Snacks
  static final List<CollapsibleGridModel> friedHotSnacks = [
    CollapsibleGridModel(icon: "bakery_snacks_items/samosa.png", label: "Samosa", tagId: GroceryConstant.SNACK_HOT_SAMOSA),
    CollapsibleGridModel(icon: "bakery_snacks_items/veg_puff.png", label: "Veg Puff", tagId: GroceryConstant.SNACK_HOT_VEG_PUFF),
    CollapsibleGridModel(icon: "bakery_snacks_items/veg_patties.png", label: "Veg Patties", tagId: GroceryConstant.SNACK_HOT_VEG_PATTIES),
    CollapsibleGridModel(icon: "bakery_snacks_items/pizza_patties.png", label: "Pizza Patties", tagId: GroceryConstant.SNACK_HOT_PIZZA_PATTIES),
    CollapsibleGridModel(icon: "bakery_snacks_items/veg_cutlet.png", label: "Veg Cutlet", tagId: GroceryConstant.SNACK_HOT_VEG_CUTLET),
    CollapsibleGridModel(icon: "bakery_snacks_items/bread_roll.png", label: "Bread Roll", tagId: GroceryConstant.SNACK_HOT_BREAD_ROLL),
    CollapsibleGridModel(icon: "bakery_snacks_items/spring_roll.png", label: "Spring Roll", tagId: GroceryConstant.SNACK_HOT_SPRING_ROLL),
    CollapsibleGridModel(icon: "bakery_snacks_items/dry_kachori.png", label: "Dry Kachori", tagId: GroceryConstant.SNACK_HOT_DRY_KACHORI),
    CollapsibleGridModel(icon: "bakery_snacks_items/khakhra.png", label: "Khakhra", tagId: GroceryConstant.SNACK_DRY_KHAKHRA),
    CollapsibleGridModel(icon: "bakery_snacks_items/chakli.png", label: "Chakli", tagId: GroceryConstant.SNACK_DRY_CHAKLI),
    CollapsibleGridModel(icon: "bakery_snacks_items/murukku.png", label: "Murukku", tagId: GroceryConstant.SNACK_DRY_MURUKKU),
    CollapsibleGridModel(icon: "bakery_snacks_items/popcorn.png", label: "Popcorn", tagId: GroceryConstant.SNACK_DRY_POPCORN),
  ];


  /// DAIRY & FROZEN ITEMS
  // Milk List
  static final List<CollapsibleGridModel> milkList = [
    CollapsibleGridModel(icon: "dairy_items/full_cream_milk.png", label: "Full Cream Milk", tagId: GroceryConstant.DAIRY_MILK_FULL_CREAM),
    CollapsibleGridModel(icon: "dairy_items/toned_milk.png", label: "Toned Milk", tagId: GroceryConstant.DAIRY_MILK_TONED),
    CollapsibleGridModel(icon: "dairy_items/double_toned_milk.png", label: "Double Toned\nMilk", tagId: GroceryConstant.DAIRY_MILK_DOUBLE_TONED),
    CollapsibleGridModel(icon: "dairy_items/skimmed_milk.png", label: "Skimmed Milk", tagId: GroceryConstant.DAIRY_MILK_SKIMMED),
    CollapsibleGridModel(icon: "dairy_items/cow_milk.png", label: "Cow Milk", tagId: GroceryConstant.DAIRY_MILK_COW),
    CollapsibleGridModel(icon: "dairy_items/buffalo_milk.png", label: "Buffalo Milk", tagId: GroceryConstant.DAIRY_MILK_BUFFALO),
    CollapsibleGridModel(icon: "dairy_items/flavoured_milk.png", label: "Flavoured Milk", tagId: GroceryConstant.DAIRY_MILK_FLAVOURED),
    CollapsibleGridModel(icon: "dairy_items/lactose_free_milk.png", label: "Lactose Free\nMilk", tagId: GroceryConstant.DAIRY_MILK_LACTOSE_FREE),
  ];

  // Curd, Buttermilk and Cream List
  static final List<CollapsibleGridModel> curdButtermilkCreamList = [
    CollapsibleGridModel(icon: "dairy_items/fresh_curd.png", label: "Fresh Curd", tagId: GroceryConstant.DAIRY_CURD_FRESH),
    CollapsibleGridModel(icon: "dairy_items/set_curd.png", label: "Set Curd", tagId: GroceryConstant.DAIRY_CURD_SET),
    CollapsibleGridModel(icon: "dairy_items/greek_yogurt.png", label: "Greek Yogurt", tagId: GroceryConstant.DAIRY_YOGURT_GREEK),
    CollapsibleGridModel(icon: "dairy_items/flavoured_yogurt.png", label: "Flavoured Yogurt", tagId: GroceryConstant.DAIRY_YOGURT_FLAVOURED),
    CollapsibleGridModel(icon: "dairy_items/butter_milk.png", label: "Butter Milk", tagId: GroceryConstant.DAIRY_BUTTER_MILK),
    CollapsibleGridModel(icon: "dairy_items/namkeen_chaas.png", label: "Namkeen Chhaach", tagId: GroceryConstant.DAIRY_CHAAS_NAMKEEN),
    CollapsibleGridModel(icon: "dairy_items/lassi.png", label: "Lassi", tagId: GroceryConstant.DAIRY_LASSI),
    CollapsibleGridModel(icon: "dairy_items/fresh_cream.png", label: "Fresh Cream", tagId: GroceryConstant.DAIRY_CREAM_FRESH),
    CollapsibleGridModel(icon: "dairy_items/cooking_cream.png", label: "Cooking Cream", tagId: GroceryConstant.DAIRY_CREAM_COOKING),
    CollapsibleGridModel(icon: "dairy_items/whipping_cream.png", label: "Whipping Cream", tagId: GroceryConstant.DAIRY_CREAM_WHIPPING),
  ];

  // Butter, Cheese and Paneer List
  static final List<CollapsibleGridModel> butterCheesePaneerList = [
    CollapsibleGridModel(icon: "dairy_items/table_butter.png", label: "Table Butter", tagId: GroceryConstant.DAIRY_BUTTER_TABLE),
    CollapsibleGridModel(icon: "dairy_items/white_butter.png", label: "White Butter", tagId: GroceryConstant.DAIRY_BUTTER_WHITE),
    CollapsibleGridModel(icon: "dairy_items/salted_butter.png", label: "Salted Butter", tagId: GroceryConstant.DAIRY_BUTTER_SALTED),
    CollapsibleGridModel(icon: "dairy_items/unsalted_butter.png", label: "Unsalted Butter", tagId: GroceryConstant.DAIRY_BUTTER_UNSALTED),
    CollapsibleGridModel(icon: "dairy_items/cheese_slices.png", label: "Cheese Slices", tagId: GroceryConstant.DAIRY_CHEESE_SLICES),
    CollapsibleGridModel(icon: "dairy_items/cheese_blocks.png", label: "Cheese Blocks", tagId: GroceryConstant.DAIRY_CHEESE_BLOCKS),
    CollapsibleGridModel(icon: "dairy_items/cheese_spread.png", label: "Cheese Spread", tagId: GroceryConstant.DAIRY_CHEESE_SPREAD),
    CollapsibleGridModel(icon: "dairy_items/fresh_paneer.png", label: "Fresh Paneer", tagId: GroceryConstant.DAIRY_PANEER_FRESH),
    CollapsibleGridModel(icon: "dairy_items/malai_paneer.png", label: "Malai Paneer", tagId: GroceryConstant.DAIRY_PANEER_MALAI),
    CollapsibleGridModel(icon: "dairy_items/frozen_paneer.png", label: "Frozen Paneer", tagId: GroceryConstant.DAIRY_PANEER_FROZEN),
  ];

  // Ghee and Dairy Fats List
  static final List<CollapsibleGridModel> gheeAndDairyFatsList = [
    CollapsibleGridModel(icon: "dairy_items/cow_ghee.png", label: "Cow Ghee", tagId: GroceryConstant.DAIRY_GHEE_COW),
    CollapsibleGridModel(icon: "dairy_items/buffalo_ghee.png", label: "Buffalo Ghee", tagId: GroceryConstant.DAIRY_GHEE_BUFFALO),
    CollapsibleGridModel(icon: "dairy_items/a2_ghee.png", label: "A2 Ghee", tagId: GroceryConstant.DAIRY_GHEE_A2),
    CollapsibleGridModel(icon: "dairy_items/organic_ghee.png", label: "Organic Ghee", tagId: GroceryConstant.DAIRY_GHEE_ORGANIC),
    CollapsibleGridModel(icon: "dairy_items/desi_ghee.png", label: "Desi Ghee", tagId: GroceryConstant.DAIRY_GHEE_DESI),
    CollapsibleGridModel(icon: "dairy_items/vanaspati.png", label: "Vanaspati", tagId: GroceryConstant.DAIRY_GHEE_VANASPATI),
  ];

  //Ice Cream and Frozen Desserts List
  static final List<CollapsibleGridModel> iceCreamFrozenDessertsList = [
    CollapsibleGridModel(icon: "dairy_items/ice_cream_cups.png", label: "Ice Cream Cups", tagId: GroceryConstant.FROZEN_ICE_CREAM_CUPS),
    CollapsibleGridModel(icon: "dairy_items/family_packs.png", label: "Ice Cream Family\nPacks", tagId: GroceryConstant.FROZEN_ICE_CREAM_FAMILY_PACKS),
    CollapsibleGridModel(icon: "dairy_items/ice_cream_bars.png", label: "Ice Cream Bars", tagId: GroceryConstant.FROZEN_ICE_CREAM_BARS),
    CollapsibleGridModel(icon: "dairy_items/ice_cream_cones.png", label: "Ice Cream Cones", tagId: GroceryConstant.FROZEN_ICE_CREAM_CONES),
    CollapsibleGridModel(icon: "dairy_items/kulfi.png", label: "Kulfi", tagId: GroceryConstant.FROZEN_KULFI),
    CollapsibleGridModel(icon: "dairy_items/malai_kulfi.png", label: "Malai Kulfi", tagId: GroceryConstant.FROZEN_MALAI_KULFI),
    CollapsibleGridModel(icon: "dairy_items/matka_kulfi.png", label: "Matka Kulfi", tagId: GroceryConstant.FROZEN_MATKA_KULFI),
    CollapsibleGridModel(icon: "dairy_items/frozen_yogurt.png", label: "Frozen Yogurt", tagId: GroceryConstant.FROZEN_YOGURT),
    CollapsibleGridModel(icon: "dairy_items/frozen_dessert.png", label: "Frozen Dessert", tagId: GroceryConstant.FROZEN_DESSERT),
    CollapsibleGridModel(icon: "dairy_items/ice_lollies.png", label: "Ice Lollies", tagId: GroceryConstant.FROZEN_ICE_LOLLIES),
    CollapsibleGridModel(icon: "dairy_items/cassata.png", label: "Cassata Ice\nCream", tagId: GroceryConstant.FROZEN_CASSATA),
    CollapsibleGridModel(icon: "dairy_items/ice_cream_sandwich.png", label: "Ice Cream\nSandwich", tagId: GroceryConstant.FROZEN_ICE_CREAM_SANDWICH),
    CollapsibleGridModel(icon: "dairy_items/fruit_sorbet.png", label: "Fruit Sorbet", tagId: GroceryConstant.FROZEN_FRUIT_SORBET),
    CollapsibleGridModel(icon: "dairy_items/gelato.png", label: "Gelato", tagId: GroceryConstant.FROZEN_GELATO),
  ];

  // Frozen Vegetables List
  static final List<CollapsibleGridModel> frozenVegetablesList = [
    CollapsibleGridModel(icon: "dairy_items/frozen_peas.png", label: "Frozen Green\nPeas", tagId: GroceryConstant.FROZEN_VEG_GREEN_PEAS),
    CollapsibleGridModel(icon: "dairy_items/frozen_corn.png", label: "Frozen Sweet\nCorn", tagId: GroceryConstant.FROZEN_VEG_SWEET_CORN),
    CollapsibleGridModel(icon: "dairy_items/frozen_mixed_veg.png", label: "Frozen Mixed\nVegetables", tagId: GroceryConstant.FROZEN_VEG_MIXED),
    CollapsibleGridModel(icon: "dairy_items/frozen_beans.png", label: "Frozen French\nBeans", tagId: GroceryConstant.FROZEN_VEG_FRENCH_BEANS),
    CollapsibleGridModel(icon: "dairy_items/frozen_carrot.png", label: "Frozen Carrot", tagId: GroceryConstant.FROZEN_VEG_CARROT),
    CollapsibleGridModel(icon: "dairy_items/frozen_spinach.png", label: "Frozen Spinach", tagId: GroceryConstant.FROZEN_VEG_SPINACH),
  ];

  //  Frozen Snacks & Meals List
  static final List<CollapsibleGridModel> frozenSnacksMealsList = [
    CollapsibleGridModel(icon: "dairy_items/french_fries.png", label: "Frozen French\nFries", tagId: GroceryConstant.FROZEN_SNACK_FRIES),
    CollapsibleGridModel(icon: "dairy_items/veg_nuggets.png", label: "Frozen Veg\nNuggets", tagId: GroceryConstant.FROZEN_SNACK_VEG_NUGGETS),
    CollapsibleGridModel(icon: "dairy_items/burger_patty.png", label: "Frozen Chicken\nNuggets", tagId: GroceryConstant.FROZEN_SNACK_CHICKEN_NUGGETS),
    CollapsibleGridModel(icon: "dairy_items/smileys.png", label: "Frozen Spring Rolls", tagId: GroceryConstant.FROZEN_SNACK_SPRING_ROLLS),
    CollapsibleGridModel(icon: "dairy_items/aloo_tikki.png", label: "Frozen Samosa", tagId: GroceryConstant.FROZEN_SNACK_SAMOSA),
    CollapsibleGridModel(icon: "dairy_items/paratha.png", label: "Frozen Paratha", tagId: GroceryConstant.FROZEN_SNACK_PARATHA),
    CollapsibleGridModel(icon: "dairy_items/momos.png", label: "Frozen Momos", tagId: GroceryConstant.FROZEN_SNACK_MOMOS),
    CollapsibleGridModel(icon: "dairy_items/spring_rolls.png", label: "Frozen Veg Cutlet", tagId: GroceryConstant.FROZEN_SNACK_SPRING_ROLLS),
  ];

  // Milk Powders and Dairy Alternatives List
  static final List<CollapsibleGridModel> milkPowdersAlternativesList = [
    CollapsibleGridModel(
        icon: "dairy_items/skimmed_milk_powder.png",
        label: "Skimmed Milk\nPowder",
        tagId: GroceryConstant.DAIRY_SKIMMED_MILK_POWDER),
    CollapsibleGridModel(
        icon: "dairy_items/full_cream_milk_powder.png",
        label: "Full Cream Milk\nPowder",
        tagId: GroceryConstant.DAIRY_FULL_CREAM_MILK_POWDER),
    CollapsibleGridModel(
        icon: "dairy_items/infant_formula.png",
        label: "Infant Milk\nFormula",
        tagId: GroceryConstant.DAIRY_INFANT_MILK_FORMULA),
    CollapsibleGridModel(
        icon: "dairy_items/condensed_milk.png",
        label: "Condensed Milk",
        tagId: GroceryConstant.DAIRY_CONDENSED_MILK),
    CollapsibleGridModel(
        icon: "dairy_items/evaporated_milk.png",
        label: "Evaporated Milk",
        tagId: GroceryConstant.DAIRY_EVAPORATED_MILK),
    CollapsibleGridModel(
        icon: "dairy_items/soy_milk.png",
        label: "Soy Milk",
        tagId: GroceryConstant.DAIRY_ALT_SOY_MILK),
    CollapsibleGridModel(
        icon: "dairy_items/almond_milk.png",
        label: "Almond Milk",
        tagId: GroceryConstant.DAIRY_ALT_ALMOND_MILK),
    CollapsibleGridModel(
        icon: "dairy_items/oats_milk.png",
        label: "Oats Milk",
        tagId: GroceryConstant.DAIRY_ALT_OATS_MILK),
  ];

}
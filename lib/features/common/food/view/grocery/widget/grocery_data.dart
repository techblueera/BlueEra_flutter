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
        icon: "basmati_rice.png",
        label: "Basmati Rice",
        tagId: GroceryConstant.RICE_BASMATI),
    CollapsibleGridModel(
        icon: "sona_masoori.png",
        label: "Sona Masoori Rice",
        tagId: GroceryConstant.RICE_SONA_MASOORI),
    CollapsibleGridModel(
        icon: "kolam_rice.png",
        label: "Kolam Rice",
        tagId: GroceryConstant.RICE_KOLAM),
    CollapsibleGridModel(
        icon: "ponni_rice.png",
        label: "Ponni Rice",
        tagId: GroceryConstant.RICE_PONNI),
    CollapsibleGridModel(
        icon: "parboiled_rice.png",
        label: "Parboiled Rice",
        tagId: GroceryConstant.RICE_PARBOILED),
    CollapsibleGridModel(
        icon: "brown_rice.png",
        label: "Brown Rice",
        tagId: GroceryConstant.RICE_BROWN),
    CollapsibleGridModel(
        icon: "red_rice.png",
        label: "Red Rice",
        tagId: GroceryConstant.RICE_RED),
    CollapsibleGridModel(
        icon: "black_rice.png",
        label: "Black Rice",
        tagId: GroceryConstant.RICE_BLACK),
  ];

  static const List<CollapsibleGridModel> wheatAndFlours = [
    CollapsibleGridModel(
        icon: "whole_wheat_atta.png",
        label: "Whole Wheat Atta",
        tagId: GroceryConstant.FLOUR_WHOLE_WHEAT),
    CollapsibleGridModel(
        icon: "chakki_atta.png",
        label: "Chakki Atta",
        tagId: GroceryConstant.FLOUR_CHAKKI_ATTA),
    CollapsibleGridModel(
        icon: "sharbati_atta.png",
        label: "Sharbati Atta",
        tagId: GroceryConstant.FLOUR_SHARBATI_ATTA),
    CollapsibleGridModel(
        icon: "multigrain_atta.png",
        label: "Multigrain Atta",
        tagId: GroceryConstant.FLOUR_MULTIGRAIN),
    CollapsibleGridModel(
        icon: "diabetic_atta.png",
        label: "Diabetic Friendly Atta",
        tagId: GroceryConstant.FLOUR_DIABETIC),
    CollapsibleGridModel(
        icon: "maida.png",
        label: "Maida",
        tagId: GroceryConstant.FLOUR_MAIDA),
    CollapsibleGridModel(
        icon: "besan.png",
        label: "Besan",
        tagId: GroceryConstant.FLOUR_BESAN),
    CollapsibleGridModel(
        icon: "rice_flour.png",
        label: "Rice Flour",
        tagId: GroceryConstant.FLOUR_RICE),
    CollapsibleGridModel(
        icon: "ragi_flour.png",
        label: "Ragi Flour",
        tagId: GroceryConstant.FLOUR_RAGI),
  ];

  static const List<CollapsibleGridModel> dalNdBeans = [
    CollapsibleGridModel(
        icon: "toor_dal.png",
        label: "Toor Dal",
        tagId: GroceryConstant.DAL_TOOR),
    CollapsibleGridModel(
        icon: "moong_dal.png",
        label: "Moong Dal",
        tagId: GroceryConstant.DAL_MOONG),
    CollapsibleGridModel(
        icon: "masoor_dal.png",
        label: "Masoor Dal",
        tagId: GroceryConstant.DAL_MASOOR),
    CollapsibleGridModel(
        icon: "urad_dal.png",
        label: "Urad Dal",
        tagId: GroceryConstant.DAL_URAD),
    CollapsibleGridModel(
        icon: "chana_dal.png",
        label: "Chana Dal",
        tagId: GroceryConstant.DAL_CHANA),
    CollapsibleGridModel(
        icon: "kabuli_chana.png",
        label: "Kabuli Chana",
        tagId: GroceryConstant.DAL_KABULI_CHANA),
    CollapsibleGridModel(
        icon: "kala_chana.png",
        label: "Kala Chana",
        tagId: GroceryConstant.DAL_KALA_CHANA),
    CollapsibleGridModel(
        icon: "rajma.png",
        label: "Rajma",
        tagId: GroceryConstant.DAL_RAJMA),
    CollapsibleGridModel(
        icon: "dry_green_peas.png",
        label: "Dry Green Peas",
        tagId: GroceryConstant.DAL_DRY_GREEN_PEAS),
  ];

  static const List<CollapsibleGridModel> milletsNdTraditionalGrains = [
    CollapsibleGridModel(
        icon: "ragi.png",
        label: "Ragi",
        tagId: GroceryConstant.MILLET_RAGI),
    CollapsibleGridModel(
        icon: "jowar.png",
        label: "Jowar",
        tagId: GroceryConstant.MILLET_JOWAR),
    CollapsibleGridModel(
        icon: "bajra.png",
        label: "Bajra",
        tagId: GroceryConstant.MILLET_BAJRA),
    CollapsibleGridModel(
        icon: "foxtail_millet.png",
        label: "Foxtail Millet",
        tagId: GroceryConstant.MILLET_FOXTAIL),
    CollapsibleGridModel(
        icon: "little_millet.png",
        label: "Little Millet",
        tagId: GroceryConstant.MILLET_LITTLE),
    CollapsibleGridModel(
        icon: "kodo_millet.png",
        label: "Kodo Millet",
        tagId: GroceryConstant.MILLET_KODO),
    CollapsibleGridModel(
        icon: "barnyard_millet.png",
        label: "Barnyard Millet",
        tagId: GroceryConstant.MILLET_BARNYARD),
    CollapsibleGridModel(
        icon: "samak_rice.png",
        label: "Samak Rice",
        tagId: GroceryConstant.RICE_SAMAK),
  ];

  static const List<CollapsibleGridModel> breakfastStaples = [
    CollapsibleGridModel(
        icon: "poha.png",
        label: "Poha",
        tagId: GroceryConstant.STAPLE_POHA),
    CollapsibleGridModel(
        icon: "aval.png",
        label: "Aval Rice Flakes",
        tagId: GroceryConstant.STAPLE_AVAL),
    CollapsibleGridModel(
        icon: "dalia.png",
        label: "Dalia Broken Wheat",
        tagId: GroceryConstant.STAPLE_DALIA),
    CollapsibleGridModel(
        icon: "oats.png",
        label: "Oats",
        tagId: GroceryConstant.STAPLE_OATS),
    CollapsibleGridModel(
        icon: "corn_grits.png",
        label: "Corn Grits",
        tagId: GroceryConstant.STAPLE_CORN_GRITS),
    CollapsibleGridModel(
        icon: "wheat_bran.png",
        label: "Wheat Bran",
        tagId: GroceryConstant.STAPLE_WHEAT_BRAN),
  ];

  static const List<CollapsibleGridModel> spicesAndMasala = [
    CollapsibleGridModel(
        icon: "cumin.png",
        label: "Cumin Seeds",
        tagId: GroceryConstant.SPICE_CUMIN_SEEDS),
    CollapsibleGridModel(
        icon: "coriander_seeds.png",
        label: "Coriander Seeds",
        tagId: GroceryConstant.SPICE_CORIANDER_SEEDS),
    CollapsibleGridModel(
        icon: "black_pepper.png",
        label: "Black Pepper",
        tagId: GroceryConstant.SPICE_BLACK_PEPPER),
    CollapsibleGridModel(
        icon: "green_cardamom.png",
        label: "Green Cardamom",
        tagId: GroceryConstant.SPICE_GREEN_CARDAMOM),
    CollapsibleGridModel(
        icon: "cloves.png",
        label: "Cloves",
        tagId: GroceryConstant.SPICE_CLOVES),
    CollapsibleGridModel(
        icon: "cinnamon.png",
        label: "Cinnamon",
        tagId: GroceryConstant.SPICE_CINNAMON),
    CollapsibleGridModel(
        icon: "turmeric.png",
        label: "Turmeric Powder",
        tagId: GroceryConstant.SPICE_TURMERIC_POWDER),
    CollapsibleGridModel(
        icon: "red_chilli.png",
        label: "Red Chilli Powder",
        tagId: GroceryConstant.SPICE_RED_CHILLI_POWDER),
    CollapsibleGridModel(
        icon: "coriander_powder.png",
        label: "Coriander Powder",
        tagId: GroceryConstant.SPICE_CORIANDER_POWDER),
    CollapsibleGridModel(
        icon: "garam_masala.png",
        label: "Garam Masala",
        tagId: GroceryConstant.MASALA_GARAM),
    CollapsibleGridModel(
        icon: "chaat_masala.png",
        label: "Chaat Masala",
        tagId: GroceryConstant.MASALA_CHAAT),
    CollapsibleGridModel(
        icon: "sambhar_masala.png",
        label: "Sambhar Masala",
        tagId: GroceryConstant.MASALA_SAMBHAR),
    CollapsibleGridModel(
        icon: "biryani_masala.png",
        label: "Biryani Masala",
        tagId: GroceryConstant.MASALA_BIRYANI),
    CollapsibleGridModel(
        icon: "chole_masala.png",
        label: "Chole Masala",
        tagId: GroceryConstant.MASALA_CHOLE),
  ];

  static const List<CollapsibleGridModel> saltNdSweeteners = [
    CollapsibleGridModel(
        icon: "iodized_salt.png",
        label: "Iodized Salt",
        tagId: GroceryConstant.SWEET_IODIZED_SALT),
    CollapsibleGridModel(
        icon: "rock_salt.png",
        label: "Rock Salt",
        tagId: GroceryConstant.SWEET_ROCK_SALT),
    CollapsibleGridModel(
        icon: "pink_salt.png",
        label: "Pink Salt",
        tagId: GroceryConstant.SWEET_PINK_SALT),
    CollapsibleGridModel(
        icon: "white_sugar.png",
        label: "White Sugar",
        tagId: GroceryConstant.SWEET_WHITE_SUGAR),
    CollapsibleGridModel(
        icon: "brown_sugar.png",
        label: "Brown Sugar",
        tagId: GroceryConstant.SWEET_BROWN_SUGAR),
    CollapsibleGridModel(
        icon: "jaggery.png",
        label: "Jaggery",
        tagId: GroceryConstant.SWEET_JAGGERY),
    CollapsibleGridModel(
        icon: "honey.png",
        label: "Honey",
        tagId: GroceryConstant.SWEET_HONEY),
    CollapsibleGridModel(
        icon: "sugar_free.png",
        label: "Sugar Free Sweetener",
        tagId: GroceryConstant.SWEET_SUGAR_FREE),
  ];

  static const List<CollapsibleGridModel> oilsAndFats = [
    CollapsibleGridModel(
        icon: "sunflower_oil.png",
        label: "Sunflower Oil",
        tagId: GroceryConstant.OIL_SUNFLOWER),
    CollapsibleGridModel(
        icon: "rice_bran_oil.png",
        label: "Rice Bran Oil",
        tagId: GroceryConstant.OIL_RICE_BRAN),
    CollapsibleGridModel(
        icon: "mustard_oil.png",
        label: "Mustard Oil",
        tagId: GroceryConstant.OIL_MUSTARD),
    CollapsibleGridModel(
        icon: "groundnut_oil.png",
        label: "Groundnut Oil",
        tagId: GroceryConstant.OIL_GROUNDNUT),
    CollapsibleGridModel(
        icon: "sesame_oil.png",
        label: "Sesame Oil",
        tagId: GroceryConstant.OIL_SESAME),
    CollapsibleGridModel(
        icon: "coconut_oil.png",
        label: "Coconut Oil",
        tagId: GroceryConstant.OIL_COCONUT),
    CollapsibleGridModel(
        icon: "olive_oil.png",
        label: "Olive Oil",
        tagId: GroceryConstant.OIL_OLIVE),
    CollapsibleGridModel(
        icon: "cow_ghee.png",
        label: "Cow Ghee",
        tagId: GroceryConstant.GHEE_COW),
    CollapsibleGridModel(
        icon: "desi_ghee.png",
        label: "Desi Ghee",
        tagId: GroceryConstant.GHEE_DESI),
    ];

  static const List<CollapsibleGridModel> teaCoffeeBeverages = [
    CollapsibleGridModel(
        icon: "assam_tea.png",
        label: "Assam Tea",
        tagId: GroceryConstant.BEV_ASSAM_TEA),
    CollapsibleGridModel(
        icon: "green_tea.png",
        label: "Green Tea",
        tagId: GroceryConstant.BEV_GREEN_TEA),
    CollapsibleGridModel(
        icon: "masala_tea.png",
        label: "Masala Tea",
        tagId: GroceryConstant.BEV_MASALA_TEA),
    CollapsibleGridModel(
        icon: "instant_coffee.png",
        label: "Instant Coffee",
        tagId: GroceryConstant.BEV_INSTANT_COFFEE),
    CollapsibleGridModel(
        icon: "filter_coffee.png",
        label: "Filter Coffee",
        tagId: GroceryConstant.BEV_FILTER_COFFEE),
    CollapsibleGridModel(
        icon: "malt_drink.png",
        label: "Malt Health Drink",
        tagId: GroceryConstant.BEV_MALT_HEALTH_DRINK),
    CollapsibleGridModel(
        icon: "glucose_powder.png",
        label: "Glucose Drink Powder",
        tagId: GroceryConstant.BEV_GLUCOSE_POWDER),
    CollapsibleGridModel(
        icon: "coconut_water.png",
        label: "Coconut Water",
        tagId: GroceryConstant.BEV_COCONUT_WATER),
    CollapsibleGridModel(
        icon: "drinking_water.png",
        label: "Packaged Drinking Water",
        tagId: GroceryConstant.BEV_DRINKING_WATER),
  ];

  static const List<CollapsibleGridModel> dryFruitsAndReadyFood = [
    // Dry Fruits & Seeds
    CollapsibleGridModel(icon: "almonds.png", label: "Almonds", tagId: GroceryConstant.DRY_ALMONDS),
    CollapsibleGridModel(icon: "cashews.png", label: "Cashew Nuts", tagId: GroceryConstant.DRY_CASHEWS),
    CollapsibleGridModel(icon: "raisins.png", label: "Raisins", tagId: GroceryConstant.DRY_RAISINS),
    CollapsibleGridModel(icon: "dates.png", label: "Dates", tagId: GroceryConstant.DRY_DATES),
    CollapsibleGridModel(icon: "dry_fig.png", label: "Dry Fig", tagId: GroceryConstant.DRY_FIG),
    CollapsibleGridModel(icon: "chia_seeds.png", label: "Chia Seeds", tagId: GroceryConstant.SEED_CHIA),
    CollapsibleGridModel(icon: "flax_seeds.png", label: "Flax Seeds", tagId: GroceryConstant.SEED_FLAX),
    CollapsibleGridModel(icon: "pumpkin_seeds.png", label: "Pumpkin Seeds", tagId: GroceryConstant.SEED_PUMPKIN),

    // Baby Food
    CollapsibleGridModel(icon: "baby_milk.png", label: "Baby Milk Powder", tagId: GroceryConstant.BABY_MILK_POWDER),
    CollapsibleGridModel(icon: "rice_cereal.png", label: "Rice Cereal", tagId: GroceryConstant.BABY_RICE_CEREAL),
    CollapsibleGridModel(icon: "khichdi_mix.png", label: "Khichdi Mix", tagId: GroceryConstant.BABY_KHICHDI_MIX),
    CollapsibleGridModel(icon: "baby_biscuits.png", label: "Baby Biscuits", tagId: GroceryConstant.BABY_BISCUITS),

    // Ready Food & Accompaniments
    CollapsibleGridModel(icon: "ready_poha.png", label: "Ready Poha", tagId: GroceryConstant.READY_POHA),
    CollapsibleGridModel(icon: "ready_upma.png", label: "Ready Upma", tagId: GroceryConstant.READY_UPMA),
    CollapsibleGridModel(icon: "ready_dal.png", label: "Ready Dal", tagId: GroceryConstant.READY_DAL),
    CollapsibleGridModel(icon: "papad.png", label: "Papad", tagId: GroceryConstant.ACC_PAPAD),
    CollapsibleGridModel(icon: "ketchup.png", label: "Tomato Ketchup", tagId: GroceryConstant.ACC_KETCHUP),
    CollapsibleGridModel(icon: "mango_pickle.png", label: "Mango Pickle", tagId: GroceryConstant.ACC_PICKLE_MANGO),
    CollapsibleGridModel(icon: "lemon_pickle.png", label: "Lemon Pickle", tagId: GroceryConstant.ACC_PICKLE_LEMON),
    CollapsibleGridModel(icon: "mixed_pickle.png", label: "Mixed Vegetable Pickle", tagId: GroceryConstant.ACC_PICKLE_MIXED),
  ];

  /// VEGETABLE
  static const List<CollapsibleGridModel> leafyVegetables = [
    CollapsibleGridModel(
        icon: "spinach.png",
        label: "Spinach",
        tagId: GroceryConstant.VEG_LEAFY_SPINACH),
    CollapsibleGridModel(
        icon: "fenugreek.png",
        label: "Fenugreek",
        tagId: GroceryConstant.VEG_LEAFY_FENUGREEK),
    CollapsibleGridModel(
        icon: "mustard_greens.png",
        label: "Mustard Greens",
        tagId: GroceryConstant.VEG_LEAFY_MUSTARD_GREENS),
    CollapsibleGridModel(
        icon: "mint.png",
        label: "Mint",
        tagId: GroceryConstant.VEG_LEAFY_MINT),
    CollapsibleGridModel(
        icon: "coriander.png",
        label: "Coriander Leaves",
        tagId: GroceryConstant.VEG_LEAFY_CORIANDER),
    CollapsibleGridModel(
        icon: "amaranth.png",
        label: "Amaranth",
        tagId: GroceryConstant.VEG_LEAFY_AMARANTH),
    CollapsibleGridModel(
        icon: "bathua.png",
        label: "Bathua",
        tagId: GroceryConstant.VEG_LEAFY_BATHUA),
    CollapsibleGridModel(
        icon: "malabar_spinach.png",
        label: "Malabar Spinach",
        tagId: GroceryConstant.VEG_LEAFY_MALABAR_SPINACH),
    CollapsibleGridModel(
        icon: "drumstick_leaves.png",
        label: "Drumstick Leaves",
        tagId: GroceryConstant.VEG_LEAFY_DRUMSTICK),
    CollapsibleGridModel(
        icon: "dill_leaves.png",
        label: "Dill Leaves",
        tagId: GroceryConstant.VEG_LEAFY_DILL),
    CollapsibleGridModel(
        icon: "taro_leaves.png",
        label: "Taro Leaves",
        tagId: GroceryConstant.VEG_LEAFY_TARO),
    CollapsibleGridModel(
        icon: "curry_leaves.png",
        label: "Curry Leaves",
        tagId: GroceryConstant.VEG_LEAFY_CURRY),
    CollapsibleGridModel(
        icon: "lettuce_indian.png",
        label: "Lettuce Indian",
        tagId: GroceryConstant.VEG_LEAFY_LETTUCE_INDIAN),
  ];

  static final List<CollapsibleGridModel> rootVegetables = [
    CollapsibleGridModel(
        icon: "potato.png",
        label: "Potato",
        tagId: GroceryConstant.VEG_ROOT_POTATO),
    CollapsibleGridModel(
        icon: "sweet_potato.png",
        label: "Sweet Potato",
        tagId: GroceryConstant.VEG_ROOT_SWEET_POTATO),
    CollapsibleGridModel(
        icon: "carrot.png",
        label: "Carrot",
        tagId: GroceryConstant.VEG_ROOT_CARROT),
    CollapsibleGridModel(
        icon: "radish.png",
        label: "Radish",
        tagId: GroceryConstant.VEG_ROOT_RADISH),
    CollapsibleGridModel(
        icon: "beetroot.png",
        label: "Beetroot",
        tagId: GroceryConstant.VEG_ROOT_BEETROOT),
    CollapsibleGridModel(
        icon: "turnip.png",
        label: "Turnip",
        tagId: GroceryConstant.VEG_ROOT_TURNIP),
    CollapsibleGridModel(
        icon: "yam.png",
        label: "Yam",
        tagId: GroceryConstant.VEG_ROOT_YAM),
    CollapsibleGridModel(
        icon: "taro_root.png",
        label: "Taro Root",
        tagId: GroceryConstant.VEG_ROOT_TARO),
    CollapsibleGridModel(
        icon: "elephant_foot_yam.png",
        label: "Elephant\nFoot Yam",
        tagId: GroceryConstant.VEG_ROOT_ELEPHANT_FOOT_YAM),
    CollapsibleGridModel(
        icon: "cassava.png",
        label: "Cassava",
        tagId: GroceryConstant.VEG_ROOT_CASSAVA),
    CollapsibleGridModel(
        icon: "lotus_root.png",
        label: "Lotus Root",
        tagId: GroceryConstant.VEG_ROOT_LOTUS_ROOT),
  ];

  static final List<CollapsibleGridModel> bulbNdStemVegetables = [
    CollapsibleGridModel(
        icon: "onion.png",
        label: "Onion",
        tagId: GroceryConstant.VEG_BULB_ONION),
    CollapsibleGridModel(
        icon: "garlic.png",
        label: "Garlic",
        tagId: GroceryConstant.VEG_BULB_GARLIC),
    CollapsibleGridModel(
        icon: "leek.png",
        label: "Leek",
        tagId: GroceryConstant.VEG_STEM_LEEK),
    CollapsibleGridModel(
        icon: "spring_onion.png",
        label: "Spring Onion",
        tagId: GroceryConstant.VEG_STEM_SPRING_ONION),
    CollapsibleGridModel(
        icon: "banana_stem.png",
        label: "Banana Stem",
        tagId: GroceryConstant.VEG_STEM_BANANA),
    CollapsibleGridModel(
        icon: "colocasia_stem.png",
        label: "Colocasia Stem",
        tagId: GroceryConstant.VEG_STEM_COLOCASIA),
  ];

  static final List<CollapsibleGridModel> fruitVegetables = [
    CollapsibleGridModel(icon: "tomato.png", label: "Tomato", tagId: GroceryConstant.VEG_FRUIT_TOMATO),
    CollapsibleGridModel(icon: "brinjal.png", label: "Brinjal Eggplant", tagId: GroceryConstant.VEG_FRUIT_BRINJAL),
    CollapsibleGridModel(icon: "bottle_gourd.png", label: "Bottle Gourd", tagId: GroceryConstant.VEG_GOURD_BOTTLE),
    CollapsibleGridModel(icon: "bitter_gourd.png", label: "Bitter Gourd", tagId: GroceryConstant.VEG_GOURD_BITTER),
    CollapsibleGridModel(icon: "ridge_gourd.png", label: "Ridge Gourd", tagId: GroceryConstant.VEG_GOURD_RIDGE),
    CollapsibleGridModel(icon: "sponge_gourd.png", label: "Sponge Gourd", tagId: GroceryConstant.VEG_GOURD_SPONGE),
    CollapsibleGridModel(icon: "snake_gourd.png", label: "Snake Gourd", tagId: GroceryConstant.VEG_GOURD_SNAKE),
    CollapsibleGridModel(icon: "pumpkin.png", label: "Pumpkin", tagId: GroceryConstant.VEG_FRUIT_PUMPKIN),
    CollapsibleGridModel(icon: "cucumber.png", label: "Cucumber", tagId: GroceryConstant.VEG_FRUIT_CUCUMBER),
    CollapsibleGridModel(icon: "ash_gourd.png", label: "Ash Gourd", tagId: GroceryConstant.VEG_GOURD_ASH),
    CollapsibleGridModel(icon: "pointed_gourd.png", label: "Pointed Gourd", tagId: GroceryConstant.VEG_GOURD_POINTED),
    CollapsibleGridModel(icon: "ivy_gourd.png", label: "Ivy Gourd", tagId: GroceryConstant.VEG_GOURD_IVY),
    CollapsibleGridModel(icon: "tinda.png", label: "Tinda", tagId: GroceryConstant.VEG_FRUIT_TINDA),
    CollapsibleGridModel(icon: "chow_chow.png", label: "Chow Chow\nChayote", tagId: GroceryConstant.VEG_FRUIT_CHOW_CHOW),
    CollapsibleGridModel(icon: "raw_banana.png", label: "Raw Banana", tagId: GroceryConstant.VEG_RAW_BANANA),
    CollapsibleGridModel(icon: "raw_papaya.png", label: "Raw Papaya", tagId: GroceryConstant.VEG_RAW_PAPAYA),
    CollapsibleGridModel(icon: "capsicum.png", label: "Capsicum Bell Pepper", tagId: GroceryConstant.VEG_FRUIT_CAPSICUM),
  ];

  static final List<CollapsibleGridModel> podNdBeansVegetables = [
    CollapsibleGridModel(
        icon: "green_peas.png",
        label: "Green Peas",
        tagId: GroceryConstant.VEG_POD_GREEN_PEAS),
    CollapsibleGridModel(
        icon: "french_beans.png",
        label: "French Beans",
        tagId: GroceryConstant.VEG_BEAN_FRENCH),
    CollapsibleGridModel(
        icon: "cluster_beans.png",
        label: "Cluster Beans",
        tagId: GroceryConstant.VEG_BEAN_CLUSTER),
    CollapsibleGridModel(
        icon: "cowpea.png",
        label: "Cowpea",
        tagId: GroceryConstant.VEG_BEAN_COWPEA),
    CollapsibleGridModel(
        icon: "hyacinth_beans.png",
        label: "Hyacinth Beans",
        tagId: GroceryConstant.VEG_BEAN_HYACINTH),
    CollapsibleGridModel(
        icon: "broad_beans.png",
        label: "Broad Beans",
        tagId: GroceryConstant.VEG_BEAN_BROAD),
    CollapsibleGridModel(
        icon: "winged_beans.png",
        label: "Winged Beans",
        tagId: GroceryConstant.VEG_BEAN_WINGED),
    CollapsibleGridModel(
        icon: "yardlong_beans.png",
        label: "Yardlong Beans",
        tagId: GroceryConstant.VEG_BEAN_YARDLONG),
  ];

  static final List<CollapsibleGridModel> flowerVegetables = [
    CollapsibleGridModel(
        icon: "cauliflower.png",
        label: "Cauliflower",
        tagId: GroceryConstant.VEG_FLOWER_CAULIFLOWER),
    CollapsibleGridModel(
        icon: "broccoli.png",
        label: "Broccoli",
        tagId: GroceryConstant.VEG_FLOWER_BROCCOLI),
    CollapsibleGridModel(
        icon: "banana_flower.png",
        label: "Banana Flower",
        tagId: GroceryConstant.VEG_FLOWER_BANANA),
    CollapsibleGridModel(
        icon: "pumpkin_flower.png",
        label: "Pumpkin Flower",
        tagId: GroceryConstant.VEG_FLOWER_PUMPKIN),
    CollapsibleGridModel(
        icon: "drumstick_flower.png",
        label: "Drumstick Flower",
        tagId: GroceryConstant.VEG_FLOWER_DRUMSTICK),
  ];

  static final List<CollapsibleGridModel> fungiNdSpecialIndianItems = [
    CollapsibleGridModel(
        icon: "mushroom.png",
        label: "Mushroom",
        tagId: GroceryConstant.VEG_FUNGI_MUSHROOM),
    CollapsibleGridModel(
        icon: "green_chilli.png",
        label: "Green Chilli",
        tagId: GroceryConstant.VEG_SPECIAL_GREEN_CHILLI),
    CollapsibleGridModel(
        icon: "ginger.png",
        label: "Ginger",
        tagId: GroceryConstant.VEG_SPECIAL_GINGER),
    CollapsibleGridModel(
        icon: "turmeric_fresh.png",
        label: "Turmeric Fresh",
        tagId: GroceryConstant.VEG_SPECIAL_TURMERIC_FRESH),
    CollapsibleGridModel(
        icon: "drumstick.png",
        label: "Drumstick",
        tagId: GroceryConstant.VEG_SPECIAL_DRUMSTICK),
    CollapsibleGridModel(
        icon: "raw_jackfruit.png",
        label: "Raw Jackfruit",
        tagId: GroceryConstant.VEG_SPECIAL_RAW_JACKFRUIT),
    CollapsibleGridModel(
        icon: "bamboo_shoot.png",
        label: "Bamboo Shoot",
        tagId: GroceryConstant.VEG_SPECIAL_BAMBOO_SHOOT),
    CollapsibleGridModel(
        icon: "kokum.png",
        label: "Kokum",
        tagId: GroceryConstant.VEG_SPECIAL_KOKUM),
    CollapsibleGridModel(
        icon: "sundakkai.png",
        label: "Sundakkai\nTurkey Berry",
        tagId: GroceryConstant.VEG_SPECIAL_SUNDAKKAI),
  ];

  static final List<CollapsibleGridModel> exoticAndSpecialty = [
    CollapsibleGridModel(
        icon: "zucchini.png",
        label: "Zucchini",
        tagId: GroceryConstant.VEG_EXOTIC_ZUCCHINI),
    CollapsibleGridModel(
        icon: "celery.png",
        label: "Celery",
        tagId: GroceryConstant.VEG_EXOTIC_CELERY),
    CollapsibleGridModel(
        icon: "asparagus.png",
        label: "Asparagus",
        tagId: GroceryConstant.VEG_EXOTIC_ASPARAGUS),
    CollapsibleGridModel(
        icon: "bok_choy.png",
        label: "Bok Choy",
        tagId: GroceryConstant.VEG_EXOTIC_BOK_CHOY),
    CollapsibleGridModel(
        icon: "lettuce_iceberg.png",
        label: "Lettuce Iceberg\nRomaine",
        tagId: GroceryConstant.VEG_EXOTIC_LETTUCE_ICEBERG),
    CollapsibleGridModel(
        icon: "kale.png",
        label: "Kale",
        tagId: GroceryConstant.VEG_EXOTIC_KALE),
    CollapsibleGridModel(
        icon: "chinese_cabbage.png",
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

}
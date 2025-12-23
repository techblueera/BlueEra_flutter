import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_constant.dart';

class GroceryData {
  /// Super Grocery Categories
  static const List<CollapsibleGridModel> grocerySuperCategories = [
    CollapsibleGridModel(
        icon: "grocery_items.svg",
        label: AppStrings.labelGroceryItems,
        tagId: GroceryConstant.GROCERY_ITEMS),
    CollapsibleGridModel(
        icon: "vegetable.svg",
        label: AppStrings.labelVegetable,
        tagId: GroceryConstant.VEGETABLE),
    CollapsibleGridModel(
        icon: "vegetable.svg",
        label: AppStrings.labelFruit,
        tagId: GroceryConstant.FRUIT),
    CollapsibleGridModel(
        icon: "bakery.svg",
        label: AppStrings.labelBakeryBreadItems,
        tagId: GroceryConstant.BAKERY_BREAD_ITEMS),
    CollapsibleGridModel(
        icon: "dairy_products.svg",
        label: AppStrings.labelDairyProducts,
        tagId: GroceryConstant.DAIRY_PRODUCTS),
    CollapsibleGridModel(
        icon: "home_essentials.svg",
        label: AppStrings.labelHomeEssentials,
        tagId: GroceryConstant.HOME_ESSENTIALS),
    CollapsibleGridModel(
        icon: "packed_sweets.svg",
        label: AppStrings.labelPackedSweetsNamkeens,
        tagId: GroceryConstant.PACKED_SWEETS_NAMKEENS),
    CollapsibleGridModel(
        icon: "crockery.svg",
        label: AppStrings.labelCrockery,
        tagId: GroceryConstant.CROCKERY),
    CollapsibleGridModel(
        icon: "medical_items.svg",
        label: AppStrings.labelMedicalItems,
        tagId: GroceryConstant.MEDICAL_ITEMS),
    CollapsibleGridModel(
        icon: "beauty_body_care.svg",
        label: AppStrings.labelBeautyBodyCare,
        tagId: GroceryConstant.BEAUTY_BODY_CARE),
    CollapsibleGridModel(
        icon: "stationary.svg",
        label: AppStrings.labelStationary,
        tagId: GroceryConstant.STATIONARY),
  ];

  /// Grocery Item
  static const List<CollapsibleGridModel> riceProducts = [
    CollapsibleGridModel(
        icon: "grocery_items/basmati_rice.png",
        label: AppStrings.labelBasmatiRice,
        tagId: GroceryConstant.RICE_BASMATI),
    CollapsibleGridModel(
        icon: "grocery_items/red_rice.png",
        label: AppStrings.labelRedRice,
        tagId: GroceryConstant.RICE_RED),
    CollapsibleGridModel(
        icon: "grocery_items/kolam_rice.png",
        label: AppStrings.labelKolamRice,
        tagId: GroceryConstant.RICE_KOLAM),
    CollapsibleGridModel(
        icon: "grocery_items/ponni_rice.png",
        label: AppStrings.labelPonniRice,
        tagId: GroceryConstant.RICE_PONNI),
    CollapsibleGridModel(
        icon: "grocery_items/parboiled_rice.png",
        label: AppStrings.labelParboiledRice,
        tagId: GroceryConstant.RICE_PARBOILED),
    CollapsibleGridModel(
        icon: "grocery_items/brown_rice.png",
        label: AppStrings.labelBrownRice,
        tagId: GroceryConstant.RICE_BROWN),
    CollapsibleGridModel(
        icon: "grocery_items/sona_masoori.png",
        label: AppStrings.labelSonaMasooriRice,
        tagId: GroceryConstant.RICE_SONA_MASOORI),
    CollapsibleGridModel(
        icon: "grocery_items/black_rice.png",
        label: AppStrings.labelBlackRice,
        tagId: GroceryConstant.RICE_BLACK),
  ];

  static const List<CollapsibleGridModel> wheatAndFlours = [
    CollapsibleGridModel(
        icon: "grocery_items/whole_wheat_atta.png",
        label: AppStrings.labelWholeWheatAtta,
        tagId: GroceryConstant.FLOUR_WHOLE_WHEAT),
    CollapsibleGridModel(
        icon: "grocery_items/chakki_atta.png",
        label: AppStrings.labelChakkiAtta,
        tagId: GroceryConstant.FLOUR_CHAKKI_ATTA),
    CollapsibleGridModel(
        icon: "grocery_items/sharbati_atta.png",
        label: AppStrings.labelSharbatiAtta,
        tagId: GroceryConstant.FLOUR_SHARBATI_ATTA),
    CollapsibleGridModel(
        icon: "grocery_items/multigrain_atta.png",
        label: AppStrings.labelMultigrainAtta,
        tagId: GroceryConstant.FLOUR_MULTIGRAIN),
    CollapsibleGridModel(
        icon: "grocery_items/diabetic_atta.png",
        label: AppStrings.labelDiabeticFriendlyAtta,
        tagId: GroceryConstant.FLOUR_DIABETIC),
    CollapsibleGridModel(
        icon: "grocery_items/maida.png",
        label: AppStrings.labelMaida,
        tagId: GroceryConstant.FLOUR_MAIDA),
    CollapsibleGridModel(
        icon: "grocery_items/besan.png",
        label: AppStrings.labelBesan,
        tagId: GroceryConstant.FLOUR_BESAN),
    CollapsibleGridModel(
        icon: "grocery_items/rice_flour.png",
        label: AppStrings.labelRiceFlour,
        tagId: GroceryConstant.FLOUR_RICE),
    CollapsibleGridModel(
        icon: "grocery_items/ragi_flour.png",
        label: AppStrings.labelRagiFlour,
        tagId: GroceryConstant.FLOUR_RAGI),
  ];

  static const List<CollapsibleGridModel> dalNdBeans = [
    CollapsibleGridModel(
        icon: "grocery_items/toor_dal.png",
        label: AppStrings.labelToorDal,
        tagId: GroceryConstant.DAL_TOOR),
    CollapsibleGridModel(
        icon: "grocery_items/moong_dal.png",
        label: AppStrings.labelMoongDal,
        tagId: GroceryConstant.DAL_MOONG),
    CollapsibleGridModel(
        icon: "grocery_items/masoor_dal.png",
        label: AppStrings.labelMasoorDal,
        tagId: GroceryConstant.DAL_MASOOR),
    CollapsibleGridModel(
        icon: "grocery_items/urad_dal.png",
        label: AppStrings.labelUradDal,
        tagId: GroceryConstant.DAL_URAD),
    CollapsibleGridModel(
        icon: "grocery_items/chana_dal.png",
        label: AppStrings.labelChanaDal,
        tagId: GroceryConstant.DAL_CHANA),
    CollapsibleGridModel(
        icon: "grocery_items/kabuli_chana.png",
        label: AppStrings.labelKabuliChana,
        tagId: GroceryConstant.DAL_KABULI_CHANA),
    CollapsibleGridModel(
        icon: "grocery_items/kala_chana.png",
        label: AppStrings.labelKalaChana,
        tagId: GroceryConstant.DAL_KALA_CHANA),
    CollapsibleGridModel(
        icon: "grocery_items/rajma.png",
        label: AppStrings.labelRajma,
        tagId: GroceryConstant.DAL_RAJMA),
    CollapsibleGridModel(
        icon: "grocery_items/dry_green_peas.png",
        label: AppStrings.labelDryGreenPeas,
        tagId: GroceryConstant.DAL_DRY_GREEN_PEAS),
  ];

  static const List<CollapsibleGridModel> milletsNdTraditionalGrains = [
    CollapsibleGridModel(
        icon: "grocery_items/ragi.png",
        label: AppStrings.labelRagi,
        tagId: GroceryConstant.MILLET_RAGI),
    CollapsibleGridModel(
        icon: "grocery_items/jowar.png",
        label: AppStrings.labelJowar,
        tagId: GroceryConstant.MILLET_JOWAR),
    CollapsibleGridModel(
        icon: "grocery_items/bajra.png",
        label: AppStrings.labelBajra,
        tagId: GroceryConstant.MILLET_BAJRA),
    CollapsibleGridModel(
        icon: "grocery_items/foxtail_millet.png",
        label: AppStrings.labelFoxtailMillet,
        tagId: GroceryConstant.MILLET_FOXTAIL),
    CollapsibleGridModel(
        icon: "grocery_items/little_millet.png",
        label: AppStrings.labelLittleMillet,
        tagId: GroceryConstant.MILLET_LITTLE),
    CollapsibleGridModel(
        icon: "grocery_items/kodo_millet.png",
        label: AppStrings.labelKodoMillet,
        tagId: GroceryConstant.MILLET_KODO),
    CollapsibleGridModel(
        icon: "grocery_items/barnyard_millet.png",
        label: AppStrings.labelBarnyardMillet,
        tagId: GroceryConstant.MILLET_BARNYARD),
    CollapsibleGridModel(
        icon: "grocery_items/samak_rice.png",
        label: AppStrings.labelSamakRice,
        tagId: GroceryConstant.RICE_SAMAK),
  ];

  static const List<CollapsibleGridModel> breakfastStaples = [
    CollapsibleGridModel(
        icon: "grocery_items/poha.png",
        label: AppStrings.labelPoha,
        tagId: GroceryConstant.STAPLE_POHA),
    CollapsibleGridModel(
        icon: "grocery_items/aval.png",
        label: AppStrings.labelAvalRiceFlakes,
        tagId: GroceryConstant.STAPLE_AVAL),
    CollapsibleGridModel(
        icon: "grocery_items/dalia.png",
        label: AppStrings.labelDaliaBrokenWheat,
        tagId: GroceryConstant.STAPLE_DALIA),
    CollapsibleGridModel(
        icon: "grocery_items/oats.png",
        label: AppStrings.labelOats,
        tagId: GroceryConstant.STAPLE_OATS),
    CollapsibleGridModel(
        icon: "grocery_items/corn_grits.png",
        label: AppStrings.labelCornGrits,
        tagId: GroceryConstant.STAPLE_CORN_GRITS),
    CollapsibleGridModel(
        icon: "grocery_items/wheat_bran.png",
        label: AppStrings.labelWheatBran,
        tagId: GroceryConstant.STAPLE_WHEAT_BRAN),
  ];

  static const List<CollapsibleGridModel> spicesAndMasala = [
    CollapsibleGridModel(
        icon: "grocery_items/cumin.png",
        label: AppStrings.labelCuminSeeds,
        tagId: GroceryConstant.SPICE_CUMIN_SEEDS),
    CollapsibleGridModel(
        icon: "grocery_items/coriander_seeds.png",
        label: AppStrings.labelCorianderSeeds,
        tagId: GroceryConstant.SPICE_CORIANDER_SEEDS),
    CollapsibleGridModel(
        icon: "grocery_items/black_pepper.png",
        label: AppStrings.labelBlackPepper,
        tagId: GroceryConstant.SPICE_BLACK_PEPPER),
    CollapsibleGridModel(
        icon: "grocery_items/green_cardamom.png",
        label: AppStrings.labelGreenCardamom,
        tagId: GroceryConstant.SPICE_GREEN_CARDAMOM),
    CollapsibleGridModel(
        icon: "grocery_items/cloves.png",
        label: AppStrings.labelCloves,
        tagId: GroceryConstant.SPICE_CLOVES),
    CollapsibleGridModel(
        icon: "grocery_items/cinnamon.png",
        label: AppStrings.labelCinnamon,
        tagId: GroceryConstant.SPICE_CINNAMON),
    CollapsibleGridModel(
        icon: "grocery_items/turmeric.png",
        label: AppStrings.labelTurmericPowder,
        tagId: GroceryConstant.SPICE_TURMERIC_POWDER),
    CollapsibleGridModel(
        icon: "grocery_items/red_chilli.png",
        label: AppStrings.labelRedChilliPowder,
        tagId: GroceryConstant.SPICE_RED_CHILLI_POWDER),
    CollapsibleGridModel(
        icon: "grocery_items/coriander_powder.png",
        label: AppStrings.labelCorianderPowder,
        tagId: GroceryConstant.SPICE_CORIANDER_POWDER),
    CollapsibleGridModel(
        icon: "grocery_items/garam_masala.png",
        label: AppStrings.labelGaramMasala,
        tagId: GroceryConstant.MASALA_GARAM),
    CollapsibleGridModel(
        icon: "grocery_items/chaat_masala.png",
        label: AppStrings.labelChaatMasala,
        tagId: GroceryConstant.MASALA_CHAAT),
    CollapsibleGridModel(
        icon: "grocery_items/sambhar_masala.png",
        label: AppStrings.labelSambharMasala,
        tagId: GroceryConstant.MASALA_SAMBHAR),
    CollapsibleGridModel(
        icon: "grocery_items/biryani_masala.png",
        label: AppStrings.labelBiryaniMasala,
        tagId: GroceryConstant.MASALA_BIRYANI),
    CollapsibleGridModel(
        icon: "grocery_items/chole_masala.png",
        label: AppStrings.labelCholeMasala,
        tagId: GroceryConstant.MASALA_CHOLE),
  ];

  static const List<CollapsibleGridModel> saltNdSweeteners = [
    CollapsibleGridModel(
        icon: "grocery_items/iodized_salt.png",
        label: AppStrings.labelIodizedSalt,
        tagId: GroceryConstant.SWEET_IODIZED_SALT),
    CollapsibleGridModel(
        icon: "grocery_items/rock_salt.png",
        label: AppStrings.labelRockSalt,
        tagId: GroceryConstant.SWEET_ROCK_SALT),
    CollapsibleGridModel(
        icon: "grocery_items/pink_salt.png",
        label: AppStrings.labelPinkSalt,
        tagId: GroceryConstant.SWEET_PINK_SALT),
    CollapsibleGridModel(
        icon: "grocery_items/white_sugar.png",
        label: AppStrings.labelWhiteSugar,
        tagId: GroceryConstant.SWEET_WHITE_SUGAR),
    CollapsibleGridModel(
        icon: "grocery_items/brown_sugar.png",
        label: AppStrings.labelBrownSugar,
        tagId: GroceryConstant.SWEET_BROWN_SUGAR),
    CollapsibleGridModel(
        icon: "grocery_items/jaggery.png",
        label: AppStrings.labelJaggery,
        tagId: GroceryConstant.SWEET_JAGGERY),
    CollapsibleGridModel(
        icon: "grocery_items/honey.png",
        label: AppStrings.labelHoney,
        tagId: GroceryConstant.SWEET_HONEY),
    CollapsibleGridModel(
        icon: "grocery_items/sugar_free.png",
        label: AppStrings.labelSugarFreeSweetener,
        tagId: GroceryConstant.SWEET_SUGAR_FREE),
  ];

  static const List<CollapsibleGridModel> oilsAndFats = [
    CollapsibleGridModel(
        icon: "grocery_items/sunflower_oil.png",
        label: AppStrings.labelSunflowerOil,
        tagId: GroceryConstant.OIL_SUNFLOWER),
    CollapsibleGridModel(
        icon: "grocery_items/rice_bran_oil.png",
        label: AppStrings.labelRiceBranOil,
        tagId: GroceryConstant.OIL_RICE_BRAN),
    CollapsibleGridModel(
        icon: "grocery_items/mustard_oil.png",
        label: AppStrings.labelMustardOil,
        tagId: GroceryConstant.OIL_MUSTARD),
    CollapsibleGridModel(
        icon: "grocery_items/groundnut_oil.png",
        label: AppStrings.labelGroundnutOil,
        tagId: GroceryConstant.OIL_GROUNDNUT),
    CollapsibleGridModel(
        icon: "grocery_items/sesame_oil.png",
        label: AppStrings.labelSesameOil,
        tagId: GroceryConstant.OIL_SESAME),
    CollapsibleGridModel(
        icon: "grocery_items/coconut_oil.png",
        label: AppStrings.labelCoconutOil,
        tagId: GroceryConstant.OIL_COCONUT),
    CollapsibleGridModel(
        icon: "grocery_items/olive_oil.png",
        label: AppStrings.labelOliveOil,
        tagId: GroceryConstant.OIL_OLIVE),
    CollapsibleGridModel(
        icon: "grocery_items/cow_ghee.png",
        label: AppStrings.labelCowGhee,
        tagId: GroceryConstant.GHEE_COW),
    CollapsibleGridModel(
        icon: "grocery_items/desi_ghee.png",
        label: AppStrings.labelDesiGhee,
        tagId: GroceryConstant.GHEE_DESI),
  ];

  static const List<CollapsibleGridModel> teaCoffeeBeverages = [
    CollapsibleGridModel(
        icon: "grocery_items/assam_tea.png",
        label: AppStrings.labelAssamTea,
        tagId: GroceryConstant.BEV_ASSAM_TEA),
    CollapsibleGridModel(
        icon: "grocery_items/green_tea.png",
        label: AppStrings.labelGreenTeaBeverage,
        tagId: GroceryConstant.BEV_GREEN_TEA),
    CollapsibleGridModel(
        icon: "grocery_items/masala_tea.png",
        label: AppStrings.labelMasalaTea,
        tagId: GroceryConstant.BEV_MASALA_TEA),
    CollapsibleGridModel(
        icon: "grocery_items/instant_coffee.png",
        label: AppStrings.labelInstantCoffee,
        tagId: GroceryConstant.BEV_INSTANT_COFFEE),
    CollapsibleGridModel(
        icon: "grocery_items/filter_coffee.png",
        label: AppStrings.labelFilterCoffee,
        tagId: GroceryConstant.BEV_FILTER_COFFEE),
    CollapsibleGridModel(
        icon: "grocery_items/malt_drink.png",
        label: AppStrings.labelMaltHealthDrink,
        tagId: GroceryConstant.BEV_MALT_HEALTH_DRINK),
    CollapsibleGridModel(
        icon: "grocery_items/glucose_powder.png",
        label: AppStrings.labelGlucoseDrinkPowder,
        tagId: GroceryConstant.BEV_GLUCOSE_POWDER),
    CollapsibleGridModel(
        icon: "grocery_items/coconut_water.png",
        label: AppStrings.labelCoconutWater,
        tagId: GroceryConstant.BEV_COCONUT_WATER),
    CollapsibleGridModel(
        icon: "grocery_items/drinking_water.png",
        label: AppStrings.labelPackagedDrinkingWater,
        tagId: GroceryConstant.BEV_DRINKING_WATER),
  ];

  static const List<CollapsibleGridModel> dryFruitsAndReadyFood = [
    // Dry Fruits & Seeds
    CollapsibleGridModel(
        icon: "grocery_items/almonds.png",
        label: AppStrings.labelAlmonds,
        tagId: GroceryConstant.DRY_ALMONDS),
    CollapsibleGridModel(
        icon: "grocery_items/cashews.png",
        label: AppStrings.labelCashewNuts,
        tagId: GroceryConstant.DRY_CASHEWS),
    CollapsibleGridModel(
        icon: "grocery_items/raisins.png",
        label: AppStrings.labelRaisins,
        tagId: GroceryConstant.DRY_RAISINS),
    CollapsibleGridModel(
        icon: "grocery_items/dates.png",
        label: AppStrings.labelDates,
        tagId: GroceryConstant.DRY_DATES),
    CollapsibleGridModel(
        icon: "grocery_items/dry_fig.png",
        label: AppStrings.labelDryFig,
        tagId: GroceryConstant.DRY_FIG),
    CollapsibleGridModel(
        icon: "grocery_items/chia_seeds.png",
        label: AppStrings.labelChiaSeeds,
        tagId: GroceryConstant.SEED_CHIA),
    CollapsibleGridModel(
        icon: "grocery_items/flax_seeds.png",
        label: AppStrings.labelFlaxSeeds,
        tagId: GroceryConstant.SEED_FLAX),
    CollapsibleGridModel(
        icon: "grocery_items/pumpkin_seeds.png",
        label: AppStrings.labelPumpkinSeeds,
        tagId: GroceryConstant.SEED_PUMPKIN),

    // Baby Food
    CollapsibleGridModel(
        icon: "grocery_items/baby_milk.png",
        label: AppStrings.labelBabyMilkPowder,
        tagId: GroceryConstant.BABY_MILK_POWDER),
    CollapsibleGridModel(
        icon: "grocery_items/rice_cereal.png",
        label: AppStrings.labelRiceCereal,
        tagId: GroceryConstant.BABY_RICE_CEREAL),
    CollapsibleGridModel(
        icon: "grocery_items/khichdi_mix.png",
        label: AppStrings.labelKhichdiMix,
        tagId: GroceryConstant.BABY_KHICHDI_MIX),
    CollapsibleGridModel(
        icon: "grocery_items/baby_biscuits.png",
        label: AppStrings.labelBabyBiscuits,
        tagId: GroceryConstant.BABY_BISCUITS),

    // Ready Food & Accompaniments
    CollapsibleGridModel(
        icon: "grocery_items/ready_poha.png",
        label: AppStrings.labelReadyPoha,
        tagId: GroceryConstant.READY_POHA),
    CollapsibleGridModel(
        icon: "grocery_items/ready_upma.png",
        label: AppStrings.labelReadyUpma,
        tagId: GroceryConstant.READY_UPMA),
    CollapsibleGridModel(
        icon: "grocery_items/ready_dal.png",
        label: AppStrings.labelReadyDal,
        tagId: GroceryConstant.READY_DAL),
    CollapsibleGridModel(
        icon: "grocery_items/papad.png",
        label: AppStrings.labelPapadStaple,
        tagId: GroceryConstant.ACC_PAPAD),
    CollapsibleGridModel(
        icon: "grocery_items/ketchup.png",
        label: AppStrings.labelTomatoKetchup,
        tagId: GroceryConstant.ACC_KETCHUP),
    CollapsibleGridModel(
        icon: "grocery_items/grocery_items/mango_pickle.png",
        label: AppStrings.labelMangoPickle,
        tagId: GroceryConstant.ACC_PICKLE_MANGO),
    CollapsibleGridModel(
        icon: "grocery_items/lemon_pickle.png",
        label: AppStrings.labelLemonPickle,
        tagId: GroceryConstant.ACC_PICKLE_LEMON),
    CollapsibleGridModel(
        icon: "grocery_items/mixed_pickle.png",
        label: AppStrings.labelMixedVegetablePickle,
        tagId: GroceryConstant.ACC_PICKLE_MIXED),
  ];

  /// VEGETABLE
  static const List<CollapsibleGridModel> leafyVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/spinach.png",
        label: AppStrings.labelSpinach,
        tagId: GroceryConstant.VEG_LEAFY_SPINACH),
    CollapsibleGridModel(
        icon: "vegetables/fenugreek.png",
        label: AppStrings.labelFenugreek,
        tagId: GroceryConstant.VEG_LEAFY_FENUGREEK),
    CollapsibleGridModel(
        icon: "vegetables/mustard_greens.png",
        label: AppStrings.labelMustardGreens,
        tagId: GroceryConstant.VEG_LEAFY_MUSTARD_GREENS),
    CollapsibleGridModel(
        icon: "vegetables/mint.png",
        label: AppStrings.labelMint,
        tagId: GroceryConstant.VEG_LEAFY_MINT),
    CollapsibleGridModel(
        icon: "vegetables/coriander.png",
        label: AppStrings.labelCorianderLeaves,
        tagId: GroceryConstant.VEG_LEAFY_CORIANDER),
    CollapsibleGridModel(
        icon: "vegetables/amaranth.png",
        label: AppStrings.labelAmaranth,
        tagId: GroceryConstant.VEG_LEAFY_AMARANTH),
    CollapsibleGridModel(
        icon: "vegetables/bathua.png",
        label: AppStrings.labelBathua,
        tagId: GroceryConstant.VEG_LEAFY_BATHUA),
    CollapsibleGridModel(
        icon: "vegetables/malabar_spinach.png",
        label: AppStrings.labelMalabarSpinach,
        tagId: GroceryConstant.VEG_LEAFY_MALABAR_SPINACH),
    CollapsibleGridModel(
        icon: "vegetables/drumstick_leaves.png",
        label: AppStrings.labelDrumstickLeaves,
        tagId: GroceryConstant.VEG_LEAFY_DRUMSTICK),
    CollapsibleGridModel(
        icon: "vegetables/dill_leaves.png",
        label: AppStrings.labelDillLeaves,
        tagId: GroceryConstant.VEG_LEAFY_DILL),
    CollapsibleGridModel(
        icon: "vegetables/taro_leaves.png",
        label: AppStrings.labelTaroLeaves,
        tagId: GroceryConstant.VEG_LEAFY_TARO),
    CollapsibleGridModel(
        icon: "vegetables/curry_leaves.png",
        label: AppStrings.labelCurryLeaves,
        tagId: GroceryConstant.VEG_LEAFY_CURRY),
    CollapsibleGridModel(
        icon: "vegetables/lettuce_indian.png",
        label: AppStrings.labelLettuceIndian,
        tagId: GroceryConstant.VEG_LEAFY_LETTUCE_INDIAN),
  ];

  static final List<CollapsibleGridModel> rootVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/potato.png",
        label: AppStrings.labelPotato,
        tagId: GroceryConstant.VEG_ROOT_POTATO),
    CollapsibleGridModel(
        icon: "vegetables/sweet_potato.png",
        label: AppStrings.labelSweetPotato,
        tagId: GroceryConstant.VEG_ROOT_SWEET_POTATO),
    CollapsibleGridModel(
        icon: "vegetables/carrot.png",
        label: AppStrings.labelCarrot,
        tagId: GroceryConstant.VEG_ROOT_CARROT),
    CollapsibleGridModel(
        icon: "vegetables/radish.png",
        label: AppStrings.labelRadish,
        tagId: GroceryConstant.VEG_ROOT_RADISH),
    CollapsibleGridModel(
        icon: "vegetables/beetroot.png",
        label: AppStrings.labelBeetroot,
        tagId: GroceryConstant.VEG_ROOT_BEETROOT),
    CollapsibleGridModel(
        icon: "vegetables/turnip.png",
        label: AppStrings.labelTurnip,
        tagId: GroceryConstant.VEG_ROOT_TURNIP),
    CollapsibleGridModel(
        icon: "vegetables/yam.png",
        label: AppStrings.labelYam,
        tagId: GroceryConstant.VEG_ROOT_YAM),
    CollapsibleGridModel(
        icon: "vegetables/taro_root.png",
        label: AppStrings.labelTaroRoot,
        tagId: GroceryConstant.VEG_ROOT_TARO),
    CollapsibleGridModel(
        icon: "vegetables/elephant_foot_yam.png",
        label: AppStrings.labelElephantFootYam,
        tagId: GroceryConstant.VEG_ROOT_ELEPHANT_FOOT_YAM),
    CollapsibleGridModel(
        icon: "vegetables/cassava.png",
        label: AppStrings.labelCassava,
        tagId: GroceryConstant.VEG_ROOT_CASSAVA),
    CollapsibleGridModel(
        icon: "vegetables/lotus_root.png",
        label: AppStrings.labelLotusRoot,
        tagId: GroceryConstant.VEG_ROOT_LOTUS_ROOT),
  ];

  static final List<CollapsibleGridModel> bulbNdStemVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/onion.png",
        label: AppStrings.labelOnion,
        tagId: GroceryConstant.VEG_BULB_ONION),
    CollapsibleGridModel(
        icon: "vegetables/garlic.png",
        label: AppStrings.labelGarlic,
        tagId: GroceryConstant.VEG_BULB_GARLIC),
    CollapsibleGridModel(
        icon: "vegetables/leek.png",
        label: AppStrings.labelLeek,
        tagId: GroceryConstant.VEG_STEM_LEEK),
    CollapsibleGridModel(
        icon: "vegetables/spring_onion.png",
        label: AppStrings.labelSpringOnion,
        tagId: GroceryConstant.VEG_STEM_SPRING_ONION),
    CollapsibleGridModel(
        icon: "vegetables/banana_stem.png",
        label: AppStrings.labelBananaStem,
        tagId: GroceryConstant.VEG_STEM_BANANA),
    CollapsibleGridModel(
        icon: "vegetables/colocasia_stem.png",
        label: AppStrings.labelColocasiaStem,
        tagId: GroceryConstant.VEG_STEM_COLOCASIA),
  ];

  static final List<CollapsibleGridModel> fruitVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/tomato.png",
        label: AppStrings.labelTomato,
        tagId: GroceryConstant.VEG_FRUIT_TOMATO),
    CollapsibleGridModel(
        icon: "vegetables/brinjal.png",
        label: AppStrings.labelBrinjalEggplant,
        tagId: GroceryConstant.VEG_FRUIT_BRINJAL),
    CollapsibleGridModel(
        icon: "vegetables/bottle_gourd.png",
        label: AppStrings.labelBottleGourd,
        tagId: GroceryConstant.VEG_GOURD_BOTTLE),
    CollapsibleGridModel(
        icon: "vegetables/bitter_gourd.png",
        label: AppStrings.labelBitterGourd,
        tagId: GroceryConstant.VEG_GOURD_BITTER),
    CollapsibleGridModel(
        icon: "vegetables/ridge_gourd.png",
        label: AppStrings.labelRidgeGourd,
        tagId: GroceryConstant.VEG_GOURD_RIDGE),
    CollapsibleGridModel(
        icon: "vegetables/sponge_gourd.png",
        label: AppStrings.labelSpongeGourd,
        tagId: GroceryConstant.VEG_GOURD_SPONGE),
    CollapsibleGridModel(
        icon: "vegetables/snake_gourd.png",
        label: AppStrings.labelSnakeGourd,
        tagId: GroceryConstant.VEG_GOURD_SNAKE),
    CollapsibleGridModel(
        icon: "vegetables/pumpkin.png",
        label: AppStrings.labelPumpkin,
        tagId: GroceryConstant.VEG_FRUIT_PUMPKIN),
    CollapsibleGridModel(
        icon: "vegetables/cucumber.png",
        label: AppStrings.labelCucumber,
        tagId: GroceryConstant.VEG_FRUIT_CUCUMBER),
    CollapsibleGridModel(
        icon: "vegetables/ash_gourd.png",
        label: AppStrings.labelAshGourd,
        tagId: GroceryConstant.VEG_GOURD_ASH),
    CollapsibleGridModel(
        icon: "vegetables/pointed_gourd.png",
        label: AppStrings.labelPointedGourd,
        tagId: GroceryConstant.VEG_GOURD_POINTED),
    CollapsibleGridModel(
        icon: "vegetables/ivy_gourd.png",
        label: AppStrings.labelIvyGourd,
        tagId: GroceryConstant.VEG_GOURD_IVY),
    CollapsibleGridModel(
        icon: "vegetables/tinda.png",
        label: AppStrings.labelTinda,
        tagId: GroceryConstant.VEG_FRUIT_TINDA),
    CollapsibleGridModel(
        icon: "vegetables/chow_chow.png",
        label: AppStrings.labelChowChowChayote,
        tagId: GroceryConstant.VEG_FRUIT_CHOW_CHOW),
    CollapsibleGridModel(
        icon: "vegetables/raw_banana.png",
        label: AppStrings.labelRawBanana,
        tagId: GroceryConstant.VEG_RAW_BANANA),
    CollapsibleGridModel(
        icon: "vegetables/raw_papaya.png",
        label: AppStrings.labelRawPapaya,
        tagId: GroceryConstant.VEG_RAW_PAPAYA),
    CollapsibleGridModel(
        icon: "vegetables/capsicum.png",
        label: AppStrings.labelCapsicumBellPepper,
        tagId: GroceryConstant.VEG_FRUIT_CAPSICUM),
  ];
  static final List<CollapsibleGridModel> podNdBeansVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/green_peas.png",
        label: AppStrings.labelGreenPeas,
        tagId: GroceryConstant.VEG_POD_GREEN_PEAS),
    CollapsibleGridModel(
        icon: "vegetables/french_beans.png",
        label: AppStrings.labelFrenchBeans,
        tagId: GroceryConstant.VEG_BEAN_FRENCH),
    CollapsibleGridModel(
        icon: "vegetables/cluster_beans.png",
        label: AppStrings.labelClusterBeans,
        tagId: GroceryConstant.VEG_BEAN_CLUSTER),
    CollapsibleGridModel(
        icon: "vegetables/cowpea.png",
        label: AppStrings.labelCowpea,
        tagId: GroceryConstant.VEG_BEAN_COWPEA),
    CollapsibleGridModel(
        icon: "vegetables/hyacinth_beans.png",
        label: AppStrings.labelHyacinthBeans,
        tagId: GroceryConstant.VEG_BEAN_HYACINTH),
    CollapsibleGridModel(
        icon: "vegetables/broad_beans.png",
        label: AppStrings.labelBroadBeans,
        tagId: GroceryConstant.VEG_BEAN_BROAD),
    CollapsibleGridModel(
        icon: "vegetables/winged_beans.png",
        label: AppStrings.labelWingedBeans,
        tagId: GroceryConstant.VEG_BEAN_WINGED),
    CollapsibleGridModel(
        icon: "vegetables/yardlong_beans.png",
        label: AppStrings.labelYardlongBeans,
        tagId: GroceryConstant.VEG_BEAN_YARDLONG),
  ];

  static final List<CollapsibleGridModel> flowerVegetables = [
    CollapsibleGridModel(
        icon: "vegetables/cauliflower.png",
        label: AppStrings.labelCauliflower,
        tagId: GroceryConstant.VEG_FLOWER_CAULIFLOWER),
    CollapsibleGridModel(
        icon: "vegetables/broccoli.png",
        label: AppStrings.labelBroccoli,
        tagId: GroceryConstant.VEG_FLOWER_BROCCOLI),
    CollapsibleGridModel(
        icon: "vegetables/banana_flower.png",
        label: AppStrings.labelBananaFlower,
        tagId: GroceryConstant.VEG_FLOWER_BANANA),
    CollapsibleGridModel(
        icon: "vegetables/pumpkin_flower.png",
        label: AppStrings.labelPumpkinFlower,
        tagId: GroceryConstant.VEG_FLOWER_PUMPKIN),
    CollapsibleGridModel(
        icon: "vegetables/drumstick_flower.png",
        label: AppStrings.labelDrumstickFlower,
        tagId: GroceryConstant.VEG_FLOWER_DRUMSTICK),
  ];

  static final List<CollapsibleGridModel> fungiNdSpecialIndianItems = [
    CollapsibleGridModel(
        icon: "vegetables/mushroom.png",
        label: AppStrings.labelMushroom,
        tagId: GroceryConstant.VEG_FUNGI_MUSHROOM),
    CollapsibleGridModel(
        icon: "vegetables/green_chilli.png",
        label: AppStrings.labelGreenChilli,
        tagId: GroceryConstant.VEG_SPECIAL_GREEN_CHILLI),
    CollapsibleGridModel(
        icon: "vegetables/ginger.png",
        label: AppStrings.labelGinger,
        tagId: GroceryConstant.VEG_SPECIAL_GINGER),
    CollapsibleGridModel(
        icon: "vegetables/turmeric_fresh.png",
        label: AppStrings.labelTurmericFresh,
        tagId: GroceryConstant.VEG_SPECIAL_TURMERIC_FRESH),
    CollapsibleGridModel(
        icon: "vegetables/drumstick.png",
        label: AppStrings.labelDrumstick,
        tagId: GroceryConstant.VEG_SPECIAL_DRUMSTICK),
    CollapsibleGridModel(
        icon: "vegetables/raw_jackfruit.png",
        label: AppStrings.labelRawJackfruit,
        tagId: GroceryConstant.VEG_SPECIAL_RAW_JACKFRUIT),
    CollapsibleGridModel(
        icon: "vegetables/bamboo_shoot.png",
        label: AppStrings.labelBambooShoot,
        tagId: GroceryConstant.VEG_SPECIAL_BAMBOO_SHOOT),
    CollapsibleGridModel(
        icon: "vegetables/kokum.png",
        label: AppStrings.labelKokum,
        tagId: GroceryConstant.VEG_SPECIAL_KOKUM),
    CollapsibleGridModel(
        icon: "vegetables/sundakkai.png",
        label: AppStrings.labelSundakkaiTurkeyBerry,
        tagId: GroceryConstant.VEG_SPECIAL_SUNDAKKAI),
  ];

  static final List<CollapsibleGridModel> exoticAndSpecialty = [
    CollapsibleGridModel(
        icon: "vegetables/zucchini.png",
        label: AppStrings.labelZucchini,
        tagId: GroceryConstant.VEG_EXOTIC_ZUCCHINI),
    CollapsibleGridModel(
        icon: "vegetables/celery.png",
        label: AppStrings.labelCelery,
        tagId: GroceryConstant.VEG_EXOTIC_CELERY),
    CollapsibleGridModel(
        icon: "vegetables/asparagus.png",
        label: AppStrings.labelAsparagus,
        tagId: GroceryConstant.VEG_EXOTIC_ASPARAGUS),
    CollapsibleGridModel(
        icon: "vegetables/bok_choy.png",
        label: AppStrings.labelBokChoy,
        tagId: GroceryConstant.VEG_EXOTIC_BOK_CHOY),
    CollapsibleGridModel(
        icon: "vegetables/lettuce_iceberg.png",
        label: AppStrings.labelLettuceIcebergRomaine,
        tagId: GroceryConstant.VEG_EXOTIC_LETTUCE_ICEBERG),
    CollapsibleGridModel(
        icon: "vegetables/kale.png",
        label: AppStrings.labelKale,
        tagId: GroceryConstant.VEG_EXOTIC_KALE),
    CollapsibleGridModel(
        icon: "vegetables/chinese_cabbage.png",
        label: AppStrings.labelChineseCabbage,
        tagId: GroceryConstant.VEG_EXOTIC_CHINESE_CABBAGE),
  ];

  /// FRUIT
  static final List<CollapsibleGridModel> dailyFruits = [
    CollapsibleGridModel(
        icon: "fruits/apple.png",
        label: AppStrings.labelApple,
        tagId: GroceryConstant.FRUIT_DAILY_APPLE),
    CollapsibleGridModel(
        icon: "fruits/banana.png",
        label: AppStrings.labelBanana,
        tagId: GroceryConstant.FRUIT_DAILY_BANANA),
    CollapsibleGridModel(
        icon: "fruits/orange.png",
        label: AppStrings.labelOrange,
        tagId: GroceryConstant.FRUIT_DAILY_ORANGE),
    CollapsibleGridModel(
        icon: "fruits/mosambi.png",
        label: AppStrings.labelMosambiSweetLime,
        tagId: GroceryConstant.FRUIT_DAILY_MOSAMBI),
    CollapsibleGridModel(
        icon: "fruits/grapes.png",
        label: AppStrings.labelGrapes,
        tagId: GroceryConstant.FRUIT_DAILY_GRAPES),
    CollapsibleGridModel(
        icon: "fruits/papaya.png",
        label: AppStrings.labelPapaya,
        tagId: GroceryConstant.FRUIT_DAILY_PAPAYA),
    CollapsibleGridModel(
        icon: "fruits/pomegranate.png",
        label: AppStrings.labelPomegranate,
        tagId: GroceryConstant.FRUIT_DAILY_POMEGRANATE),
    CollapsibleGridModel(
        icon: "fruits/guava.png",
        label: AppStrings.labelGuava,
        tagId: GroceryConstant.FRUIT_DAILY_GUAVA),
    CollapsibleGridModel(
        icon: "fruits/pear.png",
        label: AppStrings.labelPear,
        tagId: GroceryConstant.FRUIT_DAILY_PEAR),
    CollapsibleGridModel(
        icon: "fruits/chikoo.png",
        label: AppStrings.labelChikooSapota,
        tagId: GroceryConstant.FRUIT_DAILY_CHIKOO),
    CollapsibleGridModel(
        icon: "fruits/pineapple.png",
        label: AppStrings.labelPineapple,
        tagId: GroceryConstant.FRUIT_DAILY_PINEAPPLE),
    CollapsibleGridModel(
        icon: "fruits/watermelon.png",
        label: AppStrings.labelWatermelon,
        tagId: GroceryConstant.FRUIT_DAILY_WATERMELON),
    CollapsibleGridModel(
        icon: "fruits/muskmelon.png",
        label: AppStrings.labelMuskmelon,
        tagId: GroceryConstant.FRUIT_DAILY_MUSKMELON),
  ];

  static final List<CollapsibleGridModel> desiFruits = [
    CollapsibleGridModel(
        icon: "fruits/mango.png",
        label: AppStrings.labelMango,
        tagId: GroceryConstant.FRUIT_DESI_MANGO),
    CollapsibleGridModel(
        icon: "fruits/jackfruit.png",
        label: AppStrings.labelJackfruit,
        tagId: GroceryConstant.FRUIT_DESI_JACKFRUIT),
    CollapsibleGridModel(
        icon: "fruits/jamun.png",
        label: AppStrings.labelJamun,
        tagId: GroceryConstant.FRUIT_DESI_JAMUN),
    CollapsibleGridModel(
        icon: "fruits/custard_apple.png",
        label: AppStrings.labelCustardApple,
        tagId: GroceryConstant.FRUIT_DESI_CUSTARD_APPLE),
    CollapsibleGridModel(
        icon: "fruits/ber.png",
        label: AppStrings.labelBerIndianJujube,
        tagId: GroceryConstant.FRUIT_DESI_BER),
    CollapsibleGridModel(
        icon: "fruits/soursop.png",
        label: AppStrings.labelSoursop,
        tagId: GroceryConstant.FRUIT_DESI_SOURSOP),
    CollapsibleGridModel(
        icon: "fruits/wood_apple.png",
        label: AppStrings.labelWoodAppleBael,
        tagId: GroceryConstant.FRUIT_DESI_WOOD_APPLE),
    CollapsibleGridModel(
        icon: "fruits/tamarind.png",
        label: AppStrings.labelTamarind,
        tagId: GroceryConstant.FRUIT_DESI_TAMARIND),
    CollapsibleGridModel(
        icon: "fruits/monkey_jack.png",
        label: AppStrings.labelMonkeyJack,
        tagId: GroceryConstant.FRUIT_DESI_MONKEY_JACK),
    CollapsibleGridModel(
        icon: "fruits/fig.png",
        label: AppStrings.labelIndianFigAnjeer,
        tagId: GroceryConstant.FRUIT_DESI_FIG),
    CollapsibleGridModel(
        icon: "fruits/khirni.png",
        label: AppStrings.labelKhirniRayan,
        tagId: GroceryConstant.FRUIT_DESI_KHIRNI),
    CollapsibleGridModel(
        icon: "fruits/karonda.png",
        label: AppStrings.labelKaronda,
        tagId: GroceryConstant.FRUIT_DESI_KARONDA),
    CollapsibleGridModel(
        icon: "fruits/amla.png",
        label: AppStrings.labelIndianGooseberryAmla,
        tagId: GroceryConstant.FRUIT_DESI_AMLA),
  ];

  static final List<CollapsibleGridModel> sourAndStoneFruits = [
    CollapsibleGridModel(
        icon: "fruits/lemon.png",
        label: AppStrings.labelLemon,
        tagId: GroceryConstant.FRUIT_SOUR_LEMON),
    CollapsibleGridModel(
        icon: "fruits/lime.png",
        label: AppStrings.labelLime,
        tagId: GroceryConstant.FRUIT_SOUR_LIME),
    CollapsibleGridModel(
        icon: "fruits/kinnow.png",
        label: AppStrings.labelKinnow,
        tagId: GroceryConstant.FRUIT_SOUR_KINNOW),
    CollapsibleGridModel(
        icon: "fruits/pomelo.png",
        label: AppStrings.labelPomelo,
        tagId: GroceryConstant.FRUIT_SOUR_POMELO),
    CollapsibleGridModel(
        icon: "fruits/citron.png",
        label: AppStrings.labelCitron,
        tagId: GroceryConstant.FRUIT_SOUR_CITRON),
    CollapsibleGridModel(
        icon: "fruits/galgal.png",
        label: AppStrings.labelGalgal,
        tagId: GroceryConstant.FRUIT_SOUR_GALGAL),
    CollapsibleGridModel(
        icon: "fruits/peach.png",
        label: AppStrings.labelPeach,
        tagId: GroceryConstant.FRUIT_STONE_PEACH),
    CollapsibleGridModel(
        icon: "fruits/plum.png",
        label: AppStrings.labelPlum,
        tagId: GroceryConstant.FRUIT_STONE_PLUM),
    CollapsibleGridModel(
        icon: "fruits/apricot.png",
        label: AppStrings.labelApricot,
        tagId: GroceryConstant.FRUIT_STONE_APRICOT),
    CollapsibleGridModel(
        icon: "fruits/cherry.png",
        label: AppStrings.labelCherry,
        tagId: GroceryConstant.FRUIT_STONE_CHERRY),
  ];

  static final List<CollapsibleGridModel> smallNdSeasonalFruits = [
    CollapsibleGridModel(
        icon: "fruits/strawberry.png",
        label: AppStrings.labelStrawberry,
        tagId: GroceryConstant.FRUIT_SEASONAL_STRAWBERRY),
    CollapsibleGridModel(
        icon: "fruits/mulberry.png",
        label: AppStrings.labelMulberry,
        tagId: GroceryConstant.FRUIT_SEASONAL_MULBERRY),
    CollapsibleGridModel(
        icon: "fruits/raspberry.png",
        label: AppStrings.labelRaspberry,
        tagId: GroceryConstant.FRUIT_SEASONAL_RASPBERRY),
    CollapsibleGridModel(
        icon: "fruits/blueberry.png",
        label: AppStrings.labelBlueberry,
        tagId: GroceryConstant.FRUIT_SEASONAL_BLUEBERRY),
    CollapsibleGridModel(
        icon: "fruits/phalsa.png",
        label: AppStrings.labelPhalsa,
        tagId: GroceryConstant.FRUIT_SEASONAL_PHALSA),
    CollapsibleGridModel(
        icon: "fruits/litchi.png",
        label: AppStrings.labelLitchi,
        tagId: GroceryConstant.FRUIT_SEASONAL_LITCHI),
    CollapsibleGridModel(
        icon: "fruits/loquat.png",
        label: AppStrings.labelLoquat,
        tagId: GroceryConstant.FRUIT_SEASONAL_LOQUAT),
    CollapsibleGridModel(
        icon: "fruits/star_fruit.png",
        label: AppStrings.labelStarFruitCarambola,
        tagId: GroceryConstant.FRUIT_SEASONAL_STAR_FRUIT),
    CollapsibleGridModel(
        icon: "fruits/capsicum.png",
        label: AppStrings.labelCapsicumBellPepper,
        tagId: GroceryConstant.FRUIT_SEASONAL_Capsicum_Bell_PEPPER),
  ];

  static final List<CollapsibleGridModel> forestNdCoastalFruits = [
    CollapsibleGridModel(
        icon: "fruits/coconut.png",
        label: AppStrings.labelCoconut,
        tagId: GroceryConstant.FRUIT_COASTAL_COCONUT),
    CollapsibleGridModel(
        icon: "fruits/tender_coconut.png",
        label: AppStrings.labelTenderCoconut,
        tagId: GroceryConstant.FRUIT_COASTAL_TENDER_COCONUT),
    CollapsibleGridModel(
        icon: "fruits/ice_apple.png",
        label: AppStrings.labelIceApple,
        tagId: GroceryConstant.FRUIT_COASTAL_ICE_APPLE),
    CollapsibleGridModel(
        icon: "fruits/toddy_palm.png",
        label: AppStrings.labelToddyPalmFruit,
        tagId: GroceryConstant.FRUIT_COASTAL_TODDY_PALM),
    CollapsibleGridModel(
        icon: "fruits/nungu.png",
        label: AppStrings.labelNungu,
        tagId: GroceryConstant.FRUIT_COASTAL_NUNGU),
    CollapsibleGridModel(
        icon: "fruits/fresh_dates.png",
        label: AppStrings.labelDate,
        tagId: GroceryConstant.FRUIT_FOREST_DATE),
    CollapsibleGridModel(
        icon: "fruits/mahua.png",
        label: AppStrings.labelMahuaFruit,
        tagId: GroceryConstant.FRUIT_FOREST_MAHUA),
    CollapsibleGridModel(
        icon: "fruits/chironji_fruit.png",
        label: AppStrings.labelChironjiFruit,
        tagId: GroceryConstant.FRUIT_FOREST_CHIRONJI),
    CollapsibleGridModel(
        icon: "fruits/tendu_fruit.png",
        label: AppStrings.labelTenduFruit,
        tagId: GroceryConstant.FRUIT_FOREST_TENDU),
    CollapsibleGridModel(
        icon: "fruits/kaafal.png",
        label: AppStrings.labelKaafal,
        tagId: GroceryConstant.FRUIT_FOREST_KAAFAL),
    CollapsibleGridModel(
        icon: "fruits/wild_jamun.png",
        label: AppStrings.labelWildJamun,
        tagId: GroceryConstant.FRUIT_FOREST_WILD_JAMUN),
    CollapsibleGridModel(
        icon: "fruits/wild_banana.png",
        label: AppStrings.labelWildBanana,
        tagId: GroceryConstant.FRUIT_FOREST_WILD_BANANA),
    CollapsibleGridModel(
        icon: "fruits/breadfruit.png",
        label: AppStrings.labelBreadfruit,
        tagId: GroceryConstant.FRUIT_COASTAL_BREADFRUIT),
  ];

  static final List<CollapsibleGridModel> specialNdExoticFruits = [
    CollapsibleGridModel(
        icon: "fruits/kiwi.png",
        label: AppStrings.labelKiwi,
        tagId: GroceryConstant.FRUIT_EXOTIC_KIWI),
    CollapsibleGridModel(
        icon: "fruits/dragon_fruit.png",
        label: AppStrings.labelDragonFruit,
        tagId: GroceryConstant.FRUIT_EXOTIC_DRAGON),
    CollapsibleGridModel(
        icon: "fruits/avocado.png",
        label: AppStrings.labelAvocado,
        tagId: GroceryConstant.FRUIT_EXOTIC_AVOCADO),
    CollapsibleGridModel(
        icon: "fruits/passion_fruit.png",
        label: AppStrings.labelPassionFruit,
        tagId: GroceryConstant.FRUIT_EXOTIC_PASSION),
    CollapsibleGridModel(
        icon: "fruits/mangosteen.png",
        label: AppStrings.labelMangosteen,
        tagId: GroceryConstant.FRUIT_EXOTIC_MANGOSTEEN),
    CollapsibleGridModel(
        icon: "fruits/longan.png",
        label: AppStrings.labelLongan,
        tagId: GroceryConstant.FRUIT_EXOTIC_LONGAN),
    CollapsibleGridModel(
        icon: "fruits/rambutan.png",
        label: AppStrings.labelRambutan,
        tagId: GroceryConstant.FRUIT_EXOTIC_RAMBUTAN),
    CollapsibleGridModel(
        icon: "fruits/durian.png",
        label: AppStrings.labelDurian,
        tagId: GroceryConstant.FRUIT_EXOTIC_DURIAN),
  ];

  /// BAKERY & NAMKEEN ITEMS
  // Namkeen & Mixture List
  static final List<CollapsibleGridModel> namkeenAndMixture = [
    CollapsibleGridModel(
        icon: "bakery_snacks_items/aloo_bhujia.png",
        label: AppStrings.labelAlooBhujia,
        tagId: GroceryConstant.SNACK_NAMKEEN_ALOO_BHUJIA),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/sev.png",
        label: AppStrings.labelSev,
        tagId: GroceryConstant.SNACK_NAMKEEN_SEV),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/mixture.png",
        label: AppStrings.labelMixture,
        tagId: GroceryConstant.SNACK_NAMKEEN_MIXTURE),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/boondi.png",
        label: AppStrings.labelBoondi,
        tagId: GroceryConstant.SNACK_NAMKEEN_BOONDI),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/moong_dal.png",
        label: AppStrings.labelMoongDalNamkeen,
        tagId: GroceryConstant.SNACK_NAMKEEN_MOONG_DAL),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/chana_dal.png",
        label: AppStrings.labelChanaDalNamkeen,
        tagId: GroceryConstant.SNACK_NAMKEEN_CHANA_DAL),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/peanuts.png",
        label: AppStrings.labelPeanutsNamkeen,
        tagId: GroceryConstant.SNACK_NAMKEEN_PEANUTS),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/ghatiya.png",
        label: AppStrings.labelGhatiya,
        tagId: GroceryConstant.SNACK_GHATIYA),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/farsan.png",
        label: AppStrings.labelFarsanMix,
        tagId: GroceryConstant.SNACK_NAMKEEN_FARSAN),
  ];

  // Chips, Papad & Fryums List
  static final List<CollapsibleGridModel> chipsPapadFryums = [
    CollapsibleGridModel(
        icon: "bakery_snacks_items/potato_chips.png",
        label: AppStrings.labelPotatoChips,
        tagId: GroceryConstant.SNACK_CHIPS_POTATO),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/banana_chips.png",
        label: AppStrings.labelBananaChips,
        tagId: GroceryConstant.SNACK_CHIPS_BANANA),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/tapioca_chips.png",
        label: AppStrings.labelTapiocaChips,
        tagId: GroceryConstant.SNACK_CHIPS_TAPIOCA),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/corn_chips.png",
        label: AppStrings.labelCornChips,
        tagId: GroceryConstant.SNACK_CHIPS_CORN),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/multigrain_chips.png",
        label: AppStrings.labelMultigrainChips,
        tagId: GroceryConstant.SNACK_CHIPS_MULTIGRAIN),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/nacho_chips.png",
        label: AppStrings.labelNachoChips,
        tagId: GroceryConstant.SNACK_CHIPS_NACHO),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/urad_papad.png",
        label: AppStrings.labelUradPapad,
        tagId: GroceryConstant.SNACK_PAPAD_URAD),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/rice_papad.png",
        label: AppStrings.labelRicePapad,
        tagId: GroceryConstant.SNACK_PAPAD_RICE),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/sabudana_papad.png",
        label: AppStrings.labelSabudanaPapad,
        tagId: GroceryConstant.SNACK_PAPAD_SABUDANA),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/appalam.png",
        label: AppStrings.labelAppalam,
        tagId: GroceryConstant.SNACK_PAPAD_APPALAM),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/fryums.png",
        label: AppStrings.labelFryums,
        tagId: GroceryConstant.SNACK_FRYUMS),
  ];

  // Biscuits & Cookies
  static final List<CollapsibleGridModel> biscuitsCookies = [
    CollapsibleGridModel(
        icon: "bakery_snacks_items/glucose.png",
        label: AppStrings.labelGlucoseBiscuits,
        tagId: GroceryConstant.BISCUIT_GLUCOSE),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/marie.png",
        label: AppStrings.labelMarieBiscuits,
        tagId: GroceryConstant.BISCUIT_MARIE),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/milk.png",
        label: AppStrings.labelMilkBiscuits,
        tagId: GroceryConstant.BISCUIT_MILK),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/cream.png",
        label: AppStrings.labelCreamBiscuits,
        tagId: GroceryConstant.BISCUIT_CREAM),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/arrowroot.png",
        label: AppStrings.labelArrowrootBiscuits,
        tagId: GroceryConstant.BISCUIT_ARROWROOT),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/sandwich.png",
        label: AppStrings.labelSandwichBiscuits,
        tagId: GroceryConstant.BISCUIT_SANDWICH),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/multigrain.png",
        label: AppStrings.labelMultigrainBiscuits,
        tagId: GroceryConstant.BISCUIT_MULTIGRAIN),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/digestive.png",
        label: AppStrings.labelDigestiveBiscuits,
        tagId: GroceryConstant.BISCUIT_DIGESTIVE),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/jeera.png",
        label: AppStrings.labelJeeraBiscuits,
        tagId: GroceryConstant.BISCUIT_JEERA),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/butter.png",
        label: AppStrings.labelButterBiscuits,
        tagId: GroceryConstant.BISCUIT_BUTTER),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/jam.png",
        label: AppStrings.labelJamBiscuits,
        tagId: GroceryConstant.BISCUIT_JAM),
  ];

  // Bread, Bakery & Sweet Items
  static final List<CollapsibleGridModel> bakeryItems = [
    CollapsibleGridModel(
        icon: "bakery_snacks_items/white_bread.png",
        label: AppStrings.labelWhiteBread,
        tagId: GroceryConstant.BAKERY_WHITE_BREAD),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/brown_bread.png",
        label: AppStrings.labelBrownBread,
        tagId: GroceryConstant.BAKERY_BROWN_BREAD),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/multigrain_bread.png",
        label: AppStrings.labelMultigrainBread,
        tagId: GroceryConstant.BAKERY_MULTIGRAIN_BREAD),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/pav.png",
        label: AppStrings.labelPavBread,
        tagId: GroceryConstant.BAKERY_PAV),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/burger_buns.png",
        label: AppStrings.labelBurgerBuns,
        tagId: GroceryConstant.BAKERY_BURGER_BUNS),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/pizza_base.png",
        label: AppStrings.labelPizzaBase,
        tagId: GroceryConstant.BAKERY_PIZZA_BASE),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/bread_crumbs.png",
        label: AppStrings.labelBreadCrumbs,
        tagId: GroceryConstant.BAKERY_BREAD_CRUMBS),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/khari.png",
        label: AppStrings.labelKhariBiscuit,
        tagId: GroceryConstant.BAKERY_KHARI),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/rusk.png",
        label: AppStrings.labelRusk,
        tagId: GroceryConstant.BAKERY_RUSK),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/cake.png",
        label: AppStrings.labelCake,
        tagId: GroceryConstant.BAKERY_CAKE),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/cup_cake.png",
        label: AppStrings.labelCupCake,
        tagId: GroceryConstant.BAKERY_CUP_CAKE),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/muffins.png",
        label: AppStrings.labelMuffins,
        tagId: GroceryConstant.BAKERY_MUFFINS),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/swiss_roll.png",
        label: AppStrings.labelSwissRoll,
        tagId: GroceryConstant.BAKERY_SWISS_ROLL),
  ];

  // Fried & Hot Snacks
  static final List<CollapsibleGridModel> friedHotSnacks = [
    CollapsibleGridModel(
        icon: "bakery_snacks_items/samosa.png",
        label: AppStrings.labelSamosa,
        tagId: GroceryConstant.SNACK_HOT_SAMOSA),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/veg_puff.png",
        label: AppStrings.labelVegPuff,
        tagId: GroceryConstant.SNACK_HOT_VEG_PUFF),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/veg_patties.png",
        label: AppStrings.labelVegPatties,
        tagId: GroceryConstant.SNACK_HOT_VEG_PATTIES),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/pizza_patties.png",
        label: AppStrings.labelPizzaPatties,
        tagId: GroceryConstant.SNACK_HOT_PIZZA_PATTIES),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/veg_cutlet.png",
        label: AppStrings.labelVegCutlet,
        tagId: GroceryConstant.SNACK_HOT_VEG_CUTLET),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/bread_roll.png",
        label: AppStrings.labelBreadRoll,
        tagId: GroceryConstant.SNACK_HOT_BREAD_ROLL),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/spring_roll.png",
        label: AppStrings.labelSpringRoll,
        tagId: GroceryConstant.SNACK_HOT_SPRING_ROLL),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/dry_kachori.png",
        label: AppStrings.labelDryKachori,
        tagId: GroceryConstant.SNACK_HOT_DRY_KACHORI),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/khakhra.png",
        label: AppStrings.labelKhakhra,
        tagId: GroceryConstant.SNACK_DRY_KHAKHRA),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/chakli.png",
        label: AppStrings.labelChakli,
        tagId: GroceryConstant.SNACK_DRY_CHAKLI),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/murukku.png",
        label: AppStrings.labelMurukku,
        tagId: GroceryConstant.SNACK_DRY_MURUKKU),
    CollapsibleGridModel(
        icon: "bakery_snacks_items/popcorn.png",
        label: AppStrings.labelPopcorn,
        tagId: GroceryConstant.SNACK_DRY_POPCORN),
  ];

  /// DAIRY & FROZEN ITEMS
  // Milk List
  static final List<CollapsibleGridModel> milkList = [
    CollapsibleGridModel(
        icon: "dairy_items/full_cream_milk.png",
        label: AppStrings.labelFullCreamMilk,
        tagId: GroceryConstant.DAIRY_MILK_FULL_CREAM),
    CollapsibleGridModel(
        icon: "dairy_items/toned_milk.png",
        label: AppStrings.labelTonedMilk,
        tagId: GroceryConstant.DAIRY_MILK_TONED),
    CollapsibleGridModel(
        icon: "dairy_items/double_toned_milk.png",
        label: AppStrings.labelDoubleTonedMilk,
        tagId: GroceryConstant.DAIRY_MILK_DOUBLE_TONED),
    CollapsibleGridModel(
        icon: "dairy_items/skimmed_milk.png",
        label: AppStrings.labelSkimmedMilk,
        tagId: GroceryConstant.DAIRY_MILK_SKIMMED),
    CollapsibleGridModel(
        icon: "dairy_items/cow_milk.png",
        label: AppStrings.labelCowMilk,
        tagId: GroceryConstant.DAIRY_MILK_COW),
    CollapsibleGridModel(
        icon: "dairy_items/buffalo_milk.png",
        label: AppStrings.labelBuffaloMilk,
        tagId: GroceryConstant.DAIRY_MILK_BUFFALO),
    CollapsibleGridModel(
        icon: "dairy_items/flavoured_milk.png",
        label: AppStrings.labelFlavouredMilk,
        tagId: GroceryConstant.DAIRY_MILK_FLAVOURED),
    CollapsibleGridModel(
        icon: "dairy_items/lactose_free_milk.png",
        label: AppStrings.labelLactoseFreeMilk,
        tagId: GroceryConstant.DAIRY_MILK_LACTOSE_FREE),
  ];

  // Curd, Buttermilk and Cream List
  static final List<CollapsibleGridModel> curdButtermilkCreamList = [
    CollapsibleGridModel(
        icon: "dairy_items/fresh_curd.png",
        label: AppStrings.labelFreshCurd,
        tagId: GroceryConstant.DAIRY_CURD_FRESH),
    CollapsibleGridModel(
        icon: "dairy_items/set_curd.png",
        label: AppStrings.labelSetCurd,
        tagId: GroceryConstant.DAIRY_CURD_SET),
    CollapsibleGridModel(
        icon: "dairy_items/greek_yogurt.png",
        label: AppStrings.labelGreekYogurt,
        tagId: GroceryConstant.DAIRY_YOGURT_GREEK),
    CollapsibleGridModel(
        icon: "dairy_items/flavoured_yogurt.png",
        label: AppStrings.labelFlavouredYogurt,
        tagId: GroceryConstant.DAIRY_YOGURT_FLAVOURED),
    CollapsibleGridModel(
        icon: "dairy_items/butter_milk.png",
        label: AppStrings.labelButterMilk,
        tagId: GroceryConstant.DAIRY_BUTTER_MILK),
    CollapsibleGridModel(
        icon: "dairy_items/namkeen_chaas.png",
        label: AppStrings.labelNamkeenChhaach,
        tagId: GroceryConstant.DAIRY_CHAAS_NAMKEEN),
    CollapsibleGridModel(
        icon: "dairy_items/lassi.png",
        label: AppStrings.labelLassi,
        tagId: GroceryConstant.DAIRY_LASSI),
    CollapsibleGridModel(
        icon: "dairy_items/fresh_cream.png",
        label: AppStrings.labelFreshCream,
        tagId: GroceryConstant.DAIRY_CREAM_FRESH),
    CollapsibleGridModel(
        icon: "dairy_items/cooking_cream.png",
        label: AppStrings.labelCookingCream,
        tagId: GroceryConstant.DAIRY_CREAM_COOKING),
    CollapsibleGridModel(
        icon: "dairy_items/whipping_cream.png",
        label: AppStrings.labelWhippingCream,
        tagId: GroceryConstant.DAIRY_CREAM_WHIPPING),
  ];

  // Butter, Cheese and Paneer List
  static final List<CollapsibleGridModel> butterCheesePaneerList = [
    CollapsibleGridModel(
        icon: "dairy_items/table_butter.png",
        label: AppStrings.labelTableButter,
        tagId: GroceryConstant.DAIRY_BUTTER_TABLE),
    CollapsibleGridModel(
        icon: "dairy_items/white_butter.png",
        label: AppStrings.labelWhiteButter,
        tagId: GroceryConstant.DAIRY_BUTTER_WHITE),
    CollapsibleGridModel(
        icon: "dairy_items/salted_butter.png",
        label: AppStrings.labelSaltedButter,
        tagId: GroceryConstant.DAIRY_BUTTER_SALTED),
    CollapsibleGridModel(
        icon: "dairy_items/unsalted_butter.png",
        label: AppStrings.labelUnsaltedButter,
        tagId: GroceryConstant.DAIRY_BUTTER_UNSALTED),
    CollapsibleGridModel(
        icon: "dairy_items/cheese_slices.png",
        label: AppStrings.labelCheeseSlices,
        tagId: GroceryConstant.DAIRY_CHEESE_SLICES),
    CollapsibleGridModel(
        icon: "dairy_items/cheese_blocks.png",
        label: AppStrings.labelCheeseBlocks,
        tagId: GroceryConstant.DAIRY_CHEESE_BLOCKS),
    CollapsibleGridModel(
        icon: "dairy_items/cheese_spread.png",
        label: AppStrings.labelCheeseSpread,
        tagId: GroceryConstant.DAIRY_CHEESE_SPREAD),
    CollapsibleGridModel(
        icon: "dairy_items/fresh_paneer.png",
        label: AppStrings.labelFreshPaneer,
        tagId: GroceryConstant.DAIRY_PANEER_FRESH),
    CollapsibleGridModel(
        icon: "dairy_items/malai_paneer.png",
        label: AppStrings.labelMalaiPaneer,
        tagId: GroceryConstant.DAIRY_PANEER_MALAI),
    CollapsibleGridModel(
        icon: "dairy_items/frozen_paneer.png",
        label: AppStrings.labelFrozenPaneer,
        tagId: GroceryConstant.DAIRY_PANEER_FROZEN),
  ];

  // Ghee and Dairy Fats List
  static final List<CollapsibleGridModel> gheeAndDairyFatsList = [
    CollapsibleGridModel(
        icon: "dairy_items/cow_ghee.png",
        label: AppStrings.labelCowGhee,
        tagId: GroceryConstant.DAIRY_GHEE_COW),
    CollapsibleGridModel(
        icon: "dairy_items/buffalo_ghee.png",
        label: AppStrings.labelBuffaloGhee,
        tagId: GroceryConstant.DAIRY_GHEE_BUFFALO),
    CollapsibleGridModel(
        icon: "dairy_items/a2_ghee.png",
        label: AppStrings.labelA2Ghee,
        tagId: GroceryConstant.DAIRY_GHEE_A2),
    CollapsibleGridModel(
        icon: "dairy_items/organic_ghee.png",
        label: AppStrings.labelOrganicGhee,
        tagId: GroceryConstant.DAIRY_GHEE_ORGANIC),
    CollapsibleGridModel(
        icon: "dairy_items/desi_ghee.png",
        label: AppStrings.labelDesiGhee,
        tagId: GroceryConstant.DAIRY_GHEE_DESI),
    CollapsibleGridModel(
        icon: "dairy_items/vanaspati.png",
        label: AppStrings.labelVanaspati,
        tagId: GroceryConstant.DAIRY_GHEE_VANASPATI),
  ];

  //Ice Cream and Frozen Desserts List
  static final List<CollapsibleGridModel> iceCreamFrozenDessertsList = [
    CollapsibleGridModel(
        icon: "dairy_items/ice_cream_cups.png",
        label: AppStrings.labelIceCreamCups,
        tagId: GroceryConstant.FROZEN_ICE_CREAM_CUPS),
    CollapsibleGridModel(
        icon: "dairy_items/family_packs.png",
        label: AppStrings.labelIceCreamFamilyPacks,
        tagId: GroceryConstant.FROZEN_ICE_CREAM_FAMILY_PACKS),
    CollapsibleGridModel(
        icon: "dairy_items/ice_cream_bars.png",
        label: AppStrings.labelIceCreamBars,
        tagId: GroceryConstant.FROZEN_ICE_CREAM_BARS),
    CollapsibleGridModel(
        icon: "dairy_items/ice_cream_cones.png",
        label: AppStrings.labelIceCreamCones,
        tagId: GroceryConstant.FROZEN_ICE_CREAM_CONES),
    CollapsibleGridModel(
        icon: "dairy_items/kulfi.png",
        label: AppStrings.labelKulfi,
        tagId: GroceryConstant.FROZEN_KULFI),
    CollapsibleGridModel(
        icon: "dairy_items/malai_kulfi.png",
        label: AppStrings.labelMalaiKulfi,
        tagId: GroceryConstant.FROZEN_MALAI_KULFI),
    CollapsibleGridModel(
        icon: "dairy_items/matka_kulfi.png",
        label: AppStrings.labelMatkaKulfi,
        tagId: GroceryConstant.FROZEN_MATKA_KULFI),
    CollapsibleGridModel(
        icon: "dairy_items/frozen_yogurt.png",
        label: AppStrings.labelFrozenYogurt,
        tagId: GroceryConstant.FROZEN_YOGURT),
    CollapsibleGridModel(
        icon: "dairy_items/frozen_dessert.png",
        label: AppStrings.labelFrozenDessert,
        tagId: GroceryConstant.FROZEN_DESSERT),
    CollapsibleGridModel(
        icon: "dairy_items/ice_lollies.png",
        label: AppStrings.labelIceLollies,
        tagId: GroceryConstant.FROZEN_ICE_LOLLIES),
    CollapsibleGridModel(
        icon: "dairy_items/cassata.png",
        label: AppStrings.labelCassataIceCream,
        tagId: GroceryConstant.FROZEN_CASSATA),
    CollapsibleGridModel(
        icon: "dairy_items/ice_cream_sandwich.png",
        label: AppStrings.labelIceCreamSandwich,
        tagId: GroceryConstant.FROZEN_ICE_CREAM_SANDWICH),
    CollapsibleGridModel(
        icon: "dairy_items/fruit_sorbet.png",
        label: AppStrings.labelFruitSorbet,
        tagId: GroceryConstant.FROZEN_FRUIT_SORBET),
    CollapsibleGridModel(
        icon: "dairy_items/gelato.png",
        label: AppStrings.labelGelato,
        tagId: GroceryConstant.FROZEN_GELATO),
  ];

  // Frozen Vegetables List
  static final List<CollapsibleGridModel> frozenVegetablesList = [
    CollapsibleGridModel(
        icon: "dairy_items/frozen_peas.png",
        label: AppStrings.labelFrozenGreenPeas,
        tagId: GroceryConstant.FROZEN_VEG_GREEN_PEAS),
    CollapsibleGridModel(
        icon: "dairy_items/frozen_corn.png",
        label: AppStrings.labelFrozenSweetCorn,
        tagId: GroceryConstant.FROZEN_VEG_SWEET_CORN),
    CollapsibleGridModel(
        icon: "dairy_items/frozen_mixed_veg.png",
        label: AppStrings.labelFrozenMixedVegetables,
        tagId: GroceryConstant.FROZEN_VEG_MIXED),
    CollapsibleGridModel(
        icon: "dairy_items/frozen_beans.png",
        label: AppStrings.labelFrozenFrenchBeans,
        tagId: GroceryConstant.FROZEN_VEG_FRENCH_BEANS),
    CollapsibleGridModel(
        icon: "dairy_items/frozen_carrot.png",
        label: AppStrings.labelFrozenCarrot,
        tagId: GroceryConstant.FROZEN_VEG_CARROT),
    CollapsibleGridModel(
        icon: "dairy_items/frozen_spinach.png",
        label: AppStrings.labelFrozenSpinach,
        tagId: GroceryConstant.FROZEN_VEG_SPINACH),
  ];

  //  Frozen Snacks & Meals List
  static final List<CollapsibleGridModel> frozenSnacksMealsList = [
    CollapsibleGridModel(
        icon: "dairy_items/french_fries.png",
        label: AppStrings.labelFrozenFrenchFries,
        tagId: GroceryConstant.FROZEN_SNACK_FRIES),
    CollapsibleGridModel(
        icon: "dairy_items/veg_nuggets.png",
        label: AppStrings.labelFrozenVegNuggets,
        tagId: GroceryConstant.FROZEN_SNACK_VEG_NUGGETS),
    CollapsibleGridModel(
        icon: "dairy_items/burger_patty.png",
        label: AppStrings.labelFrozenChickenNuggets,
        tagId: GroceryConstant.FROZEN_SNACK_CHICKEN_NUGGETS),
    CollapsibleGridModel(
        icon: "dairy_items/smileys.png",
        label: AppStrings.labelFrozenSpringRolls,
        tagId: GroceryConstant.FROZEN_SNACK_SPRING_ROLLS),
    CollapsibleGridModel(
        icon: "dairy_items/aloo_tikki.png",
        label: AppStrings.labelFrozenSamosa,
        tagId: GroceryConstant.FROZEN_SNACK_SAMOSA),
    CollapsibleGridModel(
        icon: "dairy_items/paratha.png",
        label: AppStrings.labelFrozenParatha,
        tagId: GroceryConstant.FROZEN_SNACK_PARATHA),
    CollapsibleGridModel(
        icon: "dairy_items/momos.png",
        label: AppStrings.labelFrozenMomos,
        tagId: GroceryConstant.FROZEN_SNACK_MOMOS),
    CollapsibleGridModel(
        icon: "dairy_items/spring_rolls.png",
        label: AppStrings.labelFrozenVegCutlet,
        tagId: GroceryConstant.FROZEN_SNACK_SPRING_ROLLS),
  ];

  // Milk Powders and Dairy Alternatives List
  static final List<CollapsibleGridModel> milkPowdersAlternativesList = [
    CollapsibleGridModel(
        icon: "dairy_items/skimmed_milk_powder.png",
        label: AppStrings.labelSkimmedMilkPowder,
        tagId: GroceryConstant.DAIRY_SKIMMED_MILK_POWDER),
    CollapsibleGridModel(
        icon: "dairy_items/full_cream_milk_powder.png",
        label: AppStrings.labelFullCreamMilkPowder,
        tagId: GroceryConstant.DAIRY_FULL_CREAM_MILK_POWDER),
    CollapsibleGridModel(
        icon: "dairy_items/infant_formula.png",
        label: AppStrings.labelInfantMilkFormula,
        tagId: GroceryConstant.DAIRY_INFANT_MILK_FORMULA),
    CollapsibleGridModel(
        icon: "dairy_items/condensed_milk.png",
        label: AppStrings.labelCondensedMilk,
        tagId: GroceryConstant.DAIRY_CONDENSED_MILK),
    CollapsibleGridModel(
        icon: "dairy_items/evaporated_milk.png",
        label: AppStrings.labelEvaporatedMilk,
        tagId: GroceryConstant.DAIRY_EVAPORATED_MILK),
    CollapsibleGridModel(
        icon: "dairy_items/soy_milk.png",
        label: AppStrings.labelSoyMilk,
        tagId: GroceryConstant.DAIRY_ALT_SOY_MILK),
    CollapsibleGridModel(
        icon: "dairy_items/almond_milk.png",
        label: AppStrings.labelAlmondMilk,
        tagId: GroceryConstant.DAIRY_ALT_ALMOND_MILK),
    CollapsibleGridModel(
        icon: "dairy_items/oats_milk.png",
        label: AppStrings.labelOatsMilk,
        tagId: GroceryConstant.DAIRY_ALT_OATS_MILK),
  ];

}

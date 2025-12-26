import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_constant.dart';

class GroceryData {
  /// Super Grocery Categories
  static const List<CollapsibleGridModel> grocerySuperCategories = [
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItems,
        label: AppStrings.labelGroceryItems,
        tagId: GroceryConstant.GROCERY_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.vegetables,
        label: AppStrings.labelVegetable,
        tagId: GroceryConstant.VEGETABLES),
    CollapsibleGridModel(
        icon: AppIconAssets.fruits,
        label: AppStrings.labelFruit,
        tagId: GroceryConstant.FRUITS),
    CollapsibleGridModel(
        icon: AppIconAssets.bakeryNamkeenItems,
        label: AppStrings.labelBakeryBreadItems,
        tagId: GroceryConstant.BAKERY_NAMKEEN_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.dairyFrozenItems,
        label: AppStrings.labelDairyProducts,
        tagId: GroceryConstant.DAIRY_FROZEN_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.crockery,
        label: AppStrings.labelCrockery,
        tagId: GroceryConstant.CROCKERY),
    CollapsibleGridModel(
        icon: AppIconAssets.homeEssentials,
        label: AppStrings.labelHomeEssentials,
        tagId: GroceryConstant.HOME_ESSENTIALS),
    CollapsibleGridModel(
        icon: AppIconAssets.cleaningMaintenance,
        label: AppStrings.labelCleaningMaintenance,
        tagId: GroceryConstant.CLEANING_MAINTENANCE),
    CollapsibleGridModel(
        icon: AppIconAssets.beautyHealthCare,
        label: AppStrings.labelBeautyHealthCare,
        tagId: GroceryConstant.BEAUTY_HEALTH_CARE),
    CollapsibleGridModel(
        icon: AppIconAssets.stationary,
        label: AppStrings.labelStationary,
        tagId: GroceryConstant.STATIONARY),
  ];

  /// Grocery Item
  static const List<CollapsibleGridModel> riceProducts = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.basmatiRice,
        label: AppStrings.labelBasmatiRice,
        tagId: GroceryConstant.RICE_BASMATI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.redRice,
        label: AppStrings.labelRedRice,
        tagId: GroceryConstant.RICE_RED),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.kolamRice,
        label: AppStrings.labelKolamRice,
        tagId: GroceryConstant.RICE_KOLAM),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.ponniRice,
        label: AppStrings.labelPonniRice,
        tagId: GroceryConstant.RICE_PONNI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.parboiledRice,
        label: AppStrings.labelParboiledRice,
        tagId: GroceryConstant.RICE_PARBOILED),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.brownRice,
        label: AppStrings.labelBrownRice,
        tagId: GroceryConstant.RICE_BROWN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sonaMasooriRice,
        label: AppStrings.labelSonaMasooriRice,
        tagId: GroceryConstant.RICE_SONA_MASOORI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.blackRice,
        label: AppStrings.labelBlackRice,
        tagId: GroceryConstant.RICE_BLACK),
  ];

  static List<CollapsibleGridModel> wheatAndFlours = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.wholeWheatAtta,
        label: AppStrings.labelWholeWheatAtta,
        tagId: GroceryConstant.FLOUR_WHOLE_WHEAT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.chakkiAtta,
        label: AppStrings.labelChakkiAtta,
        tagId: GroceryConstant.FLOUR_CHAKKI_ATTA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sharbatiAtta,
        label: AppStrings.labelSharbatiAtta,
        tagId: GroceryConstant.FLOUR_SHARBATI_ATTA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.multigrainAtta,
        label: AppStrings.labelMultigrainAtta,
        tagId: GroceryConstant.FLOUR_MULTIGRAIN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.diabeticAtta,
        label: AppStrings.labelDiabeticFriendlyAtta,
        tagId: GroceryConstant.FLOUR_DIABETIC),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.maida,
        label: AppStrings.labelMaida,
        tagId: GroceryConstant.FLOUR_MAIDA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.besan,
        label: AppStrings.labelBesan,
        tagId: GroceryConstant.FLOUR_BESAN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.riceFlour,
        label: AppStrings.labelRiceFlour,
        tagId: GroceryConstant.FLOUR_RICE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.ragiFlour,
        label: AppStrings.labelRagiFlour,
        tagId: GroceryConstant.FLOUR_RAGI),
  ];

  static const List<CollapsibleGridModel> dalNdBeans = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.toorDal,
        label: AppStrings.labelToorDal,
        tagId: GroceryConstant.DAL_TOOR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.moongDal,
        label: AppStrings.labelMoongDal,
        tagId: GroceryConstant.DAL_MOONG),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.masoorDal,
        label: AppStrings.labelMasoorDal,
        tagId: GroceryConstant.DAL_MASOOR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.uradDal,
        label: AppStrings.labelUradDal,
        tagId: GroceryConstant.DAL_URAD),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.chanaDal,
        label: AppStrings.labelChanaDal,
        tagId: GroceryConstant.DAL_CHANA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.kabuliChana,
        label: AppStrings.labelKabuliChana,
        tagId: GroceryConstant.DAL_KABULI_CHANA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.kalaChana,
        label: AppStrings.labelKalaChana,
        tagId: GroceryConstant.DAL_KALA_CHANA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.rajma,
        label: AppStrings.labelRajma,
        tagId: GroceryConstant.DAL_RAJMA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.dryGreenPeas,
        label: AppStrings.labelDryGreenPeas,
        tagId: GroceryConstant.DAL_DRY_GREEN_PEAS),
  ];

  static const List<CollapsibleGridModel> milletsNdTraditionalGrains = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.ragi,
        label: AppStrings.labelRagi,
        tagId: GroceryConstant.MILLET_RAGI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.jowar,
        label: AppStrings.labelJowar,
        tagId: GroceryConstant.MILLET_JOWAR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.bajra,
        label: AppStrings.labelBajra,
        tagId: GroceryConstant.MILLET_BAJRA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.foxtailMillet,
        label: AppStrings.labelFoxtailMillet,
        tagId: GroceryConstant.MILLET_FOXTAIL),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.littleMillet,
        label: AppStrings.labelLittleMillet,
        tagId: GroceryConstant.MILLET_LITTLE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.kodoMillet,
        label: AppStrings.labelKodoMillet,
        tagId: GroceryConstant.MILLET_KODO),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.barnyardMillet,
        label: AppStrings.labelBarnyardMillet,
        tagId: GroceryConstant.MILLET_BARNYARD),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.samakRice,
        label: AppStrings.labelSamakRice,
        tagId: GroceryConstant.RICE_SAMAK),
  ];

  static const List<CollapsibleGridModel> breakfastStaples = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.poha,
        label: AppStrings.labelPoha,
        tagId: GroceryConstant.STAPLE_POHA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.aval,
        label: AppStrings.labelAvalRiceFlakes,
        tagId: GroceryConstant.STAPLE_AVAL),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.dalia,
        label: AppStrings.labelDaliaBrokenWheat,
        tagId: GroceryConstant.STAPLE_DALIA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.oats,
        label: AppStrings.labelOats,
        tagId: GroceryConstant.STAPLE_OATS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cornGrits,
        label: AppStrings.labelCornGrits,
        tagId: GroceryConstant.STAPLE_CORN_GRITS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.wheatBran,
        label: AppStrings.labelWheatBran,
        tagId: GroceryConstant.STAPLE_WHEAT_BRAN),
  ];

  static const List<CollapsibleGridModel> spicesAndMasala = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cumin,
        label: AppStrings.labelCuminSeeds,
        tagId: GroceryConstant.SPICE_CUMIN_SEEDS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.corianderSeeds,
        label: AppStrings.labelCorianderSeeds,
        tagId: GroceryConstant.SPICE_CORIANDER_SEEDS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.blackPepper,
        label: AppStrings.labelBlackPepper,
        tagId: GroceryConstant.SPICE_BLACK_PEPPER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.greenCardamom,
        label: AppStrings.labelGreenCardamom,
        tagId: GroceryConstant.SPICE_GREEN_CARDAMOM),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cloves,
        label: AppStrings.labelCloves,
        tagId: GroceryConstant.SPICE_CLOVES),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cinnamon,
        label: AppStrings.labelCinnamon,
        tagId: GroceryConstant.SPICE_CINNAMON),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.turmeric,
        label: AppStrings.labelTurmericPowder,
        tagId: GroceryConstant.SPICE_TURMERIC_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.redChilli,
        label: AppStrings.labelRedChilliPowder,
        tagId: GroceryConstant.SPICE_RED_CHILLI_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.corianderPowder,
        label: AppStrings.labelCorianderPowder,
        tagId: GroceryConstant.SPICE_CORIANDER_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.garamMasala,
        label: AppStrings.labelGaramMasala,
        tagId: GroceryConstant.MASALA_GARAM),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.chaatMasala,
        label: AppStrings.labelChaatMasala,
        tagId: GroceryConstant.MASALA_CHAAT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sambharMasala,
        label: AppStrings.labelSambharMasala,
        tagId: GroceryConstant.MASALA_SAMBHAR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.biryaniMasala,
        label: AppStrings.labelBiryaniMasala,
        tagId: GroceryConstant.MASALA_BIRYANI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.choleMasala,
        label: AppStrings.labelCholeMasala,
        tagId: GroceryConstant.MASALA_CHOLE),
  ];

  static const List<CollapsibleGridModel> saltNdSweeteners = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.iodizedSalt,
        label: AppStrings.labelIodizedSalt,
        tagId: GroceryConstant.SWEET_IODIZED_SALT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.rockSalt,
        label: AppStrings.labelRockSalt,
        tagId: GroceryConstant.SWEET_ROCK_SALT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.pinkSalt,
        label: AppStrings.labelPinkSalt,
        tagId: GroceryConstant.SWEET_PINK_SALT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.whiteSugar,
        label: AppStrings.labelWhiteSugar,
        tagId: GroceryConstant.SWEET_WHITE_SUGAR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.brownSugar,
        label: AppStrings.labelBrownSugar,
        tagId: GroceryConstant.SWEET_BROWN_SUGAR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.jaggery,
        label: AppStrings.labelJaggery,
        tagId: GroceryConstant.SWEET_JAGGERY),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.honey,
        label: AppStrings.labelHoney,
        tagId: GroceryConstant.SWEET_HONEY),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sugarFree,
        label: AppStrings.labelSugarFreeSweetener,
        tagId: GroceryConstant.SWEET_SUGAR_FREE),
  ];

  static const List<CollapsibleGridModel> oilsAndFats = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sunflowerOil,
        label: AppStrings.labelSunflowerOil,
        tagId: GroceryConstant.OIL_SUNFLOWER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.riceBranOil,
        label: AppStrings.labelRiceBranOil,
        tagId: GroceryConstant.OIL_RICE_BRAN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.mustardOil,
        label: AppStrings.labelMustardOil,
        tagId: GroceryConstant.OIL_MUSTARD),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.groundnutOil,
        label: AppStrings.labelGroundnutOil,
        tagId: GroceryConstant.OIL_GROUNDNUT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sesameOil,
        label: AppStrings.labelSesameOil,
        tagId: GroceryConstant.OIL_SESAME),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.coconutOil,
        label: AppStrings.labelCoconutOil,
        tagId: GroceryConstant.OIL_COCONUT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.oliveOil,
        label: AppStrings.labelOliveOil,
        tagId: GroceryConstant.OIL_OLIVE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cowGhee,
        label: AppStrings.labelCowGheeStaple,
        tagId: GroceryConstant.GHEE_COW),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.desiGhee,
        label: AppStrings.labelDesiGheeStaple,
        tagId: GroceryConstant.GHEE_DESI),
  ];

  static const List<CollapsibleGridModel> teaCoffeeBeverages = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.assamTea,
        label: AppStrings.labelAssamTea,
        tagId: GroceryConstant.BEV_ASSAM_TEA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.greenTea,
        label: AppStrings.labelGreenTeaBeverage,
        tagId: GroceryConstant.BEV_GREEN_TEA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.masalaTea,
        label: AppStrings.labelMasalaTea,
        tagId: GroceryConstant.BEV_MASALA_TEA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.instantCoffee,
        label: AppStrings.labelInstantCoffee,
        tagId: GroceryConstant.BEV_INSTANT_COFFEE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.filterCoffee,
        label: AppStrings.labelFilterCoffee,
        tagId: GroceryConstant.BEV_FILTER_COFFEE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.maltDrink,
        label: AppStrings.labelMaltHealthDrink,
        tagId: GroceryConstant.BEV_MALT_HEALTH_DRINK),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.glucosePowder,
        label: AppStrings.labelGlucoseDrinkPowder,
        tagId: GroceryConstant.BEV_GLUCOSE_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.coconutWater,
        label: AppStrings.labelCoconutWater,
        tagId: GroceryConstant.BEV_COCONUT_WATER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.drinkingWater,
        label: AppStrings.labelPackagedDrinkingWater,
        tagId: GroceryConstant.BEV_DRINKING_WATER),
  ];

  static const List<CollapsibleGridModel> dryFruitsAndReadyFood = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.almonds,
        label: AppStrings.labelAlmonds,
        tagId: GroceryConstant.DRY_ALMONDS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cashews,
        label: AppStrings.labelCashewNuts,
        tagId: GroceryConstant.DRY_CASHEWS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.raisins,
        label: AppStrings.labelRaisins,
        tagId: GroceryConstant.DRY_RAISINS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.dates,
        label: AppStrings.labelDates,
        tagId: GroceryConstant.DRY_DATES),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.dryFig,
        label: AppStrings.labelDryFig,
        tagId: GroceryConstant.DRY_FIG),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.chiaSeeds,
        label: AppStrings.labelChiaSeeds,
        tagId: GroceryConstant.SEED_CHIA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.flaxSeeds,
        label: AppStrings.labelFlaxSeeds,
        tagId: GroceryConstant.SEED_FLAX),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.pumpkinSeeds,
        label: AppStrings.labelPumpkinSeeds,
        tagId: GroceryConstant.SEED_PUMPKIN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.babyMilk,
        label: AppStrings.labelBabyMilkPowder,
        tagId: GroceryConstant.BABY_MILK_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.riceCereal,
        label: AppStrings.labelRiceCereal,
        tagId: GroceryConstant.BABY_RICE_CEREAL),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.khichdiMix,
        label: AppStrings.labelKhichdiMix,
        tagId: GroceryConstant.BABY_KHICHDI_MIX),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.babyBiscuits,
        label: AppStrings.labelBabyBiscuits,
        tagId: GroceryConstant.BABY_BISCUITS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.readyPoha,
        label: AppStrings.labelReadyPoha,
        tagId: GroceryConstant.READY_POHA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.readyUpma,
        label: AppStrings.labelReadyUpma,
        tagId: GroceryConstant.READY_UPMA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.readyDal,
        label: AppStrings.labelReadyDal,
        tagId: GroceryConstant.READY_DAL),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.papad,
        label: AppStrings.labelPapadStaple,
        tagId: GroceryConstant.ACC_PAPAD),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.ketchup,
        label: AppStrings.labelTomatoKetchup,
        tagId: GroceryConstant.ACC_KETCHUP),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.mangoPickle,
        label: AppStrings.labelMangoPickle,
        tagId: GroceryConstant.ACC_PICKLE_MANGO),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.lemonPickle,
        label: AppStrings.labelLemonPickle,
        tagId: GroceryConstant.ACC_PICKLE_LEMON),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.mixedPickle,
        label: AppStrings.labelMixedVegetablePickle,
        tagId: GroceryConstant.ACC_PICKLE_MIXED),
  ];

  /// VEGETABLE
  static const List<CollapsibleGridModel> leafyVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spinach, label: AppStrings.labelSpinach, tagId: GroceryConstant.VEG_LEAFY_SPINACH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fenugreek, label: AppStrings.labelFenugreek, tagId: GroceryConstant.VEG_LEAFY_FENUGREEK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mustardGreens, label: AppStrings.labelMustardGreens, tagId: GroceryConstant.VEG_LEAFY_MUSTARD_GREENS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mint, label: AppStrings.labelMint, tagId: GroceryConstant.VEG_LEAFY_MINT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.coriander, label: AppStrings.labelCorianderLeaves, tagId: GroceryConstant.VEG_LEAFY_CORIANDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.amaranth, label: AppStrings.labelAmaranth, tagId: GroceryConstant.VEG_LEAFY_AMARANTH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathua, label: AppStrings.labelBathua, tagId: GroceryConstant.VEG_LEAFY_BATHUA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.malabarSpinach, label: AppStrings.labelMalabarSpinach, tagId: GroceryConstant.VEG_LEAFY_MALABAR_SPINACH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drumstickLeaves, label: AppStrings.labelDrumstickLeaves, tagId: GroceryConstant.VEG_LEAFY_DRUMSTICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dillLeaves, label: AppStrings.labelDillLeaves, tagId: GroceryConstant.VEG_LEAFY_DILL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.taroLeaves, label: AppStrings.labelTaroLeaves, tagId: GroceryConstant.VEG_LEAFY_TARO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.curryLeaves, label: AppStrings.labelCurryLeaves, tagId: GroceryConstant.VEG_LEAFY_CURRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lettuceIndian, label: AppStrings.labelLettuceIndian, tagId: GroceryConstant.VEG_LEAFY_LETTUCE_INDIAN),
  ];

  static final List<CollapsibleGridModel> rootVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.potato, label: AppStrings.labelPotato, tagId: GroceryConstant.VEG_ROOT_POTATO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sweetPotato, label: AppStrings.labelSweetPotato, tagId: GroceryConstant.VEG_ROOT_SWEET_POTATO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.carrot, label: AppStrings.labelCarrot, tagId: GroceryConstant.VEG_ROOT_CARROT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.radish, label: AppStrings.labelRadish, tagId: GroceryConstant.VEG_ROOT_RADISH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.beetroot, label: AppStrings.labelBeetroot, tagId: GroceryConstant.VEG_ROOT_BEETROOT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.turnip, label: AppStrings.labelTurnip, tagId: GroceryConstant.VEG_ROOT_TURNIP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.yam, label: AppStrings.labelYam, tagId: GroceryConstant.VEG_ROOT_YAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.taroRoot, label: AppStrings.labelTaroRoot, tagId: GroceryConstant.VEG_ROOT_TARO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.elephantFootYam, label: AppStrings.labelElephantFootYam, tagId: GroceryConstant.VEG_ROOT_ELEPHANT_FOOT_YAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cassava, label: AppStrings.labelCassava, tagId: GroceryConstant.VEG_ROOT_CASSAVA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lotusRoot, label: AppStrings.labelLotusRoot, tagId: GroceryConstant.VEG_ROOT_LOTUS_ROOT),
  ];

  static final List<CollapsibleGridModel> bulbNdStemVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.onion, label: AppStrings.labelOnion, tagId: GroceryConstant.VEG_BULB_ONION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.garlic, label: AppStrings.labelGarlic, tagId: GroceryConstant.VEG_BULB_GARLIC),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.leek, label: AppStrings.labelLeek, tagId: GroceryConstant.VEG_STEM_LEEK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.springOnion, label: AppStrings.labelSpringOnion, tagId: GroceryConstant.VEG_STEM_SPRING_ONION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bananaStem, label: AppStrings.labelBananaStem, tagId: GroceryConstant.VEG_STEM_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.colocasiaStem, label: AppStrings.labelColocasiaStem, tagId: GroceryConstant.VEG_STEM_COLOCASIA),
  ];

  static final List<CollapsibleGridModel> fruitVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tomato, label: AppStrings.labelTomato, tagId: GroceryConstant.VEG_FRUIT_TOMATO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.brinjal, label: AppStrings.labelBrinjalEggplant, tagId: GroceryConstant.VEG_FRUIT_BRINJAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bottleGourd, label: AppStrings.labelBottleGourd, tagId: GroceryConstant.VEG_GOURD_BOTTLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bitterGourd, label: AppStrings.labelBitterGourd, tagId: GroceryConstant.VEG_GOURD_BITTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ridgeGourd, label: AppStrings.labelRidgeGourd, tagId: GroceryConstant.VEG_GOURD_RIDGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spongeGourd, label: AppStrings.labelSpongeGourd, tagId: GroceryConstant.VEG_GOURD_SPONGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.snakeGourd, label: AppStrings.labelSnakeGourd, tagId: GroceryConstant.VEG_GOURD_SNAKE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pumpkin, label: AppStrings.labelPumpkin, tagId: GroceryConstant.VEG_FRUIT_PUMPKIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cucumber, label: AppStrings.labelCucumber, tagId: GroceryConstant.VEG_FRUIT_CUCUMBER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ashGourd, label: AppStrings.labelAshGourd, tagId: GroceryConstant.VEG_GOURD_ASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pointedGourd, label: AppStrings.labelPointedGourd, tagId: GroceryConstant.VEG_GOURD_POINTED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ivyGourd, label: AppStrings.labelIvyGourd, tagId: GroceryConstant.VEG_GOURD_IVY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tinda, label: AppStrings.labelTinda, tagId: GroceryConstant.VEG_FRUIT_TINDA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chowChow, label: AppStrings.labelChowChowChayote, tagId: GroceryConstant.VEG_FRUIT_CHOW_CHOW),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rawBanana, label: AppStrings.labelRawBanana, tagId: GroceryConstant.VEG_RAW_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rawPapaya, label: AppStrings.labelRawPapaya, tagId: GroceryConstant.VEG_RAW_PAPAYA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.capsicum, label: AppStrings.labelCapsicumBellPepper, tagId: GroceryConstant.VEG_FRUIT_CAPSICUM),
  ];

  static final List<CollapsibleGridModel> podNdBeansVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.greenPeas, label: AppStrings.labelGreenPeas, tagId: GroceryConstant.VEG_POD_GREEN_PEAS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frenchBeans, label: AppStrings.labelFrenchBeans, tagId: GroceryConstant.VEG_BEAN_FRENCH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clusterBeans, label: AppStrings.labelClusterBeans, tagId: GroceryConstant.VEG_BEAN_CLUSTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cowpea, label: AppStrings.labelCowpea, tagId: GroceryConstant.VEG_BEAN_COWPEA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hyacinthBeans, label: AppStrings.labelHyacinthBeans, tagId: GroceryConstant.VEG_BEAN_HYACINTH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.broadBeans, label: AppStrings.labelBroadBeans, tagId: GroceryConstant.VEG_BEAN_BROAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wingedBeans, label: AppStrings.labelWingedBeans, tagId: GroceryConstant.VEG_BEAN_WINGED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.yardlongBeans, label: AppStrings.labelYardlongBeans, tagId: GroceryConstant.VEG_BEAN_YARDLONG),
  ];

  static final List<CollapsibleGridModel> flowerVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cauliflower, label: AppStrings.labelCauliflower, tagId: GroceryConstant.VEG_FLOWER_CAULIFLOWER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.broccoli, label: AppStrings.labelBroccoli, tagId: GroceryConstant.VEG_FLOWER_BROCCOLI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bananaFlower, label: AppStrings.labelBananaFlower, tagId: GroceryConstant.VEG_FLOWER_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pumpkinFlower, label: AppStrings.labelPumpkinFlower, tagId: GroceryConstant.VEG_FLOWER_PUMPKIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drumstickFlower, label: AppStrings.labelDrumstickFlower, tagId: GroceryConstant.VEG_FLOWER_DRUMSTICK),
  ];

  static final List<CollapsibleGridModel> fungiNdSpecialIndianItems = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mushroom, label: AppStrings.labelMushroom, tagId: GroceryConstant.VEG_FUNGI_MUSHROOM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.greenChilli, label: AppStrings.labelGreenChilli, tagId: GroceryConstant.VEG_SPECIAL_GREEN_CHILLI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ginger, label: AppStrings.labelGinger, tagId: GroceryConstant.VEG_SPECIAL_GINGER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.turmericFresh, label: AppStrings.labelTurmericFresh, tagId: GroceryConstant.VEG_SPECIAL_TURMERIC_FRESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drumstick, label: AppStrings.labelDrumstick, tagId: GroceryConstant.VEG_SPECIAL_DRUMSTICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rawJackfruit, label: AppStrings.labelRawJackfruit, tagId: GroceryConstant.VEG_SPECIAL_RAW_JACKFRUIT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bambooShoot, label: AppStrings.labelBambooShoot, tagId: GroceryConstant.VEG_SPECIAL_BAMBOO_SHOOT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kokum, label: AppStrings.labelKokum, tagId: GroceryConstant.VEG_SPECIAL_KOKUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sundakkai, label: AppStrings.labelSundakkaiTurkeyBerry, tagId: GroceryConstant.VEG_SPECIAL_SUNDAKKAI),
  ];

  static final List<CollapsibleGridModel> exoticAndSpecialty = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.zucchini, label: AppStrings.labelZucchini, tagId: GroceryConstant.VEG_EXOTIC_ZUCCHINI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.celery, label: AppStrings.labelCelery, tagId: GroceryConstant.VEG_EXOTIC_CELERY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.asparagus, label: AppStrings.labelAsparagus, tagId: GroceryConstant.VEG_EXOTIC_ASPARAGUS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bokChoy, label: AppStrings.labelBokChoy, tagId: GroceryConstant.VEG_EXOTIC_BOK_CHOY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lettuceIceberg, label: AppStrings.labelLettuceIcebergRomaine, tagId: GroceryConstant.VEG_EXOTIC_LETTUCE_ICEBERG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kale, label: AppStrings.labelKale, tagId: GroceryConstant.VEG_EXOTIC_KALE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chineseCabbage, label: AppStrings.labelChineseCabbage, tagId: GroceryConstant.VEG_EXOTIC_CHINESE_CABBAGE),
  ];

  /// FRUIT
  static final List<CollapsibleGridModel> dailyFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.apple, label: AppStrings.labelApple, tagId: GroceryConstant.FRUIT_DAILY_APPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.banana, label: AppStrings.labelBanana, tagId: GroceryConstant.FRUIT_DAILY_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.orange, label: AppStrings.labelOrange, tagId: GroceryConstant.FRUIT_DAILY_ORANGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mosambi, label: AppStrings.labelMosambiSweetLime, tagId: GroceryConstant.FRUIT_DAILY_MOSAMBI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.grapes, label: AppStrings.labelGrapes, tagId: GroceryConstant.FRUIT_DAILY_GRAPES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.papaya, label: AppStrings.labelPapaya, tagId: GroceryConstant.FRUIT_DAILY_PAPAYA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pomegranate, label: AppStrings.labelPomegranate, tagId: GroceryConstant.FRUIT_DAILY_POMEGRANATE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.guava, label: AppStrings.labelGuava, tagId: GroceryConstant.FRUIT_DAILY_GUAVA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pear, label: AppStrings.labelPear, tagId: GroceryConstant.FRUIT_DAILY_PEAR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chikoo, label: AppStrings.labelChikooSapota, tagId: GroceryConstant.FRUIT_DAILY_CHIKOO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pineapple, label: AppStrings.labelPineapple, tagId: GroceryConstant.FRUIT_DAILY_PINEAPPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.watermelon, label: AppStrings.labelWatermelon, tagId: GroceryConstant.FRUIT_DAILY_WATERMELON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.muskmelon, label: AppStrings.labelMuskmelon, tagId: GroceryConstant.FRUIT_DAILY_MUSKMELON),
  ];

  static final List<CollapsibleGridModel> desiFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mango, label: AppStrings.labelMango, tagId: GroceryConstant.FRUIT_DESI_MANGO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jackfruit, label: AppStrings.labelJackfruit, tagId: GroceryConstant.FRUIT_DESI_JACKFRUIT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jamun, label: AppStrings.labelJamun, tagId: GroceryConstant.FRUIT_DESI_JAMUN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.custardApple, label: AppStrings.labelCustardApple, tagId: GroceryConstant.FRUIT_DESI_CUSTARD_APPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ber, label: AppStrings.labelBerIndianJujube, tagId: GroceryConstant.FRUIT_DESI_BER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.soursop, label: AppStrings.labelSoursop, tagId: GroceryConstant.FRUIT_DESI_SOURSOP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.woodApple, label: AppStrings.labelWoodAppleBael, tagId: GroceryConstant.FRUIT_DESI_WOOD_APPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tamarind, label: AppStrings.labelTamarind, tagId: GroceryConstant.FRUIT_DESI_TAMARIND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.monkeyJack, label: AppStrings.labelMonkeyJack, tagId: GroceryConstant.FRUIT_DESI_MONKEY_JACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fig, label: AppStrings.labelIndianFigAnjeer, tagId: GroceryConstant.FRUIT_DESI_FIG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.khirni, label: AppStrings.labelKhirniRayan, tagId: GroceryConstant.FRUIT_DESI_KHIRNI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.karonda, label: AppStrings.labelKaronda, tagId: GroceryConstant.FRUIT_DESI_KARONDA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.amla, label: AppStrings.labelIndianGooseberryAmla, tagId: GroceryConstant.FRUIT_DESI_AMLA),
  ];

  static final List<CollapsibleGridModel> sourAndStoneFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lemon, label: AppStrings.labelLemon, tagId: GroceryConstant.FRUIT_SOUR_LEMON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lime, label: AppStrings.labelLime, tagId: GroceryConstant.FRUIT_SOUR_LIME),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kinnow, label: AppStrings.labelKinnow, tagId: GroceryConstant.FRUIT_SOUR_KINNOW),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pomelo, label: AppStrings.labelPomelo, tagId: GroceryConstant.FRUIT_SOUR_POMELO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.citron, label: AppStrings.labelCitron, tagId: GroceryConstant.FRUIT_SOUR_CITRON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.galgal, label: AppStrings.labelGalgal, tagId: GroceryConstant.FRUIT_SOUR_GALGAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.peach, label: AppStrings.labelPeach, tagId: GroceryConstant.FRUIT_STONE_PEACH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plum, label: AppStrings.labelPlum, tagId: GroceryConstant.FRUIT_STONE_PLUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.apricot, label: AppStrings.labelApricot, tagId: GroceryConstant.FRUIT_STONE_APRICOT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cherry, label: AppStrings.labelCherry, tagId: GroceryConstant.FRUIT_STONE_CHERRY),
  ];

  static final List<CollapsibleGridModel> smallNdSeasonalFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.strawberry, label: AppStrings.labelStrawberry, tagId: GroceryConstant.FRUIT_SEASONAL_STRAWBERRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mulberry, label: AppStrings.labelMulberry, tagId: GroceryConstant.FRUIT_SEASONAL_MULBERRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.raspberry, label: AppStrings.labelRaspberry, tagId: GroceryConstant.FRUIT_SEASONAL_RASPBERRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.blueberry, label: AppStrings.labelBlueberry, tagId: GroceryConstant.FRUIT_SEASONAL_BLUEBERRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.phalsa, label: AppStrings.labelPhalsa, tagId: GroceryConstant.FRUIT_SEASONAL_PHALSA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.litchi, label: AppStrings.labelLitchi, tagId: GroceryConstant.FRUIT_SEASONAL_LITCHI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.loquat, label: AppStrings.labelLoquat, tagId: GroceryConstant.FRUIT_SEASONAL_LOQUAT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.starFruit, label: AppStrings.labelStarFruitCarambola, tagId: GroceryConstant.FRUIT_SEASONAL_STAR_FRUIT),
    // CollapsibleGridModel(icon: GroceryIconCategoryAssets.capsicumFruit, label: AppStrings.labelCapsicumBellPepper, tagId: GroceryConstant.FRUIT_SEASONAL_Capsicum_Bell_PEPPER),
  ];

  static final List<CollapsibleGridModel> forestNdCoastalFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.coconut, label: AppStrings.labelCoconut, tagId: GroceryConstant.FRUIT_COASTAL_COCONUT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tenderCoconut, label: AppStrings.labelTenderCoconut, tagId: GroceryConstant.FRUIT_COASTAL_TENDER_COCONUT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceApple, label: AppStrings.labelIceApple, tagId: GroceryConstant.FRUIT_COASTAL_ICE_APPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toddyPalm, label: AppStrings.labelToddyPalmFruit, tagId: GroceryConstant.FRUIT_COASTAL_TODDY_PALM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nungu, label: AppStrings.labelNungu, tagId: GroceryConstant.FRUIT_COASTAL_NUNGU),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.freshDates, label: AppStrings.labelDate, tagId: GroceryConstant.FRUIT_FOREST_DATE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mahua, label: AppStrings.labelMahuaFruit, tagId: GroceryConstant.FRUIT_FOREST_MAHUA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chironjiFruit, label: AppStrings.labelChironjiFruit, tagId: GroceryConstant.FRUIT_FOREST_CHIRONJI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tenduFruit, label: AppStrings.labelTenduFruit, tagId: GroceryConstant.FRUIT_FOREST_TENDU),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kaafal, label: AppStrings.labelKaafal, tagId: GroceryConstant.FRUIT_FOREST_KAAFAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wildJamun, label: AppStrings.labelWildJamun, tagId: GroceryConstant.FRUIT_FOREST_WILD_JAMUN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wildBanana, label: AppStrings.labelWildBanana, tagId: GroceryConstant.FRUIT_FOREST_WILD_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.breadfruit, label: AppStrings.labelBreadfruit, tagId: GroceryConstant.FRUIT_COASTAL_BREADFRUIT),
  ];

  static final List<CollapsibleGridModel> specialNdExoticFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kiwi, label: AppStrings.labelKiwi, tagId: GroceryConstant.FRUIT_EXOTIC_KIWI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dragonFruit, label: AppStrings.labelDragonFruit, tagId: GroceryConstant.FRUIT_EXOTIC_DRAGON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.avocado, label: AppStrings.labelAvocado, tagId: GroceryConstant.FRUIT_EXOTIC_AVOCADO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.passionFruit, label: AppStrings.labelPassionFruit, tagId: GroceryConstant.FRUIT_EXOTIC_PASSION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mangosteen, label: AppStrings.labelMangosteen, tagId: GroceryConstant.FRUIT_EXOTIC_MANGOSTEEN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.longan, label: AppStrings.labelLongan, tagId: GroceryConstant.FRUIT_EXOTIC_LONGAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rambutan, label: AppStrings.labelRambutan, tagId: GroceryConstant.FRUIT_EXOTIC_RAMBUTAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.durian, label: AppStrings.labelDurian, tagId: GroceryConstant.FRUIT_EXOTIC_DURIAN),
  ];

  /// BAKERY & NAMKEEN ITEMS
// Namkeen & Mixture List
  static final List<CollapsibleGridModel> namkeenAndMixture = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.alooBhujia, label: AppStrings.labelAlooBhujia, tagId: GroceryConstant.SNACK_NAMKEEN_ALOO_BHUJIA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sev, label: AppStrings.labelSev, tagId: GroceryConstant.SNACK_NAMKEEN_SEV),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mixture, label: AppStrings.labelMixture, tagId: GroceryConstant.SNACK_NAMKEEN_MIXTURE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.boondi, label: AppStrings.labelBoondi, tagId: GroceryConstant.SNACK_NAMKEEN_BOONDI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.moongDalNamkeen, label: AppStrings.labelMoongDalNamkeen, tagId: GroceryConstant.SNACK_NAMKEEN_MOONG_DAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chanaDalNamkeen, label: AppStrings.labelChanaDalNamkeen, tagId: GroceryConstant.SNACK_NAMKEEN_CHANA_DAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.peanutsNamkeen, label: AppStrings.labelPeanutsNamkeen, tagId: GroceryConstant.SNACK_NAMKEEN_PEANUTS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ghatiya, label: AppStrings.labelGhatiya, tagId: GroceryConstant.SNACK_GHATIYA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.farsan, label: AppStrings.labelFarsanMix, tagId: GroceryConstant.SNACK_NAMKEEN_FARSAN),
  ];

// Chips, Papad & Fryums List
  static final List<CollapsibleGridModel> chipsPapadFryums = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.potatoChips, label: AppStrings.labelPotatoChips, tagId: GroceryConstant.SNACK_CHIPS_POTATO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bananaChips, label: AppStrings.labelBananaChips, tagId: GroceryConstant.SNACK_CHIPS_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tapiocaChips, label: AppStrings.labelTapiocaChips, tagId: GroceryConstant.SNACK_CHIPS_TAPIOCA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cornChips, label: AppStrings.labelCornChips, tagId: GroceryConstant.SNACK_CHIPS_CORN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multigrainChips, label: AppStrings.labelMultigrainChips, tagId: GroceryConstant.SNACK_CHIPS_MULTIGRAIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nachoChips, label: AppStrings.labelNachoChips, tagId: GroceryConstant.SNACK_CHIPS_NACHO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.uradPapad, label: AppStrings.labelUradPapad, tagId: GroceryConstant.SNACK_PAPAD_URAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ricePapad, label: AppStrings.labelRicePapad, tagId: GroceryConstant.SNACK_PAPAD_RICE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sabudanaPapad, label: AppStrings.labelSabudanaPapad, tagId: GroceryConstant.SNACK_PAPAD_SABUDANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.appalam, label: AppStrings.labelAppalam, tagId: GroceryConstant.SNACK_PAPAD_APPALAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fryums, label: AppStrings.labelFryums, tagId: GroceryConstant.SNACK_FRYUMS),
  ];

// Biscuits & Cookies
  static final List<CollapsibleGridModel> biscuitsCookies = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glucoseBiscuit, label: AppStrings.labelGlucoseBiscuits, tagId: GroceryConstant.BISCUIT_GLUCOSE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.marieBiscuit, label: AppStrings.labelMarieBiscuits, tagId: GroceryConstant.BISCUIT_MARIE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.milkBiscuit, label: AppStrings.labelMilkBiscuits, tagId: GroceryConstant.BISCUIT_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.creamBiscuit, label: AppStrings.labelCreamBiscuits, tagId: GroceryConstant.BISCUIT_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.arrowrootBiscuit, label: AppStrings.labelArrowrootBiscuits, tagId: GroceryConstant.BISCUIT_ARROWROOT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sandwichBiscuit, label: AppStrings.labelSandwichBiscuits, tagId: GroceryConstant.BISCUIT_SANDWICH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multigrainBiscuit, label: AppStrings.labelMultigrainBiscuits, tagId: GroceryConstant.BISCUIT_MULTIGRAIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.digestiveBiscuit, label: AppStrings.labelDigestiveBiscuits, tagId: GroceryConstant.BISCUIT_DIGESTIVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jeeraBiscuit, label: AppStrings.labelJeeraBiscuits, tagId: GroceryConstant.BISCUIT_JEERA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.butterBiscuit, label: AppStrings.labelButterBiscuits, tagId: GroceryConstant.BISCUIT_BUTTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jamBiscuit, label: AppStrings.labelJamBiscuits, tagId: GroceryConstant.BISCUIT_JAM),
  ];

// Bread, Bakery & Sweet Items
  static final List<CollapsibleGridModel> bakeryItems = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whiteBread, label: AppStrings.labelWhiteBread, tagId: GroceryConstant.BAKERY_WHITE_BREAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.brownBread, label: AppStrings.labelBrownBread, tagId: GroceryConstant.BAKERY_BROWN_BREAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multigrainBread, label: AppStrings.labelMultigrainBread, tagId: GroceryConstant.BAKERY_MULTIGRAIN_BREAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pavBread, label: AppStrings.labelPavBread, tagId: GroceryConstant.BAKERY_PAV),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.burgerBuns, label: AppStrings.labelBurgerBuns, tagId: GroceryConstant.BAKERY_BURGER_BUNS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pizzaBase, label: AppStrings.labelPizzaBase, tagId: GroceryConstant.BAKERY_PIZZA_BASE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.breadCrumbs, label: AppStrings.labelBreadCrumbs, tagId: GroceryConstant.BAKERY_BREAD_CRUMBS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.khari, label: AppStrings.labelKhariBiscuit, tagId: GroceryConstant.BAKERY_KHARI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rusk, label: AppStrings.labelRusk, tagId: GroceryConstant.BAKERY_RUSK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cake, label: AppStrings.labelCake, tagId: GroceryConstant.BAKERY_CAKE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cupCake, label: AppStrings.labelCupCake, tagId: GroceryConstant.BAKERY_CUP_CAKE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.muffins, label: AppStrings.labelMuffins, tagId: GroceryConstant.BAKERY_MUFFINS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.swissRoll, label: AppStrings.labelSwissRoll, tagId: GroceryConstant.BAKERY_SWISS_ROLL),
  ];

// Fried & Hot Snacks
  static final List<CollapsibleGridModel> friedHotSnacks = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.samosa, label: AppStrings.labelSamosa, tagId: GroceryConstant.SNACK_HOT_SAMOSA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vegPuff, label: AppStrings.labelVegPuff, tagId: GroceryConstant.SNACK_HOT_VEG_PUFF),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vegPatties, label: AppStrings.labelVegPatties, tagId: GroceryConstant.SNACK_HOT_VEG_PATTIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pizzaPatties, label: AppStrings.labelPizzaPatties, tagId: GroceryConstant.SNACK_HOT_PIZZA_PATTIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vegCutlet, label: AppStrings.labelVegCutlet, tagId: GroceryConstant.SNACK_HOT_VEG_CUTLET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.breadRoll, label: AppStrings.labelBreadRoll, tagId: GroceryConstant.SNACK_HOT_BREAD_ROLL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.springRoll, label: AppStrings.labelSpringRoll, tagId: GroceryConstant.SNACK_HOT_SPRING_ROLL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dryKachori, label: AppStrings.labelDryKachori, tagId: GroceryConstant.SNACK_HOT_DRY_KACHORI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.khakhra, label: AppStrings.labelKhakhra, tagId: GroceryConstant.SNACK_DRY_KHAKHRA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chakli, label: AppStrings.labelChakli, tagId: GroceryConstant.SNACK_DRY_CHAKLI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.murukku, label: AppStrings.labelMurukku, tagId: GroceryConstant.SNACK_DRY_MURUKKU),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.popcorn, label: AppStrings.labelPopcorn, tagId: GroceryConstant.SNACK_DRY_POPCORN),
  ];

  /// DAIRY & FROZEN ITEMS
  // Milk List
  static final List<CollapsibleGridModel> milkList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fullCreamMilk, label: AppStrings.labelFullCreamMilk, tagId: GroceryConstant.DAIRY_MILK_FULL_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tonedMilk, label: AppStrings.labelTonedMilk, tagId: GroceryConstant.DAIRY_MILK_TONED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.doubleTonedMilk, label: AppStrings.labelDoubleTonedMilk, tagId: GroceryConstant.DAIRY_MILK_DOUBLE_TONED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.skimmedMilk, label: AppStrings.labelSkimmedMilk, tagId: GroceryConstant.DAIRY_MILK_SKIMMED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cowMilk, label: AppStrings.labelCowMilk, tagId: GroceryConstant.DAIRY_MILK_COW),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.buffaloMilk, label: AppStrings.labelBuffaloMilk, tagId: GroceryConstant.DAIRY_MILK_BUFFALO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.flavouredMilk, label: AppStrings.labelFlavouredMilk, tagId: GroceryConstant.DAIRY_MILK_FLAVOURED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lactoseFreeMilk, label: AppStrings.labelLactoseFreeMilk, tagId: GroceryConstant.DAIRY_MILK_LACTOSE_FREE),
  ];

// Curd, Buttermilk and Cream List
  static final List<CollapsibleGridModel> curdButtermilkCreamList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.freshCurd, label: AppStrings.labelFreshCurd, tagId: GroceryConstant.DAIRY_CURD_FRESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.setCurd, label: AppStrings.labelSetCurd, tagId: GroceryConstant.DAIRY_CURD_SET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.greekYogurt, label: AppStrings.labelGreekYogurt, tagId: GroceryConstant.DAIRY_YOGURT_GREEK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.flavouredYogurt, label: AppStrings.labelFlavouredYogurt, tagId: GroceryConstant.DAIRY_YOGURT_FLAVOURED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.butterMilk, label: AppStrings.labelButterMilk, tagId: GroceryConstant.DAIRY_BUTTER_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.namkeenChaas, label: AppStrings.labelNamkeenChhaach, tagId: GroceryConstant.DAIRY_CHAAS_NAMKEEN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lassi, label: AppStrings.labelLassi, tagId: GroceryConstant.DAIRY_LASSI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.freshCream, label: AppStrings.labelFreshCream, tagId: GroceryConstant.DAIRY_CREAM_FRESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cookingCream, label: AppStrings.labelCookingCream, tagId: GroceryConstant.DAIRY_CREAM_COOKING),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whippingCream, label: AppStrings.labelWhippingCream, tagId: GroceryConstant.DAIRY_CREAM_WHIPPING),
  ];

// Butter, Cheese and Paneer List
  static final List<CollapsibleGridModel> butterCheesePaneerList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tableButter, label: AppStrings.labelTableButter, tagId: GroceryConstant.DAIRY_BUTTER_TABLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whiteButter, label: AppStrings.labelWhiteButter, tagId: GroceryConstant.DAIRY_BUTTER_WHITE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.saltedButter, label: AppStrings.labelSaltedButter, tagId: GroceryConstant.DAIRY_BUTTER_SALTED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.unsaltedButter, label: AppStrings.labelUnsaltedButter, tagId: GroceryConstant.DAIRY_BUTTER_UNSALTED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cheeseSlices, label: AppStrings.labelCheeseSlices, tagId: GroceryConstant.DAIRY_CHEESE_SLICES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cheeseBlocks, label: AppStrings.labelCheeseBlocks, tagId: GroceryConstant.DAIRY_CHEESE_BLOCKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cheeseSpread, label: AppStrings.labelCheeseSpread, tagId: GroceryConstant.DAIRY_CHEESE_SPREAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.freshPaneer, label: AppStrings.labelFreshPaneer, tagId: GroceryConstant.DAIRY_PANEER_FRESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.malaiPaneer, label: AppStrings.labelMalaiPaneer, tagId: GroceryConstant.DAIRY_PANEER_MALAI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenPaneer, label: AppStrings.labelFrozenPaneer, tagId: GroceryConstant.DAIRY_PANEER_FROZEN),
  ];

// Ghee and Dairy Fats List
  static final List<CollapsibleGridModel> gheeAndDairyFatsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cowGheeDairy, label: AppStrings.labelCowGheeStaple, tagId: GroceryConstant.DAIRY_GHEE_COW),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.buffaloGhee, label: AppStrings.labelBuffaloGhee, tagId: GroceryConstant.DAIRY_GHEE_BUFFALO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.a2Ghee, label: AppStrings.labelA2Ghee, tagId: GroceryConstant.DAIRY_GHEE_A2),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.organicGhee, label: AppStrings.labelOrganicGhee, tagId: GroceryConstant.DAIRY_GHEE_ORGANIC),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.desiGheeDairy, label: AppStrings.labelDesiGheeStaple, tagId: GroceryConstant.DAIRY_GHEE_DESI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vanaspati, label: AppStrings.labelVanaspati, tagId: GroceryConstant.DAIRY_GHEE_VANASPATI),
  ];

// Ice Cream and Frozen Desserts List
  static final List<CollapsibleGridModel> iceCreamFrozenDessertsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceCreamCups, label: AppStrings.labelIceCreamCups, tagId: GroceryConstant.FROZEN_ICE_CREAM_CUPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.familyPacks, label: AppStrings.labelIceCreamFamilyPacks, tagId: GroceryConstant.FROZEN_ICE_CREAM_FAMILY_PACKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceCreamBars, label: AppStrings.labelIceCreamBars, tagId: GroceryConstant.FROZEN_ICE_CREAM_BARS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceCreamCones, label: AppStrings.labelIceCreamCones, tagId: GroceryConstant.FROZEN_ICE_CREAM_CONES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kulfi, label: AppStrings.labelKulfi, tagId: GroceryConstant.FROZEN_KULFI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.malaiKulfi, label: AppStrings.labelMalaiKulfi, tagId: GroceryConstant.FROZEN_MALAI_KULFI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.matkaKulfi, label: AppStrings.labelMatkaKulfi, tagId: GroceryConstant.FROZEN_MATKA_KULFI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenYogurt, label: AppStrings.labelFrozenYogurt, tagId: GroceryConstant.FROZEN_YOGURT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenDessert, label: AppStrings.labelFrozenDessert, tagId: GroceryConstant.FROZEN_DESSERT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceLollies, label: AppStrings.labelIceLollies, tagId: GroceryConstant.FROZEN_ICE_LOLLIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cassata, label: AppStrings.labelCassataIceCream, tagId: GroceryConstant.FROZEN_CASSATA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceCreamSandwich, label: AppStrings.labelIceCreamSandwich, tagId: GroceryConstant.FROZEN_ICE_CREAM_SANDWICH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fruitSorbet, label: AppStrings.labelFruitSorbet, tagId: GroceryConstant.FROZEN_FRUIT_SORBET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gelato, label: AppStrings.labelGelato, tagId: GroceryConstant.FROZEN_GELATO),
  ];

// Dairy Sweets and Chocolate
  static final List<CollapsibleGridModel> sweetsChocolatesList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.milkCake, label: AppStrings.labelMilkCake, tagId: GroceryConstant.SWEET_MILK_CAKE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kalakand, label: AppStrings.labelKalakand, tagId: GroceryConstant.SWEET_KALAKAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rasgulla, label: AppStrings.labelRasgulla, tagId: GroceryConstant.SWEET_RASGULLA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rasmalai, label: AppStrings.labelRasmalai, tagId: GroceryConstant.SWEET_RASMALAI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gulabJamun, label: AppStrings.labelGulabJamun, tagId: GroceryConstant.SWEET_GULAB_JAMUN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kajuKatli, label: AppStrings.labelKajuKatli, tagId: GroceryConstant.SWEET_KAJU_KATLI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pedha, label: AppStrings.labelPedha, tagId: GroceryConstant.SWEET_PEDHA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chamCham, label: AppStrings.labelChamCham, tagId: GroceryConstant.SWEET_CHAM_CHAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sandesh, label: AppStrings.labelSandesh, tagId: GroceryConstant.SWEET_SANDESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mishtiDoi, label: AppStrings.labelMishtiDoi, tagId: GroceryConstant.SWEET_MISHTI_DOI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.milkChocolate, label: AppStrings.labelMilkChocolate, tagId: GroceryConstant.CHOCO_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.darkChocolate, label: AppStrings.labelDarkChocolate, tagId: GroceryConstant.CHOCO_DARK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whiteChocolate, label: AppStrings.labelWhiteChocolate, tagId: GroceryConstant.CHOCO_WHITE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateBars, label: AppStrings.labelChocolateBars, tagId: GroceryConstant.CHOCO_BARS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateBlocks, label: AppStrings.labelChocolateBlocks, tagId: GroceryConstant.CHOCO_BLOCKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateCoins, label: AppStrings.labelChocolateCoins, tagId: GroceryConstant.CHOCO_COINS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateGiftPacks, label: AppStrings.labelChocolateGiftPacks, tagId: GroceryConstant.CHOCO_GIFT_PACKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateSyrup, label: AppStrings.labelChocolateSyrup, tagId: GroceryConstant.CHOCO_SYRUP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateSpread, label: AppStrings.labelChocolateSpread, tagId: GroceryConstant.CHOCO_SPREAD),
  ];

// Frozen Vegetables List
  static final List<CollapsibleGridModel> frozenVegetablesList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenPeas, label: AppStrings.labelFrozenGreenPeas, tagId: GroceryConstant.FROZEN_VEG_GREEN_PEAS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenCorn, label: AppStrings.labelFrozenSweetCorn, tagId: GroceryConstant.FROZEN_VEG_SWEET_CORN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenMixedVeg, label: AppStrings.labelFrozenMixedVegetables, tagId: GroceryConstant.FROZEN_VEG_MIXED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenBeans, label: AppStrings.labelFrozenFrenchBeans, tagId: GroceryConstant.FROZEN_VEG_FRENCH_BEANS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenCarrot, label: AppStrings.labelFrozenCarrot, tagId: GroceryConstant.FROZEN_VEG_CARROT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenSpinach, label: AppStrings.labelFrozenSpinach, tagId: GroceryConstant.FROZEN_VEG_SPINACH),
  ];

// Frozen Snacks & Meals List
  static final List<CollapsibleGridModel> frozenSnacksMealsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frenchFries, label: AppStrings.labelFrozenFrenchFries, tagId: GroceryConstant.FROZEN_SNACK_FRIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vegNuggets, label: AppStrings.labelFrozenVegNuggets, tagId: GroceryConstant.FROZEN_SNACK_VEG_NUGGETS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.burgerPatty, label: AppStrings.labelFrozenChickenNuggets, tagId: GroceryConstant.FROZEN_SNACK_CHICKEN_NUGGETS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.smileys, label: AppStrings.labelFrozenSpringRolls, tagId: GroceryConstant.FROZEN_SNACK_SPRING_ROLLS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.alooTikki, label: AppStrings.labelFrozenSamosa, tagId: GroceryConstant.FROZEN_SNACK_SAMOSA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paratha, label: AppStrings.labelFrozenParatha, tagId: GroceryConstant.FROZEN_SNACK_PARATHA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.momos, label: AppStrings.labelFrozenMomos, tagId: GroceryConstant.FROZEN_SNACK_MOMOS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.springRolls, label: AppStrings.labelFrozenVegCutlet, tagId: GroceryConstant.FROZEN_SNACK_SPRING_ROLLS),
  ];

// Milk Powders and Dairy Alternatives List
  static final List<CollapsibleGridModel> milkPowdersAlternativesList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.skimmedMilkPowder, label: AppStrings.labelSkimmedMilkPowder, tagId: GroceryConstant.DAIRY_SKIMMED_MILK_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fullCreamMilkPowder, label: AppStrings.labelFullCreamMilkPowder, tagId: GroceryConstant.DAIRY_FULL_CREAM_MILK_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.infantFormula, label: AppStrings.labelInfantMilkFormula, tagId: GroceryConstant.DAIRY_INFANT_MILK_FORMULA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.condensedMilk, label: AppStrings.labelCondensedMilk, tagId: GroceryConstant.DAIRY_CONDENSED_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.evaporatedMilk, label: AppStrings.labelEvaporatedMilk, tagId: GroceryConstant.DAIRY_EVAPORATED_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.soyMilk, label: AppStrings.labelSoyMilk, tagId: GroceryConstant.DAIRY_ALT_SOY_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.almondMilk, label: AppStrings.labelAlmondMilk, tagId: GroceryConstant.DAIRY_ALT_ALMOND_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.oatsMilk, label: AppStrings.labelOatsMilk, tagId: GroceryConstant.DAIRY_ALT_OATS_MILK),
  ];

  /// Crockery
// Cooking Utensils List
  static final List<CollapsibleGridModel> cookingUtensilsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pressureCooker, label: AppStrings.labelPressureCooker, tagId: GroceryConstant.UTENSIL_PRESSURE_COOKER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kadai, label: AppStrings.labelKadai, tagId: GroceryConstant.UTENSIL_KADAI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fryingPan, label: AppStrings.labelFryingPan, tagId: GroceryConstant.UTENSIL_FRYING_PAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tawa, label: AppStrings.labelTawa, tagId: GroceryConstant.UTENSIL_TAWA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.handi, label: AppStrings.labelHandi, tagId: GroceryConstant.UTENSIL_HANDI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.saucePan, label: AppStrings.labelSaucePan, tagId: GroceryConstant.UTENSIL_SAUCE_PAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stockPot, label: AppStrings.labelStockPot, tagId: GroceryConstant.UTENSIL_STOCK_POT),
  ];

  // Eating & Dining Utensils List
  static final List<CollapsibleGridModel> diningUtensilsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.thali, label: AppStrings.labelThali, tagId: GroceryConstant.UTENSIL_THALI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plate, label: AppStrings.labelPlate, tagId: GroceryConstant.UTENSIL_PLATE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ricePlate, label: AppStrings.labelRicePlate, tagId: GroceryConstant.UTENSIL_RICE_PLATE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.katori, label: AppStrings.labelKatori, tagId: GroceryConstant.UTENSIL_KATORI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bowl, label: AppStrings.labelBowl, tagId: GroceryConstant.UTENSIL_BOWL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glass, label: AppStrings.labelGlass, tagId: GroceryConstant.UTENSIL_GLASS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tumbler, label: AppStrings.labelTumbler, tagId: GroceryConstant.UTENSIL_TUMBLER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spoon, label: AppStrings.labelSpoon, tagId: GroceryConstant.UTENSIL_SPOON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fork, label: AppStrings.labelFork, tagId: GroceryConstant.UTENSIL_FORK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.knife, label: AppStrings.labelKnife, tagId: GroceryConstant.UTENSIL_KNIFE),
  ];

  // Serving Utensils List
  static final List<CollapsibleGridModel> servingUtensilsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.servingSpoon, label: AppStrings.labelServingSpoon, tagId: GroceryConstant.UTENSIL_SERVING_SPOON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ladle, label: AppStrings.labelLadle, tagId: GroceryConstant.UTENSIL_LADLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.servingBowl, label: AppStrings.labelServingBowl, tagId: GroceryConstant.UTENSIL_SERVING_BOWL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.servingTray, label: AppStrings.labelServingTray, tagId: GroceryConstant.UTENSIL_SERVING_TRAY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.servingHandi, label: AppStrings.labelServingHandi, tagId: GroceryConstant.UTENSIL_SERVING_HANDI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.casserole, label: AppStrings.labelCasserole, tagId: GroceryConstant.UTENSIL_CASSEROLE),
  ];

  // Kitchen Hand Tools List
  static final List<CollapsibleGridModel> kitchenToolsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rollingPin, label: AppStrings.labelRollingPin, tagId: GroceryConstant.UTENSIL_ROLLING_PIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chakla, label: AppStrings.labelChakla, tagId: GroceryConstant.UTENSIL_CHAKLA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.peeler, label: AppStrings.labelPeeler, tagId: GroceryConstant.UTENSIL_PEELER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.grater, label: AppStrings.labelGrater, tagId: GroceryConstant.UTENSIL_GRATER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chopper, label: AppStrings.labelChopper, tagId: GroceryConstant.UTENSIL_CHOPPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whisk, label: AppStrings.labelWhisk, tagId: GroceryConstant.UTENSIL_WHISK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spatula, label: AppStrings.labelSpatula, tagId: GroceryConstant.UTENSIL_SPATULA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tongs, label: AppStrings.labelTongs, tagId: GroceryConstant.UTENSIL_TONGS),
  ];

  // Kitchen Appliances List
  static final List<CollapsibleGridModel> kitchenAppliancesList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gasStove, label: AppStrings.labelGasStove, tagId: GroceryConstant.APPLIANCE_GAS_STOVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.induction, label: AppStrings.labelInductionCooktop, tagId: GroceryConstant.APPLIANCE_INDUCTION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mixerGrinder, label: AppStrings.labelMixerGrinder, tagId: GroceryConstant.APPLIANCE_MIXER_GRINDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.microwave, label: AppStrings.labelMicrowaveOven, tagId: GroceryConstant.APPLIANCE_MICROWAVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.otg, label: AppStrings.labelOTGOven, tagId: GroceryConstant.APPLIANCE_OTG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.electricKettle, label: AppStrings.labelElectricKettle, tagId: GroceryConstant.APPLIANCE_KETTLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toaster, label: AppStrings.labelToaster, tagId: GroceryConstant.APPLIANCE_TOASTER),
  ];

  // Storage & Carry Items List
  static final List<CollapsibleGridModel> storageCarryList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.storageContainer, label: AppStrings.labelStorageContainer, tagId: GroceryConstant.STORAGE_CONTAINER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.canister, label: AppStrings.labelCanister, tagId: GroceryConstant.STORAGE_CANISTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spiceBox, label: AppStrings.labelSpiceBox, tagId: GroceryConstant.STORAGE_SPICE_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jar, label: AppStrings.labelJar, tagId: GroceryConstant.STORAGE_JAR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lunchBox, label: AppStrings.labelLunchBox, tagId: GroceryConstant.STORAGE_LUNCH_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterBottle, label: AppStrings.labelWaterBottle, tagId: GroceryConstant.STORAGE_WATER_BOTTLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterJug, label: AppStrings.labelWaterJug, tagId: GroceryConstant.STORAGE_WATER_JUG),
  ];

// Gas & Water Utility Items List
  static final List<CollapsibleGridModel> utilityItemsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gasLighter, label: AppStrings.labelGasLighter, tagId: GroceryConstant.UTILITY_GAS_LIGHTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gasPipe, label: AppStrings.labelGasPipe, tagId: GroceryConstant.UTILITY_GAS_PIPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cylinderStand, label: AppStrings.labelCylinderStand, tagId: GroceryConstant.UTILITY_CYLINDER_STAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.panSupport, label: AppStrings.labelPanSupport, tagId: GroceryConstant.UTILITY_PAN_SUPPORT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterFilter, label: AppStrings.labelWaterFilter, tagId: GroceryConstant.UTILITY_WATER_FILTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.roPurifier, label: AppStrings.labelROPurifier, tagId: GroceryConstant.UTILITY_RO_PURIFIER),
  ];

// Cleaning & Kitchen Setup Items List
  static final List<CollapsibleGridModel> cleaningSetupList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishScrubber, label: AppStrings.labelDishScrubber, tagId: GroceryConstant.SETUP_DISH_SCRUBBER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sponge, label: AppStrings.labelSponge, tagId: GroceryConstant.SETUP_SPONGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishCloth, label: AppStrings.labelDishCloth, tagId: GroceryConstant.SETUP_DISH_CLOTH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.trashBin, label: AppStrings.labelTrashBin, tagId: GroceryConstant.SETUP_TRASH_BIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.apron, label: AppStrings.labelApron, tagId: GroceryConstant.SETUP_APRON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kitchenRack, label: AppStrings.labelKitchenRack, tagId: GroceryConstant.SETUP_KITCHEN_RACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plateStand, label: AppStrings.labelPlateStand, tagId: GroceryConstant.SETUP_PLATE_STAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bottleRack, label: AppStrings.labelBottleRack, tagId: GroceryConstant.SETUP_BOTTLE_RACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cutleryStand, label: AppStrings.labelCutleryStand, tagId: GroceryConstant.SETUP_CUTLERY_STAND),
  ];

  /// Home Essentials

// Electrical and Safety List
  static final List<CollapsibleGridModel> electricalSafetyList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ledBulbs, label: AppStrings.labelLedBulbs, tagId: GroceryConstant.HOME_LED_BULBS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tubeLights, label: AppStrings.labelTubeLights, tagId: GroceryConstant.HOME_TUBE_LIGHTS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nightLamp, label: AppStrings.labelNightLamp, tagId: GroceryConstant.HOME_NIGHT_LAMP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.extensionBoard, label: AppStrings.labelExtensionBoard, tagId: GroceryConstant.HOME_EXTENSION_BOARD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multiPlug, label: AppStrings.labelMultiPlug, tagId: GroceryConstant.HOME_MULTI_PLUG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.electricWire, label: AppStrings.labelElectricWire, tagId: GroceryConstant.HOME_ELECTRIC_WIRE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.batteries, label: AppStrings.labelBatteries, tagId: GroceryConstant.HOME_BATTERIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.emergencyLight, label: AppStrings.labelEmergencyLight, tagId: GroceryConstant.HOME_EMERGENCY_LIGHT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mosquitoNet, label: AppStrings.labelMosquitoNet, tagId: GroceryConstant.HOME_MOSQUITO_NET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.roomHeater, label: AppStrings.labelRoomHeater, tagId: GroceryConstant.HOME_ROOM_HEATER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hotWaterBag, label: AppStrings.labelHotWaterBag, tagId: GroceryConstant.HOME_HOT_WATER_BAG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.raincoat, label: AppStrings.labelRaincoat, tagId: GroceryConstant.HOME_RAINCOAT),
  ];

// Water and Storage List
  static final List<CollapsibleGridModel> waterStorageList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterPipe, label: AppStrings.labelWaterPipe, tagId: GroceryConstant.HOME_WATER_PIPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bucket, label: AppStrings.labelBucket, tagId: GroceryConstant.HOME_BUCKET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mug, label: AppStrings.labelMug, tagId: GroceryConstant.HOME_MUG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tapConnector, label: AppStrings.labelTapConnector, tagId: GroceryConstant.HOME_TAP_CONNECTOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterDrum, label: AppStrings.labelPlasticWaterDrum, tagId: GroceryConstant.HOME_WATER_DRUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.storageBox, label: AppStrings.labelPlasticStorageBox, tagId: GroceryConstant.HOME_STORAGE_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clothBag, label: AppStrings.labelClothStorageBag, tagId: GroceryConstant.HOME_CLOTH_BAG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wardrobeOrganizer, label: AppStrings.labelWardrobeOrganizer, tagId: GroceryConstant.HOME_WARDROBE_ORGANIZER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shoeRack, label: AppStrings.labelShoeRack, tagId: GroceryConstant.HOME_SHOE_RACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.storageBasket, label: AppStrings.labelStorageBasket, tagId: GroceryConstant.HOME_STORAGE_BASKET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hanger, label: AppStrings.labelHanger, tagId: GroceryConstant.HOME_HANGER),
  ];

// Home Utility List
  static final List<CollapsibleGridModel> homeUtilityList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bedsheet, label: AppStrings.labelBedsheet, tagId: GroceryConstant.HOME_BEDSHEET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pillowCover, label: AppStrings.labelPillowCover, tagId: GroceryConstant.HOME_PILLOW_COVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.blanket, label: AppStrings.labelBlanket, tagId: GroceryConstant.HOME_BLANKET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.curtains, label: AppStrings.labelCurtains, tagId: GroceryConstant.HOME_CURTAINS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.floorMat, label: AppStrings.labelFloorMat, tagId: GroceryConstant.HOME_FLOOR_MAT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plasticStool, label: AppStrings.labelPlasticStool, tagId: GroceryConstant.HOME_PLASTIC_STOOL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plasticChair, label: AppStrings.labelPlasticChair, tagId: GroceryConstant.HOME_PLASTIC_CHAIR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.foldableTable, label: AppStrings.labelFoldableTable, tagId: GroceryConstant.HOME_FOLDABLE_TABLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clothClips, label: AppStrings.labelClothClips, tagId: GroceryConstant.HOME_CLOTH_CLIPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dryingRope, label: AppStrings.labelClothesDryingRope, tagId: GroceryConstant.HOME_DRYING_ROPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hooksStand, label: AppStrings.labelHooksStand, tagId: GroceryConstant.HOME_HOOKS_STAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.umbrella, label: AppStrings.labelUmbrella, tagId: GroceryConstant.HOME_UMBRELLA),
  ];

// Puja Items List
  static final List<CollapsibleGridModel> pujaItemsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.agarbatti, label: AppStrings.labelAgarbatti, tagId: GroceryConstant.PUJA_AGARBATTI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dhoop, label: AppStrings.labelDhoop, tagId: GroceryConstant.PUJA_DHOOP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.camphor, label: AppStrings.labelCamphor, tagId: GroceryConstant.PUJA_CAMPHOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cottonWicks, label: AppStrings.labelCottonWicks, tagId: GroceryConstant.PUJA_COTTON_WICKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pujaOil, label: AppStrings.labelPujaOil, tagId: GroceryConstant.PUJA_OIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.diya, label: AppStrings.labelDiya, tagId: GroceryConstant.PUJA_DIYA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pujaThali, label: AppStrings.labelPujaThali, tagId: GroceryConstant.PUJA_THALI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bell, label: AppStrings.labelBell, tagId: GroceryConstant.PUJA_BELL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kumkum, label: AppStrings.labelKumkum, tagId: GroceryConstant.PUJA_KUMKUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chandan, label: AppStrings.labelChandan, tagId: GroceryConstant.PUJA_CHANDAN),
  ];

  /// Cleaning & Maintenance
// Laundry Care List
  static final List<CollapsibleGridModel> laundryCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.detergentPowder, label: AppStrings.labelDetergentPowder, tagId: GroceryConstant.CLEAN_DETERGENT_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.detergentLiquid, label: AppStrings.labelDetergentLiquid, tagId: GroceryConstant.CLEAN_DETERGENT_LIQUID),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.detergentBar, label: AppStrings.labelDetergentBar, tagId: GroceryConstant.CLEAN_DETERGENT_BAR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.washingSoap, label: AppStrings.labelWashingSoap, tagId: GroceryConstant.CLEAN_WASHING_SOAP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fabricSoftener, label: AppStrings.labelFabricSoftener, tagId: GroceryConstant.CLEAN_FABRIC_SOFTENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stainRemover, label: AppStrings.labelStainRemover, tagId: GroceryConstant.CLEAN_STAIN_REMOVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fabricConditioner, label: AppStrings.labelFabricConditioner, tagId: GroceryConstant.CLEAN_FABRIC_CONDITIONER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.laundryWhitener, label: AppStrings.labelLaundryWhitener, tagId: GroceryConstant.CLEAN_LAUNDRY_WHITENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fabricDisinfectant, label: AppStrings.labelFabricDisinfectant, tagId: GroceryConstant.CLEAN_FABRIC_DISINFECTANT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clothesFreshener, label: AppStrings.labelClothesFreshener, tagId: GroceryConstant.CLEAN_CLOTHES_FRESHENER),
  ];

// Bathroom Care List
  static final List<CollapsibleGridModel> bathroomCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toiletCleaner, label: AppStrings.labelToiletCleaner, tagId: GroceryConstant.CLEAN_TOILET_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathroomCleaner, label: AppStrings.labelBathroomCleaner, tagId: GroceryConstant.CLEAN_BATHROOM_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.limescaleRemover, label: AppStrings.labelLimescaleRemover, tagId: GroceryConstant.CLEAN_LIMESCALE_REMOVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toiletFreshenerBlock, label: AppStrings.labelToiletFreshenerBlock, tagId: GroceryConstant.CLEAN_TOILET_FRESHENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glassCleaner, label: AppStrings.labelGlassCleaner, tagId: GroceryConstant.CLEAN_GLASS_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drainCleaner, label: AppStrings.labelDrainCleaner, tagId: GroceryConstant.CLEAN_DRAIN_CLEANER),
  ];

// Kitchen Care List
  static final List<CollapsibleGridModel> kitchenCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishwashLiquid, label: AppStrings.labelDishwashLiquid, tagId: GroceryConstant.CLEAN_DISHWASH_LIQUID),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishwashBar, label: AppStrings.labelDishwashBar, tagId: GroceryConstant.CLEAN_DISHWASH_BAR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishwashPowder, label: AppStrings.labelDishwashPowder, tagId: GroceryConstant.CLEAN_DISHWASH_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishScrubberClean, label: AppStrings.labelDishScrubber, tagId: GroceryConstant.CLEAN_DISH_SCRUBBER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishwashingBrush, label: AppStrings.labelDishwashingBrush, tagId: GroceryConstant.CLEAN_DISHWASH_BRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sinkCleaner, label: AppStrings.labelSinkCleaner, tagId: GroceryConstant.CLEAN_SINK_CLEANER),
  ];

// Floor and Surface List
  static final List<CollapsibleGridModel> floorSurfaceList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.floorCleaner, label: AppStrings.labelFloorCleaner, tagId: GroceryConstant.CLEAN_FLOOR_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.surfaceCleaner, label: AppStrings.labelSurfaceCleaner, tagId: GroceryConstant.CLEAN_SURFACE_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multipurposeCleaner, label: AppStrings.labelMultipurposeCleaner, tagId: GroceryConstant.CLEAN_MULTIPURPOSE_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tileStoneCleaner, label: AppStrings.labelTileStoneCleaner, tagId: GroceryConstant.CLEAN_TILE_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.woodFurnitureCleaner, label: AppStrings.labelWoodFurnitureCleaner, tagId: GroceryConstant.CLEAN_WOOD_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.furniturePolish, label: AppStrings.labelFurniturePolish, tagId: GroceryConstant.CLEAN_FURNITURE_POLISH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.metalPolish, label: AppStrings.labelMetalPolish, tagId: GroceryConstant.CLEAN_METAL_POLISH),
  ];

// Cleaning Tools List
  static final List<CollapsibleGridModel> cleaningToolsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.broom, label: AppStrings.labelBroom, tagId: GroceryConstant.CLEAN_BROOM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mop, label: AppStrings.labelMop, tagId: GroceryConstant.CLEAN_MOP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.floorWiper, label: AppStrings.labelFloorWiper, tagId: GroceryConstant.CLEAN_FLOOR_WIPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cleaningCloth, label: AppStrings.labelCleaningCloth, tagId: GroceryConstant.CLEAN_CLOTH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.scrubBrush, label: AppStrings.labelScrubBrush, tagId: GroceryConstant.CLEAN_SCRUB_BRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bucketMug, label: AppStrings.labelBucketAndMug, tagId: GroceryConstant.CLEAN_BUCKET_MUG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dustpan, label: AppStrings.labelDustpan, tagId: GroceryConstant.CLEAN_DUSTPAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.garbageBags, label: AppStrings.labelGarbageBags, tagId: GroceryConstant.CLEAN_GARBAGE_BAGS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dustbin, label: AppStrings.labelDustbin, tagId: GroceryConstant.CLEAN_DUSTBIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.doormat, label: AppStrings.labelDoormat, tagId: GroceryConstant.CLEAN_DOORMAT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cleaningGloves, label: AppStrings.labelCleaningGloves, tagId: GroceryConstant.CLEAN_GLOVES),
  ];

// Pest and Air Care List
  static final List<CollapsibleGridModel> pestAirCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mosquitoRepellent, label: AppStrings.labelMosquitoRepellent, tagId: GroceryConstant.PEST_MOSQUITO_REPELLENT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mosquitoCoil, label: AppStrings.labelMosquitoCoil, tagId: GroceryConstant.PEST_MOSQUITO_COIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cockroachKiller, label: AppStrings.labelCockroachKiller, tagId: GroceryConstant.PEST_COCKROACH_KILLER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.antKiller, label: AppStrings.labelAntKiller, tagId: GroceryConstant.PEST_ANT_KILLER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ratControl, label: AppStrings.labelRatControl, tagId: GroceryConstant.PEST_RAT_CONTROL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.airFreshener, label: AppStrings.labelAirFreshener, tagId: GroceryConstant.PEST_AIR_FRESHENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.roomFreshener, label: AppStrings.labelRoomFreshener, tagId: GroceryConstant.PEST_ROOM_FRESHENER),
  ];

// Safety and Repair List
  static final List<CollapsibleGridModel> safetyRepairList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.adhesiveTapeRepair, label: AppStrings.labelAdhesiveTape, tagId: GroceryConstant.REPAIR_ADHESIVE_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.electricalTape, label: AppStrings.labelElectricalTape, tagId: GroceryConstant.REPAIR_ELECTRICAL_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wallHooksRepair, label: AppStrings.labelWallHooks, tagId: GroceryConstant.REPAIR_WALL_HOOKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nailsScrews, label: AppStrings.labelNailsAndScrews, tagId: GroceryConstant.REPAIR_NAILS_SCREWS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.generalAdhesive, label: AppStrings.labelGeneralAdhesive, tagId: GroceryConstant.REPAIR_GENERAL_ADHESIVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sealantPutty, label: AppStrings.labelSealantAndPutty, tagId: GroceryConstant.REPAIR_SEALANT_PUTTY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.matchbox, label: AppStrings.labelMatchbox, tagId: GroceryConstant.REPAIR_MATCHBOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lighterRepair, label: AppStrings.labelLighter, tagId: GroceryConstant.REPAIR_LIGHTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fireExtinguisher, label: AppStrings.labelFireExtinguisher, tagId: GroceryConstant.REPAIR_FIRE_EXTINGUISHER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shoePolish, label: AppStrings.labelShoePolish, tagId: GroceryConstant.REPAIR_SHOE_POLISH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shoeBrush, label: AppStrings.labelShoeBrush, tagId: GroceryConstant.REPAIR_SHOE_BRUSH),
  ];

/// Beauty & Health Care

// Bath and Body Care List
  static final List<CollapsibleGridModel> bathBodyCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathSoap, label: AppStrings.labelBathSoap, tagId: GroceryConstant.BEAUTY_BATH_SOAP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bodyWash, label: AppStrings.labelBodyWash, tagId: GroceryConstant.BEAUTY_BODY_WASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bodyScrub, label: AppStrings.labelBodyScrub, tagId: GroceryConstant.BEAUTY_BODY_SCRUB),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathSponge, label: AppStrings.labelBathSponge, tagId: GroceryConstant.BEAUTY_BATH_SPONGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathBrush, label: AppStrings.labelBathBrush, tagId: GroceryConstant.BEAUTY_BATH_BRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.talcumPowder, label: AppStrings.labelTalcumPowder, tagId: GroceryConstant.BEAUTY_TALCUM_POWDER),
  ];

// Skin Care List
  static final List<CollapsibleGridModel> skinCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.faceCream, label: AppStrings.labelFaceCream, tagId: GroceryConstant.BEAUTY_FACE_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bodyLotions, label: AppStrings.labelBodyLotion, tagId: GroceryConstant.BEAUTY_BODY_LOTION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.faceWash, label: AppStrings.labelFaceWash, tagId: GroceryConstant.BEAUTY_FACE_WASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.faceScrub, label: AppStrings.labelFaceScrub, tagId: GroceryConstant.BEAUTY_FACE_SCRUB),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.facePack, label: AppStrings.labelFacePack, tagId: GroceryConstant.BEAUTY_FACE_PACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sunscreen, label: AppStrings.labelSunscreenLotion, tagId: GroceryConstant.BEAUTY_SUNSCREEN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.handCream, label: AppStrings.labelHandCream, tagId: GroceryConstant.BEAUTY_HAND_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.footCream, label: AppStrings.labelFootCream, tagId: GroceryConstant.BEAUTY_FOOT_CREAM),
  ];

// Hair Care List
  static final List<CollapsibleGridModel> hairCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shampoo, label: AppStrings.labelShampoo, tagId: GroceryConstant.BEAUTY_SHAMPOO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.conditioner, label: AppStrings.labelConditioner, tagId: GroceryConstant.BEAUTY_CONDITIONER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hairOil, label: AppStrings.labelHairOil, tagId: GroceryConstant.BEAUTY_HAIR_OIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hairSerum, label: AppStrings.labelHairSerum, tagId: GroceryConstant.BEAUTY_HAIR_SERUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hairMask, label: AppStrings.labelHairMask, tagId: GroceryConstant.BEAUTY_HAIR_MASK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stylingProduct, label: AppStrings.labelHairStylingProduct, tagId: GroceryConstant.BEAUTY_STYLING_PROD),
  ];

// Oral Care List
  static final List<CollapsibleGridModel> oralCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toothpaste, label: AppStrings.labelToothpaste, tagId: GroceryConstant.BEAUTY_TOOTHPASTE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toothbrush, label: AppStrings.labelToothbrush, tagId: GroceryConstant.BEAUTY_TOOTHBRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mouthwash, label: AppStrings.labelMouthwash, tagId: GroceryConstant.BEAUTY_MOUTHWASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tongueCleaner, label: AppStrings.labelTongueCleaner, tagId: GroceryConstant.BEAUTY_TONGUE_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toothPowder, label: AppStrings.labelToothPowder, tagId: GroceryConstant.BEAUTY_TOOTH_POWDER),
  ];

// Men Grooming List
  static final List<CollapsibleGridModel> menGroomingList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shavingCream, label: AppStrings.labelShavingCream, tagId: GroceryConstant.BEAUTY_SHAVING_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.razor, label: AppStrings.labelRazor, tagId: GroceryConstant.BEAUTY_RAZOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.afterShave, label: AppStrings.labelAfterShaveLotion, tagId: GroceryConstant.BEAUTY_AFTER_SHAVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.beardCare, label: AppStrings.labelBeardCareProduct, tagId: GroceryConstant.BEAUTY_BEARD_CARE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.trimmer, label: AppStrings.labelTrimmer, tagId: GroceryConstant.BEAUTY_TRIMMER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.deodorant, label: AppStrings.labelDeodorant, tagId: GroceryConstant.BEAUTY_DEODORANT),
  ];

// Women Hygiene List
  static final List<CollapsibleGridModel> womenHygieneList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sanitaryPads, label: AppStrings.labelSanitaryPads, tagId: GroceryConstant.BEAUTY_SANITARY_PADS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tampons, label: AppStrings.labelTampons, tagId: GroceryConstant.BEAUTY_TAMPONS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.menstrualCups, label: AppStrings.labelMenstrualCups, tagId: GroceryConstant.BEAUTY_MENSTRUAL_CUPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.intimateWash, label: AppStrings.labelIntimateWash, tagId: GroceryConstant.BEAUTY_INTIMATE_WASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hygieneWipes, label: AppStrings.labelHygieneWipes, tagId: GroceryConstant.BEAUTY_HYGIENE_WIPES),
  ];

// Beauty and Cosmetics List
  static final List<CollapsibleGridModel> beautyCosmeticsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.facePowder, label: AppStrings.labelFacePowder, tagId: GroceryConstant.BEAUTY_FACE_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.foundation, label: AppStrings.labelFoundation, tagId: GroceryConstant.BEAUTY_FOUNDATION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lipstick, label: AppStrings.labelLipstick, tagId: GroceryConstant.BEAUTY_LIPSTICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lipBalm, label: AppStrings.labelLipbalm, tagId: GroceryConstant.BEAUTY_LIP_BALM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.eyeMakeup, label: AppStrings.labelEyeMakeup, tagId: GroceryConstant.BEAUTY_EYE_MAKEUP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nailPolish, label: AppStrings.labelNailPolish, tagId: GroceryConstant.BEAUTY_NAIL_POLISH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.makeupRemover, label: AppStrings.labelMakeupRemover, tagId: GroceryConstant.BEAUTY_MAKEUP_REMOVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.perfume, label: AppStrings.labelPerfume, tagId: GroceryConstant.BEAUTY_PERFUME),
  ];

// Bathroom Hygiene and Essentials List
  static final List<CollapsibleGridModel> bathroomHygieneList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.handWash, label: AppStrings.labelHandWash, tagId: GroceryConstant.BEAUTY_HAND_WASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.handSanitizer, label: AppStrings.labelHandSanitizer, tagId: GroceryConstant.BEAUTY_HAND_SANITIZER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toiletPaper, label: AppStrings.labelToiletPaper, tagId: GroceryConstant.BEAUTY_TOILET_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.facialTissues, label: AppStrings.labelFacialTissues, tagId: GroceryConstant.BEAUTY_FACIAL_TISSUES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paperTowels, label: AppStrings.labelPaperTowels, tagId: GroceryConstant.BEAUTY_PAPER_TOWELS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cotton, label: AppStrings.labelCotton, tagId: GroceryConstant.BEAUTY_COTTON),
  ];

// Baby Personal and Bath Care List
  static final List<CollapsibleGridModel> babyCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babySoap, label: AppStrings.labelBabySoap, tagId: GroceryConstant.BABY_SOAP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyShampoo, label: AppStrings.labelBabyShampoo, tagId: GroceryConstant.BABY_SHAMPOO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyOil, label: AppStrings.labelBabyOil, tagId: GroceryConstant.BABY_OIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyLotion, label: AppStrings.labelBabyLotion, tagId: GroceryConstant.BABY_LOTION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyPowder, label: AppStrings.labelBabyPowder, tagId: GroceryConstant.BABY_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyWipes, label: AppStrings.labelBabyWipes, tagId: GroceryConstant.BABY_WIPES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.diaperCream, label: AppStrings.labelBabyDiaperCream, tagId: GroceryConstant.BABY_DIAPER_CREAM),
  ];

// First Aid and Medical Essentials List
  static final List<CollapsibleGridModel> medicalEssentialsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.antisepticLiquid, label: AppStrings.labelAntisepticLiquid, tagId: GroceryConstant.MED_ANTISEPTIC_LIQUID),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.antisepticCream, label: AppStrings.labelAntisepticCream, tagId: GroceryConstant.MED_ANTISEPTIC_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cottonBandage, label: AppStrings.labelCottonBandage, tagId: GroceryConstant.MED_COTTON_BANDAGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.adhesiveBandage, label: AppStrings.labelAdhesiveBandage, tagId: GroceryConstant.MED_ADHESIVE_BANDAGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.crepeBandage, label: AppStrings.labelCrepeBandage, tagId: GroceryConstant.MED_CREPE_BANDAGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gauzePads, label: AppStrings.labelGauzePads, tagId: GroceryConstant.MED_GAUZE_PADS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.medicalTape, label: AppStrings.labelMedicalTape, tagId: GroceryConstant.MED_MEDICAL_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.painReliefSpray, label: AppStrings.labelPainReliefSpray, tagId: GroceryConstant.MED_PAIN_SPRAY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.burnOintment, label: AppStrings.labelBurnOintment, tagId: GroceryConstant.MED_BURN_OINTMENT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.thermometer, label: AppStrings.labelThermometer, tagId: GroceryConstant.MED_THERMOMETER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.disposableGloves, label: AppStrings.labelHandGlovesDisposable, tagId: GroceryConstant.MED_GLOVES),
  ];

  /// Stationary

// Writing, Paper & Notebooks List
  static final List<CollapsibleGridModel> writingPaperNotebooksList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pen, label: AppStrings.labelPen, tagId: GroceryConstant.STATIONARY_PEN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pencil, label: AppStrings.labelPencil, tagId: GroceryConstant.STATIONARY_PENCIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mechanicalPencil, label: AppStrings.labelMechanicalPencil, tagId: GroceryConstant.STATIONARY_MECH_PENCIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.marker, label: AppStrings.labelMarker, tagId: GroceryConstant.STATIONARY_MARKER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.highlighter, label: AppStrings.labelHighlighter, tagId: GroceryConstant.STATIONARY_HIGHLIGHTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.notebook, label: AppStrings.labelNotebook, tagId: GroceryConstant.STATIONARY_NOTEBOOK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.copy, label: AppStrings.labelCopy, tagId: GroceryConstant.STATIONARY_COPY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.register, label: AppStrings.labelRegister, tagId: GroceryConstant.STATIONARY_REGISTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.roughCopy, label: AppStrings.labelRoughCopy, tagId: GroceryConstant.STATIONARY_ROUGH_COPY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.loosePaper, label: AppStrings.labelLoosePaper, tagId: GroceryConstant.STATIONARY_LOOSE_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stickyNotes, label: AppStrings.labelStickyNotes, tagId: GroceryConstant.STATIONARY_STICKY_NOTES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.diary, label: AppStrings.labelDiary, tagId: GroceryConstant.STATIONARY_DIARY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.decorativeDiary, label: AppStrings.labelDecorativeDiary, tagId: GroceryConstant.STATIONARY_DECO_DIARY),
  ];

// School Essentials List
  static final List<CollapsibleGridModel> schoolEssentialsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolBag, label: AppStrings.labelSchoolBag, tagId: GroceryConstant.STATIONARY_SCHOOL_BAG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.geometryBox, label: AppStrings.labelGeometryBox, tagId: GroceryConstant.STATIONARY_GEOMETRY_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.eraser, label: AppStrings.labelEraser, tagId: GroceryConstant.STATIONARY_ERASER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sharpener, label: AppStrings.labelSharpener, tagId: GroceryConstant.STATIONARY_SHARPENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.scale, label: AppStrings.labelScale, tagId: GroceryConstant.STATIONARY_SCALE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.compass, label: AppStrings.labelCompass, tagId: GroceryConstant.STATIONARY_COMPASS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.divider, label: AppStrings.labelDivider, tagId: GroceryConstant.STATIONARY_DIVIDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolWaterBottle, label: AppStrings.labelSchoolWaterBottle, tagId: GroceryConstant.STATIONARY_SCHOOL_WATER_BOTTLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolLunchBox, label: AppStrings.labelLunchBoxSchool, tagId: GroceryConstant.STATIONARY_SCHOOL_LUNCH_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolIdCard, label: AppStrings.labelSchoolIdCardHolder, tagId: GroceryConstant.STATIONARY_SCHOOL_ID_HOLDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolLabelStickers, label: AppStrings.labelSchoolLabelStickers, tagId: GroceryConstant.STATIONARY_SCHOOL_LABELS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kidsPencilBox, label: AppStrings.labelKidsPencilBox, tagId: GroceryConstant.STATIONARY_KIDS_PENCIL_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolGlueStick, label: AppStrings.labelSchoolGlueStick, tagId: GroceryConstant.STATIONARY_SCHOOL_GLUE_STICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kidsCrayons, label: AppStrings.labelKidsCrayons, tagId: GroceryConstant.STATIONARY_KIDS_CRAYONS),
  ];

// Office, Desk & Utility List
  static final List<CollapsibleGridModel> officeDeskUtilityList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.filesFolders, label: AppStrings.labelFilesAndFolders, tagId: GroceryConstant.STATIONARY_FILES_FOLDERS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clipFile, label: AppStrings.labelClipFile, tagId: GroceryConstant.STATIONARY_CLIP_FILE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ringBinder, label: AppStrings.labelRingBinder, tagId: GroceryConstant.STATIONARY_RING_BINDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.envelope, label: AppStrings.labelEnvelope, tagId: GroceryConstant.STATIONARY_ENVELOPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.officeRegister, label: AppStrings.labelOfficeRegister, tagId: GroceryConstant.STATIONARY_OFFICE_REGISTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paperClips, label: AppStrings.labelPaperClips, tagId: GroceryConstant.STATIONARY_PAPER_CLIPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.binderClips, label: AppStrings.labelBinderClips, tagId: GroceryConstant.STATIONARY_BINDER_CLIPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rubberBands, label: AppStrings.labelRubberBands, tagId: GroceryConstant.STATIONARY_RUBBER_BANDS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.thumbPins, label: AppStrings.labelThumbPins, tagId: GroceryConstant.STATIONARY_THUMB_PINS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.calculator, label: AppStrings.labelCalculator, tagId: GroceryConstant.STATIONARY_CALCULATOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.penStand, label: AppStrings.labelPenStand, tagId: GroceryConstant.STATIONARY_PEN_STAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.deskTray, label: AppStrings.labelDeskTray, tagId: GroceryConstant.STATIONARY_DESK_TRAY),
  ];

// Art, Craft & Project Work List
  static final List<CollapsibleGridModel> artCraftProjectList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.colourPencils, label: AppStrings.labelColourPencils, tagId: GroceryConstant.STATIONARY_COLOUR_PENCILS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.crayons, label: AppStrings.labelCrayons, tagId: GroceryConstant.STATIONARY_CRAYONS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.posterColours, label: AppStrings.labelPosterColours, tagId: GroceryConstant.STATIONARY_POSTER_COLOURS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterColours, label: AppStrings.labelWaterColours, tagId: GroceryConstant.STATIONARY_WATER_COLOURS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paintBrush, label: AppStrings.labelPaintBrush, tagId: GroceryConstant.STATIONARY_PAINT_BRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drawingBook, label: AppStrings.labelDrawingBook, tagId: GroceryConstant.STATIONARY_DRAWING_BOOK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.artCraftKits, label: AppStrings.labelArtCraftKits, tagId: GroceryConstant.STATIONARY_ART_CRAFT_KITS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glitterPack, label: AppStrings.labelGlitterPack, tagId: GroceryConstant.STATIONARY_GLITTER_PACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.projectFile, label: AppStrings.labelProjectFile, tagId: GroceryConstant.STATIONARY_PROJECT_FILE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.projectCover, label: AppStrings.labelProjectCoverSheet, tagId: GroceryConstant.STATIONARY_PROJECT_COVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chartPaper, label: AppStrings.labelChartPaper, tagId: GroceryConstant.STATIONARY_CHART_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.examPad, label: AppStrings.labelExamPad, tagId: GroceryConstant.STATIONARY_EXAM_PAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.answerSheets, label: AppStrings.labelAnswerSheets, tagId: GroceryConstant.STATIONARY_ANSWER_SHEETS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.practicalFile, label: AppStrings.labelPracticalFile, tagId: GroceryConstant.STATIONARY_PRACTICAL_FILE),
  ];

// Cutting, Fixing & Packing List
  static final List<CollapsibleGridModel> cuttingFixingPackingList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.scissors, label: AppStrings.labelScissors, tagId: GroceryConstant.STATIONARY_SCISSORS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paperCutter, label: AppStrings.labelPaperCutter, tagId: GroceryConstant.STATIONARY_PAPER_CUTTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.measuringScale, label: AppStrings.labelMeasuringScale, tagId: GroceryConstant.STATIONARY_MEASURING_SCALE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.measuringTape, label: AppStrings.labelMeasuringTape, tagId: GroceryConstant.STATIONARY_MEASURING_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fevicol, label: AppStrings.labelFevicol, tagId: GroceryConstant.STATIONARY_FEVICOL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glueStick, label: AppStrings.labelGlueStick, tagId: GroceryConstant.STATIONARY_GLUE_STICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.adhesiveTapeStat, label: AppStrings.labelAdhesiveTapeStationary, tagId: GroceryConstant.STATIONARY_ADHESIVE_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stapler, label: AppStrings.labelStapler, tagId: GroceryConstant.STATIONARY_STAPLER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.staplerPins, label: AppStrings.labelStaplerPins, tagId: GroceryConstant.STATIONARY_STAPLER_PINS),
  ];

// Printing, Gifts & Decor List
  static final List<CollapsibleGridModel> printingGiftsDecorList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.a4Paper, label: AppStrings.labelA4Paper, tagId: GroceryConstant.STATIONARY_A4_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.printerPaper, label: AppStrings.labelPrinterPaper, tagId: GroceryConstant.STATIONARY_PRINTER_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.photoPaper, label: AppStrings.labelPhotoPaper, tagId: GroceryConstant.STATIONARY_PHOTO_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.inkCartridge, label: AppStrings.labelInkCartridge, tagId: GroceryConstant.STATIONARY_INK_CARTRIDGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tonerCartridge, label: AppStrings.labelTonerCartridge, tagId: GroceryConstant.STATIONARY_TONER_CARTRIDGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.usbDrive, label: AppStrings.labelUsbPenDrive, tagId: GroceryConstant.STATIONARY_USB_DRIVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.greetingCards, label: AppStrings.labelGreetingCards, tagId: GroceryConstant.STATIONARY_GREETING_CARDS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.giftEnvelopes, label: AppStrings.labelGiftEnvelopes, tagId: GroceryConstant.STATIONARY_GIFT_ENVELOPES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wrappingPaper, label: AppStrings.labelGiftWrappingPaper, tagId: GroceryConstant.STATIONARY_WRAPPING_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ribbons, label: AppStrings.labelRibbons, tagId: GroceryConstant.STATIONARY_RIBBONS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.giftBows, label: AppStrings.labelGiftBows, tagId: GroceryConstant.STATIONARY_GIFT_BOWS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.keyChain, label: AppStrings.labelKeyChain, tagId: GroceryConstant.STATIONARY_KEY_CHAIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wallet, label: AppStrings.labelWallet, tagId: GroceryConstant.STATIONARY_WALLET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.smallGifts, label: AppStrings.labelSmallUtilityGifts, tagId: GroceryConstant.STATIONARY_UTILITY_GIFTS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.softToys, label: AppStrings.labelSoftToys, tagId: GroceryConstant.STATIONARY_SOFT_TOYS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.showpieces, label: AppStrings.labelShowpieces, tagId: GroceryConstant.STATIONARY_SHOWPIECES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tableDecor, label: AppStrings.labelTableDecorItems, tagId: GroceryConstant.STATIONARY_TABLE_DECOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.photoFrames, label: AppStrings.labelPhotoFrames, tagId: GroceryConstant.STATIONARY_PHOTO_FRAMES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.giftBoxes, label: AppStrings.labelGiftBoxes, tagId: GroceryConstant.STATIONARY_GIFT_BOXES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.giftHampers, label: AppStrings.labelGiftHampers, tagId: GroceryConstant.STATIONARY_GIFT_HAMPERS),
  ];

}

import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/common/food/view/grocery/widget/grocery_constant.dart';

class GroceryData {
  /// Super Grocery Categories
  static const List<CollapsibleGridModel> grocerySuperCategories = [
    CollapsibleGridModel(
        icon: AppIconAssets.groceryItemsGrey,
        name: AppStrings.labelGroceryItems,
        slugId: GroceryConstant.GROCERY_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.vegetablesGrey,
        name: AppStrings.labelVegetable,
        slugId: GroceryConstant.VEGETABLES),
    CollapsibleGridModel(
        icon: AppIconAssets.fruitsGrey,
        name: AppStrings.labelFruit,
        slugId: GroceryConstant.FRUITS),
    CollapsibleGridModel(
        icon: AppIconAssets.bakeryNamkeenItemsGrey,
        name: AppStrings.labelBakeryBreadItems,
        slugId: GroceryConstant.BAKERY_NAMKEEN_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.dairyFrozenItemsGrey,
        name: AppStrings.labelDairyProducts,
        slugId: GroceryConstant.DAIRY_FROZEN_ITEMS),
    CollapsibleGridModel(
        icon: AppIconAssets.crockeryGrey,
        name: AppStrings.labelCrockery,
        slugId: GroceryConstant.CROCKERY),
    CollapsibleGridModel(
        icon: AppIconAssets.homeEssentialsGrey,
        name: AppStrings.labelHomeEssentials,
        slugId: GroceryConstant.HOME_ESSENTIALS),
    CollapsibleGridModel(
        icon: AppIconAssets.cleaningMaintenanceGrey,
        name: AppStrings.labelCleaningMaintenance,
        slugId: GroceryConstant.CLEANING_MAINTENANCE),
    CollapsibleGridModel(
        icon: AppIconAssets.beautyHealthCareGrey,
        name: AppStrings.labelBeautyHealthCare,
        slugId: GroceryConstant.BEAUTY_HEALTH_CARE),
    CollapsibleGridModel(
        icon: AppIconAssets.stationaryGrey,
        name: AppStrings.labelStationary,
        slugId: GroceryConstant.STATIONARY),
  ];

  /// Grocery Item
  static const List<CollapsibleGridModel> riceProducts = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.basmatiRice,
        name: AppStrings.labelBasmatiRice,
        slugId: GroceryConstant.RICE_BASMATI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.redRice,
        name: AppStrings.labelRedRice,
        slugId: GroceryConstant.RICE_RED),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.kolamRice,
        name: AppStrings.labelKolamRice,
        slugId: GroceryConstant.RICE_KOLAM),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.ponniRice,
        name: AppStrings.labelPonniRice,
        slugId: GroceryConstant.RICE_PONNI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.parboiledRice,
        name: AppStrings.labelParboiledRice,
        slugId: GroceryConstant.RICE_PARBOILED),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.brownRice,
        name: AppStrings.labelBrownRice,
        slugId: GroceryConstant.RICE_BROWN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sonaMasooriRice,
        name: AppStrings.labelSonaMasooriRice,
        slugId: GroceryConstant.RICE_SONA_MASOORI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.blackRice,
        name: AppStrings.labelBlackRice,
        slugId: GroceryConstant.RICE_BLACK),
  ];

  static List<CollapsibleGridModel> wheatAndFlours = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.wholeWheatAtta,
        name: AppStrings.labelWholeWheatAtta,
        slugId: GroceryConstant.FLOUR_WHOLE_WHEAT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.chakkiAtta,
        name: AppStrings.labelChakkiAtta,
        slugId: GroceryConstant.FLOUR_CHAKKI_ATTA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sharbatiAtta,
        name: AppStrings.labelSharbatiAtta,
        slugId: GroceryConstant.FLOUR_SHARBATI_ATTA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.multigrainAtta,
        name: AppStrings.labelMultigrainAtta,
        slugId: GroceryConstant.FLOUR_MULTIGRAIN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.diabeticAtta,
        name: AppStrings.labelDiabeticFriendlyAtta,
        slugId: GroceryConstant.FLOUR_DIABETIC),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.maida,
        name: AppStrings.labelMaida,
        slugId: GroceryConstant.FLOUR_MAIDA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.besan,
        name: AppStrings.labelBesan,
        slugId: GroceryConstant.FLOUR_BESAN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.riceFlour,
        name: AppStrings.labelRiceFlour,
        slugId: GroceryConstant.FLOUR_RICE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.ragiFlour,
        name: AppStrings.labelRagiFlour,
        slugId: GroceryConstant.FLOUR_RAGI),
  ];

  static const List<CollapsibleGridModel> dalNdBeans = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.toorDal,
        name: AppStrings.labelToorDal,
        slugId: GroceryConstant.DAL_TOOR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.moongDal,
        name: AppStrings.labelMoongDal,
        slugId: GroceryConstant.DAL_MOONG),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.masoorDal,
        name: AppStrings.labelMasoorDal,
        slugId: GroceryConstant.DAL_MASOOR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.uradDal,
        name: AppStrings.labelUradDal,
        slugId: GroceryConstant.DAL_URAD),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.chanaDal,
        name: AppStrings.labelChanaDal,
        slugId: GroceryConstant.DAL_CHANA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.kabuliChana,
        name: AppStrings.labelKabuliChana,
        slugId: GroceryConstant.DAL_KABULI_CHANA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.kalaChana,
        name: AppStrings.labelKalaChana,
        slugId: GroceryConstant.DAL_KALA_CHANA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.rajma,
        name: AppStrings.labelRajma,
        slugId: GroceryConstant.DAL_RAJMA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.dryGreenPeas,
        name: AppStrings.labelDryGreenPeas,
        slugId: GroceryConstant.DAL_DRY_GREEN_PEAS),
  ];

  static const List<CollapsibleGridModel> milletsNdTraditionalGrains = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.ragi,
        name: AppStrings.labelRagi,
        slugId: GroceryConstant.MILLET_RAGI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.jowar,
        name: AppStrings.labelJowar,
        slugId: GroceryConstant.MILLET_JOWAR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.bajra,
        name: AppStrings.labelBajra,
        slugId: GroceryConstant.MILLET_BAJRA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.foxtailMillet,
        name: AppStrings.labelFoxtailMillet,
        slugId: GroceryConstant.MILLET_FOXTAIL),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.littleMillet,
        name: AppStrings.labelLittleMillet,
        slugId: GroceryConstant.MILLET_LITTLE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.kodoMillet,
        name: AppStrings.labelKodoMillet,
        slugId: GroceryConstant.MILLET_KODO),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.barnyardMillet,
        name: AppStrings.labelBarnyardMillet,
        slugId: GroceryConstant.MILLET_BARNYARD),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.samakRice,
        name: AppStrings.labelSamakRice,
        slugId: GroceryConstant.RICE_SAMAK),
  ];

  static const List<CollapsibleGridModel> breakfastStaples = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.poha,
        name: AppStrings.labelPoha,
        slugId: GroceryConstant.STAPLE_POHA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.aval,
        name: AppStrings.labelAvalRiceFlakes,
        slugId: GroceryConstant.STAPLE_AVAL),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.dalia,
        name: AppStrings.labelDaliaBrokenWheat,
        slugId: GroceryConstant.STAPLE_DALIA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.oats,
        name: AppStrings.labelOats,
        slugId: GroceryConstant.STAPLE_OATS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cornGrits,
        name: AppStrings.labelCornGrits,
        slugId: GroceryConstant.STAPLE_CORN_GRITS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.wheatBran,
        name: AppStrings.labelWheatBran,
        slugId: GroceryConstant.STAPLE_WHEAT_BRAN),
  ];

  static const List<CollapsibleGridModel> spicesAndMasala = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cumin,
        name: AppStrings.labelCuminSeeds,
        slugId: GroceryConstant.SPICE_CUMIN_SEEDS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.corianderSeeds,
        name: AppStrings.labelCorianderSeeds,
        slugId: GroceryConstant.SPICE_CORIANDER_SEEDS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.blackPepper,
        name: AppStrings.labelBlackPepper,
        slugId: GroceryConstant.SPICE_BLACK_PEPPER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.greenCardamom,
        name: AppStrings.labelGreenCardamom,
        slugId: GroceryConstant.SPICE_GREEN_CARDAMOM),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cloves,
        name: AppStrings.labelCloves,
        slugId: GroceryConstant.SPICE_CLOVES),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cinnamon,
        name: AppStrings.labelCinnamon,
        slugId: GroceryConstant.SPICE_CINNAMON),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.turmeric,
        name: AppStrings.labelTurmericPowder,
        slugId: GroceryConstant.SPICE_TURMERIC_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.redChilli,
        name: AppStrings.labelRedChilliPowder,
        slugId: GroceryConstant.SPICE_RED_CHILLI_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.corianderPowder,
        name: AppStrings.labelCorianderPowder,
        slugId: GroceryConstant.SPICE_CORIANDER_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.garamMasala,
        name: AppStrings.labelGaramMasala,
        slugId: GroceryConstant.MASALA_GARAM),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.chaatMasala,
        name: AppStrings.labelChaatMasala,
        slugId: GroceryConstant.MASALA_CHAAT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sambharMasala,
        name: AppStrings.labelSambharMasala,
        slugId: GroceryConstant.MASALA_SAMBHAR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.biryaniMasala,
        name: AppStrings.labelBiryaniMasala,
        slugId: GroceryConstant.MASALA_BIRYANI),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.choleMasala,
        name: AppStrings.labelCholeMasala,
        slugId: GroceryConstant.MASALA_CHOLE),
  ];

  static const List<CollapsibleGridModel> saltNdSweeteners = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.iodizedSalt,
        name: AppStrings.labelIodizedSalt,
        slugId: GroceryConstant.SWEET_IODIZED_SALT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.rockSalt,
        name: AppStrings.labelRockSalt,
        slugId: GroceryConstant.SWEET_ROCK_SALT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.pinkSalt,
        name: AppStrings.labelPinkSalt,
        slugId: GroceryConstant.SWEET_PINK_SALT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.whiteSugar,
        name: AppStrings.labelWhiteSugar,
        slugId: GroceryConstant.SWEET_WHITE_SUGAR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.brownSugar,
        name: AppStrings.labelBrownSugar,
        slugId: GroceryConstant.SWEET_BROWN_SUGAR),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.jaggery,
        name: AppStrings.labelJaggery,
        slugId: GroceryConstant.SWEET_JAGGERY),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.honey,
        name: AppStrings.labelHoney,
        slugId: GroceryConstant.SWEET_HONEY),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sugarFree,
        name: AppStrings.labelSugarFreeSweetener,
        slugId: GroceryConstant.SWEET_SUGAR_FREE),
  ];

  static const List<CollapsibleGridModel> oilsAndFats = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sunflowerOil,
        name: AppStrings.labelSunflowerOil,
        slugId: GroceryConstant.OIL_SUNFLOWER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.riceBranOil,
        name: AppStrings.labelRiceBranOil,
        slugId: GroceryConstant.OIL_RICE_BRAN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.mustardOil,
        name: AppStrings.labelMustardOil,
        slugId: GroceryConstant.OIL_MUSTARD),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.groundnutOil,
        name: AppStrings.labelGroundnutOil,
        slugId: GroceryConstant.OIL_GROUNDNUT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.sesameOil,
        name: AppStrings.labelSesameOil,
        slugId: GroceryConstant.OIL_SESAME),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.coconutOil,
        name: AppStrings.labelCoconutOil,
        slugId: GroceryConstant.OIL_COCONUT),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.oliveOil,
        name: AppStrings.labelOliveOil,
        slugId: GroceryConstant.OIL_OLIVE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cowGhee,
        name: AppStrings.labelCowGheeStaple,
        slugId: GroceryConstant.GHEE_COW),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.desiGhee,
        name: AppStrings.labelDesiGheeStaple,
        slugId: GroceryConstant.GHEE_DESI),
  ];

  static const List<CollapsibleGridModel> teaCoffeeBeverages = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.assamTea,
        name: AppStrings.labelAssamTea,
        slugId: GroceryConstant.BEV_ASSAM_TEA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.greenTea,
        name: AppStrings.labelGreenTeaBeverage,
        slugId: GroceryConstant.BEV_GREEN_TEA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.masalaTea,
        name: AppStrings.labelMasalaTea,
        slugId: GroceryConstant.BEV_MASALA_TEA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.instantCoffee,
        name: AppStrings.labelInstantCoffee,
        slugId: GroceryConstant.BEV_INSTANT_COFFEE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.filterCoffee,
        name: AppStrings.labelFilterCoffee,
        slugId: GroceryConstant.BEV_FILTER_COFFEE),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.maltDrink,
        name: AppStrings.labelMaltHealthDrink,
        slugId: GroceryConstant.BEV_MALT_HEALTH_DRINK),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.glucosePowder,
        name: AppStrings.labelGlucoseDrinkPowder,
        slugId: GroceryConstant.BEV_GLUCOSE_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.coconutWater,
        name: AppStrings.labelCoconutWater,
        slugId: GroceryConstant.BEV_COCONUT_WATER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.drinkingWater,
        name: AppStrings.labelPackagedDrinkingWater,
        slugId: GroceryConstant.BEV_DRINKING_WATER),
  ];

  static const List<CollapsibleGridModel> dryFruitsAndReadyFood = [
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.almonds,
        name: AppStrings.labelAlmonds,
        slugId: GroceryConstant.DRY_ALMONDS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.cashews,
        name: AppStrings.labelCashewNuts,
        slugId: GroceryConstant.DRY_CASHEWS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.raisins,
        name: AppStrings.labelRaisins,
        slugId: GroceryConstant.DRY_RAISINS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.dates,
        name: AppStrings.labelDates,
        slugId: GroceryConstant.DRY_DATES),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.dryFig,
        name: AppStrings.labelDryFig,
        slugId: GroceryConstant.DRY_FIG),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.chiaSeeds,
        name: AppStrings.labelChiaSeeds,
        slugId: GroceryConstant.SEED_CHIA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.flaxSeeds,
        name: AppStrings.labelFlaxSeeds,
        slugId: GroceryConstant.SEED_FLAX),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.pumpkinSeeds,
        name: AppStrings.labelPumpkinSeeds,
        slugId: GroceryConstant.SEED_PUMPKIN),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.babyMilk,
        name: AppStrings.labelBabyMilkPowder,
        slugId: GroceryConstant.BABY_MILK_POWDER),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.riceCereal,
        name: AppStrings.labelRiceCereal,
        slugId: GroceryConstant.BABY_RICE_CEREAL),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.khichdiMix,
        name: AppStrings.labelKhichdiMix,
        slugId: GroceryConstant.BABY_KHICHDI_MIX),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.babyBiscuits,
        name: AppStrings.labelBabyBiscuits,
        slugId: GroceryConstant.BABY_BISCUITS),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.readyPoha,
        name: AppStrings.labelReadyPoha,
        slugId: GroceryConstant.READY_POHA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.readyUpma,
        name: AppStrings.labelReadyUpma,
        slugId: GroceryConstant.READY_UPMA),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.readyDal,
        name: AppStrings.labelReadyDal,
        slugId: GroceryConstant.READY_DAL),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.papad,
        name: AppStrings.labelPapadStaple,
        slugId: GroceryConstant.ACC_PAPAD),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.ketchup,
        name: AppStrings.labelTomatoKetchup,
        slugId: GroceryConstant.ACC_KETCHUP),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.mangoPickle,
        name: AppStrings.labelMangoPickle,
        slugId: GroceryConstant.ACC_PICKLE_MANGO),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.lemonPickle,
        name: AppStrings.labelLemonPickle,
        slugId: GroceryConstant.ACC_PICKLE_LEMON),
    CollapsibleGridModel(
        icon: GroceryIconCategoryAssets.mixedPickle,
        name: AppStrings.labelMixedVegetablePickle,
        slugId: GroceryConstant.ACC_PICKLE_MIXED),
  ];

  /// VEGETABLE
  static const List<CollapsibleGridModel> leafyVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spinach, name: AppStrings.labelSpinach, slugId: GroceryConstant.VEG_LEAFY_SPINACH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fenugreek, name: AppStrings.labelFenugreek, slugId: GroceryConstant.VEG_LEAFY_FENUGREEK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mustardGreens, name: AppStrings.labelMustardGreens, slugId: GroceryConstant.VEG_LEAFY_MUSTARD_GREENS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mint, name: AppStrings.labelMint, slugId: GroceryConstant.VEG_LEAFY_MINT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.coriander, name: AppStrings.labelCorianderLeaves, slugId: GroceryConstant.VEG_LEAFY_CORIANDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.amaranth, name: AppStrings.labelAmaranth, slugId: GroceryConstant.VEG_LEAFY_AMARANTH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathua, name: AppStrings.labelBathua, slugId: GroceryConstant.VEG_LEAFY_BATHUA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.malabarSpinach, name: AppStrings.labelMalabarSpinach, slugId: GroceryConstant.VEG_LEAFY_MALABAR_SPINACH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drumstickLeaves, name: AppStrings.labelDrumstickLeaves, slugId: GroceryConstant.VEG_LEAFY_DRUMSTICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dillLeaves, name: AppStrings.labelDillLeaves, slugId: GroceryConstant.VEG_LEAFY_DILL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.taroLeaves, name: AppStrings.labelTaroLeaves, slugId: GroceryConstant.VEG_LEAFY_TARO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.curryLeaves, name: AppStrings.labelCurryLeaves, slugId: GroceryConstant.VEG_LEAFY_CURRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lettuceIndian, name: AppStrings.labelLettuceIndian, slugId: GroceryConstant.VEG_LEAFY_LETTUCE_INDIAN),
  ];

  static final List<CollapsibleGridModel> rootVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.potato, name: AppStrings.labelPotato, slugId: GroceryConstant.VEG_ROOT_POTATO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sweetPotato, name: AppStrings.labelSweetPotato, slugId: GroceryConstant.VEG_ROOT_SWEET_POTATO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.carrot, name: AppStrings.labelCarrot, slugId: GroceryConstant.VEG_ROOT_CARROT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.radish, name: AppStrings.labelRadish, slugId: GroceryConstant.VEG_ROOT_RADISH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.beetroot, name: AppStrings.labelBeetroot, slugId: GroceryConstant.VEG_ROOT_BEETROOT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.turnip, name: AppStrings.labelTurnip, slugId: GroceryConstant.VEG_ROOT_TURNIP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.yam, name: AppStrings.labelYam, slugId: GroceryConstant.VEG_ROOT_YAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.taroRoot, name: AppStrings.labelTaroRoot, slugId: GroceryConstant.VEG_ROOT_TARO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.elephantFootYam, name: AppStrings.labelElephantFootYam, slugId: GroceryConstant.VEG_ROOT_ELEPHANT_FOOT_YAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cassava, name: AppStrings.labelCassava, slugId: GroceryConstant.VEG_ROOT_CASSAVA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lotusRoot, name: AppStrings.labelLotusRoot, slugId: GroceryConstant.VEG_ROOT_LOTUS_ROOT),
  ];

  static final List<CollapsibleGridModel> bulbNdStemVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.onion, name: AppStrings.labelOnion, slugId: GroceryConstant.VEG_BULB_ONION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.garlic, name: AppStrings.labelGarlic, slugId: GroceryConstant.VEG_BULB_GARLIC),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.leek, name: AppStrings.labelLeek, slugId: GroceryConstant.VEG_STEM_LEEK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.springOnion, name: AppStrings.labelSpringOnion, slugId: GroceryConstant.VEG_STEM_SPRING_ONION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bananaStem, name: AppStrings.labelBananaStem, slugId: GroceryConstant.VEG_STEM_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.colocasiaStem, name: AppStrings.labelColocasiaStem, slugId: GroceryConstant.VEG_STEM_COLOCASIA),
  ];

  static final List<CollapsibleGridModel> fruitVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tomato, name: AppStrings.labelTomato, slugId: GroceryConstant.VEG_FRUIT_TOMATO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.brinjal, name: AppStrings.labelBrinjalEggplant, slugId: GroceryConstant.VEG_FRUIT_BRINJAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bottleGourd, name: AppStrings.labelBottleGourd, slugId: GroceryConstant.VEG_GOURD_BOTTLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bitterGourd, name: AppStrings.labelBitterGourd, slugId: GroceryConstant.VEG_GOURD_BITTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ridgeGourd, name: AppStrings.labelRidgeGourd, slugId: GroceryConstant.VEG_GOURD_RIDGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spongeGourd, name: AppStrings.labelSpongeGourd, slugId: GroceryConstant.VEG_GOURD_SPONGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.snakeGourd, name: AppStrings.labelSnakeGourd, slugId: GroceryConstant.VEG_GOURD_SNAKE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pumpkin, name: AppStrings.labelPumpkin, slugId: GroceryConstant.VEG_FRUIT_PUMPKIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cucumber, name: AppStrings.labelCucumber, slugId: GroceryConstant.VEG_FRUIT_CUCUMBER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ashGourd, name: AppStrings.labelAshGourd, slugId: GroceryConstant.VEG_GOURD_ASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pointedGourd, name: AppStrings.labelPointedGourd, slugId: GroceryConstant.VEG_GOURD_POINTED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ivyGourd, name: AppStrings.labelIvyGourd, slugId: GroceryConstant.VEG_GOURD_IVY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tinda, name: AppStrings.labelTinda, slugId: GroceryConstant.VEG_FRUIT_TINDA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chowChow, name: AppStrings.labelChowChowChayote, slugId: GroceryConstant.VEG_FRUIT_CHOW_CHOW),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rawBanana, name: AppStrings.labelRawBanana, slugId: GroceryConstant.VEG_RAW_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rawPapaya, name: AppStrings.labelRawPapaya, slugId: GroceryConstant.VEG_RAW_PAPAYA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.capsicum, name: AppStrings.labelCapsicumBellPepper, slugId: GroceryConstant.VEG_FRUIT_CAPSICUM),
  ];

  static final List<CollapsibleGridModel> podNdBeansVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.greenPeas, name: AppStrings.labelGreenPeas, slugId: GroceryConstant.VEG_POD_GREEN_PEAS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frenchBeans, name: AppStrings.labelFrenchBeans, slugId: GroceryConstant.VEG_BEAN_FRENCH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clusterBeans, name: AppStrings.labelClusterBeans, slugId: GroceryConstant.VEG_BEAN_CLUSTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cowpea, name: AppStrings.labelCowpea, slugId: GroceryConstant.VEG_BEAN_COWPEA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hyacinthBeans, name: AppStrings.labelHyacinthBeans, slugId: GroceryConstant.VEG_BEAN_HYACINTH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.broadBeans, name: AppStrings.labelBroadBeans, slugId: GroceryConstant.VEG_BEAN_BROAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wingedBeans, name: AppStrings.labelWingedBeans, slugId: GroceryConstant.VEG_BEAN_WINGED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.yardlongBeans, name: AppStrings.labelYardlongBeans, slugId: GroceryConstant.VEG_BEAN_YARDLONG),
  ];

  static final List<CollapsibleGridModel> flowerVegetables = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cauliflower, name: AppStrings.labelCauliflower, slugId: GroceryConstant.VEG_FLOWER_CAULIFLOWER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.broccoli, name: AppStrings.labelBroccoli, slugId: GroceryConstant.VEG_FLOWER_BROCCOLI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bananaFlower, name: AppStrings.labelBananaFlower, slugId: GroceryConstant.VEG_FLOWER_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pumpkinFlower, name: AppStrings.labelPumpkinFlower, slugId: GroceryConstant.VEG_FLOWER_PUMPKIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drumstickFlower, name: AppStrings.labelDrumstickFlower, slugId: GroceryConstant.VEG_FLOWER_DRUMSTICK),
  ];

  static final List<CollapsibleGridModel> fungiNdSpecialIndianItems = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mushroom, name: AppStrings.labelMushroom, slugId: GroceryConstant.VEG_FUNGI_MUSHROOM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.greenChilli, name: AppStrings.labelGreenChilli, slugId: GroceryConstant.VEG_SPECIAL_GREEN_CHILLI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ginger, name: AppStrings.labelGinger, slugId: GroceryConstant.VEG_SPECIAL_GINGER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.turmericFresh, name: AppStrings.labelTurmericFresh, slugId: GroceryConstant.VEG_SPECIAL_TURMERIC_FRESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drumstick, name: AppStrings.labelDrumstick, slugId: GroceryConstant.VEG_SPECIAL_DRUMSTICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rawJackfruit, name: AppStrings.labelRawJackfruit, slugId: GroceryConstant.VEG_SPECIAL_RAW_JACKFRUIT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bambooShoot, name: AppStrings.labelBambooShoot, slugId: GroceryConstant.VEG_SPECIAL_BAMBOO_SHOOT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kokum, name: AppStrings.labelKokum, slugId: GroceryConstant.VEG_SPECIAL_KOKUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sundakkai, name: AppStrings.labelSundakkaiTurkeyBerry, slugId: GroceryConstant.VEG_SPECIAL_SUNDAKKAI),
  ];

  static final List<CollapsibleGridModel> exoticAndSpecialty = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.zucchini, name: AppStrings.labelZucchini, slugId: GroceryConstant.VEG_EXOTIC_ZUCCHINI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.celery, name: AppStrings.labelCelery, slugId: GroceryConstant.VEG_EXOTIC_CELERY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.asparagus, name: AppStrings.labelAsparagus, slugId: GroceryConstant.VEG_EXOTIC_ASPARAGUS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bokChoy, name: AppStrings.labelBokChoy, slugId: GroceryConstant.VEG_EXOTIC_BOK_CHOY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lettuceIceberg, name: AppStrings.labelLettuceIcebergRomaine, slugId: GroceryConstant.VEG_EXOTIC_LETTUCE_ICEBERG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kale, name: AppStrings.labelKale, slugId: GroceryConstant.VEG_EXOTIC_KALE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chineseCabbage, name: AppStrings.labelChineseCabbage, slugId: GroceryConstant.VEG_EXOTIC_CHINESE_CABBAGE),
  ];

  /// FRUIT
  static final List<CollapsibleGridModel> dailyFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.apple, name: AppStrings.labelApple, slugId: GroceryConstant.FRUIT_DAILY_APPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.banana, name: AppStrings.labelBanana, slugId: GroceryConstant.FRUIT_DAILY_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.orange, name: AppStrings.labelOrange, slugId: GroceryConstant.FRUIT_DAILY_ORANGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mosambi, name: AppStrings.labelMosambiSweetLime, slugId: GroceryConstant.FRUIT_DAILY_MOSAMBI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.grapes, name: AppStrings.labelGrapes, slugId: GroceryConstant.FRUIT_DAILY_GRAPES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.papaya, name: AppStrings.labelPapaya, slugId: GroceryConstant.FRUIT_DAILY_PAPAYA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pomegranate, name: AppStrings.labelPomegranate, slugId: GroceryConstant.FRUIT_DAILY_POMEGRANATE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.guava, name: AppStrings.labelGuava, slugId: GroceryConstant.FRUIT_DAILY_GUAVA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pear, name: AppStrings.labelPear, slugId: GroceryConstant.FRUIT_DAILY_PEAR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chikoo, name: AppStrings.labelChikooSapota, slugId: GroceryConstant.FRUIT_DAILY_CHIKOO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pineapple, name: AppStrings.labelPineapple, slugId: GroceryConstant.FRUIT_DAILY_PINEAPPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.watermelon, name: AppStrings.labelWatermelon, slugId: GroceryConstant.FRUIT_DAILY_WATERMELON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.muskmelon, name: AppStrings.labelMuskmelon, slugId: GroceryConstant.FRUIT_DAILY_MUSKMELON),
  ];

  static final List<CollapsibleGridModel> desiFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mango, name: AppStrings.labelMango, slugId: GroceryConstant.FRUIT_DESI_MANGO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jackfruit, name: AppStrings.labelJackfruit, slugId: GroceryConstant.FRUIT_DESI_JACKFRUIT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jamun, name: AppStrings.labelJamun, slugId: GroceryConstant.FRUIT_DESI_JAMUN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.custardApple, name: AppStrings.labelCustardApple, slugId: GroceryConstant.FRUIT_DESI_CUSTARD_APPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ber, name: AppStrings.labelBerIndianJujube, slugId: GroceryConstant.FRUIT_DESI_BER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.soursop, name: AppStrings.labelSoursop, slugId: GroceryConstant.FRUIT_DESI_SOURSOP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.woodApple, name: AppStrings.labelWoodAppleBael, slugId: GroceryConstant.FRUIT_DESI_WOOD_APPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tamarind, name: AppStrings.labelTamarind, slugId: GroceryConstant.FRUIT_DESI_TAMARIND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.monkeyJack, name: AppStrings.labelMonkeyJack, slugId: GroceryConstant.FRUIT_DESI_MONKEY_JACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fig, name: AppStrings.labelIndianFigAnjeer, slugId: GroceryConstant.FRUIT_DESI_FIG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.khirni, name: AppStrings.labelKhirniRayan, slugId: GroceryConstant.FRUIT_DESI_KHIRNI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.karonda, name: AppStrings.labelKaronda, slugId: GroceryConstant.FRUIT_DESI_KARONDA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.amla, name: AppStrings.labelIndianGooseberryAmla, slugId: GroceryConstant.FRUIT_DESI_AMLA),
  ];

  static final List<CollapsibleGridModel> sourAndStoneFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lemon, name: AppStrings.labelLemon, slugId: GroceryConstant.FRUIT_SOUR_LEMON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lime, name: AppStrings.labelLime, slugId: GroceryConstant.FRUIT_SOUR_LIME),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kinnow, name: AppStrings.labelKinnow, slugId: GroceryConstant.FRUIT_SOUR_KINNOW),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pomelo, name: AppStrings.labelPomelo, slugId: GroceryConstant.FRUIT_SOUR_POMELO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.citron, name: AppStrings.labelCitron, slugId: GroceryConstant.FRUIT_SOUR_CITRON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.galgal, name: AppStrings.labelGalgal, slugId: GroceryConstant.FRUIT_SOUR_GALGAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.peach, name: AppStrings.labelPeach, slugId: GroceryConstant.FRUIT_STONE_PEACH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plum, name: AppStrings.labelPlum, slugId: GroceryConstant.FRUIT_STONE_PLUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.apricot, name: AppStrings.labelApricot, slugId: GroceryConstant.FRUIT_STONE_APRICOT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cherry, name: AppStrings.labelCherry, slugId: GroceryConstant.FRUIT_STONE_CHERRY),
  ];

  static final List<CollapsibleGridModel> smallNdSeasonalFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.strawberry, name: AppStrings.labelStrawberry, slugId: GroceryConstant.FRUIT_SEASONAL_STRAWBERRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mulberry, name: AppStrings.labelMulberry, slugId: GroceryConstant.FRUIT_SEASONAL_MULBERRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.raspberry, name: AppStrings.labelRaspberry, slugId: GroceryConstant.FRUIT_SEASONAL_RASPBERRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.blueberry, name: AppStrings.labelBlueberry, slugId: GroceryConstant.FRUIT_SEASONAL_BLUEBERRY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.phalsa, name: AppStrings.labelPhalsa, slugId: GroceryConstant.FRUIT_SEASONAL_PHALSA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.litchi, name: AppStrings.labelLitchi, slugId: GroceryConstant.FRUIT_SEASONAL_LITCHI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.loquat, name: AppStrings.labelLoquat, slugId: GroceryConstant.FRUIT_SEASONAL_LOQUAT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.starFruit, name: AppStrings.labelStarFruitCarambola, slugId: GroceryConstant.FRUIT_SEASONAL_STAR_FRUIT),
    // CollapsibleGridModel(icon: GroceryIconCategoryAssets.capsicumFruit, label: AppStrings.labelCapsicumBellPepper, tagId: GroceryConstant.FRUIT_SEASONAL_Capsicum_Bell_PEPPER),
  ];

  static final List<CollapsibleGridModel> forestNdCoastalFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.coconut, name: AppStrings.labelCoconut, slugId: GroceryConstant.FRUIT_COASTAL_COCONUT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tenderCoconut, name: AppStrings.labelTenderCoconut, slugId: GroceryConstant.FRUIT_COASTAL_TENDER_COCONUT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceApple, name: AppStrings.labelIceApple, slugId: GroceryConstant.FRUIT_COASTAL_ICE_APPLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toddyPalm, name: AppStrings.labelToddyPalmFruit, slugId: GroceryConstant.FRUIT_COASTAL_TODDY_PALM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nungu, name: AppStrings.labelNungu, slugId: GroceryConstant.FRUIT_COASTAL_NUNGU),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.freshDates, name: AppStrings.labelDate, slugId: GroceryConstant.FRUIT_FOREST_DATE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mahua, name: AppStrings.labelMahuaFruit, slugId: GroceryConstant.FRUIT_FOREST_MAHUA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chironjiFruit, name: AppStrings.labelChironjiFruit, slugId: GroceryConstant.FRUIT_FOREST_CHIRONJI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tenduFruit, name: AppStrings.labelTenduFruit, slugId: GroceryConstant.FRUIT_FOREST_TENDU),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kaafal, name: AppStrings.labelKaafal, slugId: GroceryConstant.FRUIT_FOREST_KAAFAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wildJamun, name: AppStrings.labelWildJamun, slugId: GroceryConstant.FRUIT_FOREST_WILD_JAMUN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wildBanana, name: AppStrings.labelWildBanana, slugId: GroceryConstant.FRUIT_FOREST_WILD_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.breadfruit, name: AppStrings.labelBreadfruit, slugId: GroceryConstant.FRUIT_COASTAL_BREADFRUIT),
  ];

  static final List<CollapsibleGridModel> specialNdExoticFruits = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kiwi, name: AppStrings.labelKiwi, slugId: GroceryConstant.FRUIT_EXOTIC_KIWI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dragonFruit, name: AppStrings.labelDragonFruit, slugId: GroceryConstant.FRUIT_EXOTIC_DRAGON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.avocado, name: AppStrings.labelAvocado, slugId: GroceryConstant.FRUIT_EXOTIC_AVOCADO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.passionFruit, name: AppStrings.labelPassionFruit, slugId: GroceryConstant.FRUIT_EXOTIC_PASSION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mangosteen, name: AppStrings.labelMangosteen, slugId: GroceryConstant.FRUIT_EXOTIC_MANGOSTEEN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.longan, name: AppStrings.labelLongan, slugId: GroceryConstant.FRUIT_EXOTIC_LONGAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rambutan, name: AppStrings.labelRambutan, slugId: GroceryConstant.FRUIT_EXOTIC_RAMBUTAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.durian, name: AppStrings.labelDurian, slugId: GroceryConstant.FRUIT_EXOTIC_DURIAN),
  ];

  /// BAKERY & NAMKEEN ITEMS
// Namkeen & Mixture List
  static final List<CollapsibleGridModel> namkeenAndMixture = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.alooBhujia, name: AppStrings.labelAlooBhujia, slugId: GroceryConstant.SNACK_NAMKEEN_ALOO_BHUJIA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sev, name: AppStrings.labelSev, slugId: GroceryConstant.SNACK_NAMKEEN_SEV),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mixture, name: AppStrings.labelMixture, slugId: GroceryConstant.SNACK_NAMKEEN_MIXTURE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.boondi, name: AppStrings.labelBoondi, slugId: GroceryConstant.SNACK_NAMKEEN_BOONDI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.moongDalNamkeen, name: AppStrings.labelMoongDalNamkeen, slugId: GroceryConstant.SNACK_NAMKEEN_MOONG_DAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chanaDalNamkeen, name: AppStrings.labelChanaDalNamkeen, slugId: GroceryConstant.SNACK_NAMKEEN_CHANA_DAL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.peanutsNamkeen, name: AppStrings.labelPeanutsNamkeen, slugId: GroceryConstant.SNACK_NAMKEEN_PEANUTS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ghatiya, name: AppStrings.labelGhatiya, slugId: GroceryConstant.SNACK_GHATIYA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.farsan, name: AppStrings.labelFarsanMix, slugId: GroceryConstant.SNACK_NAMKEEN_FARSAN),
  ];

// Chips, Papad & Fryums List
  static final List<CollapsibleGridModel> chipsPapadFryums = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.potatoChips, name: AppStrings.labelPotatoChips, slugId: GroceryConstant.SNACK_CHIPS_POTATO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bananaChips, name: AppStrings.labelBananaChips, slugId: GroceryConstant.SNACK_CHIPS_BANANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tapiocaChips, name: AppStrings.labelTapiocaChips, slugId: GroceryConstant.SNACK_CHIPS_TAPIOCA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cornChips, name: AppStrings.labelCornChips, slugId: GroceryConstant.SNACK_CHIPS_CORN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multigrainChips, name: AppStrings.labelMultigrainChips, slugId: GroceryConstant.SNACK_CHIPS_MULTIGRAIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nachoChips, name: AppStrings.labelNachoChips, slugId: GroceryConstant.SNACK_CHIPS_NACHO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.uradPapad, name: AppStrings.labelUradPapad, slugId: GroceryConstant.SNACK_PAPAD_URAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ricePapad, name: AppStrings.labelRicePapad, slugId: GroceryConstant.SNACK_PAPAD_RICE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sabudanaPapad, name: AppStrings.labelSabudanaPapad, slugId: GroceryConstant.SNACK_PAPAD_SABUDANA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.appalam, name: AppStrings.labelAppalam, slugId: GroceryConstant.SNACK_PAPAD_APPALAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fryums, name: AppStrings.labelFryums, slugId: GroceryConstant.SNACK_FRYUMS),
  ];

// Biscuits & Cookies
  static final List<CollapsibleGridModel> biscuitsCookies = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glucoseBiscuit, name: AppStrings.labelGlucoseBiscuits, slugId: GroceryConstant.BISCUIT_GLUCOSE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.marieBiscuit, name: AppStrings.labelMarieBiscuits, slugId: GroceryConstant.BISCUIT_MARIE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.milkBiscuit, name: AppStrings.labelMilkBiscuits, slugId: GroceryConstant.BISCUIT_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.creamBiscuit, name: AppStrings.labelCreamBiscuits, slugId: GroceryConstant.BISCUIT_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.arrowrootBiscuit, name: AppStrings.labelArrowrootBiscuits, slugId: GroceryConstant.BISCUIT_ARROWROOT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sandwichBiscuit, name: AppStrings.labelSandwichBiscuits, slugId: GroceryConstant.BISCUIT_SANDWICH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multigrainBiscuit, name: AppStrings.labelMultigrainBiscuits, slugId: GroceryConstant.BISCUIT_MULTIGRAIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.digestiveBiscuit, name: AppStrings.labelDigestiveBiscuits, slugId: GroceryConstant.BISCUIT_DIGESTIVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jeeraBiscuit, name: AppStrings.labelJeeraBiscuits, slugId: GroceryConstant.BISCUIT_JEERA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.butterBiscuit, name: AppStrings.labelButterBiscuits, slugId: GroceryConstant.BISCUIT_BUTTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jamBiscuit, name: AppStrings.labelJamBiscuits, slugId: GroceryConstant.BISCUIT_JAM),
  ];

// Bread, Bakery & Sweet Items
  static final List<CollapsibleGridModel> bakeryItems = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whiteBread, name: AppStrings.labelWhiteBread, slugId: GroceryConstant.BAKERY_WHITE_BREAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.brownBread, name: AppStrings.labelBrownBread, slugId: GroceryConstant.BAKERY_BROWN_BREAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multigrainBread, name: AppStrings.labelMultigrainBread, slugId: GroceryConstant.BAKERY_MULTIGRAIN_BREAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pavBread, name: AppStrings.labelPavBread, slugId: GroceryConstant.BAKERY_PAV),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.burgerBuns, name: AppStrings.labelBurgerBuns, slugId: GroceryConstant.BAKERY_BURGER_BUNS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pizzaBase, name: AppStrings.labelPizzaBase, slugId: GroceryConstant.BAKERY_PIZZA_BASE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.breadCrumbs, name: AppStrings.labelBreadCrumbs, slugId: GroceryConstant.BAKERY_BREAD_CRUMBS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.khari, name: AppStrings.labelKhariBiscuit, slugId: GroceryConstant.BAKERY_KHARI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rusk, name: AppStrings.labelRusk, slugId: GroceryConstant.BAKERY_RUSK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cake, name: AppStrings.labelCake, slugId: GroceryConstant.BAKERY_CAKE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cupCake, name: AppStrings.labelCupCake, slugId: GroceryConstant.BAKERY_CUP_CAKE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.muffins, name: AppStrings.labelMuffins, slugId: GroceryConstant.BAKERY_MUFFINS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.swissRoll, name: AppStrings.labelSwissRoll, slugId: GroceryConstant.BAKERY_SWISS_ROLL),
  ];

// Fried & Hot Snacks
  static final List<CollapsibleGridModel> friedHotSnacks = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.samosa, name: AppStrings.labelSamosa, slugId: GroceryConstant.SNACK_HOT_SAMOSA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vegPuff, name: AppStrings.labelVegPuff, slugId: GroceryConstant.SNACK_HOT_VEG_PUFF),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vegPatties, name: AppStrings.labelVegPatties, slugId: GroceryConstant.SNACK_HOT_VEG_PATTIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pizzaPatties, name: AppStrings.labelPizzaPatties, slugId: GroceryConstant.SNACK_HOT_PIZZA_PATTIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vegCutlet, name: AppStrings.labelVegCutlet, slugId: GroceryConstant.SNACK_HOT_VEG_CUTLET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.breadRoll, name: AppStrings.labelBreadRoll, slugId: GroceryConstant.SNACK_HOT_BREAD_ROLL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.springRoll, name: AppStrings.labelSpringRoll, slugId: GroceryConstant.SNACK_HOT_SPRING_ROLL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dryKachori, name: AppStrings.labelDryKachori, slugId: GroceryConstant.SNACK_HOT_DRY_KACHORI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.khakhra, name: AppStrings.labelKhakhra, slugId: GroceryConstant.SNACK_DRY_KHAKHRA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chakli, name: AppStrings.labelChakli, slugId: GroceryConstant.SNACK_DRY_CHAKLI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.murukku, name: AppStrings.labelMurukku, slugId: GroceryConstant.SNACK_DRY_MURUKKU),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.popcorn, name: AppStrings.labelPopcorn, slugId: GroceryConstant.SNACK_DRY_POPCORN),
  ];

  /// DAIRY & FROZEN ITEMS
  // Milk List
  static final List<CollapsibleGridModel> milkList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fullCreamMilk, name: AppStrings.labelFullCreamMilk, slugId: GroceryConstant.DAIRY_MILK_FULL_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tonedMilk, name: AppStrings.labelTonedMilk, slugId: GroceryConstant.DAIRY_MILK_TONED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.doubleTonedMilk, name: AppStrings.labelDoubleTonedMilk, slugId: GroceryConstant.DAIRY_MILK_DOUBLE_TONED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.skimmedMilk, name: AppStrings.labelSkimmedMilk, slugId: GroceryConstant.DAIRY_MILK_SKIMMED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cowMilk, name: AppStrings.labelCowMilk, slugId: GroceryConstant.DAIRY_MILK_COW),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.buffaloMilk, name: AppStrings.labelBuffaloMilk, slugId: GroceryConstant.DAIRY_MILK_BUFFALO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.flavouredMilk, name: AppStrings.labelFlavouredMilk, slugId: GroceryConstant.DAIRY_MILK_FLAVOURED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lactoseFreeMilk, name: AppStrings.labelLactoseFreeMilk, slugId: GroceryConstant.DAIRY_MILK_LACTOSE_FREE),
  ];

// Curd, Buttermilk and Cream List
  static final List<CollapsibleGridModel> curdButtermilkCreamList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.freshCurd, name: AppStrings.labelFreshCurd, slugId: GroceryConstant.DAIRY_CURD_FRESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.setCurd, name: AppStrings.labelSetCurd, slugId: GroceryConstant.DAIRY_CURD_SET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.greekYogurt, name: AppStrings.labelGreekYogurt, slugId: GroceryConstant.DAIRY_YOGURT_GREEK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.flavouredYogurt, name: AppStrings.labelFlavouredYogurt, slugId: GroceryConstant.DAIRY_YOGURT_FLAVOURED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.butterMilk, name: AppStrings.labelButterMilk, slugId: GroceryConstant.DAIRY_BUTTER_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.namkeenChaas, name: AppStrings.labelNamkeenChhaach, slugId: GroceryConstant.DAIRY_CHAAS_NAMKEEN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lassi, name: AppStrings.labelLassi, slugId: GroceryConstant.DAIRY_LASSI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.freshCream, name: AppStrings.labelFreshCream, slugId: GroceryConstant.DAIRY_CREAM_FRESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cookingCream, name: AppStrings.labelCookingCream, slugId: GroceryConstant.DAIRY_CREAM_COOKING),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whippingCream, name: AppStrings.labelWhippingCream, slugId: GroceryConstant.DAIRY_CREAM_WHIPPING),
  ];

// Butter, Cheese and Paneer List
  static final List<CollapsibleGridModel> butterCheesePaneerList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tableButter, name: AppStrings.labelTableButter, slugId: GroceryConstant.DAIRY_BUTTER_TABLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whiteButter, name: AppStrings.labelWhiteButter, slugId: GroceryConstant.DAIRY_BUTTER_WHITE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.saltedButter, name: AppStrings.labelSaltedButter, slugId: GroceryConstant.DAIRY_BUTTER_SALTED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.unsaltedButter, name: AppStrings.labelUnsaltedButter, slugId: GroceryConstant.DAIRY_BUTTER_UNSALTED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cheeseSlices, name: AppStrings.labelCheeseSlices, slugId: GroceryConstant.DAIRY_CHEESE_SLICES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cheeseBlocks, name: AppStrings.labelCheeseBlocks, slugId: GroceryConstant.DAIRY_CHEESE_BLOCKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cheeseSpread, name: AppStrings.labelCheeseSpread, slugId: GroceryConstant.DAIRY_CHEESE_SPREAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.freshPaneer, name: AppStrings.labelFreshPaneer, slugId: GroceryConstant.DAIRY_PANEER_FRESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.malaiPaneer, name: AppStrings.labelMalaiPaneer, slugId: GroceryConstant.DAIRY_PANEER_MALAI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenPaneer, name: AppStrings.labelFrozenPaneer, slugId: GroceryConstant.DAIRY_PANEER_FROZEN),
  ];

// Ghee and Dairy Fats List
  static final List<CollapsibleGridModel> gheeAndDairyFatsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cowGheeDairy, name: AppStrings.labelCowGheeStaple, slugId: GroceryConstant.DAIRY_GHEE_COW),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.buffaloGhee, name: AppStrings.labelBuffaloGhee, slugId: GroceryConstant.DAIRY_GHEE_BUFFALO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.a2Ghee, name: AppStrings.labelA2Ghee, slugId: GroceryConstant.DAIRY_GHEE_A2),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.organicGhee, name: AppStrings.labelOrganicGhee, slugId: GroceryConstant.DAIRY_GHEE_ORGANIC),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.desiGheeDairy, name: AppStrings.labelDesiGheeStaple, slugId: GroceryConstant.DAIRY_GHEE_DESI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vanaspati, name: AppStrings.labelVanaspati, slugId: GroceryConstant.DAIRY_GHEE_VANASPATI),
  ];

// Ice Cream and Frozen Desserts List
  static final List<CollapsibleGridModel> iceCreamFrozenDessertsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceCreamCups, name: AppStrings.labelIceCreamCups, slugId: GroceryConstant.FROZEN_ICE_CREAM_CUPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.familyPacks, name: AppStrings.labelIceCreamFamilyPacks, slugId: GroceryConstant.FROZEN_ICE_CREAM_FAMILY_PACKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceCreamBars, name: AppStrings.labelIceCreamBars, slugId: GroceryConstant.FROZEN_ICE_CREAM_BARS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceCreamCones, name: AppStrings.labelIceCreamCones, slugId: GroceryConstant.FROZEN_ICE_CREAM_CONES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kulfi, name: AppStrings.labelKulfi, slugId: GroceryConstant.FROZEN_KULFI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.malaiKulfi, name: AppStrings.labelMalaiKulfi, slugId: GroceryConstant.FROZEN_MALAI_KULFI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.matkaKulfi, name: AppStrings.labelMatkaKulfi, slugId: GroceryConstant.FROZEN_MATKA_KULFI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenYogurt, name: AppStrings.labelFrozenYogurt, slugId: GroceryConstant.FROZEN_YOGURT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenDessert, name: AppStrings.labelFrozenDessert, slugId: GroceryConstant.FROZEN_DESSERT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceLollies, name: AppStrings.labelIceLollies, slugId: GroceryConstant.FROZEN_ICE_LOLLIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cassata, name: AppStrings.labelCassataIceCream, slugId: GroceryConstant.FROZEN_CASSATA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.iceCreamSandwich, name: AppStrings.labelIceCreamSandwich, slugId: GroceryConstant.FROZEN_ICE_CREAM_SANDWICH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fruitSorbet, name: AppStrings.labelFruitSorbet, slugId: GroceryConstant.FROZEN_FRUIT_SORBET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gelato, name: AppStrings.labelGelato, slugId: GroceryConstant.FROZEN_GELATO),
  ];

// Dairy Sweets and Chocolate
  static final List<CollapsibleGridModel> sweetsChocolatesList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.milkCake, name: AppStrings.labelMilkCake, slugId: GroceryConstant.SWEET_MILK_CAKE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kalakand, name: AppStrings.labelKalakand, slugId: GroceryConstant.SWEET_KALAKAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rasgulla, name: AppStrings.labelRasgulla, slugId: GroceryConstant.SWEET_RASGULLA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rasmalai, name: AppStrings.labelRasmalai, slugId: GroceryConstant.SWEET_RASMALAI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gulabJamun, name: AppStrings.labelGulabJamun, slugId: GroceryConstant.SWEET_GULAB_JAMUN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kajuKatli, name: AppStrings.labelKajuKatli, slugId: GroceryConstant.SWEET_KAJU_KATLI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pedha, name: AppStrings.labelPedha, slugId: GroceryConstant.SWEET_PEDHA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chamCham, name: AppStrings.labelChamCham, slugId: GroceryConstant.SWEET_CHAM_CHAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sandesh, name: AppStrings.labelSandesh, slugId: GroceryConstant.SWEET_SANDESH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mishtiDoi, name: AppStrings.labelMishtiDoi, slugId: GroceryConstant.SWEET_MISHTI_DOI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.milkChocolate, name: AppStrings.labelMilkChocolate, slugId: GroceryConstant.CHOCO_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.darkChocolate, name: AppStrings.labelDarkChocolate, slugId: GroceryConstant.CHOCO_DARK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whiteChocolate, name: AppStrings.labelWhiteChocolate, slugId: GroceryConstant.CHOCO_WHITE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateBars, name: AppStrings.labelChocolateBars, slugId: GroceryConstant.CHOCO_BARS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateBlocks, name: AppStrings.labelChocolateBlocks, slugId: GroceryConstant.CHOCO_BLOCKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateCoins, name: AppStrings.labelChocolateCoins, slugId: GroceryConstant.CHOCO_COINS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateGiftPacks, name: AppStrings.labelChocolateGiftPacks, slugId: GroceryConstant.CHOCO_GIFT_PACKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateSyrup, name: AppStrings.labelChocolateSyrup, slugId: GroceryConstant.CHOCO_SYRUP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chocolateSpread, name: AppStrings.labelChocolateSpread, slugId: GroceryConstant.CHOCO_SPREAD),
  ];

// Frozen Vegetables List
  static final List<CollapsibleGridModel> frozenVegetablesList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenPeas, name: AppStrings.labelFrozenGreenPeas, slugId: GroceryConstant.FROZEN_VEG_GREEN_PEAS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenCorn, name: AppStrings.labelFrozenSweetCorn, slugId: GroceryConstant.FROZEN_VEG_SWEET_CORN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenMixedVeg, name: AppStrings.labelFrozenMixedVegetables, slugId: GroceryConstant.FROZEN_VEG_MIXED),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenBeans, name: AppStrings.labelFrozenFrenchBeans, slugId: GroceryConstant.FROZEN_VEG_FRENCH_BEANS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenCarrot, name: AppStrings.labelFrozenCarrot, slugId: GroceryConstant.FROZEN_VEG_CARROT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frozenSpinach, name: AppStrings.labelFrozenSpinach, slugId: GroceryConstant.FROZEN_VEG_SPINACH),
  ];

// Frozen Snacks & Meals List
  static final List<CollapsibleGridModel> frozenSnacksMealsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.frenchFries, name: AppStrings.labelFrozenFrenchFries, slugId: GroceryConstant.FROZEN_SNACK_FRIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.vegNuggets, name: AppStrings.labelFrozenVegNuggets, slugId: GroceryConstant.FROZEN_SNACK_VEG_NUGGETS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.burgerPatty, name: AppStrings.labelFrozenChickenNuggets, slugId: GroceryConstant.FROZEN_SNACK_CHICKEN_NUGGETS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.smileys, name: AppStrings.labelFrozenSpringRolls, slugId: GroceryConstant.FROZEN_SNACK_SPRING_ROLLS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.alooTikki, name: AppStrings.labelFrozenSamosa, slugId: GroceryConstant.FROZEN_SNACK_SAMOSA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paratha, name: AppStrings.labelFrozenParatha, slugId: GroceryConstant.FROZEN_SNACK_PARATHA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.momos, name: AppStrings.labelFrozenMomos, slugId: GroceryConstant.FROZEN_SNACK_MOMOS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.springRolls, name: AppStrings.labelFrozenVegCutlet, slugId: GroceryConstant.FROZEN_SNACK_SPRING_ROLLS),
  ];

// Milk Powders and Dairy Alternatives List
  static final List<CollapsibleGridModel> milkPowdersAlternativesList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.skimmedMilkPowder, name: AppStrings.labelSkimmedMilkPowder, slugId: GroceryConstant.DAIRY_SKIMMED_MILK_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fullCreamMilkPowder, name: AppStrings.labelFullCreamMilkPowder, slugId: GroceryConstant.DAIRY_FULL_CREAM_MILK_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.infantFormula, name: AppStrings.labelInfantMilkFormula, slugId: GroceryConstant.DAIRY_INFANT_MILK_FORMULA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.condensedMilk, name: AppStrings.labelCondensedMilk, slugId: GroceryConstant.DAIRY_CONDENSED_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.evaporatedMilk, name: AppStrings.labelEvaporatedMilk, slugId: GroceryConstant.DAIRY_EVAPORATED_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.soyMilk, name: AppStrings.labelSoyMilk, slugId: GroceryConstant.DAIRY_ALT_SOY_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.almondMilk, name: AppStrings.labelAlmondMilk, slugId: GroceryConstant.DAIRY_ALT_ALMOND_MILK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.oatsMilk, name: AppStrings.labelOatsMilk, slugId: GroceryConstant.DAIRY_ALT_OATS_MILK),
  ];

  /// Crockery
// Cooking Utensils List
  static final List<CollapsibleGridModel> cookingUtensilsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pressureCooker, name: AppStrings.labelPressureCooker, slugId: GroceryConstant.UTENSIL_PRESSURE_COOKER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kadai, name: AppStrings.labelKadai, slugId: GroceryConstant.UTENSIL_KADAI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fryingPan, name: AppStrings.labelFryingPan, slugId: GroceryConstant.UTENSIL_FRYING_PAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tawa, name: AppStrings.labelTawa, slugId: GroceryConstant.UTENSIL_TAWA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.handi, name: AppStrings.labelHandi, slugId: GroceryConstant.UTENSIL_HANDI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.saucePan, name: AppStrings.labelSaucePan, slugId: GroceryConstant.UTENSIL_SAUCE_PAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stockPot, name: AppStrings.labelStockPot, slugId: GroceryConstant.UTENSIL_STOCK_POT),
  ];

  // Eating & Dining Utensils List
  static final List<CollapsibleGridModel> diningUtensilsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.thali, name: AppStrings.labelThali, slugId: GroceryConstant.UTENSIL_THALI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plate, name: AppStrings.labelPlate, slugId: GroceryConstant.UTENSIL_PLATE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ricePlate, name: AppStrings.labelRicePlate, slugId: GroceryConstant.UTENSIL_RICE_PLATE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.katori, name: AppStrings.labelKatori, slugId: GroceryConstant.UTENSIL_KATORI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bowl, name: AppStrings.labelBowl, slugId: GroceryConstant.UTENSIL_BOWL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glass, name: AppStrings.labelGlass, slugId: GroceryConstant.UTENSIL_GLASS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tumbler, name: AppStrings.labelTumbler, slugId: GroceryConstant.UTENSIL_TUMBLER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spoon, name: AppStrings.labelSpoon, slugId: GroceryConstant.UTENSIL_SPOON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fork, name: AppStrings.labelFork, slugId: GroceryConstant.UTENSIL_FORK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.knife, name: AppStrings.labelKnife, slugId: GroceryConstant.UTENSIL_KNIFE),
  ];

  // Serving Utensils List
  static final List<CollapsibleGridModel> servingUtensilsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.servingSpoon, name: AppStrings.labelServingSpoon, slugId: GroceryConstant.UTENSIL_SERVING_SPOON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ladle, name: AppStrings.labelLadle, slugId: GroceryConstant.UTENSIL_LADLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.servingBowl, name: AppStrings.labelServingBowl, slugId: GroceryConstant.UTENSIL_SERVING_BOWL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.servingTray, name: AppStrings.labelServingTray, slugId: GroceryConstant.UTENSIL_SERVING_TRAY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.servingHandi, name: AppStrings.labelServingHandi, slugId: GroceryConstant.UTENSIL_SERVING_HANDI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.casserole, name: AppStrings.labelCasserole, slugId: GroceryConstant.UTENSIL_CASSEROLE),
  ];

  // Kitchen Hand Tools List
  static final List<CollapsibleGridModel> kitchenToolsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rollingPin, name: AppStrings.labelRollingPin, slugId: GroceryConstant.UTENSIL_ROLLING_PIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chakla, name: AppStrings.labelChakla, slugId: GroceryConstant.UTENSIL_CHAKLA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.peeler, name: AppStrings.labelPeeler, slugId: GroceryConstant.UTENSIL_PEELER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.grater, name: AppStrings.labelGrater, slugId: GroceryConstant.UTENSIL_GRATER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chopper, name: AppStrings.labelChopper, slugId: GroceryConstant.UTENSIL_CHOPPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.whisk, name: AppStrings.labelWhisk, slugId: GroceryConstant.UTENSIL_WHISK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spatula, name: AppStrings.labelSpatula, slugId: GroceryConstant.UTENSIL_SPATULA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tongs, name: AppStrings.labelTongs, slugId: GroceryConstant.UTENSIL_TONGS),
  ];

  // Kitchen Appliances List
  static final List<CollapsibleGridModel> kitchenAppliancesList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gasStove, name: AppStrings.labelGasStove, slugId: GroceryConstant.APPLIANCE_GAS_STOVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.induction, name: AppStrings.labelInductionCooktop, slugId: GroceryConstant.APPLIANCE_INDUCTION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mixerGrinder, name: AppStrings.labelMixerGrinder, slugId: GroceryConstant.APPLIANCE_MIXER_GRINDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.microwave, name: AppStrings.labelMicrowaveOven, slugId: GroceryConstant.APPLIANCE_MICROWAVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.otg, name: AppStrings.labelOTGOven, slugId: GroceryConstant.APPLIANCE_OTG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.electricKettle, name: AppStrings.labelElectricKettle, slugId: GroceryConstant.APPLIANCE_KETTLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toaster, name: AppStrings.labelToaster, slugId: GroceryConstant.APPLIANCE_TOASTER),
  ];

  // Storage & Carry Items List
  static final List<CollapsibleGridModel> storageCarryList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.storageContainer, name: AppStrings.labelStorageContainer, slugId: GroceryConstant.STORAGE_CONTAINER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.canister, name: AppStrings.labelCanister, slugId: GroceryConstant.STORAGE_CANISTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.spiceBox, name: AppStrings.labelSpiceBox, slugId: GroceryConstant.STORAGE_SPICE_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.jar, name: AppStrings.labelJar, slugId: GroceryConstant.STORAGE_JAR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lunchBox, name: AppStrings.labelLunchBox, slugId: GroceryConstant.STORAGE_LUNCH_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterBottle, name: AppStrings.labelWaterBottle, slugId: GroceryConstant.STORAGE_WATER_BOTTLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterJug, name: AppStrings.labelWaterJug, slugId: GroceryConstant.STORAGE_WATER_JUG),
  ];

// Gas & Water Utility Items List
  static final List<CollapsibleGridModel> utilityItemsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gasLighter, name: AppStrings.labelGasLighter, slugId: GroceryConstant.UTILITY_GAS_LIGHTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gasPipe, name: AppStrings.labelGasPipe, slugId: GroceryConstant.UTILITY_GAS_PIPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cylinderStand, name: AppStrings.labelCylinderStand, slugId: GroceryConstant.UTILITY_CYLINDER_STAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.panSupport, name: AppStrings.labelPanSupport, slugId: GroceryConstant.UTILITY_PAN_SUPPORT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterFilter, name: AppStrings.labelWaterFilter, slugId: GroceryConstant.UTILITY_WATER_FILTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.roPurifier, name: AppStrings.labelROPurifier, slugId: GroceryConstant.UTILITY_RO_PURIFIER),
  ];

// Cleaning & Kitchen Setup Items List
  static final List<CollapsibleGridModel> cleaningSetupList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishScrubber, name: AppStrings.labelDishScrubber, slugId: GroceryConstant.SETUP_DISH_SCRUBBER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sponge, name: AppStrings.labelSponge, slugId: GroceryConstant.SETUP_SPONGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishCloth, name: AppStrings.labelDishCloth, slugId: GroceryConstant.SETUP_DISH_CLOTH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.trashBin, name: AppStrings.labelTrashBin, slugId: GroceryConstant.SETUP_TRASH_BIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.apron, name: AppStrings.labelApron, slugId: GroceryConstant.SETUP_APRON),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kitchenRack, name: AppStrings.labelKitchenRack, slugId: GroceryConstant.SETUP_KITCHEN_RACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plateStand, name: AppStrings.labelPlateStand, slugId: GroceryConstant.SETUP_PLATE_STAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bottleRack, name: AppStrings.labelBottleRack, slugId: GroceryConstant.SETUP_BOTTLE_RACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cutleryStand, name: AppStrings.labelCutleryStand, slugId: GroceryConstant.SETUP_CUTLERY_STAND),
  ];

  /// Home Essentials

// Electrical and Safety List
  static final List<CollapsibleGridModel> electricalSafetyList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ledBulbs, name: AppStrings.labelLedBulbs, slugId: GroceryConstant.HOME_LED_BULBS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tubeLights, name: AppStrings.labelTubeLights, slugId: GroceryConstant.HOME_TUBE_LIGHTS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nightLamp, name: AppStrings.labelNightLamp, slugId: GroceryConstant.HOME_NIGHT_LAMP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.extensionBoard, name: AppStrings.labelExtensionBoard, slugId: GroceryConstant.HOME_EXTENSION_BOARD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multiPlug, name: AppStrings.labelMultiPlug, slugId: GroceryConstant.HOME_MULTI_PLUG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.electricWire, name: AppStrings.labelElectricWire, slugId: GroceryConstant.HOME_ELECTRIC_WIRE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.batteries, name: AppStrings.labelBatteries, slugId: GroceryConstant.HOME_BATTERIES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.emergencyLight, name: AppStrings.labelEmergencyLight, slugId: GroceryConstant.HOME_EMERGENCY_LIGHT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mosquitoNet, name: AppStrings.labelMosquitoNet, slugId: GroceryConstant.HOME_MOSQUITO_NET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.roomHeater, name: AppStrings.labelRoomHeater, slugId: GroceryConstant.HOME_ROOM_HEATER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hotWaterBag, name: AppStrings.labelHotWaterBag, slugId: GroceryConstant.HOME_HOT_WATER_BAG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.raincoat, name: AppStrings.labelRaincoat, slugId: GroceryConstant.HOME_RAINCOAT),
  ];

// Water and Storage List
  static final List<CollapsibleGridModel> waterStorageList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterPipe, name: AppStrings.labelWaterPipe, slugId: GroceryConstant.HOME_WATER_PIPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bucket, name: AppStrings.labelBucket, slugId: GroceryConstant.HOME_BUCKET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mug, name: AppStrings.labelMug, slugId: GroceryConstant.HOME_MUG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tapConnector, name: AppStrings.labelTapConnector, slugId: GroceryConstant.HOME_TAP_CONNECTOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterDrum, name: AppStrings.labelPlasticWaterDrum, slugId: GroceryConstant.HOME_WATER_DRUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.storageBox, name: AppStrings.labelPlasticStorageBox, slugId: GroceryConstant.HOME_STORAGE_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clothBag, name: AppStrings.labelClothStorageBag, slugId: GroceryConstant.HOME_CLOTH_BAG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wardrobeOrganizer, name: AppStrings.labelWardrobeOrganizer, slugId: GroceryConstant.HOME_WARDROBE_ORGANIZER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shoeRack, name: AppStrings.labelShoeRack, slugId: GroceryConstant.HOME_SHOE_RACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.storageBasket, name: AppStrings.labelStorageBasket, slugId: GroceryConstant.HOME_STORAGE_BASKET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hanger, name: AppStrings.labelHanger, slugId: GroceryConstant.HOME_HANGER),
  ];

// Home Utility List
  static final List<CollapsibleGridModel> homeUtilityList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bedsheet, name: AppStrings.labelBedsheet, slugId: GroceryConstant.HOME_BEDSHEET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pillowCover, name: AppStrings.labelPillowCover, slugId: GroceryConstant.HOME_PILLOW_COVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.blanket, name: AppStrings.labelBlanket, slugId: GroceryConstant.HOME_BLANKET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.curtains, name: AppStrings.labelCurtains, slugId: GroceryConstant.HOME_CURTAINS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.floorMat, name: AppStrings.labelFloorMat, slugId: GroceryConstant.HOME_FLOOR_MAT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plasticStool, name: AppStrings.labelPlasticStool, slugId: GroceryConstant.HOME_PLASTIC_STOOL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.plasticChair, name: AppStrings.labelPlasticChair, slugId: GroceryConstant.HOME_PLASTIC_CHAIR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.foldableTable, name: AppStrings.labelFoldableTable, slugId: GroceryConstant.HOME_FOLDABLE_TABLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clothClips, name: AppStrings.labelClothClips, slugId: GroceryConstant.HOME_CLOTH_CLIPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dryingRope, name: AppStrings.labelClothesDryingRope, slugId: GroceryConstant.HOME_DRYING_ROPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hooksStand, name: AppStrings.labelHooksStand, slugId: GroceryConstant.HOME_HOOKS_STAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.umbrella, name: AppStrings.labelUmbrella, slugId: GroceryConstant.HOME_UMBRELLA),
  ];

// Puja Items List
  static final List<CollapsibleGridModel> pujaItemsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.agarbatti, name: AppStrings.labelAgarbatti, slugId: GroceryConstant.PUJA_AGARBATTI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dhoop, name: AppStrings.labelDhoop, slugId: GroceryConstant.PUJA_DHOOP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.camphor, name: AppStrings.labelCamphor, slugId: GroceryConstant.PUJA_CAMPHOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cottonWicks, name: AppStrings.labelCottonWicks, slugId: GroceryConstant.PUJA_COTTON_WICKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pujaOil, name: AppStrings.labelPujaOil, slugId: GroceryConstant.PUJA_OIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.diya, name: AppStrings.labelDiya, slugId: GroceryConstant.PUJA_DIYA),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pujaThali, name: AppStrings.labelPujaThali, slugId: GroceryConstant.PUJA_THALI),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bell, name: AppStrings.labelBell, slugId: GroceryConstant.PUJA_BELL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kumkum, name: AppStrings.labelKumkum, slugId: GroceryConstant.PUJA_KUMKUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chandan, name: AppStrings.labelChandan, slugId: GroceryConstant.PUJA_CHANDAN),
  ];

  /// Cleaning & Maintenance
// Laundry Care List
  static final List<CollapsibleGridModel> laundryCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.detergentPowder, name: AppStrings.labelDetergentPowder, slugId: GroceryConstant.CLEAN_DETERGENT_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.detergentLiquid, name: AppStrings.labelDetergentLiquid, slugId: GroceryConstant.CLEAN_DETERGENT_LIQUID),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.detergentBar, name: AppStrings.labelDetergentBar, slugId: GroceryConstant.CLEAN_DETERGENT_BAR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.washingSoap, name: AppStrings.labelWashingSoap, slugId: GroceryConstant.CLEAN_WASHING_SOAP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fabricSoftener, name: AppStrings.labelFabricSoftener, slugId: GroceryConstant.CLEAN_FABRIC_SOFTENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stainRemover, name: AppStrings.labelStainRemover, slugId: GroceryConstant.CLEAN_STAIN_REMOVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fabricConditioner, name: AppStrings.labelFabricConditioner, slugId: GroceryConstant.CLEAN_FABRIC_CONDITIONER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.laundryWhitener, name: AppStrings.labelLaundryWhitener, slugId: GroceryConstant.CLEAN_LAUNDRY_WHITENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fabricDisinfectant, name: AppStrings.labelFabricDisinfectant, slugId: GroceryConstant.CLEAN_FABRIC_DISINFECTANT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clothesFreshener, name: AppStrings.labelClothesFreshener, slugId: GroceryConstant.CLEAN_CLOTHES_FRESHENER),
  ];

// Bathroom Care List
  static final List<CollapsibleGridModel> bathroomCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toiletCleaner, name: AppStrings.labelToiletCleaner, slugId: GroceryConstant.CLEAN_TOILET_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathroomCleaner, name: AppStrings.labelBathroomCleaner, slugId: GroceryConstant.CLEAN_BATHROOM_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.limescaleRemover, name: AppStrings.labelLimescaleRemover, slugId: GroceryConstant.CLEAN_LIMESCALE_REMOVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toiletFreshenerBlock, name: AppStrings.labelToiletFreshenerBlock, slugId: GroceryConstant.CLEAN_TOILET_FRESHENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glassCleaner, name: AppStrings.labelGlassCleaner, slugId: GroceryConstant.CLEAN_GLASS_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drainCleaner, name: AppStrings.labelDrainCleaner, slugId: GroceryConstant.CLEAN_DRAIN_CLEANER),
  ];

// Kitchen Care List
  static final List<CollapsibleGridModel> kitchenCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishwashLiquid, name: AppStrings.labelDishwashLiquid, slugId: GroceryConstant.CLEAN_DISHWASH_LIQUID),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishwashBar, name: AppStrings.labelDishwashBar, slugId: GroceryConstant.CLEAN_DISHWASH_BAR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishwashPowder, name: AppStrings.labelDishwashPowder, slugId: GroceryConstant.CLEAN_DISHWASH_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishScrubberClean, name: AppStrings.labelDishScrubber, slugId: GroceryConstant.CLEAN_DISH_SCRUBBER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dishwashingBrush, name: AppStrings.labelDishwashingBrush, slugId: GroceryConstant.CLEAN_DISHWASH_BRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sinkCleaner, name: AppStrings.labelSinkCleaner, slugId: GroceryConstant.CLEAN_SINK_CLEANER),
  ];

// Floor and Surface List
  static final List<CollapsibleGridModel> floorSurfaceList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.floorCleaner, name: AppStrings.labelFloorCleaner, slugId: GroceryConstant.CLEAN_FLOOR_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.surfaceCleaner, name: AppStrings.labelSurfaceCleaner, slugId: GroceryConstant.CLEAN_SURFACE_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.multipurposeCleaner, name: AppStrings.labelMultipurposeCleaner, slugId: GroceryConstant.CLEAN_MULTIPURPOSE_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tileStoneCleaner, name: AppStrings.labelTileStoneCleaner, slugId: GroceryConstant.CLEAN_TILE_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.woodFurnitureCleaner, name: AppStrings.labelWoodFurnitureCleaner, slugId: GroceryConstant.CLEAN_WOOD_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.furniturePolish, name: AppStrings.labelFurniturePolish, slugId: GroceryConstant.CLEAN_FURNITURE_POLISH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.metalPolish, name: AppStrings.labelMetalPolish, slugId: GroceryConstant.CLEAN_METAL_POLISH),
  ];

// Cleaning Tools List
  static final List<CollapsibleGridModel> cleaningToolsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.broom, name: AppStrings.labelBroom, slugId: GroceryConstant.CLEAN_BROOM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mop, name: AppStrings.labelMop, slugId: GroceryConstant.CLEAN_MOP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.floorWiper, name: AppStrings.labelFloorWiper, slugId: GroceryConstant.CLEAN_FLOOR_WIPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cleaningCloth, name: AppStrings.labelCleaningCloth, slugId: GroceryConstant.CLEAN_CLOTH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.scrubBrush, name: AppStrings.labelScrubBrush, slugId: GroceryConstant.CLEAN_SCRUB_BRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bucketMug, name: AppStrings.labelBucketAndMug, slugId: GroceryConstant.CLEAN_BUCKET_MUG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dustpan, name: AppStrings.labelDustpan, slugId: GroceryConstant.CLEAN_DUSTPAN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.garbageBags, name: AppStrings.labelGarbageBags, slugId: GroceryConstant.CLEAN_GARBAGE_BAGS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.dustbin, name: AppStrings.labelDustbin, slugId: GroceryConstant.CLEAN_DUSTBIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.doormat, name: AppStrings.labelDoormat, slugId: GroceryConstant.CLEAN_DOORMAT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cleaningGloves, name: AppStrings.labelCleaningGloves, slugId: GroceryConstant.CLEAN_GLOVES),
  ];

// Pest and Air Care List
  static final List<CollapsibleGridModel> pestAirCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mosquitoRepellent, name: AppStrings.labelMosquitoRepellent, slugId: GroceryConstant.PEST_MOSQUITO_REPELLENT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mosquitoCoil, name: AppStrings.labelMosquitoCoil, slugId: GroceryConstant.PEST_MOSQUITO_COIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cockroachKiller, name: AppStrings.labelCockroachKiller, slugId: GroceryConstant.PEST_COCKROACH_KILLER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.antKiller, name: AppStrings.labelAntKiller, slugId: GroceryConstant.PEST_ANT_KILLER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ratControl, name: AppStrings.labelRatControl, slugId: GroceryConstant.PEST_RAT_CONTROL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.airFreshener, name: AppStrings.labelAirFreshener, slugId: GroceryConstant.PEST_AIR_FRESHENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.roomFreshener, name: AppStrings.labelRoomFreshener, slugId: GroceryConstant.PEST_ROOM_FRESHENER),
  ];

// Safety and Repair List
  static final List<CollapsibleGridModel> safetyRepairList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.adhesiveTapeRepair, name: AppStrings.labelAdhesiveTape, slugId: GroceryConstant.REPAIR_ADHESIVE_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.electricalTape, name: AppStrings.labelElectricalTape, slugId: GroceryConstant.REPAIR_ELECTRICAL_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wallHooksRepair, name: AppStrings.labelWallHooks, slugId: GroceryConstant.REPAIR_WALL_HOOKS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nailsScrews, name: AppStrings.labelNailsAndScrews, slugId: GroceryConstant.REPAIR_NAILS_SCREWS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.generalAdhesive, name: AppStrings.labelGeneralAdhesive, slugId: GroceryConstant.REPAIR_GENERAL_ADHESIVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sealantPutty, name: AppStrings.labelSealantAndPutty, slugId: GroceryConstant.REPAIR_SEALANT_PUTTY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.matchbox, name: AppStrings.labelMatchbox, slugId: GroceryConstant.REPAIR_MATCHBOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lighterRepair, name: AppStrings.labelLighter, slugId: GroceryConstant.REPAIR_LIGHTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fireExtinguisher, name: AppStrings.labelFireExtinguisher, slugId: GroceryConstant.REPAIR_FIRE_EXTINGUISHER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shoePolish, name: AppStrings.labelShoePolish, slugId: GroceryConstant.REPAIR_SHOE_POLISH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shoeBrush, name: AppStrings.labelShoeBrush, slugId: GroceryConstant.REPAIR_SHOE_BRUSH),
  ];

/// Beauty & Health Care

// Bath and Body Care List
  static final List<CollapsibleGridModel> bathBodyCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathSoap, name: AppStrings.labelBathSoap, slugId: GroceryConstant.BEAUTY_BATH_SOAP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bodyWash, name: AppStrings.labelBodyWash, slugId: GroceryConstant.BEAUTY_BODY_WASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bodyScrub, name: AppStrings.labelBodyScrub, slugId: GroceryConstant.BEAUTY_BODY_SCRUB),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathSponge, name: AppStrings.labelBathSponge, slugId: GroceryConstant.BEAUTY_BATH_SPONGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bathBrush, name: AppStrings.labelBathBrush, slugId: GroceryConstant.BEAUTY_BATH_BRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.talcumPowder, name: AppStrings.labelTalcumPowder, slugId: GroceryConstant.BEAUTY_TALCUM_POWDER),
  ];

// Skin Care List
  static final List<CollapsibleGridModel> skinCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.faceCream, name: AppStrings.labelFaceCream, slugId: GroceryConstant.BEAUTY_FACE_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.bodyLotions, name: AppStrings.labelBodyLotion, slugId: GroceryConstant.BEAUTY_BODY_LOTION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.faceWash, name: AppStrings.labelFaceWash, slugId: GroceryConstant.BEAUTY_FACE_WASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.faceScrub, name: AppStrings.labelFaceScrub, slugId: GroceryConstant.BEAUTY_FACE_SCRUB),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.facePack, name: AppStrings.labelFacePack, slugId: GroceryConstant.BEAUTY_FACE_PACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sunscreen, name: AppStrings.labelSunscreenLotion, slugId: GroceryConstant.BEAUTY_SUNSCREEN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.handCream, name: AppStrings.labelHandCream, slugId: GroceryConstant.BEAUTY_HAND_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.footCream, name: AppStrings.labelFootCream, slugId: GroceryConstant.BEAUTY_FOOT_CREAM),
  ];

// Hair Care List
  static final List<CollapsibleGridModel> hairCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shampoo, name: AppStrings.labelShampoo, slugId: GroceryConstant.BEAUTY_SHAMPOO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.conditioner, name: AppStrings.labelConditioner, slugId: GroceryConstant.BEAUTY_CONDITIONER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hairOil, name: AppStrings.labelHairOil, slugId: GroceryConstant.BEAUTY_HAIR_OIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hairSerum, name: AppStrings.labelHairSerum, slugId: GroceryConstant.BEAUTY_HAIR_SERUM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hairMask, name: AppStrings.labelHairMask, slugId: GroceryConstant.BEAUTY_HAIR_MASK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stylingProduct, name: AppStrings.labelHairStylingProduct, slugId: GroceryConstant.BEAUTY_STYLING_PROD),
  ];

// Oral Care List
  static final List<CollapsibleGridModel> oralCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toothpaste, name: AppStrings.labelToothpaste, slugId: GroceryConstant.BEAUTY_TOOTHPASTE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toothbrush, name: AppStrings.labelToothbrush, slugId: GroceryConstant.BEAUTY_TOOTHBRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mouthwash, name: AppStrings.labelMouthwash, slugId: GroceryConstant.BEAUTY_MOUTHWASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tongueCleaner, name: AppStrings.labelTongueCleaner, slugId: GroceryConstant.BEAUTY_TONGUE_CLEANER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toothPowder, name: AppStrings.labelToothPowder, slugId: GroceryConstant.BEAUTY_TOOTH_POWDER),
  ];

// Men Grooming List
  static final List<CollapsibleGridModel> menGroomingList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.shavingCream, name: AppStrings.labelShavingCream, slugId: GroceryConstant.BEAUTY_SHAVING_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.razor, name: AppStrings.labelRazor, slugId: GroceryConstant.BEAUTY_RAZOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.afterShave, name: AppStrings.labelAfterShaveLotion, slugId: GroceryConstant.BEAUTY_AFTER_SHAVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.beardCare, name: AppStrings.labelBeardCareProduct, slugId: GroceryConstant.BEAUTY_BEARD_CARE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.trimmer, name: AppStrings.labelTrimmer, slugId: GroceryConstant.BEAUTY_TRIMMER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.deodorant, name: AppStrings.labelDeodorant, slugId: GroceryConstant.BEAUTY_DEODORANT),
  ];

// Women Hygiene List
  static final List<CollapsibleGridModel> womenHygieneList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sanitaryPads, name: AppStrings.labelSanitaryPads, slugId: GroceryConstant.BEAUTY_SANITARY_PADS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tampons, name: AppStrings.labelTampons, slugId: GroceryConstant.BEAUTY_TAMPONS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.menstrualCups, name: AppStrings.labelMenstrualCups, slugId: GroceryConstant.BEAUTY_MENSTRUAL_CUPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.intimateWash, name: AppStrings.labelIntimateWash, slugId: GroceryConstant.BEAUTY_INTIMATE_WASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.hygieneWipes, name: AppStrings.labelHygieneWipes, slugId: GroceryConstant.BEAUTY_HYGIENE_WIPES),
  ];

// Beauty and Cosmetics List
  static final List<CollapsibleGridModel> beautyCosmeticsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.facePowder, name: AppStrings.labelFacePowder, slugId: GroceryConstant.BEAUTY_FACE_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.foundation, name: AppStrings.labelFoundation, slugId: GroceryConstant.BEAUTY_FOUNDATION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lipstick, name: AppStrings.labelLipstick, slugId: GroceryConstant.BEAUTY_LIPSTICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.lipBalm, name: AppStrings.labelLipbalm, slugId: GroceryConstant.BEAUTY_LIP_BALM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.eyeMakeup, name: AppStrings.labelEyeMakeup, slugId: GroceryConstant.BEAUTY_EYE_MAKEUP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.nailPolish, name: AppStrings.labelNailPolish, slugId: GroceryConstant.BEAUTY_NAIL_POLISH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.makeupRemover, name: AppStrings.labelMakeupRemover, slugId: GroceryConstant.BEAUTY_MAKEUP_REMOVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.perfume, name: AppStrings.labelPerfume, slugId: GroceryConstant.BEAUTY_PERFUME),
  ];

// Bathroom Hygiene and Essentials List
  static final List<CollapsibleGridModel> bathroomHygieneList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.handWash, name: AppStrings.labelHandWash, slugId: GroceryConstant.BEAUTY_HAND_WASH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.handSanitizer, name: AppStrings.labelHandSanitizer, slugId: GroceryConstant.BEAUTY_HAND_SANITIZER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.toiletPaper, name: AppStrings.labelToiletPaper, slugId: GroceryConstant.BEAUTY_TOILET_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.facialTissues, name: AppStrings.labelFacialTissues, slugId: GroceryConstant.BEAUTY_FACIAL_TISSUES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paperTowels, name: AppStrings.labelPaperTowels, slugId: GroceryConstant.BEAUTY_PAPER_TOWELS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cotton, name: AppStrings.labelCotton, slugId: GroceryConstant.BEAUTY_COTTON),
  ];

// Baby Personal and Bath Care List
  static final List<CollapsibleGridModel> babyCareList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babySoap, name: AppStrings.labelBabySoap, slugId: GroceryConstant.BABY_SOAP),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyShampoo, name: AppStrings.labelBabyShampoo, slugId: GroceryConstant.BABY_SHAMPOO),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyOil, name: AppStrings.labelBabyOil, slugId: GroceryConstant.BABY_OIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyLotion, name: AppStrings.labelBabyLotion, slugId: GroceryConstant.BABY_LOTION),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyPowder, name: AppStrings.labelBabyPowder, slugId: GroceryConstant.BABY_POWDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.babyWipes, name: AppStrings.labelBabyWipes, slugId: GroceryConstant.BABY_WIPES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.diaperCream, name: AppStrings.labelBabyDiaperCream, slugId: GroceryConstant.BABY_DIAPER_CREAM),
  ];

// First Aid and Medical Essentials List
  static final List<CollapsibleGridModel> medicalEssentialsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.antisepticLiquid, name: AppStrings.labelAntisepticLiquid, slugId: GroceryConstant.MED_ANTISEPTIC_LIQUID),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.antisepticCream, name: AppStrings.labelAntisepticCream, slugId: GroceryConstant.MED_ANTISEPTIC_CREAM),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.cottonBandage, name: AppStrings.labelCottonBandage, slugId: GroceryConstant.MED_COTTON_BANDAGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.adhesiveBandage, name: AppStrings.labelAdhesiveBandage, slugId: GroceryConstant.MED_ADHESIVE_BANDAGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.crepeBandage, name: AppStrings.labelCrepeBandage, slugId: GroceryConstant.MED_CREPE_BANDAGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.gauzePads, name: AppStrings.labelGauzePads, slugId: GroceryConstant.MED_GAUZE_PADS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.medicalTape, name: AppStrings.labelMedicalTape, slugId: GroceryConstant.MED_MEDICAL_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.painReliefSpray, name: AppStrings.labelPainReliefSpray, slugId: GroceryConstant.MED_PAIN_SPRAY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.burnOintment, name: AppStrings.labelBurnOintment, slugId: GroceryConstant.MED_BURN_OINTMENT),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.thermometer, name: AppStrings.labelThermometer, slugId: GroceryConstant.MED_THERMOMETER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.disposableGloves, name: AppStrings.labelHandGlovesDisposable, slugId: GroceryConstant.MED_GLOVES),
  ];

  /// Stationary

// Writing, Paper & Notebooks List
  static final List<CollapsibleGridModel> writingPaperNotebooksList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pen, name: AppStrings.labelPen, slugId: GroceryConstant.STATIONARY_PEN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.pencil, name: AppStrings.labelPencil, slugId: GroceryConstant.STATIONARY_PENCIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.mechanicalPencil, name: AppStrings.labelMechanicalPencil, slugId: GroceryConstant.STATIONARY_MECH_PENCIL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.marker, name: AppStrings.labelMarker, slugId: GroceryConstant.STATIONARY_MARKER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.highlighter, name: AppStrings.labelHighlighter, slugId: GroceryConstant.STATIONARY_HIGHLIGHTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.notebook, name: AppStrings.labelNotebook, slugId: GroceryConstant.STATIONARY_NOTEBOOK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.copy, name: AppStrings.labelCopy, slugId: GroceryConstant.STATIONARY_COPY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.register, name: AppStrings.labelRegister, slugId: GroceryConstant.STATIONARY_REGISTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.roughCopy, name: AppStrings.labelRoughCopy, slugId: GroceryConstant.STATIONARY_ROUGH_COPY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.loosePaper, name: AppStrings.labelLoosePaper, slugId: GroceryConstant.STATIONARY_LOOSE_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stickyNotes, name: AppStrings.labelStickyNotes, slugId: GroceryConstant.STATIONARY_STICKY_NOTES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.diary, name: AppStrings.labelDiary, slugId: GroceryConstant.STATIONARY_DIARY),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.decorativeDiary, name: AppStrings.labelDecorativeDiary, slugId: GroceryConstant.STATIONARY_DECO_DIARY),
  ];

// School Essentials List
  static final List<CollapsibleGridModel> schoolEssentialsList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolBag, name: AppStrings.labelSchoolBag, slugId: GroceryConstant.STATIONARY_SCHOOL_BAG),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.geometryBox, name: AppStrings.labelGeometryBox, slugId: GroceryConstant.STATIONARY_GEOMETRY_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.eraser, name: AppStrings.labelEraser, slugId: GroceryConstant.STATIONARY_ERASER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.sharpener, name: AppStrings.labelSharpener, slugId: GroceryConstant.STATIONARY_SHARPENER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.scale, name: AppStrings.labelScale, slugId: GroceryConstant.STATIONARY_SCALE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.compass, name: AppStrings.labelCompass, slugId: GroceryConstant.STATIONARY_COMPASS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.divider, name: AppStrings.labelDivider, slugId: GroceryConstant.STATIONARY_DIVIDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolWaterBottle, name: AppStrings.labelSchoolWaterBottle, slugId: GroceryConstant.STATIONARY_SCHOOL_WATER_BOTTLE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolLunchBox, name: AppStrings.labelLunchBoxSchool, slugId: GroceryConstant.STATIONARY_SCHOOL_LUNCH_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolIdCard, name: AppStrings.labelSchoolIdCardHolder, slugId: GroceryConstant.STATIONARY_SCHOOL_ID_HOLDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolLabelStickers, name: AppStrings.labelSchoolLabelStickers, slugId: GroceryConstant.STATIONARY_SCHOOL_LABELS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kidsPencilBox, name: AppStrings.labelKidsPencilBox, slugId: GroceryConstant.STATIONARY_KIDS_PENCIL_BOX),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.schoolGlueStick, name: AppStrings.labelSchoolGlueStick, slugId: GroceryConstant.STATIONARY_SCHOOL_GLUE_STICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.kidsCrayons, name: AppStrings.labelKidsCrayons, slugId: GroceryConstant.STATIONARY_KIDS_CRAYONS),
  ];

// Office, Desk & Utility List
  static final List<CollapsibleGridModel> officeDeskUtilityList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.filesFolders, name: AppStrings.labelFilesAndFolders, slugId: GroceryConstant.STATIONARY_FILES_FOLDERS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.clipFile, name: AppStrings.labelClipFile, slugId: GroceryConstant.STATIONARY_CLIP_FILE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ringBinder, name: AppStrings.labelRingBinder, slugId: GroceryConstant.STATIONARY_RING_BINDER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.envelope, name: AppStrings.labelEnvelope, slugId: GroceryConstant.STATIONARY_ENVELOPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.officeRegister, name: AppStrings.labelOfficeRegister, slugId: GroceryConstant.STATIONARY_OFFICE_REGISTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paperClips, name: AppStrings.labelPaperClips, slugId: GroceryConstant.STATIONARY_PAPER_CLIPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.binderClips, name: AppStrings.labelBinderClips, slugId: GroceryConstant.STATIONARY_BINDER_CLIPS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.rubberBands, name: AppStrings.labelRubberBands, slugId: GroceryConstant.STATIONARY_RUBBER_BANDS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.thumbPins, name: AppStrings.labelThumbPins, slugId: GroceryConstant.STATIONARY_THUMB_PINS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.calculator, name: AppStrings.labelCalculator, slugId: GroceryConstant.STATIONARY_CALCULATOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.penStand, name: AppStrings.labelPenStand, slugId: GroceryConstant.STATIONARY_PEN_STAND),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.deskTray, name: AppStrings.labelDeskTray, slugId: GroceryConstant.STATIONARY_DESK_TRAY),
  ];

// Art, Craft & Project Work List
  static final List<CollapsibleGridModel> artCraftProjectList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.colourPencils, name: AppStrings.labelColourPencils, slugId: GroceryConstant.STATIONARY_COLOUR_PENCILS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.crayons, name: AppStrings.labelCrayons, slugId: GroceryConstant.STATIONARY_CRAYONS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.posterColours, name: AppStrings.labelPosterColours, slugId: GroceryConstant.STATIONARY_POSTER_COLOURS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.waterColours, name: AppStrings.labelWaterColours, slugId: GroceryConstant.STATIONARY_WATER_COLOURS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paintBrush, name: AppStrings.labelPaintBrush, slugId: GroceryConstant.STATIONARY_PAINT_BRUSH),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.drawingBook, name: AppStrings.labelDrawingBook, slugId: GroceryConstant.STATIONARY_DRAWING_BOOK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.artCraftKits, name: AppStrings.labelArtCraftKits, slugId: GroceryConstant.STATIONARY_ART_CRAFT_KITS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glitterPack, name: AppStrings.labelGlitterPack, slugId: GroceryConstant.STATIONARY_GLITTER_PACK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.projectFile, name: AppStrings.labelProjectFile, slugId: GroceryConstant.STATIONARY_PROJECT_FILE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.projectCover, name: AppStrings.labelProjectCoverSheet, slugId: GroceryConstant.STATIONARY_PROJECT_COVER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.chartPaper, name: AppStrings.labelChartPaper, slugId: GroceryConstant.STATIONARY_CHART_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.examPad, name: AppStrings.labelExamPad, slugId: GroceryConstant.STATIONARY_EXAM_PAD),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.answerSheets, name: AppStrings.labelAnswerSheets, slugId: GroceryConstant.STATIONARY_ANSWER_SHEETS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.practicalFile, name: AppStrings.labelPracticalFile, slugId: GroceryConstant.STATIONARY_PRACTICAL_FILE),
  ];

// Cutting, Fixing & Packing List
  static final List<CollapsibleGridModel> cuttingFixingPackingList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.scissors, name: AppStrings.labelScissors, slugId: GroceryConstant.STATIONARY_SCISSORS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.paperCutter, name: AppStrings.labelPaperCutter, slugId: GroceryConstant.STATIONARY_PAPER_CUTTER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.measuringScale, name: AppStrings.labelMeasuringScale, slugId: GroceryConstant.STATIONARY_MEASURING_SCALE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.measuringTape, name: AppStrings.labelMeasuringTape, slugId: GroceryConstant.STATIONARY_MEASURING_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.fevicol, name: AppStrings.labelFevicol, slugId: GroceryConstant.STATIONARY_FEVICOL),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.glueStick, name: AppStrings.labelGlueStick, slugId: GroceryConstant.STATIONARY_GLUE_STICK),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.adhesiveTapeStat, name: AppStrings.labelAdhesiveTapeStationary, slugId: GroceryConstant.STATIONARY_ADHESIVE_TAPE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.stapler, name: AppStrings.labelStapler, slugId: GroceryConstant.STATIONARY_STAPLER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.staplerPins, name: AppStrings.labelStaplerPins, slugId: GroceryConstant.STATIONARY_STAPLER_PINS),
  ];

// Printing, Gifts & Decor List
  static final List<CollapsibleGridModel> printingGiftsDecorList = [
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.a4Paper, name: AppStrings.labelA4Paper, slugId: GroceryConstant.STATIONARY_A4_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.printerPaper, name: AppStrings.labelPrinterPaper, slugId: GroceryConstant.STATIONARY_PRINTER_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.photoPaper, name: AppStrings.labelPhotoPaper, slugId: GroceryConstant.STATIONARY_PHOTO_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.inkCartridge, name: AppStrings.labelInkCartridge, slugId: GroceryConstant.STATIONARY_INK_CARTRIDGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tonerCartridge, name: AppStrings.labelTonerCartridge, slugId: GroceryConstant.STATIONARY_TONER_CARTRIDGE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.usbDrive, name: AppStrings.labelUsbPenDrive, slugId: GroceryConstant.STATIONARY_USB_DRIVE),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.greetingCards, name: AppStrings.labelGreetingCards, slugId: GroceryConstant.STATIONARY_GREETING_CARDS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.giftEnvelopes, name: AppStrings.labelGiftEnvelopes, slugId: GroceryConstant.STATIONARY_GIFT_ENVELOPES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wrappingPaper, name: AppStrings.labelGiftWrappingPaper, slugId: GroceryConstant.STATIONARY_WRAPPING_PAPER),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.ribbons, name: AppStrings.labelRibbons, slugId: GroceryConstant.STATIONARY_RIBBONS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.giftBows, name: AppStrings.labelGiftBows, slugId: GroceryConstant.STATIONARY_GIFT_BOWS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.keyChain, name: AppStrings.labelKeyChain, slugId: GroceryConstant.STATIONARY_KEY_CHAIN),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.wallet, name: AppStrings.labelWallet, slugId: GroceryConstant.STATIONARY_WALLET),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.smallGifts, name: AppStrings.labelSmallUtilityGifts, slugId: GroceryConstant.STATIONARY_UTILITY_GIFTS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.softToys, name: AppStrings.labelSoftToys, slugId: GroceryConstant.STATIONARY_SOFT_TOYS),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.showpieces, name: AppStrings.labelShowpieces, slugId: GroceryConstant.STATIONARY_SHOWPIECES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.tableDecor, name: AppStrings.labelTableDecorItems, slugId: GroceryConstant.STATIONARY_TABLE_DECOR),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.photoFrames, name: AppStrings.labelPhotoFrames, slugId: GroceryConstant.STATIONARY_PHOTO_FRAMES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.giftBoxes, name: AppStrings.labelGiftBoxes, slugId: GroceryConstant.STATIONARY_GIFT_BOXES),
    CollapsibleGridModel(icon: GroceryIconCategoryAssets.giftHampers, name: AppStrings.labelGiftHampers, slugId: GroceryConstant.STATIONARY_GIFT_HAMPERS),
  ];

}

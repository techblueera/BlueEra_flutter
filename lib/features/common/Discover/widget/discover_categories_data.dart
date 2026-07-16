import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';

/// Static category data for the redesigned Discover landing page.
///
/// The illustrated icons already ship in the asset bundle (see
/// [AppImageAssets] / [OnboardingBusinessAssets]). `slugId`s reuse the
/// existing service slugs so taps can route into the current grocery / food
/// flows unchanged.

final List<CollapsibleGridModel> discoverGroceryCategories = [
  CollapsibleGridModel(
    name: 'Kirana Store',
    slugId: 'KIRANA_STORE',
    icon: AppImageAssets.kiranaStore,
  ),
  CollapsibleGridModel(
    name: 'General Store',
    slugId: 'GENERAL_STORE',
    icon: AppImageAssets.generalStore,
  ),
  CollapsibleGridModel(
    name: 'Vegetable & Fruits',
    slugId: 'VEG_FRUITS',
    icon: AppImageAssets.vegFruitStore,
  ),
  CollapsibleGridModel(
    name: 'Dairy & Bakery',
    slugId: 'DAIRY_BAKERY',
    icon: AppImageAssets.dairyBakeryStore,
  ),
  CollapsibleGridModel(
    name: 'Home Essentials',
    slugId: 'HOME_ESSENTIALS',
    icon: AppImageAssets.homeEssentialsStore,
  ),
];

final List<CollapsibleGridModel> discoverFoodCategories = [
  CollapsibleGridModel(
    name: 'Multicuisine Restaurant',
    slugId: 'MULTICUISINE',
    icon: OnboardingBusinessAssets.multicuisineRestaurant,
  ),
  CollapsibleGridModel(
    name: 'Pure - Veg Restaurant',
    slugId: 'PURE_VEG',
    icon: OnboardingBusinessAssets.pureVegRestaurant,
  ),
  CollapsibleGridModel(
    name: 'Non-Veg Restaurant',
    slugId: 'NON_VEG',
    icon: OnboardingBusinessAssets.nonVegRestaurant,
  ),
  CollapsibleGridModel(
    name: 'Economy Dhaba',
    slugId: 'ECONOMY_DHABA',
    icon: OnboardingBusinessAssets.economyDhaba,
  ),
  CollapsibleGridModel(
    name: 'Garden/ Buffet Restaurant',
    slugId: 'GARDEN_BUFFET',
    icon: OnboardingBusinessAssets.gardenBuffetRestaurant,
  ),
  CollapsibleGridModel(
    name: 'Cloud Kitchen',
    slugId: 'CLOUD_KITCHEN',
    icon: OnboardingBusinessAssets.cloudKitchenMess,
  ),
  CollapsibleGridModel(
    name: 'Breakfast / Fast-food',
    slugId: 'BREAKFAST_FASTFOOD',
    icon: OnboardingBusinessAssets.breakfastFastFood,
  ),
  CollapsibleGridModel(
    name: 'Sweet & Namkeen',
    slugId: 'SWEET_NAMKEEN',
    icon: OnboardingBusinessAssets.sweetNamkeenShop,
  ),
  CollapsibleGridModel(
    name: 'Ice Cream Corner',
    slugId: 'ICE_CREAM',
    icon: OnboardingBusinessAssets.iceCreamCorner,
  ),
  CollapsibleGridModel(
    name: 'Coffee & Braverages',
    slugId: 'COFFEE_BEVERAGES',
    icon: OnboardingBusinessAssets.coffeeBeveragesShop,
  ),
];

/// Home Made Food sub-categories for the redesigned Discover page.
///
/// The app has no dedicated per-item routing/icons for these yet, so every
/// tile reuses the closest existing illustrated icon and opens the shared
/// Home Made Food discover flow (see `HmfCategoryDiscoverScreen`).
final List<CollapsibleGridModel> discoverHomeMadeFoodCategories = [
  CollapsibleGridModel(
    name: 'Tiffin',
    slugId: 'HOME_MADE_FOOD',
    icon: AppImageAssets.tiffin,
  ),
  CollapsibleGridModel(
    name: 'Bakery',
    slugId: 'HOME_MADE_FOOD',
    icon: AppImageAssets.dairyBakeryStore,
  ),
  CollapsibleGridModel(
    name: 'Sweets',
    slugId: 'HOME_MADE_FOOD',
    icon: AppImageAssets.sweets,
  ),
  CollapsibleGridModel(
    name: 'Namkeen',
    slugId: 'HOME_MADE_FOOD',
    icon: AppImageAssets.namkeens,
  ),
  CollapsibleGridModel(
    name: 'Pickles',
    slugId: 'HOME_MADE_FOOD',
    icon: AppImageAssets.pickels,
  ),
];

/// Home Made Product sub-categories for the redesigned Discover page.
///
/// Every tile opens the shared Home Made Products flow
/// (`HmpDiscoverScreenV2`); the slug is cosmetic since routing is uniform.
final List<CollapsibleGridModel> discoverHomeMadeProductCategories = [
  CollapsibleGridModel(
    name: 'Art & Craft',
    slugId: 'PRODUCT',
    icon: AppImageAssets.artCrafts,
  ),
  CollapsibleGridModel(
    name: 'Gift Items',
    slugId: 'PRODUCT',
    icon: AppImageAssets.giftItems,
  ),
  CollapsibleGridModel(
    name: 'Handicrafts',
    slugId: 'PRODUCT',
    icon: AppImageAssets.handicraft,
  ),
  CollapsibleGridModel(
    name: 'Textile',
    slugId: 'PRODUCT',
    icon: AppImageAssets.artsCraftsSewing,
  ),
  CollapsibleGridModel(
    name: 'Utility Product',
    slugId: 'PRODUCT',
    icon: AppImageAssets.utilityProducts,
  ),
];

/// Home Services sub-categories for the redesigned Discover page.
///
/// Every tile opens the shared Home Services flow
/// (`HomeServiceDiscoverScreenV2`); the slug is cosmetic since routing is
/// uniform.
final List<CollapsibleGridModel> discoverHomeServicesCategories = [
  CollapsibleGridModel(
    name: 'Tailor',
    slugId: 'SERVICE',
    icon: AppImageAssets.tailor,
  ),
  CollapsibleGridModel(
    name: 'Beautician',
    slugId: 'SERVICE',
    icon: AppImageAssets.beautician,
  ),
  CollapsibleGridModel(
    name: 'Interior Decor',
    slugId: 'SERVICE',
    icon: AppImageAssets.interiorDesigner,
  ),
  CollapsibleGridModel(
    name: 'Digital Marketing',
    slugId: 'SERVICE',
    icon: AppImageAssets.digitalMarketing,
  ),
];

/// Top quick-access tabs shown under the location bar.
const List<Map<String, String>> discoverQuickAccessTabs = [
  {'title': 'Quick\nAccess', 'icon': AppImageAssets.overviewDiscover},
  {'title': 'Grocery &\nFood', 'icon': AppImageAssets.groceryItemsDiscover},
  {'title': 'Travel &\nBooking', 'icon': AppImageAssets.bookingDiscover},
  {'title': 'Shopping\n& Sell', 'icon': AppImageAssets.shoppingDiscover},
  {'title': 'Services &\nProfessional', 'icon': AppImageAssets.servicesDiscover},
  {'title': 'Jobs &\nEducation', 'icon': AppImageAssets.professionalDiscover},
];

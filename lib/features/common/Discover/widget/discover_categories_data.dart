import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/discover_icon_assets.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';

/// Static category data for the Discover landing page.
///
/// The illustrated icons already ship in the asset bundle (see
/// [AppImageAssets] / [OnboardingBusinessAssets]). `slugId`s reuse the
/// existing service slugs so taps can route into the current flows unchanged.
///
/// Grocery and Food used to be listed here too. They are not any more: those
/// two verticals have real onboarding categories on the API, and a bundled
/// copy whose ids only nearly matched the server's meant a tapped tile could
/// not name its own category to the screen it opened. They now read
/// [AuthController]'s lists directly — see `discover_screen.dart`. What is left
/// here is the sets the backend has no category endpoint for.

/// Home Made Food sub-categories for the redesigned Discover page.
///
/// Routing is uniform — every tile opens the shared Home Made Food discover
/// flow (see `HmfCategoryDiscoverScreen`) — but the artwork is no longer a
/// "closest existing icon" stand-in: the 2026 [DiscoverIcons] set ships one
/// drawn for each of these five.
final List<CollapsibleGridModel> discoverHomeMadeFoodCategories = [
  CollapsibleGridModel(
    name: 'Tiffin',
    slugId: 'HOME_MADE_FOOD',
    icon: DiscoverIcons.tiffin,
  ),
  CollapsibleGridModel(
    name: 'Bakery',
    slugId: 'HOME_MADE_FOOD',
    icon: DiscoverIcons.bakery,
  ),
  CollapsibleGridModel(
    name: 'Sweets',
    slugId: 'HOME_MADE_FOOD',
    icon: DiscoverIcons.sweets,
  ),
  CollapsibleGridModel(
    name: 'Namkeen',
    slugId: 'HOME_MADE_FOOD',
    icon: DiscoverIcons.namkeen,
  ),
  CollapsibleGridModel(
    name: 'Pickles',
    slugId: 'HOME_MADE_FOOD',
    icon: DiscoverIcons.pickles,
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
    icon: DiscoverIcons.artCraft,
  ),
  CollapsibleGridModel(
    name: 'Gift Items',
    slugId: 'PRODUCT',
    icon: DiscoverIcons.giftItems,
  ),
  CollapsibleGridModel(
    name: 'Handicrafts',
    slugId: 'PRODUCT',
    icon: DiscoverIcons.handicrafts,
  ),
  CollapsibleGridModel(
    name: 'Textile',
    slugId: 'PRODUCT',
    icon: DiscoverIcons.textile,
  ),
  CollapsibleGridModel(
    name: 'Utility Product',
    slugId: 'PRODUCT',
    icon: DiscoverIcons.utilityProduct,
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
    // No tailoring icon in the 2026 set; textile (bolts of cloth) is the
    // nearest subject in it and keeps the row on one style.
    icon: DiscoverIcons.textile,
  ),
  CollapsibleGridModel(
    name: 'Beautician',
    slugId: 'SERVICE',
    icon: DiscoverIcons.beautyPersonalCare,
  ),
  CollapsibleGridModel(
    name: 'Interior Decor',
    slugId: 'SERVICE',
    icon: DiscoverIcons.renovator,
  ),
  CollapsibleGridModel(
    name: 'Digital Marketing',
    slugId: 'SERVICE',
    icon: DiscoverIcons.mediaPublicity,
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

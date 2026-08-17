import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/rental/view/rental_discover_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalCardWidget extends StatelessWidget {
  const RentalCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DiscoverGridSection(
      title: AppStrings.rentAndProperties.tr,
      items: propertyDiscoverTiles,
      getName: _tileName,
      getIcon: (item) => item.image,
      // Into the rental flow's own entry screen, not straight to the results.
      // Property search is worthless without a place — "2BHK" is not an answer
      // until you say where — so every way into this vertical goes through the
      // screen that asks for one. This used to jump past it, which meant the
      // Discover tiles searched wherever the phone happened to be while the
      // rental card asked properly.
      //
      // The tap is not discarded to get there: the tile's listing type narrows
      // the entry grid, and the category itself arrives highlighted, so the
      // location step reads as a step forward rather than as being sent back to
      // pick the same thing again.
      onItemTap: (item) => Get.to(() => RentalDiscoverEntryScreen(
            isSale: item.isSale,
            highlightCategoryIndex: propertyDiscoverTiles.indexOf(item),
          )),
      // Straight to the entry screen — no category sheet on the way.
      //
      // Without this, tapping the folder tile opened [DiscoverFolderSheet] to
      // pick a category, and picking one opened the entry screen, whose own grid
      // then showed the same eight categories again. Two pickers for one choice,
      // the second a copy of the first. The sheet is skipped and the screen's
      // grid is the only place the choice is made; `isSale: null` there means all
      // eight, sale and rental together.
      onFolderTap: () => Get.to(() => const RentalDiscoverEntryScreen()),
    );
  }

  /// What the tile is called in the picker: **the listing type, then the
  /// category**.
  ///
  /// Three of the eight categories are sold AND rented — houses & apartments,
  /// lands & plots, shops & offices — so `label` alone printed the same name
  /// twice in the sheet with nothing to tell the pair apart. The two tiles go to
  /// different listings, so the label has to say which.
  ///
  /// The listing type leads for two reasons. It is the thing being
  /// disambiguated, and it is what a user scans by ("I want to rent") — with the
  /// type trailing, the labels all open with the same words and the answer sits
  /// at the end. It also guarantees the type stays VISIBLE: the tile allows two
  /// lines and a long category ellipsises, which would otherwise cut off the one
  /// word the label was added for ("For Sale · New Projects & Prop…" keeps it,
  /// "New Projects & Properties · For…" loses it).
  String _tileName(PropertyTileData item) =>
      '${(item.isSale ? AppStrings.forSale : AppStrings.forRent).tr}'
      ' · ${_categoryLabel(item)}';

  /// The category's own translated name.
  ///
  /// Keyed off `propertyType` rather than reusing `label`, which is a raw
  /// English string in [propertyDiscoverTiles] and is passed to the destination
  /// controller as data — so it can't be turned into a translation key without
  /// touching the routing. These five keys already exist for the same five
  /// categories. An unknown type falls back to the raw label: an English name is
  /// a better answer than a blank tile.
  String _categoryLabel(PropertyTileData item) {
    switch (item.propertyType) {
      case 'HouseAndApartment':
        return AppStrings.propertyCategoryHousesApartments.tr;
      case 'NewProjectsAndProperties':
        return AppStrings.propertyCategoryNewProjectsProperties.tr;
      case 'LandAndPlots':
        return AppStrings.propertyCategoryLandsPlots.tr;
      case 'ShopAndOffices':
        return AppStrings.propertyCategoryShopsOffices.tr;
      case 'PGAndGuestHouse':
        return AppStrings.propertyCategoryPGGuestHouse.tr;
    }
    return item.label;
  }
}

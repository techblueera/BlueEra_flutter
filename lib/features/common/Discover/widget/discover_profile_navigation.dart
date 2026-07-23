import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Opens the profile of whoever posted / owns a Discover listing.
///
/// Discover mixes both account types in the same lists — an individual's
/// self-employed service sits right next to a business storefront — so the
/// same avatar tap has to land on two different screens: the business
/// visiting card for `BUSINESS`, the personal profile for `INDIVIDUAL`
/// (and the "own profile" variants when the listing belongs to the logged
/// in user, which [redirectToProfileScreen] already handles).
///
/// Callers pass whichever ids their card model carries. [accountType]
/// decides which id is used; when the model has no account type we infer
/// it from which id is present, and if the id for the resolved type is
/// missing we fall back to the other one rather than dead-ending the tap.
void openDiscoverProfile({
  String? accountType,
  String? userId,
  String? businessId,
  String? screenName,
}) {
  final type = (accountType ?? '').trim().toUpperCase();
  final bId = (businessId ?? '').trim();
  final uId = (userId ?? '').trim();

  bool isBusiness;
  if (type == AppConstants.business) {
    isBusiness = true;
  } else if (type == AppConstants.individual) {
    isBusiness = false;
  } else {
    isBusiness = bId.isNotEmpty;
  }

  // The resolved type has no id but the other one does — trust the id.
  if (isBusiness && bId.isEmpty && uId.isNotEmpty) isBusiness = false;
  if (!isBusiness && uId.isEmpty && bId.isNotEmpty) isBusiness = true;

  final profileId = isBusiness ? bId : uId;
  if (profileId.isEmpty) {
    commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    return;
  }

  redirectToProfileScreen(
    accountType: isBusiness ? AppConstants.business : AppConstants.individual,
    profileId: profileId,
    screenName: screenName,
  );
}

/// Wraps a Discover card's avatar / name block so tapping it opens the
/// poster's profile instead of falling through to the card's own tap
/// (which opens the listing detail). Same argument contract as
/// [openDiscoverProfile].
class DiscoverProfileTap extends StatelessWidget {
  final Widget child;
  final String? accountType;
  final String? userId;
  final String? businessId;
  final String? screenName;

  const DiscoverProfileTap({
    super.key,
    required this.child,
    this.accountType,
    this.userId,
    this.businessId,
    this.screenName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openDiscoverProfile(
        accountType: accountType,
        userId: userId,
        businessId: businessId,
        screenName: screenName,
      ),
      child: child,
    );
  }
}

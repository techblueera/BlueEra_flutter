import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/account_plan_controller.dart';
import 'account_plan_catalog_view.dart';

/// Standalone host for the Account Plan catalog.
///
/// The catalog itself lives in [AccountPlanCatalogView]; this only supplies the
/// scaffold, the scroll and pull-to-refresh. `ContributionScreenV2` hosts the
/// same view with an explainer video above it, which is where the flow is
/// normally entered — this screen exists for direct navigation.
///
/// See docs/backend/ACCOUNT_PLAN_FLUTTER_INTEGRATION_GUIDE.md.
class AccountPlanScreen extends StatefulWidget {
  const AccountPlanScreen({
    super.key,
    required this.tagId,
    this.hasGst = false,
    this.accountType,
    this.buyerState,
  });

  /// Category (business) or profession (individual) tag. Required for a
  /// business — the catalog cannot pick a radius track without it.
  final String tagId;

  /// Selects the GST vs no-GST radius track. Business only; ignored elsewhere.
  final bool hasGst;

  final String? accountType;

  /// Improves the CGST/SGST-vs-IGST split on the invoice. Optional.
  final String? buyerState;

  @override
  State<AccountPlanScreen> createState() => _AccountPlanScreenState();
}

class _AccountPlanScreenState extends State<AccountPlanScreen> {
  late final AccountPlanController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = getOrPut(() => AccountPlanController())
      ..tagId = widget.tagId
      ..hasGst = widget.hasGst
      ..accountType = widget.accountType
      ..buyerState = widget.buyerState;
    hydrateAccountPlanBuyer(_ctrl);
    _ctrl.fetchPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: CommonBackAppBar(
        isLeading: true,
        appBarColor: AppColors.white,
        title: AppStrings.chooseYourPlan.tr,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _ctrl.fetchPlans,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                AccountPlanCatalogView(controller: _ctrl),
                SizedBox(height: SizeConfig.size24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fills the Razorpay prefill (name / email / phone) from the signed-in
/// profile, the same way the deposit flow does.
///
/// Best-effort and shared by both hosts: checkout still opens without it, the
/// user just types their own details.
void hydrateAccountPlanBuyer(AccountPlanController ctrl) {
  try {
    final user = Get.find<ViewPersonalDetailsController>()
        .personalProfileDetails
        .value
        .user;
    ctrl.buyerName = user?.name ?? '';
    ctrl.buyerEmail = user?.email ?? '';
    ctrl.buyerPhone = user?.contactNo ?? userMobileGlobal;
  } catch (_) {
    ctrl.buyerPhone = userMobileGlobal;
  }
}

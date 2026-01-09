import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/rental_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_card.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class RentalServiceScreen extends StatefulWidget {
  const RentalServiceScreen({super.key});

  @override
  State<RentalServiceScreen> createState() => _RentalServiceScreenState();
}

class _RentalServiceScreenState extends State<RentalServiceScreen> {
  final controller = Get.put(RentalController());

  @override
  void initState() {
    controller.callApi(forceRefresh: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     body: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         _filterButtons(),
         _buildTabViews()
       ],
     ),
    );
  }

  Widget _filterButtons() {
    return Obx(() {
      final selectedTab = controller.selectedRentalTabs.value;

      return Padding(
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size15,
            horizontal: SizeConfig.size8,
        ),
        child: HorizontalTabSelector<RentalServiceType>(
          tabs: controller.rentalTabs,
          selectedIndex: controller.rentalTabs.indexOf(selectedTab),
          horizontalMargin: 0.0,
          onTabSelected: (index, _) {
            final selectedEnum = controller.rentalTabs[index];

            if (controller.selectedRentalTabs.value == selectedEnum) return;

            controller.selectedRentalTabs.value = selectedEnum;
            controller.callApi();
          },
          labelBuilder: (r) => r.label,
          unSelectedBackgroundColor: AppColors.white,
        ),
      );
    });
  }



  Widget _buildTabViews() {
    return Obx(()=> Expanded(
      child: rentalServices(controller.selectedRentalTabs.value),
     )
    );
  }

  Widget rentalServices(RentalServiceType rentalServiceTab) {
    final List<RentalServiceData> list;

    switch (rentalServiceTab) {
      case RentalServiceType.homeStay:
        list = controller.homeStayServices;
        break;

      case RentalServiceType.flatRoom:
        list = controller.flatRoomServices;
        break;

      case RentalServiceType.vehicle:
        list = controller.vehicleServices;
        break;
    }

    if(controller.isLoading.value){
      return Center(
          child: CircularProgressIndicator()
      );
    }

    // EMPTY LIST VIEW
    if (list.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          message: "${rentalServiceTab.label} ${AppStrings.servicesAreEmpty.tr}\n${AppStrings.createYourService.tr}",
        ),
      );
    }

    // GRID UI (REUSED FOR ALL TABS)
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = 2;
          final crossSpacing = 6.0;
          final mainSpacing = 6.0;

          final itemWidth =
              (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing)) /
                  crossAxisCount;

          return MasonryGridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: mainSpacing,
            itemCount: list.length,
            padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 40),
            itemBuilder: (context, index) {
              final service = list[index];
              return RentalCard(
                  rentalServiceData: service,
                  width: itemWidth,
                  deleteServiceApi: () async {
                    await showCommonDialog(
                    context: context,
                    text: AppStrings.areYouSureDelete,
                    confirmText: AppStrings.delete,
                    cancelText: AppStrings.cancel,
                    confirmCallback: () {
                      controller.deleteService(
                          serviceId: service.sId ?? '',
                      );
                    },
                    cancelCallback: () {
                      Get.back();
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }



}

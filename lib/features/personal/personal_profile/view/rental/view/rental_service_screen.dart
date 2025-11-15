import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/rental_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_card.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
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
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.channelFilterIcon),
            SizedBox(width: SizeConfig.size10),
            Row(
              children: controller.rentalTabs.map((tab) {
                final isSelected = controller.selectedRentalTabs.value == tab;
                return Padding(
                  padding: EdgeInsets.only(right: SizeConfig.size14),
                  child: GestureDetector(
                    onTap: () {
                      controller.selectedRentalTabs.value = tab;
                      controller.callApi();
                    },
                    child: CustomText(
                      tab.label,
                      decoration: TextDecoration.underline,
                      color: isSelected ? AppColors.primaryColor : AppColors.secondaryTextColor,
                      decorationColor:
                      isSelected ? AppColors.primaryColor : AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
          message: "${rentalServiceTab.label} services are empty\nCreate your service",
        ),
      );
    }

    // GRID UI (REUSED FOR ALL TABS)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    text: "Are you sure you want to delete this service? Once deleted, it cannot be recovered.",
                    confirmText: 'Delete',
                    cancelText: 'Cancel',
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

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_detail_screen.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/actions/vehicle_owner_actions.dart';
import 'package:BlueEra/features/me/vehicle/view/v2/widgets/vehicle_overview_sections.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_discover_card.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Vehicles (fleet) tab — full vertical list of the owner's vehicles
/// with edit/delete affordances. Adding is driven by the shell FAB.
class VehicleVehiclesTabV2 extends StatelessWidget {
  final VehicleController controller;

  const VehicleVehiclesTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: SizeConfig.size12,
          right: SizeConfig.size12,
          top: SizeConfig.size12),
      // Column so the deck sits above every state the Obx can return —
      // loading, empty and the populated fleet list alike.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contribution / Bank / Refer deck. No catalog card here: this tab IS
          // the add surface and carries its own add masthead, so a card pointing
          // at the screen you are already on would be noise.
          OrderActionsCarousel(),
          SizedBox(height: SizeConfig.size12),
          Obx(() {
        final state = controller.myVehiclesState.value.status;
        if (state == Status.LOADING && controller.myVehicles.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.myVehicles.isEmpty) {
          return VehicleEmptyState(
            title: AppStrings.noVehiclesInFleet.tr,
            subtitle: AppStrings.tapAddVehicleHint.tr,
            cta: AppStrings.addAVehicleCta.tr,
            onTap: () => VehicleOwnerActions.addVehicle(context, controller),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: controller.myVehicles.length,
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
          itemBuilder: (_, i) {
            final v = controller.myVehicles[i];
            // Mirrors the public Discover card exactly (tap/chat/book open
            // the detail screen); Edit/Delete live in the card's "more" menu.
            void openDetail() {
              if (v.id == null) return;
              Get.to(() => VehicleDetailScreen(vehicleId: v.id!));
            }

            return VehicleDiscoverCard(
              vehicle: v,
              showOwnerActions: true,
              onTap: openDetail,
              onChat: openDetail,
              onBook: openDetail,
              onEdit: () =>
                  VehicleOwnerActions.editVehicle(context, controller, v),
              onDelete: () => VehicleOwnerActions.confirmDeleteVehicle(
                  context, controller, v),
            );
          },
        );
          }),
        ],
      ),
    );
  }
}

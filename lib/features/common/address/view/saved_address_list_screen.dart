import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/address/model/user_address_model.dart';
import 'package:BlueEra/features/common/address/controller/address_controller.dart';
import 'package:BlueEra/features/common/address/model/address_ui_model.dart';
import 'package:BlueEra/features/common/address/view/add_edit_address_screen.dart';
import 'package:BlueEra/features/common/address/widget/saved_address_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/delete_dialog.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The user's saved addresses: list, select one, add / edit / delete.
///
/// Open it through `AddressPicker.pick(...)` rather than constructing it
/// directly — that helper wires the controller and the result callback.
class SavedAddressListScreen extends StatefulWidget {
  const SavedAddressListScreen({
    super.key,
    this.onAddressSelected,
    this.isSelectionMode = true,
  });

  /// Fired when the user confirms a selection, before this screen pops.
  final AddressSelectedCallback? onAddressSelected;

  /// `false` renders it as a plain "manage my addresses" screen — no confirm
  /// bar, tapping a card only marks it as the active address.
  final bool isSelectionMode;

  @override
  State<SavedAddressListScreen> createState() => _SavedAddressListScreenState();
}

class _SavedAddressListScreenState extends State<SavedAddressListScreen> {
  final AddressController controller = getOrPut(() => AddressController());

  @override
  void initState() {
    super.initState();
    // The controller outlives this screen (it is the app-wide address
    // state), so `onInit` only runs on the very first open — re-sync on
    // every open instead, otherwise a second visit shows a stale list.
    controller.fetchAddresses();
  }

  Future<void> _openForm({UserAddress? address}) async {
    if (address == null && !controller.canAddMore) {
      commonSnackBar(
        message:
            'You can save up to ${AddressController.maxAddressLimit} addresses. Delete one to add another.',
      );
      return;
    }

    final result = await Get.to<UserAddress?>(
      () => AddEditAddressScreen(address: address),
    );

    if (result == null) return;

    await controller.fetchAddresses();
    // Newly added / just-edited address becomes the active one.
    final saved = controller.addresses
            .firstWhereOrNull((a) => a.id != null && a.id == result.id) ??
        result;
    await controller.selectAddress(saved);
  }

  void _confirmDelete(UserAddress address) {
    showConfirmDeleteDialog(context, () async {
      Navigator.of(context).pop();
      await controller.deleteAddress(address.id ?? '');
    });
  }

  void _onUseAddress() {
    final address = controller.selectedAddress.value;
    if (address == null) {
      commonSnackBar(message: 'Please select an address');
      return;
    }
    widget.onAddressSelected?.call(address);
    Get.back(result: address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fillColor,
      appBar: CommonBackAppBar(
        title: widget.isSelectionMode
            ? AppStrings.chooseDeliveryAddress
            : 'Saved Addresses',
      ),
      body: SafeArea(
        child: Obx(() {
          final response = controller.addressListResponse.value;
          final addresses = controller.addresses;
          // Read the selection HERE, in the Obx builder's tracking scope.
          // `ListView.builder`'s itemBuilder runs later, outside that scope,
          // so a `selectedAddress` read from inside it registers no
          // dependency and taps would never repaint the list.
          final selectedId = controller.selectedAddress.value?.id;

          if (response.status == Status.LOADING && addresses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (response.status == Status.ERROR && addresses.isEmpty) {
            return EmptyStateWidget(
              message: response.message ?? AppStrings.somethingWentWrong,
              actionText: 'Retry',
              actionCallback: () => controller.fetchAddresses(),
            );
          }

          if (addresses.isEmpty) {
            return EmptyStateWidget(
              message: AppStrings.noAddressFound,
              actionText: AppStrings.addAddress,
              actionCallback: () => _openForm(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchAddresses(),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.paddingM,
                SizeConfig.paddingS,
                SizeConfig.paddingM,
                SizeConfig.paddingM,
              ),
              itemCount: addresses.length + 1,
              itemBuilder: (context, index) {
                if (index == addresses.length) return _slotsHint();

                final address = addresses[index];
                return SavedAddressCard(
                  address: address,
                  isSelected: selectedId != null && selectedId == address.id,
                  onTap: () => controller.selectAddress(address),
                  onEdit: () => _openForm(address: address),
                  onDelete: () => _confirmDelete(address),
                );
              },
            ),
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Obx(() {
            final canAdd = controller.canAddMore;
            final hasSelection = controller.selectedAddress.value != null;
            final addButton = CustomBtn(
              onTap: canAdd ? () => _openForm() : null,
              title: AppStrings.addAddress,
              bgColor: AppColors.white,
              borderColor:
                  canAdd ? AppColors.primaryColor : AppColors.borderGray,
              textColor: canAdd ? AppColors.primaryColor : AppColors.greyAF,
            );

            if (!widget.isSelectionMode) return addButton;

            return Row(
              children: [
                Expanded(child: addButton),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: CustomBtn(
                    onTap: hasSelection ? _onUseAddress : null,
                    title: 'Use this address',
                    bgColor: hasSelection
                        ? AppColors.primaryColor
                        : AppColors.grey9B,
                    textColor: AppColors.white,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// "3 of 5 saved" — makes the cap visible before the user hits it.
  Widget _slotsHint() {
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size4),
      child: Center(
        child: CustomText(
          '${controller.addresses.length} of ${AddressController.maxAddressLimit} addresses saved',
          fontSize: SizeConfig.extraSmall,
          color: AppColors.grey7E,
        ),
      ),
    );
  }
}

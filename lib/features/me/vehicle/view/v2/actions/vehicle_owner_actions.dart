import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/add_vehicle/vehicle_catalog_picker_screen.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_contact_form_sheet.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_form_sheet.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Owner-side action handlers for the vehicle "me" dashboard, factored
/// out of the screen state so every tab (Overview, Vehicles) and the
/// shell FAB can share one implementation. Each function owns its own
/// navigation + dialogs, taking the caller's [BuildContext] + the shared
/// [VehicleController].
class VehicleOwnerActions {
  const VehicleOwnerActions._();

  // ─── Vehicles ──────────────────────────────────────────────────────

  /// Opens the add-vehicle flow. The category implied by the business
  /// (`businessCategoryGlobal`) fixes NEW vs USED so the chooser is skipped.
  /// Starts at the catalog picker (Select Brand → Model → Variant) so the
  /// listing references a catalog `variant_id`; the picker then opens the
  /// detail form pre-filled.
  static Future<void> addVehicle(
    BuildContext context,
    VehicleController ctrl,
  ) async {
    print("businessSubCategoryGlobal---${businessSubCategoryGlobal}");
    final condition =
        businessSubCategoryGlobal == 'Used Vehicle Dealer' ? VehicleCondition.used : VehicleCondition.isNew;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VehicleCatalogPickerScreen(condition: condition),
        fullscreenDialog: true,
      ),
    );
    if (created == true) {
      await ctrl.fetchMyVehicles(showProgress: false);
    }
  }

  static Future<void> editVehicle(
    BuildContext context,
    VehicleController ctrl,
    Vehicle v,
  ) async {
    final result = await Navigator.of(context).push<VehicleFormResult>(
      MaterialPageRoute(
        builder: (_) => VehicleFormSheet(initial: v),
        fullscreenDialog: true,
      ),
    );
    if (result == null || v.id == null) return;
    await ctrl.updateVehicle(id: v.id!, patch: result.draft.toCreateJson());
    if (result.coverFile != null) {
      final coverUrl = await ctrl.uploadFile(result.coverFile!);
      if (coverUrl != null) {
        await ctrl.updateVehicle(id: v.id!, patch: {'cover_image': coverUrl});
      }
    }
    if (result.imageFiles.isNotEmpty) {
      await ctrl.addVehicleImagesFromFiles(id: v.id!, files: result.imageFiles);
    }
  }

  static Future<void> confirmDeleteVehicle(
    BuildContext context,
    VehicleController ctrl,
    Vehicle v,
  ) async {
    final ok = await _confirm(
      context,
      title: AppStrings.deleteVehicleTitle.tr,
      message: AppStrings.removeNameCannotUndo.trParams({'N': v.name}),
      confirmLabel: AppStrings.delete.tr,
    );
    if (ok && v.id != null) await ctrl.deleteVehicle(v.id!);
  }

  // ─── Gallery ───────────────────────────────────────────────────────

  static Future<void> addGalleryPhoto(VehicleController ctrl) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      await ctrl.addGalleryFromFile(File(picked.path));
    } catch (_) {
      // Controller surfaces upload failures itself; swallow picker errors.
    }
  }

  static Future<void> confirmDeleteGalleryItem(
    BuildContext context,
    VehicleController ctrl,
    VehicleGalleryItem g,
  ) async {
    if (g.id == null) return;
    final ok = await _confirm(
      context,
      title: AppStrings.removePhotoTitle.tr,
      message: AppStrings.removePhotoConfirm.tr,
      confirmLabel: AppStrings.remove.tr,
    );
    if (ok) await ctrl.deleteGalleryItem(g.id!);
  }

  // ─── Contacts ──────────────────────────────────────────────────────

  static Future<void> addContact(
    BuildContext context,
    VehicleController ctrl,
  ) async {
    final draft = await Navigator.of(context).push<VehicleContact>(
      MaterialPageRoute(builder: (_) => const VehicleContactFormSheet()),
    );
    if (draft == null) return;
    await ctrl.addContact(draft);
  }

  static Future<void> editContact(
    BuildContext context,
    VehicleController ctrl,
    VehicleContact c,
  ) async {
    final patched = await Navigator.of(context).push<VehicleContact>(
      MaterialPageRoute(
        builder: (_) => VehicleContactFormSheet(initial: c),
        fullscreenDialog: true,
      ),
    );
    if (patched == null || c.id == null) return;
    await ctrl.updateContact(id: c.id!, patch: patched.toCreateJson());
  }

  static Future<void> confirmDeleteContact(
    BuildContext context,
    VehicleController ctrl,
    VehicleContact c,
  ) async {
    if (c.id == null) return;
    final ok = await _confirm(
      context,
      title: AppStrings.removeContactTitle.tr,
      message: AppStrings.removeNameCannotUndo.trParams({
        'N': c.locationName.isNotEmpty ? c.locationName : AppStrings.thisContactFallback.tr,
      }),
      confirmLabel: AppStrings.remove.tr,
    );
    if (ok) await ctrl.deleteContact(c.id!);
  }

  // ─── Shared confirm dialog ─────────────────────────────────────────

  /// Common delete-confirmation dialog shared with the school service
  /// ([showCommonDialog]). Bridged to a [Future] so the existing
  /// callers keep their `await _confirm(...)` flow.
  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    final completer = Completer<bool>();
    showCommonDialog(
      context: context,
      header: title,
      text: message,
      confirmText: confirmLabel,
      cancelText: AppStrings.cancel.tr,
      confirmCallback: () {
        Navigator.of(context).pop();
        if (!completer.isCompleted) completer.complete(true);
      },
      cancelCallback: () {
        Navigator.of(context).pop();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    return completer.future;
  }
}

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// GetX provider for the rental property-enquiry flow — the rental
/// counterpart of the self-profession `DiscoverController` enquiry methods.
/// Kept as its own controller so it is safe to `getOrPut` from anywhere
/// (the rental Discover card and the in-chat card) without instantiating the
/// heavier [PropertyDiscoverController]. See
/// docs/backend/property-enquiry-flutter-integration.md.
class PropertyEnquiryController extends GetxController {
  /// Backend property-enquiry endpoints are live (see
  /// docs/backend/property-enquiry-frontend-integration-guide.md), so the
  /// real API is used. Set back to `true` only to exercise the UI offline.
  static const bool _useStub = false;

  final RxBool isSubmitting = false.obs;

  /// Raise a property enquiry. [selections] is the grouped checkbox map
  /// (purpose / requirements / intendedUse / timeline → values); only
  /// non-empty arrays are sent. Returns true on HTTP 2xx (treat 201 as
  /// success — the backend does not return a conversationId).
  Future<bool> submitPropertyEnquiry({
    required String propertyId,
    required Map<String, List<String>> selections,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    try {
      isSubmitting.value = true;
      AppLoader.show();

      if (_useStub) {
        await Future.delayed(const Duration(milliseconds: 600));
        return true;
      }

      // Only non-empty arrays + a non-empty note are sent, mirroring the
      // server-side "at least one selection or a note" gating.
      final body = <String, dynamic>{
        ApiKeys.property_id: propertyId,
        ...selections,
        if (note.trim().isNotEmpty) ApiKeys.note: note.trim(),
      };
      final response = await PropertyRepo()
          .sendPropertyEnquiry(params: body, photoPaths: photoPaths);
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Owner accepts / declines a property enquiry from the in-chat card.
  /// [status] is 'accepted' or 'declined'. Returns true on success.
  Future<bool> updatePropertyEnquiryStatus({
    required String enquiryId,
    required String status,
  }) async {
    if (_useStub) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    try {
      final response = await PropertyRepo().updatePropertyEnquiryStatus(
        enquiryId: enquiryId,
        params: {ApiKeys.status: status},
      );
      // 409 = the opposite decision was already made; the socket event has
      // already flipped the card, so treat it as success (idempotent) rather
      // than surfacing an error. See the integration guide §9.
      if (response.statusCode == 409) return true;
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }
}

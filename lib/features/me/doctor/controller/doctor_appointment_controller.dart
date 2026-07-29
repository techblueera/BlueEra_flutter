import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_appointment_model.dart';
import 'package:BlueEra/features/me/doctor/repo/doctor_appointment_repo.dart';
import 'package:get/get.dart';

/// Backs the doctor dashboard's Booking tab —
/// `GET /doctor-appointments/owner/me` with status filter + infinite scroll.
class DoctorAppointmentController extends GetxController {
  final DoctorAppointmentRepo _repo = DoctorAppointmentRepo();

  static const int _pageSize = 20;

  final RxList<DoctorAppointment> appointments = <DoctorAppointment>[].obs;

  /// Empty string = the "All" chip.
  final RxString statusFilter = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString loadError = ''.obs;

  /// Ids currently mid accept/decline, so only that card's button spins.
  final RxSet<String> updatingIds = <String>{}.obs;

  int _page = 1;
  DoctorPagination _pagination = const DoctorPagination();

  bool get hasMore => _pagination.hasMore;

  @override
  void onInit() {
    super.onInit();
    fetchAppointments();
  }

  /// Switches the status chip and reloads. No-op when already selected, so
  /// re-tapping a chip doesn't refire the request.
  Future<void> setStatusFilter(String status) async {
    if (statusFilter.value == status) return;
    statusFilter.value = status;
    await fetchAppointments();
  }

  /// Loads page 1, replacing the list. Used by first paint, filter changes
  /// and pull-to-refresh.
  Future<void> fetchAppointments() async {
    isLoading.value = true;
    loadError.value = '';
    _page = 1;
    try {
      final response = await _repo.getOwnerAppointments(
        status: statusFilter.value,
        page: _page,
        limit: _pageSize,
      );
      if (!response.isSuccess) {
        loadError.value = response.message?.toString() ??
            AppStrings.somethingWentWrong.tr;
        return;
      }
      appointments.assignAll(DoctorAppointment.listFrom(response.data));
      _pagination = DoctorPagination.fromJson(
        response.getExtraData('pagination') is Map
            ? Map<String, dynamic>.from(response.getExtraData('pagination'))
            : null,
      );
    } on Exception catch (e) {
      loadError.value = '${AppStrings.errorFetchingData.tr}: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Appends the next page. Guarded so hitting the scroll boundary twice
  /// cannot double-fire.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    try {
      final next = _page + 1;
      final response = await _repo.getOwnerAppointments(
        status: statusFilter.value,
        page: next,
        limit: _pageSize,
      );
      if (!response.isSuccess) return;
      appointments.addAll(DoctorAppointment.listFrom(response.data));
      _page = next;
      _pagination = DoctorPagination.fromJson(
        response.getExtraData('pagination') is Map
            ? Map<String, dynamic>.from(response.getExtraData('pagination'))
            : null,
      );
    } on Exception {
      // Silent — the already-loaded page stays on screen and the user can
      // scroll again to retry.
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Accept / decline. Updates that one card in place rather than reloading
  /// the list.
  ///
  /// A 409 means the other party already resolved it — the guide's rule is to
  /// refresh rather than retry.
  Future<void> updateStatus({
    required String appointmentId,
    required String status,
  }) async {
    if (updatingIds.contains(appointmentId)) return;
    updatingIds.add(appointmentId);
    try {
      final response = await _repo.updateStatus(
        appointmentId: appointmentId,
        status: status,
      );
      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message?.toString() ??
              AppStrings.somethingWentWrong.tr,
        );
        if (response.response?.statusCode == 409) {
          await fetchAppointments();
        }
        return;
      }
      final index = appointments.indexWhere((a) => a.id == appointmentId);
      if (index >= 0) {
        appointments[index] = appointments[index].copyWithStatus(status);
      }
      commonSnackBar(
        message: response.message?.toString() ?? AppStrings.successful.tr,
      );
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      updatingIds.remove(appointmentId);
    }
  }

  Future<void> accept(String appointmentId) => updateStatus(
        appointmentId: appointmentId,
        status: DoctorAppointmentStatus.accepted,
      );

  Future<void> decline(String appointmentId) => updateStatus(
        appointmentId: appointmentId,
        status: DoctorAppointmentStatus.declined,
      );
}

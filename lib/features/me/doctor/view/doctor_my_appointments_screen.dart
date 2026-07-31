import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/doctor/controller/doctor_booking_controller.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_appointment_model.dart';
import 'package:BlueEra/features/me/doctor/widget/doctor_appointment_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The customer's own doctor-appointment requests
/// (`GET hospital-service/doctor-appointments/me`), with Cancel.
///
/// Counterpart to the doctor's Booking tab: same model and card, opposite
/// permissions. Before this screen existed a customer who booked had no way to
/// see the request again, let alone cancel it — `getMyAppointments()` had zero
/// callers (guide §3.4).
class DoctorMyAppointmentsScreen extends StatefulWidget {
  const DoctorMyAppointmentsScreen({super.key});

  @override
  State<DoctorMyAppointmentsScreen> createState() =>
      _DoctorMyAppointmentsScreenState();
}

class _DoctorMyAppointmentsScreenState
    extends State<DoctorMyAppointmentsScreen> {
  late final DoctorBookingController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = getOrPut(() => DoctorBookingController());
    // Always refetch on open: the doctor may have accepted or declined since
    // the list was last built, and a stale "pending" would offer a Cancel that
    // the server then rejects.
    _controller.fetchMyAppointments();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Cancelling is irreversible — `cancelled` is terminal server-side, so a
  /// mis-tap cannot be undone by re-booking the same request.
  Future<void> _confirmCancel(DoctorAppointment appointment) async {
    final id = appointment.id ?? '';
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(
          AppStrings.doctorCancelConfirmTitle.tr,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        content: CustomText(
          AppStrings.doctorCancelConfirmBody.tr,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: CustomText(
              AppStrings.doctorKeepIt.tr,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: CustomText(
              AppStrings.doctorCancelAppointment.tr,
              color: const Color(0xFFEA4335),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _controller.cancel(id);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: AppColors.skyE7,
      appBar: CommonBackAppBar(title: AppStrings.doctorMyAppointments.tr),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.myAppointments.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        if (_controller.loadError.value.isNotEmpty &&
            _controller.myAppointments.isEmpty) {
          return _errorState();
        }
        if (_controller.myAppointments.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: _controller.fetchMyAppointments,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: SizeConfig.size100),
                _emptyState(),
              ],
            ),
          );
        }

        // Read inside the Obx body, not in `itemBuilder` — the builder runs
        // lazily outside the reactive scope, so a read there would never
        // subscribe and the footer spinner would never update.
        final isLoadingMore = _controller.isLoadingMore.value;
        final updating = _controller.updatingIds;
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: _controller.fetchMyAppointments,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size12,
              horizontal: SizeConfig.size12,
            ),
            itemCount: _controller.myAppointments.length + 1,
            itemBuilder: (context, index) {
              if (index == _controller.myAppointments.length) {
                return isLoadingMore
                    ? Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: SizeConfig.size12),
                        child: const Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(height: SizeConfig.size20);
              }
              final appointment = _controller.myAppointments[index];
              return DoctorAppointmentCard(
                appointment: appointment,
                isUpdating: updating.contains(appointment.id ?? ''),
                // Customer view: no Accept / Decline (the server answers 403),
                // Cancel instead — allowed while pending AND accepted.
                onCancel: () => _confirmCancel(appointment),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _emptyState() => Column(
        children: [
          Icon(Icons.event_note_outlined, size: 56, color: Colors.grey[300]),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            AppStrings.doctorNoMyAppointments.tr,
            color: AppColors.secondaryTextColor,
            fontSize: SizeConfig.medium,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      );

  Widget _errorState() => Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 42, color: Colors.grey[400]),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              _controller.loadError.value,
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            SizedBox(height: SizeConfig.size12),
            OutlinedButton(
              onPressed: _controller.fetchMyAppointments,
              child: CustomText(
                AppStrings.retry.tr,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

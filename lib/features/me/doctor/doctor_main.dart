import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/doctor/view/v2/doctor_home_screen_v2.dart';
import 'package:flutter/material.dart';

/// Module entry for a STANDALONE DOCTOR business account
/// (Healthcare → DOCTORS / CLINICS).
///
/// Mirrors `HospitalMain` / `OthersMain`: a thin shell the bottom-nav "Me"
/// tab resolves to, so the routing switch stays a one-line mapping.
///
/// This is deliberately separate from `HospitalMain`. A standalone doctor is
/// an independent business — own listing, own profile
/// (`hospital-service/doctors`), own appointments
/// (`hospital-service/doctor-appointments`) — whereas a hospital OPD doctor is
/// a record inside a hospital. Nothing under `lib/features/me/hospital/` is
/// affected by this module.
class DoctorMain extends StatelessWidget {
  const DoctorMain({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: const DoctorHomeScreenV2(),
    );
  }
}

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/doctor/view/about/doctor_about_me_form.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Routable wrapper around [DoctorAboutMeForm].
///
/// The dashboard's About tab embeds the form directly — the design keeps the
/// tab bar visible while editing, so it must not push a route. This wrapper
/// exists only for entries from OUTSIDE the dashboard, where there is no tab
/// to embed into: today that is the certificates screen, which routes here on
/// `404 "Create your doctor profile before adding certificates"`.
class DoctorAboutMeEditScreen extends StatelessWidget {
  const DoctorAboutMeEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),
      appBar: CommonBackAppBar(title: AppStrings.doctorAboutMe.tr),
      body: SingleChildScrollView(
        // This route has an app-bar back arrow already, but the inline Back
        // button keeps the two entry points behaving identically — and it is
        // the one that warns about unsaved changes.
        child: DoctorAboutMeForm(
          onSaved: () => Get.back(),
          onCancel: () => Get.back(),
        ),
      ),
    );
  }
}

import 'package:BlueEra/core/api/model/service_option_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/me_menu_card_design.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_controller.dart';
import 'package:BlueEra/features/me/school/view/category/about_school/school_about_us.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/school_academics_page.dart';
import 'package:BlueEra/features/me/school/view/category/campus_life/campus_life_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/career_jobs/school_job_listing_screen.dart';
import 'package:BlueEra/features/me/school/view/category/notice_news/notice_news_screen.dart';
import 'package:BlueEra/features/me/school/view/category/school_contact_us/school_contact_us.dart';
import 'package:BlueEra/features/me/school/view/category/school_student_corner.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(

      child: Center(child: CustomText("Coming soon...")),
    );
  }
}

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/job_seekar/controller/job_seeker_portfolio_professionals_controller.dart';
import 'package:BlueEra/features/me/job_seekar/view/project_portfolio/job_seeker_portfolio_form_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_project_card_widget.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerPortfolioScreen extends StatelessWidget {
  JobSeekerPortfolioScreen({super.key});

  // final aiController = Get.find<AiProfessionalsController>();
  final portfolioController =
      Get.put(JobSeekerPortfolioProfessionalsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.portfolioProjects.tr),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0, top: 10),
          child: AddMoreIconButton(
            onTapEvent: () {
              portfolioController.openForCreate();
              Get.to(() => JobSeekerPortfolioFormScreen());
            },
          ),
        ),
      ),
      body: Obx(() {
        if (portfolioController.certificates.isNotEmpty) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return JobSeekerPortfolioProjectCardWidget(
                project: ProfessionalPortfolio(
                  id: portfolioController.certificates[index].id,
                    projectImage:  portfolioController.certificates[index].projectImage,
                    projectTitle: portfolioController.certificates[index].title,
                    category: portfolioController.certificates[index].category,
                    description:
                        portfolioController.certificates[index].description,
                    completionDate:
                        portfolioController.certificates[index].completionDate,),
              isDateFormateReq: false,);
            },
            itemCount: portfolioController.certificates.length,
          );
        }
        return Center(child: CustomText(AppStrings.noDataFound.tr));
      }),
    );
  }
}

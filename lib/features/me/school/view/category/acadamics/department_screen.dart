import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/category/acadamics/add_more_department_screen.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/features/me/school/view/widget/department_card_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DepartmentScreen extends StatelessWidget {
  const DepartmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Departments",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return DepartmentCard();
                  }),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size5, vertical: SizeConfig.size10),
              child: AddMoreIconButton(
                onTapEvent: () {
                  Get.to(AddMoreDepartmentScreen());
                },
                buttonName: "Add More Department",
              ),
            ),
            SizedBox(
              height: SizeConfig.size16,
            )
          ],
        ),
      ),
    );
  }
}

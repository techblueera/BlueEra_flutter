import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/school/view/category/school_gallery/add_school_photos.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../widgets/custom_text_cm.dart';
import '../../../../medical/view/widget/otc_items.dart';

class SchoolGallery extends StatefulWidget {
  const SchoolGallery({super.key});

  @override
  State<SchoolGallery> createState() => _SchoolGalleryState();
}

class _SchoolGalleryState extends State<SchoolGallery> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Gallery",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: CategoryListView()),
            SizedBox(height: SizeConfig.size14),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: AddMoreIconButton(
                onTapEvent: () {
                  Get.to(AddSchoolPhotos());
                },
                buttonName: "Add More Photo",
              ),
            ),
            SizedBox(height: SizeConfig.size30),
          ],
        ),
      ),
    );
  }
}

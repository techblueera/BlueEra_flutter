import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/notice_news_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/school/controller/notice_news_controller.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoticeNewsScreen extends StatefulWidget {
  const NoticeNewsScreen({super.key});

  @override
  State<NoticeNewsScreen> createState() => _NoticeNewsScreenState();
}

class _NoticeNewsScreenState extends State<NoticeNewsScreen> {
  final noticeController = Get.put(NoticeController());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    noticeController.getSchoolNoticeNewsController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Notice & News",
      ),
      body: Obx(() {
        if (noticeController.getNoticeNewsResponse.value.status ==
            Status.ERROR) {
          return CustomText(AppStrings.somethingWentWrong);
        }
        if (noticeController.getNoticeNewsResponse.value.status ==
            Status.COMPLETE) {
          if (noticeController.noticeNewsDataList.isNotEmpty) {
            return ListView.builder(
              itemBuilder: (context, index) {
                NoticeNewsData data =
                    noticeController.noticeNewsDataList[index];
                return Column(
                  children: [
                    CustomText(data.title),
                    CustomText("Delete"),
                    CustomText("Edit"),
                  ],
                );
              },
              itemCount: noticeController.noticeNewsDataList.length,
            );
          }
          return CustomText("No Data Notice & News Found");
        }
        return SizedBox();
      }),
    );
  }
}

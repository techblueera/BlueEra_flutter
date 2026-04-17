import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/controller/chat_view_controller.dart';
import '../widget/common_subtab_widget.dart';
import '../widget/contact_by_service_tile_widget.dart';

class ProfessionalsMain extends StatefulWidget {
  const ProfessionalsMain({super.key,});



  @override
  State<ProfessionalsMain> createState() => _ProfessionalsMainState();
}

class _ProfessionalsMainState extends State<ProfessionalsMain> {
  final chatViewController = Get.find<ChatViewController>();

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((val){
      chatViewController.selectedIndex.value=0;
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Obx(() {
        return Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SizeConfig.size10,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for(int i=0;i<professionalContactCategories.length;i++ )
                    CommonSubTabWidget(
                      selectedIndex: chatViewController.selectedIndex
                          .value,
                      index: i,
                      title: professionalContactCategories[i].name,
                      icon:professionalContactCategories[i].icon,
                      onTap: () async{
                        chatViewController.selectedIndex.value = i;
                        await chatViewController.findServiceByContacts(
                            professionalContactCategories[i].slugId, null);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size10,),
            FindContactByServiceListWidget(
              chatViewController: chatViewController,
              theme: theme,
            )

          ],
        );
    }));
  }
}

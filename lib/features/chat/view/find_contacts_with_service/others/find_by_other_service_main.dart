import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:get/get.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../widget/common_subtab_widget.dart';
import '../widget/contact_by_service_tile_widget.dart';

class FindByOtherService extends StatefulWidget {
  const FindByOtherService({super.key,});



  @override
  State<FindByOtherService> createState() => _FindByOtherServiceState();
}

class _FindByOtherServiceState extends State<FindByOtherService> {
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

    return Obx(() {
      return Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size10,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for(int i=0;i<othersContactCategories.length;i++ )
                    CommonSubTabWidget(
                      selectedIndex: chatViewController.selectedIndex
                          .value,
                      index: i,
                      title: othersContactCategories[i].name,
                      icon:othersContactCategories[i].icon,
                      onTap: () async{
                        chatViewController.selectedIndex.value = i;
                        await chatViewController.findServiceByContacts(
                            othersContactCategories[i].slugId, null);
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
    });
  }
}

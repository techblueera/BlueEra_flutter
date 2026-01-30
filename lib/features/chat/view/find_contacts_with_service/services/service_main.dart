import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../widget/common_subtab_widget.dart';
import '../widget/contact_by_service_tile_widget.dart';

class ServiceMain extends StatefulWidget {
  const ServiceMain({super.key});

  @override
  State<ServiceMain> createState() => _ServiceMainState();
}

class _ServiceMainState extends State<ServiceMain> {
  final chatViewController = Get.find<ChatViewController>();
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((val){
      chatViewController.selectedIndex.value=0;
    });
}
  @override
  Widget build(BuildContext context) {
    //serviceContactCategories
    final theme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size10,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() {
              return Row(
                children: [

                  for(int i = 0; i < serviceContactCategories.length; i++ )
                    CommonSubTabWidget(
                      selectedIndex: chatViewController.selectedIndex
                          .value,
                      index: i,
                      title: serviceContactCategories[i].name,
                      icon: serviceContactCategories[i].icon,
                      onTap: () async {
                        chatViewController.selectedIndex.value = i;
                        await chatViewController.findServiceByContacts(
                            serviceContactCategories[i].slugId, null);
                      },
                    ),
                ],
              );
            }),
          ),
        ),
        SizedBox(height: SizeConfig.size10,),
        FindContactByServiceListWidget(
          chatViewController: chatViewController,
          theme: theme,
        )
      ],
    );
  }
}

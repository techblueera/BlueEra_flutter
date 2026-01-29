import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_constant.dart';
import '../../../auth/controller/chat_view_controller.dart';

import '../widget/common_subtab_widget.dart';
import '../widget/contact_by_service_tile_widget.dart';
class ShoppingMain extends StatefulWidget {
  const ShoppingMain({super.key});

  @override
  State<ShoppingMain> createState() => _ShoppingMainState();
}

class _ShoppingMainState extends State<ShoppingMain> {
  final chatViewController = Get.find<ChatViewController>();



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

                  for(int i=0;i<fashionContactCategories.length;i++ )
                    CommonSubTabWidget(
                      selectedIndex: chatViewController.selectedIndex
                          .value,
                      index: i,
                      title: fashionContactCategories[i].name,
                      icon:fashionContactCategories[i].icon,
                      onTap: () async{
                        chatViewController.selectedIndex.value = i;
                        await chatViewController.findServiceByContacts(
                            fashionContactCategories[i].slugId, null);
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

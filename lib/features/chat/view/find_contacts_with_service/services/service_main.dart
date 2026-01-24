import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/constants/app_constant.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../widget/component_widgets.dart';
class ServiceMain extends StatefulWidget {
  const ServiceMain({super.key});

  @override
  State<ServiceMain> createState() => _ServiceMainState();
}

class _ServiceMainState extends State<ServiceMain> {
  final chatViewController = Get.find<ChatViewController>();

  List<String> content=[
    "Education & Training",
    "Beauty & Personal Care",
    "Tour, Travel & Tourism",
    "Service Centre & Essential Utility",
  ];
  int selectedSubTab=0;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size10,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // for(int i=0;i<content.length;i++)
                //   CommonSubTabWidget(
                //     index: i,
                //     selectedIndex: selectedSubTab,
                //     title: content[i],
                //     onTap: () {
                //       setState(() {
                //         selectedSubTab = i;
                //       });
                //     },
                //   )


              ],
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size10,),
        Expanded(
          child: Container(

            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20))
                ,
                color: AppColors.white
            ),
            padding: EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              itemCount: 1, // ADD 1 EXTRA ITEM
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final chat =
                    ChatViewController.personalAiChatModule
                ;
                return ChatListTile(
                  onTab:
                  null,
                  onSelect: () {

                  },
                  type: chat?.sender?.accountType ?? AppConstants.individual,
                  index: index - 1, // correct index for chat list
                  chatViewController: chatViewController,
                  chat: chat,
                  theme: theme,
                  context: context,
                  isForwardUI: null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

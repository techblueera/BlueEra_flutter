
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import '../../../../core/constants/size_config.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../widget/component_widgets.dart';
import 'order_chat_screen.dart';

class OrdersTabView extends StatefulWidget {
  @override
  State<OrdersTabView> createState() => _OrdersTabViewState();
}

class _OrdersTabViewState extends State<OrdersTabView> {

  List<String> get filters => ['filter', AppStrings.allTab.tr, AppStrings.productLabel.tr, AppStrings.serviceLabel.tr, AppStrings.foodLabel.tr];

  String seletecValue = "";
  final chatViewController = Get.find<ChatViewController>();

  @override
  Widget build(BuildContext context) {
    if (seletecValue.isEmpty) seletecValue = AppStrings.allTab.tr;
    final theme = Theme.of(context);
    // Obx(() {

      return Obx(() {
        if(chatViewController.orderChatListResponse.value.status ==
            Status.COMPLETE){
          GetChatListModel? data =
              chatViewController.getOrderChatListModel?.value;
          return RefreshIndicator(
            onRefresh: () async {
              chatViewController.emitEvent(
                  ChatEmitEvents.ChatList, {ApiKeys.type: "order"});
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: filters.map((filter) {
                      final isSelected = filter == seletecValue;
                      return (filter == "filter") ?
                      PopupMenuButton<String>(
                        padding: EdgeInsets.only(top: 18),
                        offset: const Offset(-6, 36),
                        color: AppColors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        onSelected: (value) {},
                        icon: SvgPicture.asset(AppIconAssets.mage_filter),
                        itemBuilder: (context) => PopupMenuBuilders.popupMenuOrderTabItems(),
                      ) : Padding(
                        padding: EdgeInsets.only(right: 8, top: 18),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              seletecValue = filter;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.buttonLiteBlue
                                    : Colors.white,
                                border: isSelected ? null : Border.all(
                                    color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10)
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: filter == "All" ? 13 : 8,
                                vertical: 5),
                            child: CustomText(
                              filter,
                              color: isSelected ? Colors.black : AppColors
                                  .optionShowGray,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10),
                // Orders List
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: SizeConfig.size70),
                    child: (data?.chatList?.isEmpty ?? true)
                        ? noChatsFound()
                        : ListView.builder(
                      itemCount: data?.chatList?.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final chat = data?.chatList?[index];
                        final isInSelectionMode = chatViewController
                            .isChatListSelectionMode.value;
                        final isChatSelected = chatViewController
                            .selectedConversationIds
                            .contains(chat?.conversationId ?? '');

                        return ChatListTile(
                          onTab: () {
                            if (isInSelectionMode) {
                              chatViewController.toggleChatListSelection(chat);
                              setState(() {});
                              return;
                            }
                            Navigator.push(
                                context, MaterialPageRoute(builder: (context) =>
                                OrderChatScreen(
                                  name: chat?.sender?.name ?? '',
                                  contactNo: chat?.sender?.contactNo ?? '',
                                  conversationId: chat?.conversationId ?? '',
                                  type: chat?.sender?.accountType ?? '',
                                  userId: chat?.sender?.id ?? '',
                                  profileImage:
                                      chat?.sender?.profileImage ?? '',
                                  designation: chat?.sender?.designation ?? '',
                                )));
                          },
                          onLongPress: () {
                            if (!isInSelectionMode) {
                              chatViewController
                                  .isChatListSelectionMode.value = true;
                              chatViewController
                                  .toggleChatListSelection(chat);
                              setState(() {});
                            }
                          },
                          isChatListSelected: isChatSelected,
                          onSelect: () {
                            setState(() {});
                          },
                          type: chat?.sender?.accountType ??
                              AppConstants.individual,
                          index: index,
                          chatViewController: chatViewController,
                          chat: chat,
                          theme: theme,
                          isForwardUI: false,
                          context: context,
                          showNewBadgeIfRecent: true,
                          showFlagBadge: true,
                        );
                      },
                    ),
                  ),
                )
                // Expanded(
                //   child: ListView.builder(
                //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                //     itemCount: orders.length,
                //     itemBuilder: (context, index) {
                //       final order = orders[index];
                //       return InkWell(
                //         onTap: (){
                //           Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderChatScreen()));
                //         },
                //         child: Container(
                //           margin: EdgeInsets.only(bottom: 22),
                //           child: Row(
                //             children: [
                //               CircleAvatar(
                //                 backgroundColor: Colors.blue,
                //                 radius: 22,
                //                 child: CustomText(
                //                     'BE',
                //                     color: Colors.white, fontWeight: FontWeight.bold
                //                 ),
                //               ),
                //               SizedBox(width: 12),
                //               Expanded(
                //                 child: Column(
                //                   crossAxisAlignment: CrossAxisAlignment.start,
                //                   children: [
                //                     CustomText(
                //                       order['title'],
                //                           fontSize: 16,
                //                         fontWeight: FontWeight.bold
                //
                //                     ),
                //                     SizedBox(height: 4),
                //                     CustomText(
                //                       order['subtitle'],
                //                           color: Colors.grey.shade600, fontSize: 14,
                //                       overflow: TextOverflow.ellipsis,
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //               Column(
                //                 crossAxisAlignment: CrossAxisAlignment.end,
                //                 children: [
                //                   CustomText(
                //                     order['time'],
                //                         fontSize: 11,
                //                       color: Colors.grey
                //                   ),
                //                   SizedBox(height: 4),
                //                   Container(
                //                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                //                     decoration: BoxDecoration(
                //                       color: Colors.transparent,
                //                       border: Border.all(color: order['statusColor']),
                //                       borderRadius: BorderRadius.circular(20),
                //                     ),
                //                     child: CustomText(
                //                       order['status'],
                //                         color: order['statusColor'],
                //                         fontSize: 11,
                //                         fontWeight: FontWeight.w500,
                //                     ),
                //                   )
                //                 ],
                //               ),
                //             ],
                //           ),
                //         ),
                //       );
                //     },
                //   ),
                // ),
              ],
            ),
          );
        }else{
          return SizedBox();
        }

      });

    // });

  }
}
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
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
  final List<Map<String, dynamic>> orders = [
    {
      'title': "McDonald’s",
      'subtitle': "Pizza, Burger, French Fries, 1 L bottle of Cold Drink...",
      'time': "9:52 PM",
      'status': "Active",
      'statusColor': Colors.green,
      'logo': 'assets/mcd.png',
    },
    {
      'title': "Pizza Hut",
      'subtitle': "Pizza, Burger, French Fries, 1 L bottle of Cold Drink...",
      'time': "9:52 PM",
      'status': "Cancelled",
      'statusColor': Colors.red,
      'logo': 'assets/pizza.png',
    },
    {
      'title': "Dominos",
      'subtitle': "Pizza, Burger, French Fries, 1 L bottle of Cold Drink...",
      'time': "9:52 PM",
      'status': "Completed",
      'statusColor': Colors.grey,
      'logo': 'assets/dominos.png',
    },
  ];

  final List<String> filters = ['filter', 'All', 'Product', 'Service', 'Food'];

  String seletecValue = "All";
  final chatViewController = Get.find<ChatViewController>();

  @override
  Widget build(BuildContext context) {
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
                  "ChatList", {ApiKeys.type: "order"});
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
                        itemBuilder: (context) => popupMenuOrderTabItems(),
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
                        return ChatListTile(
                          onTab: () {
                            Navigator.push(
                                context, MaterialPageRoute(builder: (context) =>
                                OrderChatScreen(
                                  name: data?.chatList?[index]?.sender?.name ??
                                      '',
                                  contactNo: data?.chatList?[index]?.sender
                                      ?.contactNo ?? '',
                                  conversationId: data?.chatList?[index]
                                      ?.conversationId ?? '',
                                  type: data?.chatList?[index]?.sender
                                      ?.accountType ?? '',
                                  userId: data?.chatList?[index]?.sender?.id ?? ''
                                  ,
                                  profileImage: data?.chatList?[index]?.sender
                                      ?.profileImage ?? '',
                                )));
                          },
                          onSelect: () {
                            setState(() {});
                          },
                          type: data?.chatList?[index]?.sender?.accountType ??
                              AppConstants.individual,
                          index: index,
                          chatViewController: chatViewController,
                          chat: data?.chatList?[index],
                          theme: theme,
                          isForwardUI: false,
                          context: context,
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
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get.dart';
//
// import '../../../../core/api/apiService/api_keys.dart';
// import '../../../../core/constants/app_icon_assets.dart';
// import '../../auth/controller/chat_theme_controller.dart';
// import '../../auth/controller/chat_view_controller.dart';
// import '../../auth/model/GetListOfMessageData.dart';
// import '../business_chat/business_chat_list.dart';
// import '../orders_chat/orders_chat_list.dart';
// import '../personal_chat/personal_chat_list.dart';
// class ForwardListPage extends StatefulWidget {
//   const ForwardListPage({super.key, required this.forwardId, required this.message});
//   final String forwardId;
//   final Messages? message;
//
//   @override
//   State<ForwardListPage> createState() => _ForwardListPageState();
// }
//
//
// class _ForwardListPageState extends State<ForwardListPage>     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//
//
//   final chatViewController = Get.find<ChatViewController>();
//   final chatThemeController = Get.find<ChatThemeController>();
//
//   @override
//   void initState() {
//
//     chatViewController.selectedUserIds.clear();
//     _tabController = TabController(length: 3, vsync: this);
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonBackAppBar(
//         title: "Forward to",
//       ),
//       body: SafeArea(
//         child: Stack(
//           children: [
//            Column(
//              children: [
//                TabBar(onTap: (index){
//
//                },
//                  indicatorSize: TabBarIndicatorSize.tab,
//                  dividerHeight: 0,
//                  dividerColor: Colors.transparent,
//                  controller: _tabController,
//                  labelColor: Colors.black,
//                  unselectedLabelColor: Colors.black54,
//                  indicatorColor: Colors.lightBlue,
//                  labelPadding: EdgeInsets.all(0),
//                  physics: NeverScrollableScrollPhysics(),
//                  indicatorPadding:
//                  EdgeInsets.only(left: 0, right: 2, bottom: 0, top: 0),
//                  labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                  tabs: [
//                    Tab(
//                      text: "Personal",
//                    ),
//                    Tab(text: "Business"),
//                    Tab(text: "Orders"),
//                  ],
//                ),
//                Divider(height: 1, color: Colors.blue[50]),
//                Expanded(
//                  child: TabBarView(controller: _tabController, children: [
//                    PersonalChatsList(isForwardUI: true,),
//                    BusinessChatsList(),
//                    OrdersTabView()
//                  ]),
//                ),
//              ],
//            ),
//             Positioned(
//                 right: 30,
//                 bottom: 28,
//                 child: InkWell(
//                   onTap: ()async{
//                     // Map<String,dynamic> data={
//                     //   ApiKeys.forward_to_conversations:chatViewController.selectedUserIds.join(',').toString(),
//                     //   ApiKeys.forward_id:"${widget.forwardId}",
//                     // };
//                     Map<String,dynamic> data={
//                       ApiKeys.forward_id: chatThemeController.selectedId,
//                       ApiKeys.forward_to_conversations: chatViewController.selectedUserIds,
//                       // ApiKeys.additional_message: "${widget.message?.messageType}"
//                       // ApiKeys.additional_message: "${widget.message?.messageType}"
//                     };
//
//                    bool value= await chatViewController.forwardMessageApi(data);
//                    if(value){
//                      chatViewController.emitEvent("ChatList", {
//                        ApiKeys.type:"personal"
//                      });
//                      Navigator.pop(context);
//                      Navigator.pop(context);
//                    }
//
//                   },
//                   child: Container(
//                                 padding: EdgeInsets.all(14),
//                                 decoration: BoxDecoration(
//                     color: chatThemeController.myMessageBgColor.value,
//                     borderRadius: BorderRadius.circular(10)
//                                 ),
//                                 child: Center(
//                   child: Row(
//                     children: [
//                       CustomText("Forward",color: Colors.white,),
//                       const SizedBox(width: 4,),
//                       SvgPicture.asset(height: 18,width: 18,
//                           AppIconAssets.send_message_chat),
//                     ],
//                   ),
//                                 ) ,
//                               ),
//                 ))
//           ],
//         ),
//       ),
//     );
//   }
// }

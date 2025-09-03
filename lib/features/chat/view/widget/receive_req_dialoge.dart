import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/widget/view_req_profile_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatRequestListModel.dart';


class ReceivedRequestsDialog extends StatefulWidget {
  @override
  State<ReceivedRequestsDialog> createState() => _ReceivedRequestsDialogState();
}

class _ReceivedRequestsDialogState extends State<ReceivedRequestsDialog> {

  final chatViewController = Get.find<ChatViewController>();


  @override
  void initState() {
    chatViewController.getChatRequestList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
      return Obx(() {
        if (chatViewController.chatMessageRequestResponse.value.status ==
            Status.COMPLETE) {
          GetChatRequestListModel? data = chatViewController
              .getChatRequestListModel
              ?.value;
          List<Data>? requestDetails = data?.data;
          return Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 20,),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: BoxConstraints(maxHeight: 700),
              child: Column(
                children: [
                  // Title row
                  SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                            "Received Requests",
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                        ),

                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: AppColors.whiteEE
                          ),
                          child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Icon(Icons.close, color: Colors.black,)),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 18),

                  // List of requests
                  (requestDetails?.isEmpty??false)?CustomText("No Record Found"):Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      itemCount: requestDetails?.length ?? 0,
                      separatorBuilder: (_, __) => SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final req = requestDetails?[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: InkWell(
                            onTap: () {
                              showDialog(context: context,
                                  builder: (BuildContext context) {
                                    return ViewReqProfileDialog( requestedBy: req?.requestBy??'',);
                                  });
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:  req?.user?.profileImage !=
                                      null
                                      ? NetworkImage(req?.user?.profileImage??'')
                                      : null,
                                  radius: 22,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        // req.name,
                                        "${requestDetails?[index].user?.name??requestDetails?[index].user?.contactNo}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "Message",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    CustomBtn(
                                        radius: 8,
                                      height: 40,
                                        width: 91,
                                        bgColor: theme.colorScheme.primary,
                                        onTap: (){
                                          Map<String, dynamic> data = {
                                            ApiKeys.action: "accept",
                                            ApiKeys
                                                .request_by: "${requestDetails?[index]
                                                .requestBy}"
                                          };
                                          chatViewController
                                              .acceptOrRejectRequest(data);
                                        }, title: "Accept")
                                    // InkWell(
                                    //     onTap: () {
                                    //       Map<String, dynamic> data = {
                                    //         ApiKeys.action: "accept",
                                    //         ApiKeys
                                    //             .request_by: "${requestDetails?[index]
                                    //             .requestBy}"
                                    //       };
                                    //       chatViewController
                                    //           .acceptOrRejectRequest(data);
                                    //     },
                                    //     child: _circleIcon(
                                    //         Icons.check, Colors.green)),
                                    // SizedBox(width: 6),
                                    // InkWell(
                                    //     onTap: () {
                                    //       Map<String, dynamic> data = {
                                    //         ApiKeys.action: "reject",
                                    //         ApiKeys
                                    //             .request_by: "${requestDetails?[index]
                                    //             .id}"
                                    //       };
                                    //       chatViewController
                                    //           .acceptOrRejectRequest(data);
                                    //     },
                                    //     child: _circleIcon(
                                    //         Icons.clear, Colors.red)),
                                    // SizedBox(width: 6),
                                    // InkWell(
                                    //     onTap: () {
                                    //       Map<String, dynamic> data = {
                                    //         ApiKeys.action: "block",
                                    //         ApiKeys
                                    //             .request_by: "${requestDetails?[index]
                                    //             .id}"
                                    //       };
                                    //       chatViewController
                                    //           .acceptOrRejectRequest(data);
                                    //     },
                                    //     child: _circleIcon(
                                    //         Icons.block, Colors.red.shade300)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }else{
          return Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 20,),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: BoxConstraints(maxHeight: 700),
              child: Column(
                children: [
                  // Title row
                  SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                            "Received Requests",
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                        ),

                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: AppColors.whiteEE
                          ),
                          child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Icon(Icons.close, color: Colors.black,)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 18),

                  // List of requests

                ],
              ),
            ),
          );
        }

      });

  }


}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/getChatRequestProfileDetailsModel.dart';

class ViewReqProfileDialog extends StatefulWidget {
  const ViewReqProfileDialog({super.key, required this.requestedBy});

  final String requestedBy;

  @override
  State<ViewReqProfileDialog> createState() => _ViewReqProfileDialogState();
}

class _ViewReqProfileDialogState extends State<ViewReqProfileDialog> {
  final chatViewController = Get.find<ChatViewController>();

  @override
  void initState() {
    // TODO: implement initState

    Map<String, dynamic> data = {
      ApiKeys.request_by: "${widget.requestedBy}"
    };
    chatViewController.getDetailsChatRequestPerson(data);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (chatViewController.chatMessageRequestResponse.value.status ==
          Status.COMPLETE) {
        GetChatRequestProfileDetailsModel? data = chatViewController
            .getChatRequestProfileDetailsModel
            ?.value;
        Data? requestDetails = data?.data?.first;
        return Dialog(insetPadding: EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                            Icons.close, size: 20, color: Colors.black),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 18.0),
                          child:  CircleAvatar(
                            backgroundImage:  requestDetails?.user?.profileImage !=
                                null
                                ? NetworkImage(requestDetails?.user?.profileImage??'')
                                : null,
                            radius: 40,
                          ),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment
                              .start,
                            children: [
                              Row(mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CustomText(
                                        "${requestDetails?.user?.name}",
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.verified,
                                          color: Color(0xFF0085FF), size: 18),
                                    ],
                                  ),

                                ],
                              ),
                              const SizedBox(height: 2),
                               CustomText(
                                  "${requestDetails?.user?.profession}",
                                  fontSize: 13,
                                  color: Colors.black54
                              ),
                              const SizedBox(height: 12),
                              Row(crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: const [
                                  _StatBlock(count: "0", label: "Posts"),
                                  _StatBlock(count: "0k", label: "Followers"),
                                  _StatBlock(count: "0K", label: "Following"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                   CustomText(
                    "${requestDetails?.user?.designation}",
                        fontSize: 13, color: Colors.black87,
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _DialogButton(
                          text: "Block",
                          color: Colors.transparent,
                          borderColor: Colors.red,
                          textColor: Colors.red),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: (){
                          Map<String, dynamic> data = {
                            ApiKeys.action: "accept",
                            ApiKeys.request_by: "${requestDetails?.requestBy}"
                          };
                          chatViewController
                              .acceptOrRejectRequest(data);
                        },
                        child: _DialogButton(text: "Accept",
                            color: Color(0xFF0085FF),
                            textColor: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      _DialogButton(
                          text: "Decline",
                          color: Colors.transparent,
                          borderColor: Color(0xFF0085FF),
                          textColor: Color(0xFF0085FF)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: CustomText(
                        "Bio",
                        fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text:
                          "",
                          style: TextStyle(fontSize: 13,
                              color: Colors.black87,
                              height: 1.4),
                        ),
                        // const TextSpan(
                        //   text: "Read more",
                        //   style: TextStyle(fontSize: 13,
                        //       color: Colors.blue,
                        //       height: 1.4,
                        //       fontWeight: FontWeight.bold),
                        // ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }else{
        return SizedBox();
      }
    });
  }
}

class _StatBlock extends StatelessWidget {
  final String count;
  final String label;

  const _StatBlock({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black)),
        Text(
            label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  const _DialogButton({
    required this.text,
    required this.color,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        side: borderColor != null
            ? BorderSide(color: borderColor!, width: 1.4)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

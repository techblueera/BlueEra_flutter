import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/view_group_members_model.dart';
import '../../contacts/view/be_available_contacts_list.dart';

class ViewGroupMembers extends StatefulWidget {
  const ViewGroupMembers(
      {required this.conversationId,
      this.profileImage,
      required this.type,
      this.name,
      super.key});

  final String? conversationId;
  final String? profileImage;
  final String? name;
  final String? type;

  @override
  State<ViewGroupMembers> createState() => _ViewGroupMembersState();
}

class _ViewGroupMembersState extends State<ViewGroupMembers> {
  final chatViewController = Get.find<ChatViewController>();
  @override
  void initState() {
    // TODO: implement initState
    Map<String, dynamic> data = {
      ApiKeys.conversation_id: widget.conversationId
    };
    chatViewController.getGroupMembersApi(data);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // appBar: CommonBackAppBar(
      //   title: "Group Members",
      // ),
      body: Obx(() {
        if (chatViewController.getGroupMembersResponse.value.status ==
            Status.COMPLETE) {
          List<GroupMembersListModel> members =
              chatViewController.getGroupMembersResponse.value.data;
            
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 10,left: 10,right: 10),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                spreadRadius: 0.5,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 18,
                            ),
                            InkWell(
                              onTap: (){
                                Navigator.pop(context);
                              },
                              child: Row(
                                children: [
                                  const SizedBox(width: 20,),
                                  Icon(Icons.arrow_back_ios,size: 22,),
                                  const SizedBox(width: 2,),
                                  CustomText("Group Info",
                                    fontSize: SizeConfig.extraLarge-2,
                                  fontWeight: FontWeight.bold,
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 24,
                            ),
                            Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 30, end: 60), // radius from 30 → 60
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutBack,
                                builder: (context, radius, child) {
                                  return TweenAnimationBuilder<Offset>(
                                    tween: Tween(begin: const Offset(-1.8, -1), end: Offset.zero),
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeIn,
                                    builder: (context, offset, innerChild) {
                                      return Transform.translate(
                                        offset: Offset(offset.dx * 100, offset.dy * 100),
                                        child: CircleAvatar(
                                          backgroundColor: theme.colorScheme.primary,
                                          radius: radius,
                                          backgroundImage: (widget.profileImage != null &&
                                              widget.profileImage!.trim().isNotEmpty)
                                              ? (widget.profileImage!.startsWith('http')
                                              ? NetworkImage(widget.profileImage!)
                                              : (File(widget.profileImage!).existsSync()
                                              ? FileImage(File(widget.profileImage!)) as ImageProvider
                                              : null))
                                              : null,
                                          child: (widget.profileImage != null &&
                                              widget.profileImage!.trim().isNotEmpty &&
                                              (widget.profileImage!.startsWith('http') ||
                                                  File(widget.profileImage!).existsSync()))
                                              ? null
                                              : (widget.name != null && widget.name!.isNotEmpty)
                                              ? Center(
                                            child: CustomText(
                                              "${widget.name!.split('')[0]}",
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: radius * 0.83, // scale font with avatar
                                            ),
                                          )
                                              : Center(
                                            child: Icon(
                                              Icons.person,
                                              color: theme.colorScheme.surface,
                                              size: radius, // scale icon too
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                            SizedBox(
                              height: SizeConfig.size15,
                            ),
                            SizedBox(
                              //width: 160,
                              child: CustomText(
                                '${widget.name?.capitalize}',
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(
                              height: SizeConfig.size5,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CustomText(
                                  'Group',
                                  color: AppColors.grayText,
                                ),
                                CustomText(" • ", color: AppColors.grayText),
                                CustomText(
                                  "${members.length} Members",
                                  color: AppColors.grayText,
                                )
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // _groupFeature(
                                //     icon: AppIconAssets.chat_call,
                                //     title: 'Audio'),
                                // _groupFeature(
                                //     icon: AppIconAssets.chat_video_call,
                                //     title: 'Video'),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          spreadRadius: 0.5,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: CustomText(
                            "${members.length} Members",
                            // style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            // ),
                          ),
                        ),
                        ListView.builder(
                          padding: const EdgeInsets.only(bottom: 10),
                          itemCount: members.length > 6 ? 8 : members.length + 1,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            // First item — Add Members card

                            if (index == 0) {
                              return InkWell(
                                onTap: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(builder: (_) => ),
                                  // );
                                  Get.to(()=>BeAvailableContactsList(isFromAddMember: true,members: members,conversationId: widget.conversationId,));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primaryColor,
                                        radius: 22,
                                        child: const Icon(Icons.person_add, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      const CustomText(
                                        "Add Members",
                                        // style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        // ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Show current user ("You") right after Add Members
                            if (index == 1) {
                              GroupMembersListModel? me = members.firstWhere(
                                    (m) => m.id == userId,
                              );

                              if (me != null) {
                                final String displayName =
                                (me.name?.trim().isNotEmpty == true) ? me.name!.trim() : "-";
                                final String initial =
                                displayName.isNotEmpty ? displayName[0] : '?';
                                return ListTile(
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary,
                                    radius: 22,
                                    child: (me.profileImage != null)
                                        ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: me.profileImage!,
                                        fit: BoxFit.cover,
                                        width: 44,
                                        height: 44,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey.shade300,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Center(
                                          child: CustomText(
                                            initial,
                                            // style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                            // ),
                                          ),
                                        ),
                                      ),
                                    )
                                        : Center(
                                      child: CustomText(
                                        initial,
                                        // style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        // ),
                                      ),
                                    ),
                                  ),
                                  title: const CustomText(
                                    "You",
                                    // style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold
                                    // ),
                                  ),
                                  trailing: (me.isAdmin ?? false)
                                      ? Container(
                                    padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade400),
                                    ),
                                    child: const CustomText(
                                      'Admin',
                                      // style: TextStyle(
                                          fontSize: 14
                                      // ),
                                    ),
                                  )
                                      : null,
                                );
                              }
                            }

                            // Last item — View All button if more than 6 members
                            if (members.length > 6 && index == 7) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                                    label: const CustomText(
                                      "View All",
                                          fontWeight: FontWeight.w600,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Normal member tile (excluding "You")
                            final nonMeMembers =
                            members.where((m) => m.id != userId).toList(); // exclude current user
                            final member = nonMeMembers[index - 2]; // shift by 2 (Add + You)

                            final String displayName =
                            (member.name?.trim().isNotEmpty == true) ? member.name!.trim() : "-";
                            final String initial = displayName.isNotEmpty ? displayName[0] : '?';

                            return ListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                radius: 22,
                                child: (member.profileImage != null)
                                    ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: member.profileImage!,
                                    fit: BoxFit.cover,
                                    width: 44,
                                    height: 44,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: CustomText(
                                        initial,
                                        // style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        // ),
                                      ),
                                    ),
                                  ),
                                )
                                    : Center(
                                  child: CustomText(
                                    initial,
                                    // style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    // ),
                                  ),
                                ),
                              ),
                              title: CustomText(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                // style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                // ),
                              ),
                              trailing: (member.isAdmin ?? false)
                                  ? Container(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: const CustomText(
                                  'Admin',
                                  // style: TextStyle(
                                      fontSize: 14
                                  // ),
                                ),
                              )
                                  : null,
                            );
                          },
                        )

                      ],
                    ),
                  )

                ],
              ),
            ),
          );
        } else {
          return Center(
            child: SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(),
            ),
          );
        }
      }),
    );
  }

  Row _groupFeature({String? icon, String? title}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.all(10),
          width: SizeConfig.size80,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade400)),
          child: Column(
            children: [
              if (icon != null && icon.isNotEmpty)
                SvgPicture.asset(
                  height: title == "Add" ? SizeConfig.size25 : null,
                  icon,
                  color: Colors.black54,
                )
              else
                Icon(
                  Icons.image_not_supported,
                  color: Colors.black54,
                ),
              // SizedBox(
              //   height: SizeConfig.size5,
              // ),
              // CustomText(title ?? '')
            ],
          ),
        )
      ],
    );
  }
}

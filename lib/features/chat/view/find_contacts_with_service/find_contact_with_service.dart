import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/professionals/professionals_main.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/services/service_main.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/shopping/shopping_main.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/service/contact_store_service.dart';

class FindContactWithService extends StatefulWidget {
  const FindContactWithService({super.key});

  @override
  State<FindContactWithService> createState() => _FindContactWithServiceState();
}

class _FindContactWithServiceState extends State<FindContactWithService>
    with SingleTickerProviderStateMixin {
  TabController? tabController;
  final chatViewController = Get.find<ChatViewController>();

  @override
  void initState() {
    // TODO: implement initState
    tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    loadContacts();
    super.initState();
  }

  Future<void> loadContacts() async {
    final contacts = await HiveContactService.getOrFetchContacts(
      onFetch: fetchFormattedContacts,
    );

    if (contacts.isNotEmpty) {
      chatViewController.setContact(getType(0), contacts);
    }
  }

  Future<List<Map<String, String>>> fetchFormattedContacts() async {
    PermissionStatus status = await Permission.contacts.status;

    if (!status.isGranted) {
      status = await Permission.contacts.request();
      if (!status.isGranted) {
        throw Exception('Permission denied');
      }
    }

    List<Contact> contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withAccounts: true,

    );

    List<Map<String, dynamic>> rawContacts = contacts.map((c) {
      return {
        ApiKeys.name: c.displayName,
        ApiKeys.number: c.phones.map((p) => p.number).toList(),
      };
    }).toList();

    List<Map<String, String>> valueMap = formatContactsInIsolate(rawContacts);

    chatViewController.setContact(getType(0), valueMap);
    return await valueMap;
  }

  String cleanPhoneNumber(String number) {
    // keep only digits
    return number.replaceAll(RegExp(r'[^0-9]'), '');
  }


// This is the isolate function → runs in background
  List<Map<String, String>> formatContactsInIsolate(
      List<Map<String, dynamic>> rawContacts) {
    return rawContacts
        .where((c) => (c[ApiKeys.number] as List).isNotEmpty)
        .map((c) {
      final rawNumber =
      (c[ApiKeys.number] as List).first as String;

      final cleanedNumber = cleanPhoneNumber(rawNumber);

      // skip invalid / too short numbers
      if (cleanedNumber.length < 10) {
        return null;
      }

      return {
        ApiKeys.number: cleanedNumber,
        ApiKeys.name: c[ApiKeys.name] as String,
      };
    })
        .whereType<Map<String, String>>() // removes nulls
        .toList();
  }


// Runs in isolate – must only use JSON-safe data

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const CustomText(AppStrings.permissionRequired),
            content: const CustomText(AppStrings.allowContactAccess),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const CustomText(AppStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: const CustomText(AppStrings.allowPermission),
              ),
            ],
          ),
    );
  }

  String getType(int index) {
    switch (index) {
      case 0:
        return "professional";
      case 1:
        return "shopping";
      case 2:
        return "services";
      case 3:
        return "others";
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isShadowShow: false,
        title: "Find In Your Contact",
      ),
      body: Obx(() {
        if(chatViewController.getServiceByContactResponse.value.status==Status.COMPLETE){
          final details =chatViewController.professionalContactsResponse.value;
          return Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: AppColors.white,
                child: TabBar(
                  tabAlignment: TabAlignment.start,
                  indicatorPadding: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  isScrollable: true,
                  onTap: (index) async {
                    await chatViewController.findServiceByContacts(
                        getType(index), null);
                  },
                  indicatorSize: TabBarIndicatorSize.tab,
                  controller: tabController,
                  dividerColor: AppColors.primaryColor.withOpacity(0.10),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: AppColors.primaryColor,
                  labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500
                  ),
                  tabs: const [
                    Tab(text: "Professionals",),
                    Tab(text: "Shopping"),
                    Tab(text: "Services"),
                    Tab(text: "Others"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    ProfessionalsMain(details: details,),
                    ProfessionalsMain(details: details,),
                    ProfessionalsMain(details: details,),
                    ProfessionalsMain(details: details,),
                  ],
                ),
              ),
            ],
          );
        }else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }

      }),
    );
  }
}

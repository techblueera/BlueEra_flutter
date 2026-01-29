import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/professionals/professionals_main.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/services/service_main.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/shopping/shopping_main.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/service/contact_store_service.dart';
import 'others/find_by_other_service_main.dart';

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
    chatViewController.selectedIndex.value=0;
    super.initState();
  }

  Future<void> loadContacts() async {
    final contacts = await HiveContactService.getOrFetchContacts(
      onFetch: fetchFormattedContacts,
    );

    if (contacts.isNotEmpty) {
      chatViewController.setContact(professionalContactCategories.first.slugId, contacts);
    }
  }
  Future<void> releadContacts() async {
    final contacts = await HiveContactService.getOrFetchContacts(
      onFetch: fetchFormattedContacts,
    );

    if (contacts.isNotEmpty) {
      chatViewController.reloadContact();
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

    // chatViewController.setContact(professionalContactCategories.first.slugId, valueMap);
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isShadowShow: false,
        title: "Find In Your Contact",
        isReloadContactButton: true,
        onRefreshContact: () {
          releadContacts();
        },
      ),
      body:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.white,
            child: TabBar(
              physics: NeverScrollableScrollPhysics(),
              tabAlignment: TabAlignment.start,
              indicatorPadding: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              isScrollable: true,
              onTap: (index) async {

                if(index==0){
                  chatViewController.findServiceByContacts(professionalContactCategories.first.slugId, null);
                }else if(index==1){
                  chatViewController.findServiceByContacts(
                      fashionContactCategories.first.slugId, null);
                }else if(index==2){
                  chatViewController.findServiceByContacts(
                      othersContactCategories.first.slugId, null);
                }else if(index==3){
                  chatViewController.findServiceByContacts(
                      serviceContactCategories.first.slugId, null);
                }
                chatViewController.selectedIndex.value=0;
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
                Tab(text: "Essential"),
                Tab(text: "Services"),

              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                ProfessionalsMain(),
                ShoppingMain(),
                FindByOtherService(),
                ServiceMain(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:http/http.dart' as http;
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/shared_preference_utils.dart';
import '../model/snd_contact_sync_list_model.dart';
import '../sec_chat_socket/sec_chat_socket.dart';
class SecondChatViewController extends GetxController {
  final chatSocket = SecChatSocketService();
  Rx<SndContactSyncListModel>? sndContactSyncListModel = SndContactSyncListModel().obs;

  Future<void> connectSocket() async {

    // if (socketConnected.value == false) {
      await chatSocket.connectToSocket();
    //   socketConnected.value = true;
    // }
    // final connectivityResult = await NetworkUtils.isConnected();
    // if (connectivityResult) {
    //   await loadChatListFromLocal("personal");
    // }


    // }
  }
  Future<void> syncContacts(Map<String,dynamic> params) async {
    const url = "https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/api/call-chat-service/api/contacts/sync";


    log("contact Sync APi Params ++ ${params}");
    // try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        ApiKeys.authorization: 'Bearer $authTokenGlobal'
      },
      body: jsonEncode(params),
    );

    if (response.statusCode == 200) {
      log("contact Sync APi Res ++ ${response.body}");
      final data = jsonDecode(response.body);
      sndContactSyncListModel?.value=SndContactSyncListModel.fromJson(data);
      print("✅ Success: $data");
    } else {
      print("❌ Error: ${response.statusCode} - ${response.body}");
    }
    // } catch (e) {
    //   print("⚠️ Exception: $e");
    // }
  }

  Future<void> createNewConversation(Map<String,dynamic> params) async {
    const url = "https://p3qw782za2.execute-api.ap-south-1.amazonaws.com/api/call-chat-service/api/conversations";


    log(" APi Params ++ ${params}");
    // try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        ApiKeys.authorization: 'Bearer $authTokenGlobal'
      },
      body: jsonEncode(params),
    );

    if (response.statusCode == 200||response.statusCode == 201) {
      log(" APi Params ++ ${response.body}");
      final data = jsonDecode(response.body);
      // sndContactSyncListModel?.value=SndContactSyncListModel.fromJson(data);
      print("✅ Success: $data");
    } else {
      print("❌ Error: ${response.statusCode} - ${response.body}");
    }
    // } catch (e) {
    //   print("⚠️ Exception: $e");
    // }
  }

}
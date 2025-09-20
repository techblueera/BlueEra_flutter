import 'package:flutter/material.dart';
import 'package:get/get.dart';
class BottomBarController extends GetxController{
RxInt currentIndex=0.obs;
void onChangeIndex(int index){
  currentIndex.value=index;
}
}
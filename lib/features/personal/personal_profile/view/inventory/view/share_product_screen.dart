import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShareProductScreen extends StatefulWidget {
  final String productId;
  const ShareProductScreen({super.key, required this.productId});

  @override
  State<ShareProductScreen> createState() => _ShareProductScreenState();
}

class _ShareProductScreenState extends State<ShareProductScreen> {
  final ProductController controller = Get.put(ProductController());

  @override
  void initState() {
    controller.fetchSingleProductDataApi(productId: widget.productId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

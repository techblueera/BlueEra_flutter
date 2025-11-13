import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:get/get.dart';

class RentalController extends GetxController{
  final List<RentalServiceTab> rentalTabs =
      RentalServiceTab.values;
  RxInt selectedRentalIndex = 0.obs;

}
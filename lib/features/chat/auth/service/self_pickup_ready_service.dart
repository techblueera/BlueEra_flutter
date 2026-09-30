import 'dart:developer';

import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';

/// What a self-pickup order card is selling, which decides the service that
/// marks it ready.
enum SelfPickupOrderKind { grocery, food, homeMade, tiffin, product, medical }

/// Marks a self-pickup order ready for the seller, on the service that owns
/// that kind of order:
///
/// * grocery — `grocery-service`
/// * food — `food-service` (restaurant orders)
/// * home-made food — `PUT earn-service/homeFoodOrders/{orderId}/ready`
/// * tiffin — `PUT earn-service/tiffinOrders/{orderId}/ready`
/// * product — the inventory service
/// * medical — `medical-service` (pharmacy orders)
class SelfPickupReadyService {
  SelfPickupReadyService({
    GroceryRepo? groceryRepo,
    FoodRepo? foodRepo,
    EarnProfileRepo? earnRepo,
    ProductRepo? productRepo,
    MedicalRepo? medicalRepo,
  })  : _groceryRepo = groceryRepo ?? GroceryRepo(),
        _foodRepo = foodRepo ?? FoodRepo(),
        _earnRepo = earnRepo ?? EarnProfileRepo(),
        _productRepo = productRepo ?? ProductRepo(),
        _medicalRepo = medicalRepo ?? MedicalRepo();

  final GroceryRepo _groceryRepo;
  final FoodRepo _foodRepo;
  final EarnProfileRepo _earnRepo;
  final ProductRepo _productRepo;
  final MedicalRepo _medicalRepo;

  /// Returns null on success, or the server's message ('' when it gave none,
  /// or the call threw) on failure.
  Future<String?> markReady(SelfPickupOrderKind kind, String orderId) async {
    try {
      final response = switch (kind) {
        SelfPickupOrderKind.grocery =>
          await _groceryRepo.markSelfPickupOrderReadyRepo(orderId: orderId),
        SelfPickupOrderKind.food =>
          await _foodRepo.markFoodOrderReadyRepo(orderId: orderId),
        SelfPickupOrderKind.homeMade =>
          await _earnRepo.markHomeFoodOrderReadyRepo(orderId: orderId),
        SelfPickupOrderKind.tiffin =>
          await _earnRepo.markTiffinOrderReadyRepo(orderId: orderId),
        SelfPickupOrderKind.product =>
          await _productRepo.markProductOrderReadyRepo(orderId: orderId),
        SelfPickupOrderKind.medical =>
          await _medicalRepo.markMedicalOrderReadyRepo(orderId: orderId),
      };
      if (response.isSuccess) {
        log('${kind.name} self-pickup order $orderId marked as ready');
        return null;
      }
      return response.message ?? '';
    } catch (e) {
      log('Error marking order ready: $e');
      return '';
    }
  }
}

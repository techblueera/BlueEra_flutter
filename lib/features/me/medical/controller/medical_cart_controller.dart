import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/me/medical/model/add_medical_order_response.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// Delivery mode the pharmacy cart is checking out under. Kept as string
/// constants matching the backend contract (see `UserMedicalController`).
class MedicalDeliveryType {
  static const String selfPickup = 'self-pickup';
  static const String rider = 'rider';
}

/// One cart line — flat, self-contained so the cart screen can render it
/// without touching the source `PopularProduct` / `CategoryProduct` tree.
/// Adapted at the add-site (see `MedicalProductCard`), so the controller is
/// agnostic to which API shape the product came from.
class MedicalCartLine {
  final String variantId;
  final String? productId;
  final String? inventoryId;
  final String? productName;
  final String? brand;
  final String? variantName;
  final String? productForm;
  final bool isPrescriptionRequired;
  final num? mrp;
  final num? sellingPrice;
  final String? imageUrl;

  const MedicalCartLine({
    required this.variantId,
    this.productId,
    this.inventoryId,
    this.productName,
    this.brand,
    this.variantName,
    this.productForm,
    this.isPrescriptionRequired = false,
    this.mrp,
    this.sellingPrice,
    this.imageUrl,
  });

  double get mrpValue => (mrp ?? 0).toDouble();
  double get sellingValue => (sellingPrice ?? 0).toDouble();
  double get savingPerUnit {
    final diff = mrpValue - sellingValue;
    return diff > 0 ? diff : 0;
  }
}

/// Business context the cart was opened against. Single-store scope for
/// the first pass — adding lines from a different pharmacy prompts to clear.
class MedicalCartBusiness {
  final String businessId;
  final String businessName;
  final String? logo;
  final String? address;
  final double? lat;
  final double? lng;
  final String? category;

  const MedicalCartBusiness({
    required this.businessId,
    required this.businessName,
    this.logo,
    this.address,
    this.lat,
    this.lng,
    this.category,
  });
}

class MedicalCartController extends GetxController {
  /// Cart lines keyed by variant id (add-order preserved by cartQuantities).
  final RxMap<String, MedicalCartLine> cartLines = <String, MedicalCartLine>{}.obs;

  /// Quantity per variant id — separate map so the qty stepper can rebuild
  /// via `Obx` without notifying every line consumer.
  final RxMap<String, int> cartQuantities = <String, int>{}.obs;

  /// Which pharmacy the current cart belongs to. Cleared with the cart.
  final Rxn<MedicalCartBusiness> business = Rxn<MedicalCartBusiness>();

  /// Buyer-picked delivery mode. Drives the request body's `deliveryType`
  /// AND the post-order route: self-pickup lands the user in the buyer-side
  /// business chat (mirroring grocery); rider hands off to
  /// [MedicalConfirmScreen] so the rider stream can take over.
  final RxString deliveryType = MedicalDeliveryType.selfPickup.obs;
  void setDeliveryType(String type) => deliveryType.value = type;

  Rx<ApiResponse> placeOrderResponse = ApiResponse.initial('Initial').obs;
  RxBool isPlacingOrder = false.obs;

  bool get isEmpty => cartLines.isEmpty;
  bool get isNotEmpty => cartLines.isNotEmpty;

  int getQuantity(String? variantId) =>
      variantId == null ? 0 : (cartQuantities[variantId] ?? 0);

  bool contains(String? variantId) =>
      variantId != null && cartLines.containsKey(variantId);

  /// Add or increment. If [businessCtx] is non-null and differs from the
  /// current cart business, the caller should have already prompted the
  /// user (see `MedicalProductCard`) — we still overwrite here as a safety.
  void addLine(MedicalCartLine line, {MedicalCartBusiness? businessCtx}) {
    if (businessCtx != null && business.value == null) {
      business.value = businessCtx;
    }
    if (cartQuantities.containsKey(line.variantId)) {
      cartQuantities[line.variantId] = cartQuantities[line.variantId]! + 1;
    } else {
      cartLines[line.variantId] = line;
      cartQuantities[line.variantId] = 1;
    }
  }

  /// Decrement by one — removes the line entirely when quantity reaches 0.
  void removeOne(String variantId) {
    final qty = cartQuantities[variantId];
    if (qty == null) return;
    if (qty > 1) {
      cartQuantities[variantId] = qty - 1;
    } else {
      cartQuantities.remove(variantId);
      cartLines.remove(variantId);
      if (cartLines.isEmpty) business.value = null;
    }
  }

  void removeLine(String variantId) {
    cartQuantities.remove(variantId);
    cartLines.remove(variantId);
    if (cartLines.isEmpty) business.value = null;
  }

  // clearAll() is defined further down — it also resets the delivery choice.

  // ── Totals ─────────────────────────────────────────────────────────
  double get totalSellingPrice {
    double t = 0;
    cartLines.forEach((id, line) {
      t += line.sellingValue * (cartQuantities[id] ?? 0);
    });
    return t;
  }

  double get totalMRP {
    double t = 0;
    cartLines.forEach((id, line) {
      final base = line.mrpValue > 0 ? line.mrpValue : line.sellingValue;
      t += base * (cartQuantities[id] ?? 0);
    });
    return t;
  }

  double get totalSavings {
    final diff = totalMRP - totalSellingPrice;
    return diff > 0 ? diff : 0;
  }

  int get totalItemsCount {
    int n = 0;
    cartQuantities.forEach((_, q) => n += q);
    return n;
  }

  bool get hasAnyPrescriptionItem =>
      cartLines.values.any((l) => l.isPrescriptionRequired);

  List<String?> get previewImages =>
      cartLines.values.take(3).map((l) => l.imageUrl).toList();

  // ── Checkout ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> buildOrderItems() {
    final items = <Map<String, dynamic>>[];
    cartLines.forEach((id, line) {
      final qty = cartQuantities[id] ?? 0;
      if (qty <= 0) return;
      items.add({
        'inventory': line.inventoryId ?? '',
        'productVariant': line.variantId,
        'quantity': qty,
        'mrp': line.mrpValue,
        'sellingPrice': line.sellingValue,
      });
    });
    return items;
  }

  Future<void> placeOrder() async {
    if (isEmpty) return;
    isPlacingOrder.value = true;
    AppLoader.show();

    final chosenDelivery = deliveryType.value;
    final Map<String, dynamic> body = {
      'items': buildOrderItems(),
      'deliveryType': chosenDelivery,
      'discount': totalSavings,
    };

    final response = await MedicalRepo().groceryOrderRepo(params: body);

    if (!response.isSuccess) {
      AppLoader.hide();
      isPlacingOrder.value = false;
      commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      return;
    }

    placeOrderResponse.value = ApiResponse.complete(response);

    // Parse orderId early — the rider handoff route needs it.
    String? orderId;
    try {
      final parsed = AddMedicalOrderResponseModel.fromJson(response.response?.data);
      orderId = parsed.id;
    } catch (_) {
      orderId = null;
    }

    // Snapshot the values we need for post-order routing BEFORE clearing —
    // clearAll() nulls out the cart state including the delivery type reset.
    final isRiderMode = chosenDelivery == MedicalDeliveryType.rider;
    clearAll();
    AppLoader.hide();
    isPlacingOrder.value = false;

    if (isRiderMode && orderId != null && orderId.isNotEmpty) {
      // Hand off to the existing rider matching pipeline (same route the
      // medical-listing flow uses after its own place-order call).
      Get.toNamed(
        RouteHelper.getMedicalConfirmScreenRoute(),
        arguments: {ApiKeys.argOrderId: orderId},
      );
      return;
    }

    // Self-pickup: drop the user on the Inquiry (business) chat tab —
    // the placed pharmacy order surfaces there as a buyer-side chat.
    final bottom = getOrPut(() => BottomBarController());
    bottom.onChangeIndex(2);
    final chat = getOrPut(() => ChatViewController());
    chat.onSelectChatTab(1);
    Get.until(
      (route) => route.settings.name == RouteConstant.BottomNavigationBarScreen,
    );
    chat.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
  }

  void clearAll() {
    cartQuantities.clear();
    cartLines.clear();
    business.value = null;
    // Reset the buyer's delivery choice — next cart starts fresh.
    deliveryType.value = MedicalDeliveryType.selfPickup;
  }
}

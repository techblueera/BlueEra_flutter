import 'dart:async';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/account_plan/controller/account_plan_controller.dart';
import 'package:BlueEra/features/account_plan/controller/account_plan_entitlement.dart';
import 'package:BlueEra/features/account_plan/model/deposit_migration_model.dart';
import 'package:BlueEra/features/account_plan/repo/account_plan_repo.dart';
import 'package:get/get.dart';

/// Moving a legacy deposit onto an account plan: whether this user is offered
/// the move, and making it.
class DepositMigrationService {
  DepositMigrationService({AccountPlanRepo? repo})
      : _repo = repo ?? AccountPlanRepo();

  final AccountPlanRepo _repo;

  /// Whether (and with which plan) the user can migrate. Null when the check
  /// failed.
  Future<DepositMigrationEligibility?> eligibility() async {
    final res = await _repo.migrationEligibility();
    if (!res.isSuccess) {
      logs('DEPOSIT_MIGRATION: eligibility failed — ${res.message}');
      return null;
    }
    final body = res.response?.data;
    if (body is! Map) return null;
    return DepositMigrationEligibility.fromJson(
        Map<String, dynamic>.from(body));
  }

  /// Accepts the T&C and activates the plan. [message] is the server's own
  /// wording when it gave one.
  ///
  /// Idempotent by contract: a second call answers `already: true`, which is
  /// the plan being active — the same outcome the first call wanted, so it
  /// counts as [ok].
  ///
  /// On success, refreshes the entitlement snapshot the go-live gates read
  /// (or the app keeps telling the user to pay for a plan) and, if it is
  /// alive, the plans screen.
  Future<({bool ok, bool already, String? message})> migrate() async {
    final res = await _repo.migrate();
    final body = res.response?.data;
    final data = body is Map && body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : const <String, dynamic>{};
    final already =
        data['already'] == true || body is Map && body['already'] == true;
    final ok =
        res.isSuccess && (body is! Map || body['success'] != false || already);
    final message = (body is Map ? body['message']?.toString() : null) ??
        (ok ? null : res.message?.toString());

    if (ok) {
      unawaited(AccountPlanEntitlement.to.refresh());
      if (Get.isRegistered<AccountPlanController>()) {
        unawaited(Get.find<AccountPlanController>().fetchMyPlans());
      }
    }
    return (ok: ok, already: already, message: message);
  }
}

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';

class OtherRepo extends BaseService {
  Future<dynamic> createAboutOrganisationRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      createAboutOrganisation,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getAboutOrganisationRepo() async {
    return await ApiBaseHelper().getHTTP(
      createAboutOrganisation,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateAboutOrganisationRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$createAboutOrganisation/$id",
      params:body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteAboutOrganisationRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$createAboutOrganisation/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // Management APIs
  Future<dynamic> createManagementRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      management,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getManagementRepo() async {
    return await ApiBaseHelper().getHTTP(
      management,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateManagementRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$management/$id",
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteManagementRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$management/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  // Staff APIs
  Future<dynamic> createStaffRepo(Map<String, dynamic> body) async {
    return await ApiBaseHelper().postHTTP(
      staff,
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> getStaffRepo() async {
    return await ApiBaseHelper().getHTTP(
      staff,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> updateStaffRepo(String id, Map<String, dynamic> body) async {
    return await ApiBaseHelper().putHTTP(
      "$staff/$id",
      params: body,
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }

  Future<dynamic> deleteStaffRepo(String id) async {
    return await ApiBaseHelper().deleteHTTP(
      "$staff/$id",
      showProgress: true,
      onSuccess: (res) {},
      onError: (error) {},
    );
  }
}

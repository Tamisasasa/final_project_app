import 'package:intl/intl.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'package:final_project_vaccine/feature/data/models/RegisterModel.dart';

class RegisterService {
  Future<Register?> login(String idCard, String password) async {
    try {
      final response = await DioClient.dio.post(
        '/pet-owners/login',
        data: {"idCard": idCard, "password": password},
      );
      if (response.statusCode == 200 && response.data["status"] == true) {
        return Register.fromJson(response.data["data"]);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> createMember({
    required String idCard,
    required String fullName,
    required DateTime birthDate,
    required String email,
    required String phoneNumber,
    required String password,
    required String address,
  }) async {
    await DioClient.dio.post(
      '/pet-owners',
      data: {
        "idCard": idCard,
        "fullName": fullName,
        "birthDate": DateFormat("yyyy-MM-dd").format(birthDate),
        "email": email,
        "phoneNumber": phoneNumber,
        "password": password,
        "address": address,
      },
    );
  }

  Future<Register> getPetOwner(int id) async {
    var response = await DioClient.dio.get("/pet-owners/$id");
    return Register.fromJson(response.data);
  }

  Future<void> editProfile({
    required int id,
    required String idCard,
    required String fullName,
    required DateTime birthDate,
    required String email,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      await DioClient.dio.post(
        "/pet-owners/$id",
        data: {
          "idCard": idCard,
          "fullName": fullName,
          "birthDate": DateFormat("yyyy-MM-dd").format(birthDate),
          "email": email,
          "phoneNumber": phoneNumber,
          "address": address,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

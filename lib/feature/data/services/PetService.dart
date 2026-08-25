import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'package:final_project_vaccine/feature/data/models/PetModel.dart';

class PetService {
  Future<FormData> _prepareFormData(
    Map<String, dynamic> data,
    XFile? imagePet,
  ) async {
    FormData formData = FormData.fromMap(data);

    if (imagePet != null) {
      formData.files.add(
        MapEntry(
          "imagePet",
          await MultipartFile.fromFile(imagePet.path, filename: imagePet.name),
        ),
      );
    }
    return formData;
  }

  Future<void> createPetInfo({
    required int ownerId,
    required String petName,
    required String breed,
    required DateTime birthDate,
    required double weight,
    required double height,
    required String gender,
    required String typePet,
    required String description,
    required String imagePet,
  }) async {
    final Map<String, dynamic> data = {
      "petName": petName,
      "breed": breed,
      "birthDate": DateFormat("yyyy-MM-dd").format(birthDate),
      "weight": weight,
      "height": height,
      "gender": gender,
      "typePet": typePet,
      "description": description,
      "petOwnerId": ownerId,
      "imagePet": imagePet,
      "isDeceased": false,
    };
    await DioClient.dio.post("/pet", data: data);
  }

  Future<void> updatePet({
    required int ownerId,
    required int id,
    required String petName,
    required String breed,
    required DateTime birthDate,
    required double weight,
    required double height,
    required String gender,
    required String typePet,
    required String description,
    required String imagePet, 
    required bool isDeceased,
  }) async {
    Map<String, dynamic> data = {
      "petName": petName,
      "breed": breed,
      "birthDate": DateFormat("yyyy-MM-dd").format(birthDate),
      "weight": weight,
      "height": height,
      "gender": gender,
      "typePet": typePet,
      "description": description,
      "petOwnerId": ownerId,
      "imagePet": imagePet,
      "isDeceased": isDeceased,
    };

    await DioClient.dio.post("/pet/$id", data: data);
  }

  Future<List<PetInfo>> getPetsByOwnerId(int ownerId) async {
    var response = await DioClient.dio.get(
      "/pet",
      queryParameters: {"petOwnerId": ownerId},
    );

    if (response.data is List) {
      final dataList = response.data as List;
      return dataList.map((item) => PetInfo.fromJson(item)).toList();
    }

    if (response.data is Map && response.data["result"] != null) {
      final dataList = response.data["result"] as List;
      return dataList.map((item) => PetInfo.fromJson(item)).toList();
    }

    return [];
  }
}
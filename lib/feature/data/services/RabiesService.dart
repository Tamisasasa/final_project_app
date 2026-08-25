import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/data/models/RabiesModel.dart';

class RabiesReportService {
  final Dio dio;

  RabiesReportService(this.dio);

  Future<void> createReport(RabiesReport report) async {
    try {
      await dio.post(
        "/rabies-reports",
        data: report.toJson(), 
      );
    } on DioException catch (e) {
      throw Exception(
          "สร้างรายงานไม่สำเร็จ: ${e.response?.data ?? e.message}");
    }
  }

  Future<List<RabiesReport>> getReportsByOwner(int ownerId) async {
  try {
    final response =
        await dio.get("/rabies-reports/owner/$ownerId");

    final data = response.data;

    List list = [];

    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = data["result"] ?? data["data"] ?? [];
    }

    return list.map((e) => RabiesReport.fromJson(e)).toList();
  } catch (e) {
    throw Exception("ดึงข้อมูลไม่สำเร็จ: $e");
  }
}
}
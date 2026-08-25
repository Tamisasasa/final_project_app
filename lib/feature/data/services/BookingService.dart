import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/data/models/AppointmentModel.dart';
import 'package:final_project_vaccine/feature/data/models/BookingModel.dart';
import 'package:final_project_vaccine/feature/data/models/PetModel.dart';

class BookingService {
  final Dio dio;

  BookingService(this.dio);

  Future<List<Appointment>> getAppointments() async {
    try {
      final res = await dio.get("/appointments");

      final data = res.data;
      final List list = data["data"] ?? [];

      return list.map((e) => Appointment.fromJson(e)).toList();
    } catch (e) {
      throw Exception("ดึงกิจกรรมไม่สำเร็จ: $e");
    }
  }

  Future<void> createBooking(Booking booking) async {
    try {
      await dio.post(
        "/bookings",
        data: booking.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(
        "จองไม่สำเร็จ: ${e.response?.data ?? e.message}",
      );
    }
  }

  Future<List<PetInfo>> getPetsByOwner(int ownerId) async {
  try {
    final res = await dio.get("/pets/owner/$ownerId");
    

    final data = res.data;
    final List list = data["result"] ?? [];

    return list.map((e) => PetInfo.fromJson(e)).toList();
  } catch (e) {
    throw Exception("ดึงสัตว์เลี้ยงไม่สำเร็จ: $e");
  }
}
}
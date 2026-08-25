class Booking {
  final String bookingDate;   // yyyy-MM-dd
  final String bookingTime;   // HH:mm
  final String vaccinationMethod;
  final String bookingStatus;
  final List<int> petIds;     // เปลี่ยนจาก petId ตัวเดี่ยว เป็น petIds (List)
  final int appointmentId;
  final int petOwnerId;
  final int servicePointId;

  Booking({
    required this.bookingDate,
    required this.bookingTime,
    required this.vaccinationMethod,
    required this.bookingStatus,
    required this.petIds,
    required this.appointmentId,
    required this.petOwnerId,
    required this.servicePointId,
  });

  Map<String, dynamic> toJson() {
    return {
      "bookingDate": bookingDate,
      "bookingTime": bookingTime,
      "vaccinationMethod": vaccinationMethod,
      "bookingStatus": bookingStatus,
      "petIds": petIds,
      "appointmentId": appointmentId,
      "petOwnerId": petOwnerId,
      "servicePointId": servicePointId,
    };
  }
}
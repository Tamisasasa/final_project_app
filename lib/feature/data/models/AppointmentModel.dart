class Appointment {
  final int appointmentId;
  final String activityName;

  Appointment({
    required this.appointmentId,
    required this.activityName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentId: json['appointmentId'],
      activityName: json['activityName'] ?? '',
    );
  }
}
class RabiesReport {
  final int? reportId;
  final String reporterName;
  final int numberOfAnimals;
  final String animalType;
  final String reporterPhoneNumber;
  final DateTime reportDate;
  final String location;
  final String deathCause;
  final String reportStatus;
  final String? attachments; 
  final int? petOwnerId;

  RabiesReport({
    this.reportId,
    required this.reporterName,
    required this.numberOfAnimals,
    required this.animalType,
    required this.reporterPhoneNumber,
    required this.reportDate,
    required this.location,
    required this.deathCause,
    required this.reportStatus,
    this.attachments, 
    this.petOwnerId,
  });

  factory RabiesReport.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null) return DateTime.now();
      try {
        return DateTime.parse(dateStr.toString());
      } catch (_) {
        try {
          final parts = dateStr.toString().split('T')[0].split('-');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        } catch (_) {}
        return DateTime.now();
      }
    }

    return RabiesReport(
      reportId: json['reportId'],
      reporterName: json['reporterName'] ?? '',
      numberOfAnimals: json['numberOfAnimals'] ?? 0,
      animalType: json['animalType'] ?? '',
      reporterPhoneNumber: json['reporterPhoneNumber'] ?? '',
      reportDate: parseDate(json['reportDate']), 
      location: json['location'] ?? '',
      deathCause: json['deathCause'] ?? '',
      reportStatus: json['reportStatus'] ?? 'รอดำเนินการ',
      attachments: json['attachments'], 
      petOwnerId: json['petOwner']?['petOwnerId'] ?? json['petOwnerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "reporterName": reporterName,
      "numberOfAnimals": numberOfAnimals,
      "animalType": animalType,
      "reporterPhoneNumber": reporterPhoneNumber,
      "reportDate": reportDate.toIso8601String().split("T")[0],
      "location": location,
      "deathCause": deathCause,
      "reportStatus": reportStatus,
      "attachments": attachments, 
      "petOwnerId": petOwnerId,
    };
  }
}
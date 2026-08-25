class Register {
  final int petOwnerId;
  final String idCard;
  final String fullName;
  final String birthDate;
  final String? email;
  final String phoneNumber;
  final String address;

  Register({
    required this.petOwnerId,
    required this.idCard,
    required this.fullName,
    required this.birthDate,
    this.email,
    required this.phoneNumber,
    required this.address,
  });

  factory Register.fromJson(Map<String, dynamic> json) {
    return Register(
      petOwnerId: json['petOwnerId'] ?? 0,
      idCard: json['idCard'] ?? "",
      fullName: json['fullName'] ?? "",
      birthDate: json['birthDate'] ?? "",
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? "",
      address: json['address'] ?? "",
    );
  }
}
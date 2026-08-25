class PetInfo {
  int? id;
  String? petName;
  String? breed;
  DateTime? birthDate;
  double? weight;
  double? height;
  String? gender;
  String? description;
  String? typePet;
  String? imagePet;
  int? petOwnerId;
  bool? isDeceased;

  PetInfo({
    this.id,
    this.petName,
    this.breed,
    this.birthDate,
    this.weight,
    this.height,
    this.gender,
    this.description,
    this.typePet,
    this.imagePet,
    this.petOwnerId,
    this.isDeceased,
  });

  factory PetInfo.fromJson(Map<String, dynamic> json) => PetInfo(
        id: json["petId"] ?? json["id"],
        petName: json["petName"],
        breed: json["breed"],
        birthDate: json["birthDate"] != null ? DateTime.parse(json["birthDate"]) : null,
        weight: (json["weight"] as num?)?.toDouble(),
        height: (json["height"] as num?)?.toDouble(),
        gender: json["gender"],
        description: json["description"],
        typePet: json["typePet"],
        imagePet: json["imagePet"], 
        petOwnerId: json["petOwner"] != null ? json["petOwner"]["petOwnerId"] : json["petOwnerId"],
        isDeceased: json["isDeceased"] ?? json["is_deceased"] ?? json["deceased"] ?? false,
      );
}
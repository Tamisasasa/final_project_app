import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:final_project_vaccine/feature/data/models/PetModel.dart';
import 'EditPet.dart';
import 'HomePage.dart';
import 'ViewProfile.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
// นำเข้าหน้า ListBookingAppointment
import 'ListBookingAppointment.dart';

class ViewPet extends StatefulWidget {
  final PetInfo pet;
  const ViewPet({super.key, required this.pet});

  @override
  State<ViewPet> createState() => _ViewPetState();
}

class _ViewPetState extends State<ViewPet> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  int _currentIndex = 2;
  
  late PetInfo _currentPet;

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
  }

  int calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _refreshPetData() async {
    try {
      final res = await DioClient.dio.get(
        "/pet",
        queryParameters: {"petOwnerId": _currentPet.petOwnerId},
      );

      final petsData = res.data;
      List list = [];
      if (petsData is List) {
        list = petsData;
      } else if (petsData is Map && petsData["result"] is List) {
        list = petsData["result"];
      }

      final latestPetJson = list.firstWhere(
        (p) => (p["petId"] ?? p["id"]) == _currentPet.id,
        orElse: () => null,
      );

      if (latestPetJson != null) {
        setState(() {
          _currentPet = PetInfo.fromJson(latestPetJson);
        });
      }
    } catch (e) {
      debugPrint("Error refreshing pet: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? ownerId = _currentPet.petOwnerId;
    return Scaffold(
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            if (ownerId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(userId: ownerId),
                ),
              );
            }
          } else if (index == 1) {
            if (ownerId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListBookingAppointment(userId: ownerId),
                ),
              );
            }
          } else if (index == 3) {
            if (ownerId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewProfile(id: ownerId),
                ),
              );
            }
          }
        },
      ),
      backgroundColor: const Color.fromARGB(255, 254, 254, 254),
      appBar: AppBar(
        title: const Text(
          "Pet Profile",
          style: TextStyle(
            fontFamily: 'VERDANAI',
            color: Color.fromARGB(221, 86, 82, 148),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.indigo),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.indigo),
            onPressed: () async {
              // เช็คว่าถ้าสัตว์เลี้ยงเสียชีวิตแล้ว ห้ามแก้ไข
              if (_currentPet.isDeceased == true) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text(
                      "ไม่สามารถแก้ไขได้",
                      style: TextStyle(
                        fontFamily: 'sarabun-Regular',
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      "สัตว์เลี้ยงที่เสียชีวิตแล้ว ไม่สามารถแก้ไขข้อมูลได้",
                      style: TextStyle(
                        fontFamily: 'sarabun-Regular',
                        fontSize: 16,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "ตกลง",
                          style: TextStyle(fontFamily: 'sarabun-Regular'),
                        ),
                      ),
                    ],
                  ),
                );
                return; // หยุดการทำงาน ไม่ให้เปิดหน้าแก้ไข
              }

              // ถ้ายังไม่เสียชีวิต ให้ไปหน้าแก้ไขปกติ
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditPetPage(pet: _currentPet)),
              );

              if (updated == true) {
                _refreshPetData();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : NetworkImage(
                            '${DioClient.dio.options.baseUrl}/pet/${_currentPet.id}/image_pet?t=${DateTime.now().millisecondsSinceEpoch}',
                          ) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        radius: 18,
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentPet.petName ?? "-",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'sarabun-Regular',
                color: Color.fromARGB(221, 86, 82, 148),
              ),
            ),
            Text(
              _currentPet.breed ?? "-",
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'sarabun-Regular',
                color: Color.fromARGB(221, 86, 82, 148),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard(
                  "อายุ (AGE)",
                  "${calculateAge(_currentPet.birthDate)} ปี",
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  "น้ำหนัก (WEIGHT)",
                  "${_currentPet.weight ?? '0'} กก.",
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 233, 233, 255),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _infoRow(
                    "วันเกิด (Birthday)",
                    DateFormat(
                      "dd/MM/yyyy",
                    ).format(_currentPet.birthDate ?? DateTime.now()),
                  ),
                  const Divider(),
                  _infoRow("ประเภท (Category)", _currentPet.typePet ?? "-"),
                  const Divider(),
                  _infoRow("เพศ (Gender)", _currentPet.gender ?? "-"),
                  const Divider(),
                  _infoRow(
                    "สถานะชีวิต",
                    _currentPet.isDeceased == true ? "เสียชีวิตแล้ว" : "ยังมีชีวิตอยู่",
                    valueColor: _currentPet.isDeceased == true ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 239, 246, 255),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'sarabun-Regular',
                color: Color.fromARGB(221, 23, 21, 68),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'sarabun-Regular',
                color: Color.fromARGB(221, 86, 82, 148),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'sarabun-Regular',
              color: Color.fromARGB(221, 36, 34, 71),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'sarabun-Regular',
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color.fromARGB(221, 86, 82, 148),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/projects/ListPet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:final_project_vaccine/feature/data/services/RegisterService.dart';
import 'package:final_project_vaccine/feature/data/models/RegisterModel.dart';
import 'package:final_project_vaccine/feature/projects/EditProfile.dart';
import 'Login.dart';
import 'HomePage.dart';
import 'ViewProfile.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
// นำเข้าหน้า ListBookingAppointment
import 'ListBookingAppointment.dart';

class ViewProfile extends StatefulWidget {
  final int id;
  const ViewProfile({super.key, required this.id});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  final RegisterService petOwnerService = RegisterService();
  Register? petOwner;
  bool isLoading = false;
  int _currentIndex = 3;

  final Color primaryColor = const Color.fromARGB(221, 96, 96, 156);
  final Color borderColor = const Color.fromARGB(255, 137, 125, 183);

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await petOwnerService.getPetOwner(widget.id);

      if (!mounted) return;

      setState(() {
        petOwner = response;
      });
    } on DioException catch (e) {
      debugPrint("Dio Error: ${e.response?.data ?? e.message}");
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";

    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "ออกจากระบบ",
            style: TextStyle(fontFamily: 'sarabun-Regular'),
          ),
          content: const Text(
            "คุณต้องการออกจากระบบใช่หรือไม่?",
            style: TextStyle(fontFamily: 'sarabun-Regular'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "ยกเลิก",
                style: TextStyle(color: Colors.grey, fontFamily: 'sarabun-Regular'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); 
                
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (route) => false,
                );
              },
              child: const Text(
                "ออกจากระบบ",
                style: TextStyle(color: Colors.white, fontFamily: 'sarabun-Regular'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(userId: widget.id),
              ),
            );
          } else if (index == 1) {
            // พาไปหน้า ListBookingAppointment ทันที
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListBookingAppointment(userId: widget.id),
              ),
            );
          }  else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewProfile(id: widget.id),
              ),
            );
          }
        },
      ),
      backgroundColor: const Color.fromARGB(255, 250, 250, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 255),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_square,
              color: Color.fromARGB(255, 99, 92, 148),
              size: 28,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfile(userId: widget.id),
                ),
              );

              if (result == true) {
                fetch();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color.fromARGB(255, 99, 92, 148),
              size: 28,
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'ออกจากระบบ',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'sarabun-Regular',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          petOwner == null
              ? const Center(child: Text("ไม่พบข้อมูลเจ้าของในระบบ"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              petOwner!.fullName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontFamily: 'sarabun-Regular',
                                color: Color.fromARGB(221, 86, 82, 148),
                              ),
                            ),
                            const Text(
                              "เจ้าของสัตว์เลี้ยง",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontFamily: 'sarabun-Regular',
                              ),
                            ),
                            const SizedBox(height: 35),
                            _buildInfoCard("เลขบัตรประชาชน", petOwner!.idCard),
                            _buildInfoCard(
                              "วัน-เดือน-ปีเกิด",
                              formatDate(petOwner!.birthDate),
                            ),
                            _buildInfoCard("อีเมล", petOwner!.email ?? "-"),
                            _buildInfoCard("เบอร์โทร", petOwner!.phoneNumber),
                            _buildInfoCard("ที่อยู่", petOwner!.address),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ListPet(ownerId: widget.id),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFDE8E8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  "รายชื่อสัตว์เลี้ยง",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'sarabun-Regular',
                                    color: Color(0xFFE57373),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 236, 249, 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4FC3F7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: primaryColor, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'sarabun-Regular',
              color: Color.fromARGB(221, 86, 82, 148),
            ),
          ),
        ],
      ),
    );
  }
}
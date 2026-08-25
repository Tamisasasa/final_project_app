import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:final_project_vaccine/feature/data/models/PetModel.dart';
import 'package:final_project_vaccine/feature/data/services/PetService.dart';
import 'package:final_project_vaccine/feature/projects/AddPet_Info.dart';
import 'package:final_project_vaccine/feature/projects/ViewPet.dart';
import 'ViewProfile.dart';
import 'HomePage.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'package:dio/dio.dart';
// นำเข้าหน้า ListBookingAppointment
import 'ListBookingAppointment.dart';

class ListPet extends StatefulWidget {
  final int ownerId;
  const ListPet({super.key, required this.ownerId});

  @override
  State<ListPet> createState() => _ListPetState();
}

class _ListPetState extends State<ListPet> {
  final PetService _petService = PetService();
  final Dio dio = Dio();
  List<PetInfo> _pets = [];
  bool _isLoading = true;
  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    try {
      setState(() => _isLoading = true);
      final response = await _petService.getPetsByOwnerId(widget.ownerId);
      setState(() => _pets = response);
    } catch (e) {
      debugPrint("❌ Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
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
                builder: (context) => HomePage(userId: widget.ownerId),
              ),
            );
          } else if (index == 1) {
            // แก้ไขตรงนี้ให้พาไปหน้า ListBookingAppointment ทันที
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListBookingAppointment(userId: widget.ownerId),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewProfile(id: widget.ownerId),
              ),
            );
          }
        },
      ),
      appBar: AppBar(
        title: const Text(
          "สัตว์เลี้ยงของฉัน",
          style: TextStyle(
            fontFamily: 'sarabun-Regular',
            color: Color.fromARGB(221, 86, 82, 148),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchPets,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.80,
                ),
                itemCount: _pets.length,
                itemBuilder: (context, index) =>
                    _buildPetGridCard(_pets[index]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddpetInfo(ownerId: widget.ownerId),
          ),
        ).then((_) => _fetchPets()),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "ยังไม่มีข้อมูลสัตว์เลี้ยง",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchPets, child: const Text("โหลดใหม่")),
        ],
      ),
    );
  }

  Widget _buildPetGridCard(PetInfo pet) {
    String baseUrl = DioClient.dio.options.baseUrl;
    String imageUrl = '$baseUrl/pet/${pet.id}/image_pet?t=${DateTime.now().millisecondsSinceEpoch}';

    bool deceased = pet.isDeceased ?? false;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViewPet(pet: pet)),
        );
        _fetchPets(); 
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (c, o, s) => Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.pets, size: 40, color: Colors.blue),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    pet.petName ?? "ไม่ระบุชื่อ",
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'sarabun-Regular',
                      color: Color.fromARGB(221, 86, 82, 148),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pet.breed ?? "ไม่ระบุสายพันธุ์",
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'sarabun-Regular',
                      color: Color.fromARGB(221, 86, 82, 148),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deceased ? "เสียชีวิต" : "ยังมีชีวิตอยู่",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'sarabun-Regular',
                      color: deceased ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (!deceased)
                    FutureBuilder<Response>(
                      future: DioClient.dio.get("/pet", queryParameters: {"petOwnerId": widget.ownerId}),
                      builder: (context, snapshot) {
                        String statusLabel = "ยังไม่ได้จอง";
                        Color statusColor = Colors.grey;

                        if (snapshot.hasData && snapshot.data?.data != null) {
                          var petsData = snapshot.data!.data;
                          List list = [];
                          if (petsData is List) {
                            list = petsData;
                          } else if (petsData is Map && petsData["result"] is List) {
                            list = petsData["result"];
                          }

                          var found = list.firstWhere(
                            (p) => (p["petId"] ?? p["id"]) == pet.id,
                            orElse: () => null,
                          );

                          if (found != null && found["bookings"] is List) {
                            List bookings = found["bookings"];
                            var activeBooking = bookings.firstWhere(
                              (b) => b["bookingStatus"] != "ยกเลิก",
                              orElse: () => null,
                            );

                            if (activeBooking != null) {
                              String bStatus = activeBooking["bookingStatus"] ?? "";
                              if (bStatus == "รอดำเนินการ") {
                                statusLabel = "รอดำเนินการ"; 
                                statusColor = Colors.orange; 
                              } else if (bStatus == "เสร็จสิ้น") {
                                statusLabel = "สถานะ: เสร็จสิ้น";
                                statusColor = Colors.blue;
                              }
                            }
                          }
                        }

                        return Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'sarabun-Regular',
                            color: statusColor,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
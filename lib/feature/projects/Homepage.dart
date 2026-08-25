import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'package:final_project_vaccine/feature/projects/ListPet.dart';
import 'package:final_project_vaccine/feature/projects/BookingAppointment.dart';
import 'package:final_project_vaccine/feature/projects/BookingHistoryScreen.dart';
import 'package:final_project_vaccine/feature/projects/ListRabiesOwnerReport.dart';
import 'package:final_project_vaccine/feature/projects/ViewProfile.dart';
import 'package:final_project_vaccine/feature/projects/ListBookingAppointment.dart';

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Dio dio = DioClient.dio;
  List<Map<String, dynamic>> petsWithImages = [];
  String userName = "";
  int _currentIndex = 0;
  
  int pendingBookingsCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchActivePet();
    fetchPendingBookingsCount();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await dio.get('/pet-owners/${widget.userId}');

      if (response.data != null) {
        setState(() {
          userName = response.data['fullName'] ?? "User";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
      setState(() {
        userName = "User";
      });
    }
  }

  Future<void> fetchActivePet() async {
    try {
      final response = await dio.get(
        '/pet',
        queryParameters: {'petOwnerId': widget.userId},
      );

      if (response.data != null) {
        List<dynamic> allPets = response.data;
        List<Map<String, dynamic>> tempPets = [];
        String baseUrl = DioClient.dio.options.baseUrl;

        for (var pet in allPets) {
          int petId = pet['petId'];

          String url =
              '$baseUrl/pet/$petId/image_pet?t=${DateTime.now().millisecondsSinceEpoch}';

          tempPets.add({'url': url, 'name': pet['petName']});
        }

        setState(() {
          petsWithImages = tempPets;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> fetchPendingBookingsCount() async {
    try {
      final res = await dio.get("/bookings/owner/${widget.userId}/current");
      final responseBody = res.data;
      
      List<dynamic>? bookingList;
      if (responseBody is List) {
        bookingList = responseBody;
      } else if (responseBody is Map) {
        if (responseBody["data"] is List) {
          bookingList = responseBody["data"];
        } else if (responseBody["result"] is List) {
          bookingList = responseBody["result"];
        }
      }

      int count = 0;
      if (bookingList != null) {
        for (var b in bookingList) {
          if (b is Map<String, dynamic> && b["bookingStatus"] == "รอดำเนินการ") {
            count++;
          }
        }
      }

      if (mounted) {
        setState(() {
          pendingBookingsCount = count;
        });
      }
    } catch (e) {
      debugPrint("Error fetching pending bookings count: $e");
    }
  }

  Future<void> goAndRefresh(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    fetchActivePet();
    fetchUserProfile();
    fetchPendingBookingsCount(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 247, 248),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _currentIndex == 0 ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.pets,
                  color: _currentIndex == 1 ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                  // เปลี่ยนให้วิ่งไปหน้า ListBookingAppointment แทนการยิง API ยาวๆ
                  goAndRefresh(ListBookingAppointment(userId: widget.userId));
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: _currentIndex == 3 ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewProfile(id: widget.userId),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: "Hello\n",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'sarabun-Regular',
                                      color: Color.fromARGB(221, 86, 82, 148),
                                    ),
                                  ),
                                  TextSpan(
                                    text: "$userName!",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'sarabun-Regular',
                                      color: Color.fromARGB(221, 86, 82, 148),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Ready for a fun day with Buddy?",
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'VERDANAI',
                                color: Color.fromARGB(221, 110, 107, 158),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ViewProfile(id: widget.userId),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Color.fromARGB(255, 86, 56, 158),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  petsWithImages.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            "ยังไม่มีข้อมูลสัตว์เลี้ยง",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: petsWithImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage: NetworkImage(
                                        petsWithImages[index]['url'],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      petsWithImages[index]['name'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'VERDANAI',
                                        color: Color.fromARGB(221, 86, 82, 148),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
            
            // ---------------- Dashboard Status ----------------
            GestureDetector(
              onTap: () {
                goAndRefresh(ListBookingAppointment(userId: widget.userId));
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "สถานะการนัดหมาย",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'sarabun-Regular',
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pendingBookingsCount > 0 
                              ? "รอดำเนินการ $pendingBookingsCount รายการ" 
                              : "ไม่มีนัดหมายที่รอดำเนินการ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'sarabun-Regular',
                            color: pendingBookingsCount > 0 
                                ? const Color(0xFFE57373) 
                                : const Color.fromARGB(221, 86, 82, 148),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.pending_actions,
                        color: Color(0xFFE57373),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ------------------------------------------------
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _menu(
                        "จองนัดหมาย",
                        Icons.calendar_today,
                        const Color(0xFFFDE8E8),
                        const Color(0xFFE57373),
                        () => goAndRefresh(
                          BookingAppointmentScreen(userId: widget.userId),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _menu(
                        "แจ้งเหตุ",
                        Icons.campaign,
                        const Color(0xFFFFF9C4),
                        const Color(0xFFD4E157),
                        () => goAndRefresh(
                          RabiesReportListScreen(userId: widget.userId),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _menu(
                        "สัตว์เลี้ยงของฉัน",
                        Icons.pets,
                        const Color(0xFFE0F2F1),
                        const Color(0xFF4DB6AC),
                        () => goAndRefresh(ListPet(ownerId: widget.userId)),
                      ),
                      const SizedBox(height: 12),
                      _menu(
                        "ประวัติการจอง",
                        Icons.history,
                        const Color(0xFFE1F5FE),
                        const Color(0xFF4FC3F7),
                        () => goAndRefresh(
                          BookingHistoryScreen(userId: widget.userId),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(
    String title,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'sarabun-Regular',
              color: Color.fromARGB(221, 52, 49, 95),
            ),
          ),
        ],
      ),
    ),
  );
}
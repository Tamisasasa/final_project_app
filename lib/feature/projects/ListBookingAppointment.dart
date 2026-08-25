import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'HomePage.dart';
import 'ViewProfile.dart';

class ListBookingAppointment extends StatefulWidget {
  final int userId;

  const ListBookingAppointment({super.key, required this.userId});

  @override
  State<ListBookingAppointment> createState() => _ListBookingAppointmentState();
}

class _ListBookingAppointmentState extends State<ListBookingAppointment> {
  final Dio dio = DioClient.dio;
  
  List<dynamic> bookings = [];
  bool isLoading = true;
  int _currentIndex = 1; // เปลี่ยนเป็น 1 เพื่อให้ตรงกับเมนู (รูปเท้าสัตว์)

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      // 1. เปลี่ยนไปเรียก API /current แทน /history
      final response = await dio.get(
        "/bookings/owner/${widget.userId}/current",
      );

      final responseData = response.data;
      List<dynamic> fetchedBookings = [];

      if (responseData is Map) {
        if (responseData["data"] is List) {
          fetchedBookings = responseData["data"];
        } else if (responseData["result"] is List) {
          fetchedBookings = responseData["result"];
        }
      } else if (responseData is List) {
        fetchedBookings = responseData;
      }

      setState(() {
        // 2. กรองข้อมูลเอาเฉพาะที่สถานะเป็น "รอดำเนินการ"
        bookings = fetchedBookings.where((b) {
          if (b is Map) {
            return b["bookingStatus"] == "รอดำเนินการ";
          }
          return false;
        }).toList();
        
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("โหลดไม่สำเร็จ: $e")),
        );
      }
    }
  }

  void goDetail(dynamic booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewBookingAppointment(
          bookingData: Map<String, dynamic>.from(booking),
          userId: widget.userId,
        ),
      ),
    );
  }

  // ฟังก์ชันแปลงสถานะเป็นสี
  Color _getStatusColor(String status) {
    switch (status) {
      case "รอดำเนินการ":
        return Colors.orange;
      case "เสร็จสิ้น":
      case "สำเร็จ":
        return Colors.green;
      case "ยกเลิก":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "ยกเลิก":
        return Icons.cancel;
      case "เสร็จสิ้น":
      case "สำเร็จ":
        return Icons.check_circle;
      case "รอดำเนินการ":
        return Icons.pending_actions;
      default:
        return Icons.calendar_month_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(221, 110, 107, 158)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "รายการนัดหมายที่รอดำเนินการ",
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'sarabun-Regular',
            color: Color.fromARGB(221, 110, 107, 158),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "ไม่มีรายการที่รอดำเนินการ",
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.grey.shade600,
                          fontFamily: 'sarabun-Regular'
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      
                      // 3. แก้ไขการดึงชื่อสัตว์เลี้ยงให้โชว์ถูกต้อง
                      String petName = "ไม่ระบุชื่อ";
                      if (b["bookings"] != null && b["bookings"] is List && b["bookings"].isNotEmpty) {
                        final firstPet = b["bookings"][0]["pet"];
                        if (firstPet != null) {
                          petName = firstPet["petName"] ?? "ไม่ระบุชื่อ";
                        }
                        if (b["bookings"].length > 1) {
                          petName += " และตัวอื่นๆ";
                        }
                      } else if (b["pet"] != null) {
                        petName = b["pet"]["petName"] ?? "ไม่ระบุชื่อ";
                      }

                      final servicePoint = b["servicePoint"] ?? {};
                      final String date = b['bookingDate'] ?? "";
                      final String time = b['bookingTime'] ?? "";
                      final String status = b['bookingStatus'] ?? "ไม่ทราบสถานะ";
                      final String servicePointName = servicePoint["servicePointName"] ?? "-";

                      return GestureDetector(
                        onTap: () => goDetail(b),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getStatusIcon(status),
                                  color: _getStatusColor(status),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "จองคิว: $petName",
                                      style: const TextStyle(
                                        fontFamily: 'sarabun-Regular',
                                        color: Color.fromARGB(221, 110, 107, 158),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "วันที่: $date เวลา: $time น.",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontFamily: 'sarabun-Regular',
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "สถานที่: $servicePointName",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontFamily: 'sarabun-Regular',
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "สถานะ: $status",
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontFamily: 'sarabun-Regular',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(userId: widget.userId),
              ),
            );
          } else if (index == 1) {
            // ดึงข้อมูลซ้ำเมื่อกดเมนูนี้
            fetchBookings();
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ViewProfile(id: widget.userId),
              ),
            );
          }
        },
      ),
    );
  }
}
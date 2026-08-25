import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'HomePage.dart';
import 'ViewProfile.dart';
// นำเข้าหน้า ListBookingAppointment
import 'ListBookingAppointment.dart';

class BookingHistoryScreen extends StatefulWidget {
  final int userId;

  const BookingHistoryScreen({super.key, required this.userId});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final Dio dio = DioClient.dio;
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    _fetchBookingHistory();
  }

  Future<void> _fetchBookingHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await dio.get(
        "/bookings/owner/${widget.userId}/history",
      );

      final responseData = response.data;
      List<dynamic> listData = [];

      if (responseData is Map) {
        if (responseData["data"] is List) {
          listData = responseData["data"];
        } else if (responseData["result"] is List) {
          listData = responseData["result"];
        }
      } else if (responseData is List) {
        listData = responseData;
      }

      setState(() {
        _bookings = listData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching bookings: $e");
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("โหลดข้อมูลไม่สำเร็จ: $e")),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "ยกเลิก":
        return Colors.red;
      case "เสร็จสิ้น":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "ยกเลิก":
        return Icons.cancel;
      case "เสร็จสิ้น":
        return Icons.check_circle;
      default:
        return Icons.info;
    }
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
                builder: (context) => HomePage(userId: widget.userId),
              ),
            );
          } else if (index == 1) {
            // แก้ไขตรงนี้ให้พาไปหน้า ListBookingAppointment ทันที
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListBookingAppointment(userId: widget.userId),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewProfile(id: widget.userId),
              ),
            );
          }
        },
      ),
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ประวัติการจองนัดหมาย",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "ยังไม่มีประวัติการจอง",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchBookingHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      final servicePoint = booking["servicePoint"] ?? {};
                      final status = booking["bookingStatus"] ?? "";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewBookingAppointment(
                                    bookingData: Map<String, dynamic>.from(booking),
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(status).withOpacity(0.1),
                              child: Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                              ),
                            ),
                            title: Text(
                              "รหัสการจอง: ${booking["bookingId"] ?? "-"}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text("วันที่นัด: ${booking["bookingDate"] ?? "-"}"),
                                Text("เวลา: ${booking["bookingTime"] ?? "-"} น."),
                                Text(
                                  "สถานที่: ${servicePoint["servicePointName"] ?? "-"}",
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
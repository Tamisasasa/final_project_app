import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/data/models/RabiesModel.dart';
import 'package:final_project_vaccine/feature/data/services/RabiesService.dart';
import 'HomePage.dart';
import 'ViewProfile.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'package:final_project_vaccine/feature/projects/ViewRabiesOwnerReport.dart';
import 'package:final_project_vaccine/feature/projects/SubmitRabiesOwnerReport.dart';
// นำเข้าหน้า ListBookingAppointment
import 'ListBookingAppointment.dart';

class RabiesReportListScreen extends StatefulWidget {
  final int userId;

  const RabiesReportListScreen({super.key, required this.userId});

  @override
  State<RabiesReportListScreen> createState() => _RabiesReportListScreenState();
}

class _RabiesReportListScreenState extends State<RabiesReportListScreen> {
  final service = RabiesReportService(DioClient.dio);

  List<RabiesReport> reports = [];
  bool isLoading = true;
  int _currentIndex = 2; 

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> goToAddReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RabiesReportScreen(userId: widget.userId),
      ),
    );

    if (result == true) {
      fetchReports();
    }
  }

  Future<void> fetchReports() async {
    try {
      final data = await service.getReportsByOwner(widget.userId);

      setState(() {
        reports = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("โหลดไม่สำเร็จ: $e")));
    }
  }

  void goDetail(RabiesReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewRabiesOwnerReport(
          report: report,
          ownerId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "รายการแจ้งเหตุ",
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'sarabun-Regular',
            color: Color.fromARGB(221, 110, 107, 158),
          ),
        ),
        backgroundColor: const Color(0xFFFFF9C4),
        automaticallyImplyLeading: false, 
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? const Center(child: Text("ไม่มีข้อมูล"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, i) {
                final r = reports[i];

                return GestureDetector(
                  onTap: () => goDetail(r),
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
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.location,
                                style: const TextStyle(
                                  fontFamily: 'sarabun-Regular',
                                  color: Color.fromARGB(221, 110, 107, 158),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "สาเหตุ: ${r.deathCause}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "สถานะ: ${r.reportStatus}",
                                style: TextStyle(
                                  color: r.reportStatus == "PENDING"
                                      ? Colors.orange
                                      : Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToAddReport,
        backgroundColor: const Color(0xFF4FC3F7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
            // พาไปหน้า ListBookingAppointment ทันที
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
    );
  }
}
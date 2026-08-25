import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'package:final_project_vaccine/feature/data/models/RabiesModel.dart';
import 'package:final_project_vaccine/feature/data/services/RabiesService.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'HomePage.dart';
import 'ViewProfile.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'package:dio/dio.dart';
// นำเข้าหน้า ListBookingAppointment
import 'ListBookingAppointment.dart';

class ViewRabiesOwnerReport extends StatefulWidget {
  final RabiesReport report;
  final int ownerId;

  const ViewRabiesOwnerReport({
    super.key,
    required this.report,
    required this.ownerId,
  });

  @override
  State<ViewRabiesOwnerReport> createState() => _ViewRabiesOwnerReportState();
}

class _ViewRabiesOwnerReportState extends State<ViewRabiesOwnerReport> {
  int _currentIndex = 2;
  late RabiesReport currentReport;
  bool isLoadingStatus = false;

  @override
  void initState() {
    super.initState();
    currentReport = widget.report;
    _fetchLatestReportStatus();
  }

  Future<void> _fetchLatestReportStatus() async {
    if (currentReport.reportId == null) return;

    setState(() {
      isLoadingStatus = true;
    });

    try {
      final response = await DioClient.dio.get(
        "/rabies-reports/${currentReport.reportId}",
      );

      final body = response.data;
      if (body == null) return;

      Map<String, dynamic>? reportData;
      if (body is Map) {
        if (body["data"] is Map) {
          reportData = Map<String, dynamic>.from(body["data"]);
        } else if (body["result"] is Map) {
          reportData = Map<String, dynamic>.from(body["result"]);
        } else if (body["location"] != null || body["reportId"] != null) {
          reportData = Map<String, dynamic>.from(body);
        }
      }

      if (reportData != null) {
        setState(() {
          currentReport = RabiesReport.fromJson(reportData!);
        });
      }
    } catch (e) {
      debugPrint("[_fetchLatestReportStatus] error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingStatus = false;
        });
      }
    }
  }

  void _showFullImage(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget item(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              color: Color.fromARGB(221, 44, 41, 82),
              fontFamily: 'sarabun-Regular',
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              softWrap: true,
              style: const TextStyle(
                fontFamily: 'sarabun-Regular',
                color: Color.fromARGB(221, 110, 107, 158),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget rowTwoItems(String title1, String val1, String title2, String val2) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$title1: ",
                  style: const TextStyle(
                    color: Color.fromARGB(221, 44, 41, 82),
                    fontFamily: 'sarabun-Regular',
                  ),
                ),
                Expanded(
                  child: Text(
                    val1.isEmpty ? "-" : val1,
                    style: const TextStyle(
                      fontFamily: 'sarabun-Regular',
                      color: Color.fromARGB(221, 110, 107, 158),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$title2: ",
                  style: const TextStyle(
                    color: Color.fromARGB(221, 44, 41, 82),
                    fontFamily: 'sarabun-Regular',
                  ),
                ),
                Expanded(
                  child: Text(
                    val2.isEmpty ? "-" : val2,
                    style: const TextStyle(
                      fontFamily: 'sarabun-Regular',
                      color: Color.fromARGB(221, 110, 107, 158),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case "PENDING":
      case "รอดำเนินการ":
        return Colors.orange;
      case "APPROVED":
      case "อนุมัติ":
        return Colors.green;
      case "REJECTED":
      case "ไม่อนุมัติ":
        return Colors.red;
      default:
        return Colors.grey;
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
                builder: (context) => HomePage(userId: widget.ownerId),
              ),
            );
          } else if (index == 1) {
            // พาไปหน้า ListBookingAppointment ทันที
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text("รายละเอียดแจ้งเหตุ",
            style: TextStyle(
              fontFamily: 'sarabun-Regular',
              color: Color.fromARGB(221, 44, 41, 82),
            )),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: statusColor(currentReport.reportStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: statusColor(currentReport.reportStatus),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "สถานะ: ${currentReport.reportStatus}",
                      style: TextStyle(
                        color: statusColor(currentReport.reportStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isLoadingStatus)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            item("สถานที่", currentReport.location),
            rowTwoItems(
              "ประเภทสัตว์",
              currentReport.animalType,
              "จำนวน",
              currentReport.numberOfAnimals.toString(),
            ),
            item("สาเหตุการตาย", currentReport.deathCause),
            item("ผู้แจ้ง", currentReport.reporterName),
            item("เบอร์โทร", currentReport.reporterPhoneNumber),
            item(
              "วันที่",
              currentReport.reportDate.toString().split("T")[0],
            ),
            if (currentReport.attachments != null && currentReport.attachments!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "รูปภาพประกอบ (แตะเพื่อดูรูปเต็ม):",
                      style: TextStyle(
                        color: Color.fromARGB(221, 44, 41, 82),
                        fontFamily: 'sarabun-Regular',
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showFullImage(currentReport.attachments!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.black12,
                          child: Image.memory(
                            base64Decode(currentReport.attachments!),
                            fit: BoxFit.cover, 
                            errorBuilder: (context, error, stackTrace) => 
                              const Center(child: Text("ไม่สามารถแสดงรูปภาพได้")),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
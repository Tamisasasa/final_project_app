import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'package:final_project_vaccine/feature/projects/ServiceReview.dart';
import 'EditPet.dart';
import 'HomePage.dart';
import 'ViewProfile.dart';
import 'custom_bottom_bar.dart';
import 'ListBookingAppointment.dart';

class ViewBookingAppointment extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final int userId;

  const ViewBookingAppointment({
    super.key,
    required this.bookingData,
    required this.userId,
  });

  @override
  State<ViewBookingAppointment> createState() => _ViewBookingAppointmentState();
}

class _ViewBookingAppointmentState extends State<ViewBookingAppointment> {
  int currentPage = 1;
  final Dio dio = DioClient.dio;
  bool isDeleting = false;
  Map<String, dynamic> _booking = {};
  int _currentIndex = 2;

  String _calculateAge(String? birthDateStr) {
    if (birthDateStr == null || birthDateStr.isEmpty) return "-";
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final now = DateTime.now();
      int years = now.year - birthDate.year;
      int months = now.month - birthDate.month;
      if (now.day < birthDate.day) months--;
      if (months < 0) {
        years--;
        months += 12;
      }
      if (years > 0)
        return months > 0 ? "$years ปี $months เดือน" : "$years ปี";
      return "$months เดือน";
    } catch (e) {
      return "-";
    }
  }

  // ฟังก์ชันช่วยแปลงคำศัพท์ประเภทสัตว์เลี้ยง
  String _translatePetType(String? type) {
    if (type == null || type.trim().isEmpty) return "-";
    
    String lowerType = type.toLowerCase().trim();
    if (lowerType == 'dog') return 'หมา'; // หรือถ้าอยากให้ทางการใช้ 'สุนัข' แทนได้ครับ
    if (lowerType == 'cat') return 'แมว';
    
    return type; // ถ้าไม่ใช่ dog หรือ cat ให้คืนค่าเดิมกลับไป
  }

  @override
  void initState() {
    super.initState();
    _booking = Map<String, dynamic>.from(widget.bookingData);

    if (widget.bookingData['bookingId'] != null) {
      fetchBookingDetail(widget.bookingData['bookingId']);
    }
  }

  Future<void> fetchBookingDetail(int id) async {
    try {
      final response = await dio.get('/bookings/$id');
      if (response.data != null) {
        var resData = response.data['result'] ?? response.data['data'] ?? response.data;
        if (mounted && resData is Map<String, dynamic>) {
          setState(() {
            _booking = Map<String, dynamic>.from(resData);
          });
        }
      }
    } catch (e) {
      print("Error fetching detail: $e");
    }
  }

  Future<void> _reloadBooking() async {
    try {
      final petOwnerId = widget.bookingData["petOwner"]?["petOwnerId"];
      if (petOwnerId == null) return;

      final res = await dio.get("/bookings/owner/$petOwnerId/current");
      final data = res.data["result"];

      if (mounted) {
        setState(() {
          if (data is List && data.isNotEmpty) {
            final pendingData = data.firstWhere(
              (booking) => booking["bookingStatus"] == "รอดำเนินการ",
              orElse: () => data[0],
            );
            if (pendingData != null)
              _booking = Map<String, dynamic>.from(pendingData);
          } else if (data is Map<String, dynamic> && data.isNotEmpty) {
            _booking = Map<String, dynamic>.from(data);
          }
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> cancelBooking() async {
    final bookingId = _booking["bookingId"];
    if (bookingId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ไม่พบรหัสการจอง")));
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      await dio.post(
        "/bookings/$bookingId/status",
        queryParameters: {"status": "ยกเลิก"},
      );

      await _reloadBooking();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ยกเลิกการนัดหมายสำเร็จแล้ว")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาดในการยกเลิก: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  void showConfirmCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 249, 249, 249),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Text(
                  "ต้องการยกเลิก\nการนัดหมาย",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 90, 85, 137),
                    fontSize: 22,
                    fontFamily: 'sarabun-Regular',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4D4D4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.close, size: 60, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE57373),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "ยกเลิก",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA5D6A7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          cancelBooking();
                        },
                        child: const Text(
                          "ยืนยัน",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<dynamic> _extractPets() {
    List<dynamic> pets = [];
    if (_booking["pets"] is List) {
      pets = _booking["pets"];
    } else if (_booking["pet"] != null) {
      pets = [_booking["pet"]];
    } else if (_booking["bookings"] is List) {
      for (var b in _booking["bookings"]) {
        if (b["pet"] != null) {
          pets.add(b["pet"]);
        } else if (b["pets"] != null && b["pets"] is List) {
          pets.addAll(b["pets"]);
        }
      }
    }
    return pets;
  }

  Future<void> generateAndPrintPdf() async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.sarabunRegular();
    final boldFont = await PdfGoogleFonts.sarabunBold();

    var petOwner = _booking["petOwner"] ?? {};
    var servicePoint = _booking["servicePoint"] ?? {};
    List<dynamic> pets = _extractPets();

    String servicePointName = _booking["appointment"]?["servicePoint"]?["servicePointName"] ?? 
                              servicePoint["servicePointName"] ?? "";
    String officerName = _booking["appointment"]?["officer"]?["officerName"] ?? 
                         _booking["appointment"]?["officerName"] ?? "";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Container(
                  width: 70,
                  height: 70,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      "ตรา",
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  "ใบยืนยันการจองการนัดหมาย",
                  style: pw.TextStyle(font: boldFont, fontSize: 24),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "รหัสการจอง",
                        style: pw.TextStyle(font: boldFont, fontSize: 14),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "${_booking["bookingId"] ?? ""}",
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "ข้อมูลเจ้าของ",
                        style: pw.TextStyle(font: boldFont, fontSize: 14),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "ชื่อเจ้าของ: ${petOwner["fullName"] ?? ""}",
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        "เบอร์โทร: ${petOwner["phoneNumber"] ?? ""}",
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        "ที่อยู่: ${petOwner["address"] ?? ""}",
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Text(
                "สถานะ",
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "วัน: ${_booking["bookingDate"] ?? ""}",
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        "เวลา: ${_booking["bookingTime"] ?? ""}",
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        "จุดบริการวัคซีน: $servicePointName",
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "ผู้รับผิดชอบ: $officerName",
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        "สถานะ: ${_booking["bookingStatus"] ?? ""}",
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        "จำนวนสัตว์เลี้ยง: ${pets.isNotEmpty ? pets.length : 1}",
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Text(
                "ข้อมูลสัตว์เลี้ยง",
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "ชื่อสัตว์เลี้ยง",
                          style: pw.TextStyle(font: boldFont, fontSize: 11),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "ประเภท",
                          style: pw.TextStyle(font: boldFont, fontSize: 11),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "อายุ",
                          style: pw.TextStyle(font: boldFont, fontSize: 11),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "สายพันธุ์",
                          style: pw.TextStyle(font: boldFont, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  if (pets.isEmpty)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text("-", style: pw.TextStyle(font: font, fontSize: 11)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text("-", style: pw.TextStyle(font: font, fontSize: 11)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text("-", style: pw.TextStyle(font: font, fontSize: 11)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text("-", style: pw.TextStyle(font: font, fontSize: 11)),
                        ),
                      ],
                    )
                  else
                    ...pets.map(
                      (pet) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              pet["petName"] ?? "",
                              style: pw.TextStyle(font: font, fontSize: 11),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              // แก้ไขตรงนี้สำหรับการสร้าง PDF
                              _translatePetType(pet["typePet"] ?? pet["type"]),
                              style: pw.TextStyle(font: font, fontSize: 11),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              _calculateAge(pet["birthDate"]),
                              style: pw.TextStyle(font: font, fontSize: 11),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              pet["breed"] ?? "",
                              style: pw.TextStyle(font: font, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Text(
                "หมายเหตุ:",
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                "- กรุณานำเอกสารนี้มาแสดงต่อเจ้าหน้าที่",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                "- กรุณามาก่อนเวลานัดหมาย 10 นาที",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text("ใบยืนยันการจอง"),
            backgroundColor: const Color.fromARGB(221, 86, 82, 148),
          ),
          body: PdfPreview(
            build: (format) => pdf.save(),
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName: 'ใบยืนยันการจอง_${_booking["bookingId"] ?? "doc"}.pdf',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? ownerId = widget.userId;
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
      backgroundColor: const Color.fromARGB(255, 254, 254, 255),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "รายละเอียดการนัดหมาย",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'sarabun-Regular',
                  color: Color.fromARGB(221, 86, 82, 148),
                ),
              ),
              const SizedBox(height: 16),
              currentPage == 1 ? _buildPageOne() : _buildPageTwo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageOne() {
    var petOwner = _booking["petOwner"] ?? {};
    var servicePoint = _booking["servicePoint"] ?? {};
    List<dynamic> pets = _extractPets();

    String servicePointName = _booking["appointment"]?["servicePoint"]?["servicePointName"] ?? 
                              servicePoint["servicePointName"] ?? "";
    String officerName = _booking["appointment"]?["officer"]?["officerName"] ?? 
                         _booking["appointment"]?["officerName"] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("รหัสการจอง"),
        _buildInfoBox("${_booking["bookingId"] ?? ""}"),
        const SizedBox(height: 12),
        _buildLabel("สถานะ:"),
        _buildCardContainer([
          _buildRowInfo("วัน", _booking["bookingDate"] ?? ""),
          _buildRowInfo("เวลา", _booking["bookingTime"] ?? ""),
          _buildRowInfo(
            "จุดบริการวัคซีน",
            servicePointName,
          ),
          _buildRowInfo(
            "ผู้รับผิดชอบ", 
            officerName,
          ),
          _buildRowInfo("สถานะ", _booking["bookingStatus"] ?? ""),
          _buildRowInfo(
            "จำนวนสัตว์เลี้ยง",
            "${pets.isNotEmpty ? pets.length : 1}",
          ),
        ]),
        const SizedBox(height: 16),
        _buildLabel("ข้อมูลเจ้าของ"),
        _buildCardContainer([
          _buildRowInfo("ชื่อเจ้าของ", petOwner["fullName"] ?? ""),
          _buildRowInfo("เบอร์โทร", petOwner["phoneNumber"] ?? ""),
          _buildRowInfo("ที่อยู่", petOwner["address"] ?? ""),
        ]),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () => setState(() => currentPage = 2),
            child: const Text(
              "ถัดไป",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageTwo() {
    List<dynamic> pets = _extractPets();
    String currentStatus = _booking["bookingStatus"] ?? "";

    bool isCompleted = currentStatus == "เสร็จสิ้น";
    bool isCancelled = currentStatus == "ยกเลิก";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("ข้อมูลสัตว์เลี้ยง"),
        if (pets.isEmpty)
          _buildCardContainer([
            _buildRowInfo("ชื่อสัตว์เลี้ยง", "-"),
            _buildRowInfo("ประเภท", "-"),
            _buildRowInfo("อายุ", "-"),
            _buildRowInfo("สายพันธุ์", "-"),
          ])
        else
          ...pets.map(
            (pet) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildCardContainer([
                _buildRowInfo("ชื่อสัตว์เลี้ยง", pet["petName"] ?? ""),
                // แก้ไขตรงนี้สำหรับการแสดงผลบนหน้าแอป
                _buildRowInfo("ประเภท", _translatePetType(pet["typePet"] ?? pet["type"])),
                _buildRowInfo("อายุ", _calculateAge(pet["birthDate"])),
                _buildRowInfo("สายพันธุ์", pet["breed"] ?? ""),
              ]),
            ),
          ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(221, 86, 82, 148),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: generateAndPrintPdf,
            child: const Text(
              "พิมพ์",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'sarabun-Regular',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isCompleted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewScreen(bookingData: _booking),
                  ),
                );
              },
              child: const Text(
                "รีวิวความพึงพอใจ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'sarabun-Regular',
                ),
              ),
            ),
          ),
        ] else if (!isCancelled) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: showConfirmCancelDialog,
              child: const Text(
                "ยกเลิกการนัดหมาย",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontFamily: 'sarabun-Regular',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color.fromARGB(221, 86, 82, 148),
          fontFamily: 'sarabun-Regular',
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRowInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: const Color.fromARGB(255, 116, 105, 172),
              fontFamily: 'sarabun-Regular',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
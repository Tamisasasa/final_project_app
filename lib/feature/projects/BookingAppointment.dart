import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'package:final_project_vaccine/feature/data/models/PetModel.dart';
import 'dart:convert';
import 'HomePage.dart';
import 'ViewProfile.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
// นำเข้าหน้า ListBookingAppointment
import 'ListBookingAppointment.dart';

class BookingAppointmentScreen extends StatefulWidget {
  final int userId;
  const BookingAppointmentScreen({super.key, required this.userId});

  @override
  State<BookingAppointmentScreen> createState() =>
      _BookingAppointmentScreenState();
}

class _BookingAppointmentScreenState extends State<BookingAppointmentScreen> {
  final dio = DioClient.dio;
  List<PetInfo> pets = [];
  int _currentIndex = 4;
  List<PetInfo> selectedPets = [];
  
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> uniqueServicePoints = [];
  Map<String, dynamic>? selectedAppointment;
  List<String> timeList = [];
  String? selectedTime;
  int? targetAppointmentId;
  String? vaccinationMethod = "ฉีดที่จุดบริการ";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  bool _isEligibleAge(DateTime? birthDate) {
    if (birthDate == null) return false;
    try {
      DateTime now = DateTime.now();
      int months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
      if (now.day < birthDate.day) {
        months--;
      }
      return months >= 3;
    } catch (e) {
      return false;
    }
  }

  void updateTimes(Map<String, dynamic>? appointment) {
    if (appointment == null) {
      setState(() {
        timeList = [];
        selectedTime = null;
        targetAppointmentId = null;
      });
      return;
    }

    final selectedSpName = appointment["servicePoint"]?["servicePointName"];
    List<String> allTimes = [];

    for (var item in appointments) {
      final sp = item["servicePoint"];
      if (sp != null && sp["servicePointName"] == selectedSpName) {
        var raw = item["serviceTimePeriod"];
        if (raw != null) {
          if (raw is String) {
            var splitTimes = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
            allTimes.addAll(splitTimes);
          } else if (raw is List) {
            allTimes.addAll(raw.map((e) => e.toString()));
          }
        }
      }
    }

    setState(() {
      timeList = allTimes.toSet().toList();
      selectedTime = null;
      targetAppointmentId = null;
    });
  }

  Future<void> fetchData() async {
    try {
      final petRes = await dio.get(
        "/pet",
        queryParameters: {"petOwnerId": widget.userId},
        options: Options(responseType: ResponseType.plain),
      );

      final appRes = await dio.get(
        "/appointments",
        options: Options(responseType: ResponseType.plain),
      );

      var decodedPetData = jsonDecode(petRes.data);
      var decodedAppData = jsonDecode(appRes.data);

      List<Map<String, dynamic>> loadedAppointments = [];
      if (decodedAppData is List) {
        loadedAppointments = List<Map<String, dynamic>>.from(decodedAppData);
      } else if (decodedAppData is Map) {
        var list = decodedAppData["result"] ?? decodedAppData["data"] ?? [];
        loadedAppointments = List<Map<String, dynamic>>.from(list);
      }

      final Map<String, Map<String, dynamic>> mapUnique = {};
      for (var item in loadedAppointments) {
        final sp = item["servicePoint"];
        if (sp != null) {
          String spName = sp["servicePointName"] ?? "";
          if (spName.isNotEmpty && !mapUnique.containsKey(spName)) {
            mapUnique[spName] = item; 
          }
        }
      }

      setState(() {
        List<dynamic> rawPetList = [];
        if (decodedPetData is List) {
          rawPetList = decodedPetData;
        } else if (decodedPetData is Map) {
          rawPetList = decodedPetData["result"] ?? decodedPetData["data"] ?? [];
        }

        pets = rawPetList
            .map((e) => PetInfo.fromJson(e))
            .where((pet) {
              bool isEligible = (pet.isDeceased != true) && _isEligibleAge(pet.birthDate);
              if (!isEligible) return false;

              var originalPetJson = rawPetList.firstWhere(
                (p) => (p["petId"] ?? p["id"]) == pet.id,
                orElse: () => null,
              );

              if (originalPetJson != null && originalPetJson["bookings"] is List) {
                List bookings = originalPetJson["bookings"];
                bool hasActiveOrCompletedBooking = bookings.any((b) {
                  String status = b["bookingStatus"] ?? "";
                  return status != "ยกเลิก"; 
                });

                if (hasActiveOrCompletedBooking) return false;
              }

              return true;
            })
            .toList();

        appointments = loadedAppointments;
        uniqueServicePoints = mapUnique.values.toList(); 
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Map<String, dynamic>? _getAppointmentForTime(String time) {
    if (selectedAppointment == null) return null;
    final selectedSpName = selectedAppointment!["servicePoint"]?["servicePointName"];

    for (var item in appointments) {
      final sp = item["servicePoint"];
      if (sp != null && sp["servicePointName"] == selectedSpName) {
        var raw = item["serviceTimePeriod"];
        if (raw != null) {
          List<String> times = [];
          if (raw is String) {
            times = raw.split(',').map((e) => e.trim()).toList();
          } else if (raw is List) {
            times = raw.map((e) => e.toString()).toList();
          }

          if (times.contains(time)) {
            return item;
          }
        }
      }
    }
    return null;
  }

  void onSelectTime(String time) {
    var matchedApp = _getAppointmentForTime(time);
    if (matchedApp != null) {
      int quota = matchedApp["appointmentQuota"] ?? 0;
      int booked = matchedApp["bookedCount"] ?? 0;
      int selectedCount = selectedPets.isEmpty ? 1 : selectedPets.length;

      if ((booked + selectedCount) > quota) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ช่วงเวลานี้โควตาไม่เพียงพอสำหรับจำนวนสัตว์เลี้ยงที่เลือก")),
        );
        return;
      }
    }

    setState(() {
      selectedTime = time;
    });

    if (matchedApp != null) {
      setState(() {
        targetAppointmentId = matchedApp["appointmentId"];
        selectedAppointment!["appointmentDate"] = matchedApp["appointmentDate"];
      });
    }
  }

  Future<void> confirmBooking() async {
    if (selectedAppointment == null ||
        selectedPets.isEmpty ||
        selectedTime == null ||
        targetAppointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเลือกข้อมูลให้ครบถ้วน")),
      );
      return;
    }

    try {
      String bookingDate = selectedAppointment!["appointmentDate"] ?? "";
      String rawTime = selectedTime!;
      String bookingTime = rawTime;

      if (rawTime.contains("-")) {
        bookingTime = rawTime.split("-")[0].trim();
      }
      if (bookingTime.length == 5) {
        bookingTime = "$bookingTime:00";
      } else if (bookingTime.length == 4 && bookingTime.contains(":")) {
        bookingTime = "0$bookingTime:00";
      }

      final data = {
        "bookingDate": bookingDate,
        "bookingTime": bookingTime,
        "vaccinationMethod": vaccinationMethod,
        "bookingStatus": "รอดำเนินการ",
        "petIds": selectedPets.map((p) => p.id).toList(),
        "appointmentId": targetAppointmentId,
        "petOwnerId": widget.userId,
        "servicePointId": selectedAppointment!["servicePoint"]?["servicePointId"] ?? 1,
      };

      await dio.post(
        "/bookings",
        data: data,
        options: Options(responseType: ResponseType.plain),
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("สำเร็จ"),
          content: const Text("บันทึกการนัดหมายเรียบร้อยแล้ว"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("ตกลง"),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      String errorMessage = "เกิดข้อผิดพลาดในการจอง";
      
      try {
        final responseData = e.response?.data;
        if (responseData != null) {
          if (responseData is Map && responseData["message"] != null) {
            errorMessage = responseData["message"];
          } else if (responseData is String) {
            final decoded = jsonDecode(responseData);
            if (decoded["message"] != null) {
              errorMessage = decoded["message"];
            }
          }
        }
      } catch (_) {}

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "แจ้งเตือน",
            style: TextStyle(fontFamily: 'sarabun-Regular', color: Colors.redAccent),
          ),
          content: Text(
            errorMessage,
            style: const TextStyle(fontFamily: 'sarabun-Regular', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "ตกลง",
                style: TextStyle(fontFamily: 'sarabun-Regular', fontSize: 16),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("จองไม่สำเร็จ: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color.fromARGB(221, 86, 82, 148);
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListBookingAppointment(userId: widget.userId),
              ),
            );
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
      backgroundColor: const Color(0xFFF0F5FF),
      appBar: AppBar(
        title: const Text(
          "นัดหมายการฉีดวัคซีน",
          style: TextStyle(
            fontFamily: 'sarabun-Regular',
            color: Color.fromARGB(221, 86, 82, 148),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 167, 152, 232),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label("เลือกนัดหมาย"),
                  _box(
                    child: DropdownButton<Map<String, dynamic>>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: selectedAppointment,
                      hint: const Text("กรุณาเลือกนัดหมาย"),
                      items: uniqueServicePoints
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                a["servicePoint"] != null
                                    ? (a["servicePoint"]["servicePointName"] ?? '')
                                    : "",
                                style: const TextStyle(fontFamily: 'sarabun-Regular'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => selectedAppointment = val);
                        updateTimes(val);
                      },
                    ),
                  ),
                  _label("วันที่"),
                  _box(
                    color: Colors.white.withOpacity(0.5),
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          selectedAppointment?["appointmentDate"] ??
                              "วัน/เดือน/ปี",
                          style: TextStyle(
                            color: selectedAppointment != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _label("เลือกสัตว์เลี้ยง"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.shade50),
                    ),
                    child: pets.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "ไม่มีสัตว์เลี้ยงที่สามารถเข้ารับบริการได้",
                              style: TextStyle(color: Colors.grey, fontFamily: 'sarabun-Regular'),
                            ),
                          )
                        : Column(
                            children: pets
                                .map((pet) => _petItem(pet, const Color(0xFFE57373)))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 15),
                  _label("เลือกช่วงเวลา"),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: timeList.map((t) {
                      var appItem = _getAppointmentForTime(t);
                      int quota = appItem?["appointmentQuota"] ?? 0;
                      int booked = appItem?["bookedCount"] ?? 0;
                      int remaining = quota - booked;
                      bool isFull = remaining <= 0;

                      return ChoiceChip(
                        label: Text("$t (เหลือ $remaining)"),
                        selected: selectedTime == t,
                        onSelected: isFull
                            ? null
                            : (v) {
                                if (v) {
                                  onSelectTime(t);
                                } else {
                                  setState(() {
                                    selectedTime = null;
                                    targetAppointmentId = null;
                                  });
                                }
                              },
                        selectedColor: const Color(0xFFFDE8E8),
                        backgroundColor: isFull ? Colors.grey.shade300 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle: TextStyle(
                          color: isFull
                              ? Colors.grey
                              : (selectedTime == t ? const Color(0xFFE57373) : primary),
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _label("รูปแบบการรับวัคซีน"),
                  _methodTile(
                    "ฉีดที่จุดบริการ",
                    const Color.fromARGB(255, 247, 201, 101),
                  ),
                  _methodTile(
                    "รับวัคซีนไปฉีดเอง",
                    const Color.fromARGB(255, 247, 201, 101),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      onPressed: confirmBooking,
                      child: const Text(
                        "ยืนยันการนัดหมาย",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'sarabun-Regular',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 8, left: 5),
        child: Text(
          t,
          style: const TextStyle(
            fontFamily: 'sarabun-Regular',
            color: Color.fromARGB(221, 86, 82, 148),
            fontSize: 18,
          ),
        ),
      );

  Widget _box({required Widget child, Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: child,
      );

  Widget _petItem(PetInfo p, Color c) {
    bool deceased = p.isDeceased ?? false;
    return CheckboxListTile(
      title: Text(
        p.petName ?? "",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'sarabun-Regular',
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            "สายพันธุ์: ${p.breed ?? '-'}",
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'sarabun-Regular',
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            deceased ? "เสียชีวิตแล้ว" : "ยังมีชีวิตอยู่",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'sarabun-Regular',
              color: deceased ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
      value: selectedPets.contains(p),
      activeColor: c,
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      onChanged: (v) =>
          setState(() => v! ? selectedPets.add(p) : selectedPets.remove(p)),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _methodTile(String t, Color c) => RadioListTile(
        title: Text(t, style: const TextStyle(fontFamily: 'sarabun-Regular')),
        value: t,
        groupValue: vaccinationMethod,
        activeColor: c,
        onChanged: (v) => setState(() => vaccinationMethod = v as String),
      );
}
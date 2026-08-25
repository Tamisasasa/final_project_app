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

class RabiesReportScreen extends StatefulWidget {
  final int userId;

  const RabiesReportScreen({super.key, required this.userId});

  @override
  State<RabiesReportScreen> createState() => _RabiesReportScreenState();
}

class _RabiesReportScreenState extends State<RabiesReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final locationController = TextEditingController();
  final numberController = TextEditingController();
  final dateController = TextEditingController();
  final deathCauseController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final service = RabiesReportService(DioClient.dio);

  String selectedAnimal = "แมว";
  DateTime? selectedDate;
  int _currentIndex = 0;
  bool isUserDataLoading = true;
  bool isSubmitting = false; 
  File? image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    locationController.dispose();
    numberController.dispose();
    dateController.dispose();
    deathCauseController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    Future<bool> tryEndpoint(String path) async {
      try {
        final response = await DioClient.dio.get(path);
        debugPrint("[_fetchUserData] GET $path -> ${response.data}");

        final body = response.data;
        if (body == null) return false;

        Map<String, dynamic>? userData;
        if (body is Map) {
          if (body["data"] is Map) {
            userData = Map<String, dynamic>.from(body["data"]);
          } else if (body["result"] is Map) {
            userData = Map<String, dynamic>.from(body["result"]);
          } else if (body["fullName"] != null || body["phoneNumber"] != null) {
            userData = Map<String, dynamic>.from(body);
          }
        }

        if (userData == null) return false;

        final name = (userData["fullName"] ?? "").toString();
        final phone = (userData["phoneNumber"] ?? "").toString();

        if (name.isEmpty && phone.isEmpty) return false;

        setState(() {
          nameController.text = name;
          phoneController.text = phone;
        });
        return true;
      } catch (e) {
        debugPrint("[_fetchUserData] GET $path failed: $e");
        return false;
      }
    }

    bool success = await tryEndpoint("/rabies-reports/pet-owner/${widget.userId}");

    if (!success) {
      await tryEndpoint("/users/${widget.userId}");
    }

    if (mounted) {
      setState(() {
        isUserDataLoading = false;
      });
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
        dateController.text = "${date.year}-${date.month}-${date.day}";
      });
    }
  }

  Future<void> pickImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => image = File(file.path));
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (isSubmitting) return;

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเลือกรูปภาพประกอบการแจ้งเหตุ")),
      );
      return;
    }

    final number = int.tryParse(numberController.text);
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("จำนวนต้องเป็นตัวเลข")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final bytes = await image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final report = RabiesReport(
        reporterName: nameController.text,
        numberOfAnimals: number,
        animalType: selectedAnimal,
        reporterPhoneNumber: phoneController.text,
        reportDate: selectedDate ?? DateTime.now(),
        location: locationController.text,
        deathCause: deathCauseController.text,
        reportStatus: "รอดำเนินการ",
        attachments: base64Image, 
        petOwnerId: widget.userId,
      );

      await service.createReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ส่งสำเร็จ")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ผิดพลาด: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Widget input(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final isLockedField = readOnly && (controller == nameController || controller == phoneController);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color.fromARGB(221, 86, 82, 148),
                fontFamily: 'sarabun-Regular',
              ),
            ),
            if (isLockedField && isUserDataLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(fontFamily: 'sarabun-Regular'),
          validator: (v) => v == null || v.isEmpty ? "กรุณากรอกข้อมูล" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: isLockedField
                ? const Color.fromARGB(255, 235, 230, 232)
                : const Color.fromARGB(255, 247, 241, 243),
            suffixIcon: readOnly && controller == dateController 
                ? const Icon(Icons.calendar_today) 
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget animal(String text) {
    final selected = selectedAnimal == text;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedAnimal = text),
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4DB6AC) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4DB6AC)),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF4DB6AC),
              ),
            ),
          ),
        ),
      ),
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          "แจ้งเหตุ",
          style: TextStyle(
            fontFamily: 'sarabun-Regular',
            color: Color.fromARGB(221, 86, 82, 148),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              input("สถานที่", locationController),
              Row(children: [animal("สุนัข"), animal("แมว")]),
              const SizedBox(height: 12),
              input("จำนวน", numberController),
              input(
                "วันที่เกิดเหตุ",
                dateController,
                readOnly: true,
                onTap: pickDate,
              ),
              input("สาเหตุการตาย", deathCauseController, maxLines: 2),
              const Divider(color: Colors.grey, thickness: 1),
              input("ชื่อผู้แจ้ง", nameController, readOnly: true),
              input("เบอร์โทร", phoneController, readOnly: true),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: isSubmitting ? null : pickImage,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: image == null
                      ? const Center(child: Icon(Icons.camera_alt))
                      : Image.file(image!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "กำลังดำเนินการลง DB...",
                              style: TextStyle(fontFamily: 'sarabun-Regular'),
                            ),
                          ],
                        )
                      : const Text("ส่งรายงาน"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
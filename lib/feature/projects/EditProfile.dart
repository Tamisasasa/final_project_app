import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/data/services/RegisterService.dart';
import 'HomePage.dart';
import 'ViewProfile.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'ListBookingAppointment.dart';

class EditProfile extends StatefulWidget {
  final int userId;

  const EditProfile({super.key, required this.userId});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final RegisterService service = RegisterService();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = true;
  int _currentIndex = 3;

  final idCardController = TextEditingController();
  final fullNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  DateTime? selectedBirthDate;

  final Color primaryColor = const Color.fromARGB(221, 86, 82, 148);

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    try {
      final user = await service.getPetOwner(widget.userId);

      idCardController.text = user.idCard;
      fullNameController.text = user.fullName;
      emailController.text = user.email ?? "";
      phoneController.text = user.phoneNumber;
      addressController.text = user.address;

      selectedBirthDate = DateTime.parse(user.birthDate);
      birthDateController.text = DateFormat(
        "yyyy-MM-dd",
      ).format(selectedBirthDate!);

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      await service.editProfile(
        id: widget.userId,
        idCard: idCardController.text,
        fullName: fullNameController.text,
        birthDate: selectedBirthDate!,
        email: emailController.text,
        phoneNumber: phoneController.text,
        address: addressController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("บันทึกสำเร็จ")));
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data.toString() ?? "Error")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color.fromARGB(255, 255, 255, 255),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFE0F2F1), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFE0F2F1), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFE0F2F1), width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
      backgroundColor: const Color.fromARGB(255, 250, 250, 255),
      appBar: AppBar(
        title: const Text(
          "แก้ไขข้อมูลส่วนตัว",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontFamily: 'sarabun-Regular',
          ),
        ),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "เลขประจำตัวประชาชน",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'sarabun-Regular',
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: idCardController,
                style: const TextStyle(
                  fontFamily: 'sarabun-Regular',
                  color: Color.fromARGB(221, 86, 82, 148),
                ),
                decoration: input("กรอกเลขบัตร 13 หลัก"),
                validator: (v) => v!.length < 13 ? "กรอกให้ครบ 13 หลัก" : null,
              ),
              const SizedBox(height: 16),

              // --- ช่องชื่อ ---
              const Text(
                "ชื่อ-นามสกุล",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'sarabun-Regular',
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: fullNameController,
                style: const TextStyle(
                  fontFamily: 'sarabun-Regular',
                  color: Color.fromARGB(221, 86, 82, 148),
                ),
                decoration: input("กรอกชื่อ-นามสกุล"),
                validator: (v) => v!.isEmpty ? "กรอกชื่อ" : null,
              ),
              const SizedBox(height: 16),

              const Text(
                "วันเกิด",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'sarabun-Regular',
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: birthDateController,
                readOnly: true,
                style: const TextStyle(
                  fontFamily: 'sarabun-Regular',
                  color: Color.fromARGB(221, 86, 82, 148),
                ),
                decoration: input("เลือกวันเกิด"),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedBirthDate ?? DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    selectedBirthDate = picked;
                    birthDateController.text = DateFormat(
                      "yyyy-MM-dd",
                    ).format(picked);
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 16),

              const Text(
                "อีเมล",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'sarabun-Regular',
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress, 
                style: const TextStyle(
                  fontFamily: 'sarabun-Regular',
                  color: Color.fromARGB(221, 86, 82, 148),
                ),
                decoration: input("กรอกอีเมล"),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    bool emailValid = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(v);
                    if (!emailValid) {
                      return "รูปแบบอีเมลไม่ถูกต้อง (ต้องมี @ และ .com)";
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                "เบอร์โทรศัพท์",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'sarabun-Regular',
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: const TextStyle(
                  fontFamily: 'sarabun-Regular',
                  color: Color.fromARGB(221, 86, 82, 148),
                ),
                decoration: input("กรอกเบอร์โทรศัพท์ 10 หลัก").copyWith(
                  counterText: "", 
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "กรุณากรอกเบอร์โทรศัพท์";
                  }
                  if (v.length != 10) {
                    return "เบอร์โทรศัพท์ต้องมี 10 หลัก";
                  }
                  if (!v.startsWith('0')) {
                    return "เบอร์โทรศัพท์ต้องขึ้นต้นด้วยเลข 0";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            
              const Text(
                "ที่อยู่",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'sarabun-Regular',
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: addressController,
                style: const TextStyle(
                  fontFamily: 'sarabun-Regular',
                  color: Color.fromARGB(221, 86, 82, 148),
                ),
                decoration: input("กรอกที่อยู่"),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDE8E8),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: handleSave,
                child: const Text(
                  "บันทึก",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFFE57373),
                    fontFamily: 'sarabun-Regular',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/data/services/RegisterService.dart';
import 'package:final_project_vaccine/feature/projects/Login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final RegisterService _registerService = RegisterService();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  DateTime? selectedBirthDate;
  bool _obscurePassword = true;

  final idCardController = TextEditingController();
  final fullNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();

  final Color primaryColor = const Color.fromARGB(221, 86, 82, 148);

  @override
  void dispose() {
    idCardController.dispose();
    fullNameController.dispose();
    birthDateController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedBirthDate == null) {
      _showSnackBar("กรุณาเลือกวันเกิด", Colors.red);
      return;
    }

    try {
      setState(() => isLoading = true);

      await _registerService.createMember(
        idCard: idCardController.text,
        fullName: fullNameController.text,
        birthDate: selectedBirthDate!,
        email: emailController.text,
        phoneNumber: phoneController.text,
        password: passwordController.text,
        address: addressController.text,
      );

      if (mounted) {
        _showSnackBar("ลงทะเบียนสำเร็จ", Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    } on DioException catch (e) {
      String errorMsg = "สมัครสมาชิกไม่สำเร็จ (400 Bad Request)";
      if (e.response?.data != null) {
        errorMsg = e.response?.data.toString() ?? errorMsg;
      }
      if (mounted) _showSnackBar(errorMsg, Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'sarabun-Regular'),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color.fromARGB(255, 241, 249, 253),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color.fromARGB(255, 165, 227, 255), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color.fromARGB(255, 165, 227, 255), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color.fromARGB(255, 165, 227, 255), width: 2.0),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'sarabun-Regular',
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 255),
      appBar: AppBar(
        title: const Text(
          "สมัครสมาชิก",
          style: TextStyle(
            fontFamily: 'sarabun-Regular',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/image/logo.jpg',
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "สร้างบัญชีผู้ใช้งานใหม่",
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'sarabun-Regular',
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel("เลขบัตรประชาชน *"),
                    TextFormField(
                      controller: idCardController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [LengthLimitingTextInputFormatter(13)],
                      style: TextStyle(fontFamily: 'sarabun-Regular', color: primaryColor),
                      decoration: _buildInputDecoration("13 หลัก"),
                      validator: (v) =>
                          v!.length < 13 ? "กรุณากรอกให้ครบ 13 หลัก" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("ชื่อ-นามสกุล *"),
                    TextFormField(
                      controller: fullNameController,
                      style: TextStyle(fontFamily: 'sarabun-Regular', color: primaryColor),
                      decoration: _buildInputDecoration("กรอกชื่อ-นามสกุล"),
                      validator: (v) =>
                          v!.isEmpty ? "กรุณากรอกชื่อ-นามสกุล" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("วันเกิด *"),
                    TextFormField(
                      controller: birthDateController,
                      readOnly: true,
                      style: TextStyle(fontFamily: 'sarabun-Regular', color: primaryColor),
                      decoration: _buildInputDecoration(
                        "เลือกวันที่",
                        suffixIcon: Icon(Icons.calendar_today, color: primaryColor),
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          selectedBirthDate = picked;
                          birthDateController.text = DateFormat(
                            "yyyy-MM-dd",
                          ).format(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("อีเมล"),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontFamily: 'sarabun-Regular', color: primaryColor),
                      decoration: _buildInputDecoration("example@mail.com"),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("เบอร์โทรศัพท์ *"),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontFamily: 'sarabun-Regular', color: primaryColor),
                      decoration: _buildInputDecoration("กรอกเบอร์โทรศัพท์"),
                      validator: (v) =>
                          v!.isEmpty ? "กรุณากรอกเบอร์โทรศัพท์" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("รหัสผ่าน *"),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(fontFamily: 'sarabun-Regular', color: primaryColor),
                      decoration: _buildInputDecoration(
                        "รหัสผ่านอย่างน้อย 6 ตัวอักษร",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: primaryColor,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) => v!.length < 6
                          ? "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("ที่อยู่ *"),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      style: TextStyle(fontFamily: 'sarabun-Regular', color: primaryColor),
                      decoration: _buildInputDecoration("กรอกที่อยู่ของคุณ"),
                      validator: (v) => v!.isEmpty ? "กรุณากรอกที่อยู่" : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC3F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _handleRegister,
                        child: const Text(
                          "REGISTER",
                          style: TextStyle(
                            color: Color(0xFFE1F5FE),
                            fontSize: 18,
                            fontFamily: 'sarabun-Regular',
                            fontWeight: FontWeight.bold,
                          ),
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
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:final_project_vaccine/feature/data/services/PetService.dart';
import 'ViewProfile.dart';
import 'ViewPet.dart';
import 'HomePage.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
// นำเข้าหน้า ListBookingAppointment
import 'ListBookingAppointment.dart'; 

class AddpetInfo extends StatefulWidget {
  final int ownerId;

  const AddpetInfo({super.key, required this.ownerId});

  @override
  State<AddpetInfo> createState() => _AddpetInfoState();
}

class _AddpetInfoState extends State<AddpetInfo> {
  final PetService addPetService = PetService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String? selectedImageName;
  DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  DateTime? selectedBirthDate;
  int _currentIndex = 4;

  bool isLoading = false;
  String selectedGender = "Male";
  String selectedType = "Dog";

  late TextEditingController petNameController;
  late TextEditingController breedController;
  late TextEditingController birthDateController;
  late TextEditingController weightController;
  late TextEditingController heightController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    petNameController = TextEditingController();
    breedController = TextEditingController();
    birthDateController = TextEditingController();
    weightController = TextEditingController();
    heightController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    petNameController.dispose();
    breedController.dispose();
    birthDateController.dispose();
    weightController.dispose();
    heightController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    List<String> image = ["1.jpg", "2.jpg", "3.jpg","4.jpg", "5.jpg", "6.jpg"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("เลือกรูปภาพ"),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: image.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                setState(() => selectedImageName = image[index]);
                Navigator.pop(context);
              },
              child: Image.asset("assets/image/${image[index]}"),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color.fromARGB(255, 255, 255, 255),
        fontWeight: FontWeight.bold,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBDC9FF), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF5C79FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: 'sarabun-Regular',
            color: Color.fromARGB(221, 86, 82, 148),
            fontSize: 16,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedBirthDate == null) {
      _showSnackBar("กรุณาเลือกวันเกิด", Colors.orange);
      return;
    }

    try {
      setState(() => isLoading = true);

      await addPetService.createPetInfo(
        ownerId: widget.ownerId,
        petName: petNameController.text,
        breed: breedController.text,
        birthDate: selectedBirthDate!,
        weight: double.tryParse(weightController.text) ?? 0,
        height: double.tryParse(heightController.text) ?? 0,
        gender: selectedGender,
        typePet: selectedType,
        description: descriptionController.text,
        imagePet: selectedImageName ?? "default.png",
      );

      if (mounted) {
        _showSnackBar("เพิ่มสัตว์เลี้ยงสำเร็จ", Colors.green);
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      _showSnackBar(e.response?.data.toString() ?? "Error", Colors.red);
    } catch (e) {
      _showSnackBar("เกิดข้อผิดพลาดในการบันทึกข้อมูล", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color.fromARGB(255, 253, 252, 236),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: selectedImageName != null
                                        ? AssetImage(
                                            "assets/image/$selectedImageName",
                                          )
                                        : null,
                                    child: selectedImageName == null
                                        ? Icon(
                                            Icons.pets,
                                            size: 60,
                                            color: Colors.grey[400],
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE57373),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildLabel("ชื่อสัตว์เลี้ยง"),
                          TextFormField(
                            controller: petNameController,
                            decoration: _buildInputDecoration(""),
                            validator: (v) =>
                                v!.isEmpty ? "กรอกชื่อสัตว์เลี้ยง" : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("ประเภทสัตว์เลี้ยง"),
                                    DropdownButtonFormField<String>(
                                      value: selectedType,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontFamily: 'sarabun-Regular',
                                        fontSize: 16,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: "Dog",
                                          child: Text("สุนัข"),
                                        ),
                                        DropdownMenuItem(
                                          value: "Cat",
                                          child: Text("แมว"),
                                        ),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => selectedType = v!),
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFBDC9FF),
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF5C79FF),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("สายพันธุ์"),
                                    TextFormField(
                                      controller: breedController,
                                      decoration: _buildInputDecoration(""),
                                      validator: (v) => v!.isEmpty ? "ระบุสายพันธุ์" : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildLabel("วันเกิด"),
                          TextFormField(
                            controller: birthDateController,
                            readOnly: true,
                            decoration: _buildInputDecoration(
                              "",
                              suffixIcon: const Icon(Icons.calendar_month),
                            ),
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                selectedBirthDate = picked;
                                birthDateController.text = dateFormat.format(
                                  picked,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("น้ำหนัก(กก.)"),
                                    TextFormField(
                                      controller: weightController,
                                      keyboardType: TextInputType.number,
                                      decoration: _buildInputDecoration(""),
                                      // --- เพิ่ม Validator เช็คน้ำหนักตรงนี้ ---
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "ระบุน้ำหนัก";
                                        }
                                        final double? weight = double.tryParse(value);
                                        if (weight == null) {
                                          return "ตัวเลขเท่านั้น";
                                        }
                                        if (weight <= 0) {
                                          return "ต้องมากกว่า 0";
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel("ส่วนสูง(ซม.)"),
                                    TextFormField(
                                      controller: heightController,
                                      keyboardType: TextInputType.number,
                                      decoration: _buildInputDecoration(""),
                                      // --- เพิ่ม Validator เช็คส่วนสูงด้วย ---
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "ระบุส่วนสูง";
                                        }
                                        final double? height = double.tryParse(value);
                                        if (height == null) {
                                          return "ตัวเลขเท่านั้น";
                                        }
                                        if (height <= 0) {
                                          return "ต้องมากกว่า 0";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "วัดเมื่อสัตว์เลี้ยงยืน 4 ขา",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontFamily: 'sarabun-Regular',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildLabel("เพศ"),
                          DropdownButtonFormField<String>(
                            value: selectedGender,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontFamily: 'sarabun-Regular',
                              fontSize: 16,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "Male",
                                child: Text("เพศผู้"),
                              ),
                              DropdownMenuItem(
                                value: "Female",
                                child: Text("เพศเมีย"),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => selectedGender = v!),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBDC9FF),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF5C79FF),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildLabel("รายละเอียด"),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: _buildInputDecoration(""),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE57373),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "บันทึกสัตว์เลี้ยง",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontFamily: 'VERDANAI',
                                  color: Color.fromARGB(255, 255, 241, 241),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
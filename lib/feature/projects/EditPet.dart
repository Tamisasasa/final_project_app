import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:final_project_vaccine/feature/data/models/PetModel.dart';
import 'package:final_project_vaccine/feature/data/services/PetService.dart';
import 'HomePage.dart';
import 'ViewProfile.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'ListBookingAppointment.dart';

class EditPetPage extends StatefulWidget {
  final PetInfo pet;

  const EditPetPage({super.key, required this.pet});

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();
  final PetService _service = PetService();
  int _currentIndex = 4;

  late TextEditingController nameCtrl;
  late TextEditingController breedCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController heightCtrl;
  late TextEditingController descCtrl;
  late TextEditingController birthDateCtrl;

  DateTime? birthDate;
  String gender = "Male";
  bool isDeceased = false;
  bool isLoading = false;
  String? _selectedImageName;
  DateFormat dateFormat = DateFormat("yyyy-MM-dd");

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.pet.petName);
    breedCtrl = TextEditingController(text: widget.pet.breed);
    weightCtrl = TextEditingController(text: widget.pet.weight?.toString());
    heightCtrl = TextEditingController(text: widget.pet.height?.toString());
    descCtrl = TextEditingController(text: widget.pet.description);

    birthDate = widget.pet.birthDate;
    birthDateCtrl = TextEditingController(
      text: birthDate != null ? dateFormat.format(birthDate!) : "",
    );

    gender = widget.pet.gender ?? "Male";
    isDeceased = widget.pet.isDeceased ?? false;
  }

  // ปรับปรุงฟังก์ชันเลือกรูปภาพให้แสดง 1.jpg ถึง 6.jpg ครบถ้วน
  Future<void> _pickImage() async {
    List<String> images = ["1.jpg", "2.jpg", "3.jpg", "4.jpg", "5.jpg", "6.jpg"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "เลือกรูปภาพ",
          style: TextStyle(fontFamily: 'sarabun-Regular'),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                setState(() => _selectedImageName = images[index]);
                Navigator.pop(context);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/image/${images[index]}",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirmDialog() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ยืนยันการบันทึก", style: TextStyle(fontFamily: 'sarabun-Regular')),
        content: const Text("แน่ใจว่าข้อมูลถูกต้องแล้วใช่หรือไม่?", style: TextStyle(fontFamily: 'sarabun-Regular')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey, fontFamily: 'sarabun-Regular')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 85, 76, 168),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              updatePet();
            },
            child: const Text("ยืนยัน", style: TextStyle(color: Colors.white, fontFamily: 'sarabun-Regular')),
          ),
        ],
      ),
    );
  }

  Future<void> updatePet() async {
    try {
      setState(() => isLoading = true);

      print("🚀 กำลังส่งค่า isDeceased ไปหลังบ้าน: $isDeceased");

      await _service.updatePet(
        ownerId: widget.pet.petOwnerId!,
        id: widget.pet.id!,
        petName: nameCtrl.text,
        breed: breedCtrl.text,
        birthDate: birthDate ?? DateTime.now(),
        weight: double.tryParse(weightCtrl.text) ?? 0.0,
        height: double.tryParse(heightCtrl.text) ?? 0.0,
        typePet: widget.pet.typePet ?? "",
        description: descCtrl.text,
        gender: gender,
        imagePet: _selectedImageName ?? widget.pet.imagePet ?? "1.jpg",
        isDeceased: isDeceased, 
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("❌ Error updating pet: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาดในการบันทึก")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'sarabun-Regular',
        color: Color.fromARGB(221, 86, 82, 148),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBDC9FF), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5C79FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'sarabun-Regular',
          color: Color.fromARGB(221, 86, 82, 148),
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? ownerId = widget.pet.petOwnerId;
    return Scaffold(
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0 && ownerId != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(userId: ownerId)));
          } else if (index == 1 && ownerId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListBookingAppointment(userId: ownerId),
              ),
            );
          } else if (index == 3 && ownerId != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ViewProfile(id: ownerId)));
          }
        },
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "แก้ไขข้อมูลสัตว์เลี้ยง",
          style: TextStyle(
            fontFamily: 'sarabun-Regular',
            color: Color.fromARGB(255, 97, 96, 141),
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
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
                              backgroundImage: _selectedImageName != null
                                  ? AssetImage("assets/image/$_selectedImageName") as ImageProvider
                                  : (widget.pet.imagePet != null && widget.pet.imagePet!.isNotEmpty
                                      ? AssetImage("assets/image/${widget.pet.imagePet}") as ImageProvider
                                      : NetworkImage('${DioClient.dio.options.baseUrl}/pet/${widget.pet.id}/image_pet') as ImageProvider),
                            ),
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: Colors.indigo,
                                radius: 18,
                                child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel("ชื่อสัตว์เลี้ยง"),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: _buildInputDecoration(""),
                      validator: (v) => v == null || v.isEmpty ? "กรุณากรอกชื่อสัตว์เลี้ยง" : null,
                    ),
                    _buildLabel("สายพันธุ์"),
                    TextFormField(
                      controller: breedCtrl,
                      decoration: _buildInputDecoration(""),
                      validator: (v) => v == null || v.isEmpty ? "กรุณาระบุสายพันธุ์" : null,
                    ),
                    _buildLabel("วันเกิด"),
                    TextFormField(
                      controller: birthDateCtrl,
                      readOnly: true,
                      decoration: _buildInputDecoration("", suffixIcon: const Icon(Icons.calendar_month)),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: birthDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            birthDate = picked;
                            birthDateCtrl.text = dateFormat.format(picked);
                          });
                        }
                      },
                    ),
                    _buildLabel("น้ำหนัก (kg)"),
                    TextFormField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(""),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณาระบุน้ำหนัก";
                        }
                        final double? weight = double.tryParse(value);
                        if (weight == null) {
                          return "กรุณากรอกเป็นตัวเลขเท่านั้น";
                        }
                        if (weight <= 0) {
                          return "น้ำหนักต้องมากกว่า 0";
                        }
                        return null;
                      },
                    ),
                    _buildLabel("เพศ"),
                    DropdownButtonFormField<String>(
                      value: gender,
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("เพศผู้")),
                        DropdownMenuItem(value: "Female", child: Text("เพศเมีย")),
                      ],
                      onChanged: (v) => setState(() => gender = v!),
                      decoration: _buildInputDecoration(""),
                    ),
                    _buildLabel("รายละเอียด"),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: _buildInputDecoration(""),
                    ),
                    
                    const SizedBox(height: 15),

                    CheckboxListTile(
                      title: const Text(
                        "สัตว์เลี้ยงเสียชีวิตแล้ว",
                        style: TextStyle(fontFamily: 'sarabun-Regular', color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      value: isDeceased,
                      onChanged: (widget.pet.isDeceased == true) 
                          ? null 
                          : (val) => setState(() => isDeceased = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 85, 76, 168),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: _showConfirmDialog,
                        child: const Text(
                          "บันทึกการแก้ไข",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'sarabun-Regular'),
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
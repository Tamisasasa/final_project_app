import 'package:flutter/material.dart';
import 'package:final_project_vaccine/feature/projects/Homepage.dart';
import 'package:final_project_vaccine/feature/projects/Register.dart';
import 'package:final_project_vaccine/feature/data/services/RegisterService.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final RegisterService _service = RegisterService();

  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final Color primaryColor = const Color.fromARGB(221, 86, 82, 148);

  Future<void> _handleLogin() async {
    String idCard = _idCardController.text.trim();
    String password = _passwordController.text.trim();

    if (idCard.isEmpty || password.isEmpty) {
      _showSnackBar("กรุณากรอกข้อมูลให้ครบ", Colors.orange);
      return;
    }

    if (idCard.length != 13) {
      _showSnackBar("เลขบัตรต้อง 13 หลัก", Colors.orange);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final user = await _service.login(idCard, password);

      if (user != null) {
        _showSnackBar("เข้าสู่ระบบสำเร็จ", Colors.green);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(userId: user.petOwnerId)),
        );
      } else {
        _showSnackBar("เลขบัตรหรือรหัสผ่านไม่ถูกต้อง", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  InputDecoration _input(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBDC9FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5C79FF), width: 2),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        "$text *",
        style: TextStyle(
          color: primaryColor,
          fontFamily: 'sarabun-Regular',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idCardController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/image/logo.jpg',
                        height: 85,
                        width: 85,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'sarabun-Regular',
                        color: Color.fromARGB(221, 86, 82, 148),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "ยินดีต้อนรับเข้าสู่ระบบ",
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'sarabun-Regular',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label("เลขบัตรประชาชน"),
                  TextField(
                    controller: _idCardController,
                    keyboardType: TextInputType.number,
                    maxLength: 13,
                    decoration: _input("เลขบัตร 13 หลัก"),
                  ),
                  _label("รหัสผ่าน"),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _input(
                      "รหัสผ่าน",
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "LOG IN",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'sarabun-Regular',
                          color: Color(0xFFE1F5FE),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Divider(color: Colors.grey, thickness: 1),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Register()),
                        );
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'sarabun-Regular',
                          color: Color(0xFF4FC3F7),
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
}
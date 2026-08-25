import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:final_project_vaccine/feature/core/network/dio_client.dart';
import 'ViewBookingAppointment.dart';
import 'custom_bottom_bar.dart';
import 'ViewProfile.dart';
import 'ViewPet.dart';
import 'HomePage.dart';
// นำเข้าหน้า ListBookingAppointment
import 'ListBookingAppointment.dart';

class ReviewScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const ReviewScreen({super.key, required this.bookingData});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _selectedRating = 5.0;
  final TextEditingController _recommendController = TextEditingController();
  final Dio dio = DioClient.dio;
  int _currentIndex = 4;
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  int? get _ownerId {
    final petOwner = widget.bookingData["petOwner"];
    if (petOwner != null && petOwner["petOwnerId"] != null) {
      return petOwner["petOwnerId"];
    }
    return widget.bookingData["userId"];
  }

  Future<void> _checkExistingReview() async {
    final bookingId = widget.bookingData["bookingId"];
    final localReview = widget.bookingData["review"];

    debugPrint("🔍 [Review Check] bookingId = $bookingId (type: ${bookingId.runtimeType})");
    debugPrint("🔍 [Review Check] localReview จาก bookingData = $localReview");

    if (localReview != null) {
      debugPrint("✅ [Review Check] เจอ localReview -> hasReviewed = true");
      setState(() {
        _hasReviewed = true;
        _selectedRating = (localReview["reviewScore"] ?? 5.0).toDouble();
        _recommendController.text = localReview["reviewRecommend"] ?? "";
        _isLoading = false;
      });
      return;
    }

    if (bookingId == null) {
      debugPrint("⚠️ [Review Check] bookingId เป็น null -> ข้ามการเช็ค API");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await dio.get("/reviews/booking/$bookingId");

      debugPrint("🔍 [Review Check] API status code = ${response.statusCode}");
      debugPrint("🔍 [Review Check] API response.data = ${response.data}");

      if (response.data != null &&
          response.data["status"] == true &&
          response.data["data"] != null) {
        final reviewData = response.data["data"];
        debugPrint("✅ [Review Check] API เจอรีวิวเดิม -> hasReviewed = true");
        setState(() {
          _hasReviewed = true;
          _selectedRating = (reviewData["reviewScore"] ?? 5.0).toDouble();
          _recommendController.text = reviewData["reviewRecommend"] ?? "";
          _isLoading = false;
        });
      } else {
        debugPrint("❌ [Review Check] API ตอบมาแต่ status ไม่ true หรือ data เป็น null -> hasReviewed = false");
        setState(() {
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      debugPrint(
        "❌ [Review Check] DioException: statusCode=${e.response?.statusCode}, "
        "data=${e.response?.data}, message=${e.message}",
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ [Review Check] Unknown error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_hasReviewed) return;

    final bookingId = widget.bookingData["bookingId"];
    final petOwner = widget.bookingData["petOwner"] ?? {};
    final petOwnerId = petOwner["petOwnerId"] ?? _ownerId;

    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่พบรหัสการจอง")),
      );
      return;
    }

    if (petOwnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่พบรหัสเจ้าของสัตว์เลี้ยง")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await dio.post(
        "/reviews",
        data: {
          "reviewScore": _selectedRating,
          "reviewRecommend": _recommendController.text.trim(),
          "bookingId": bookingId,
          "petOwnerId": petOwnerId,
        },
      );

      if (!mounted) return;

      if (response.data["status"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data["message"] ?? "บันทึกการรีวิวสำเร็จ"),
          ),
        );
        
        setState(() {
          _hasReviewed = true;
          _isSubmitting = false;
        });
      } else {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data["message"] ?? "เกิดข้อผิดพลาด")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการส่งข้อมูล: $e")),
      );
    }
  }

  Widget _buildStars({required bool interactive}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final filled = index < _selectedRating;
        final icon = Icon(
          filled ? Icons.star : Icons.star_border,
          size: 40,
          color: const Color(0xFFE59373),
        );
        if (!interactive) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: icon,
          );
        }
        return IconButton(
          icon: icon,
          onPressed: () {
            setState(() {
              _selectedRating = (index + 1).toDouble();
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? ownerId = _ownerId;
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
            // แก้ไขตรงนี้ให้พาไปหน้า ListBookingAppointment ทันที
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
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context, true),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        _hasReviewed ? "คะแนนรีวิวของคุณ" : "ให้คะแนนความพึงพอใจ",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C79FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildStars(interactive: !_hasReviewed),

                    if (_hasReviewed) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "${_selectedRating.toStringAsFixed(0)} / 5 ดาว",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(color: Colors.blue, thickness: 1),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        "เพิ่มเติม",
                        style: const TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ),

                    if (_hasReviewed)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.blue.shade200, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _recommendController.text.trim().isEmpty
                              ? "ไม่มีความคิดเห็นเพิ่มเติม"
                              : _recommendController.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: _recommendController.text.trim().isEmpty
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.blue.shade200, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: _recommendController,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "พิมพ์รายละเอียดเพิ่มเติมที่นี่...",
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                    if (!_hasReviewed) ...[
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5C79FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isSubmitting ? null : _submitReview,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "ส่งรีวิว",
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          "คุณได้ส่งรีวิวสำหรับการจองนี้แล้ว",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
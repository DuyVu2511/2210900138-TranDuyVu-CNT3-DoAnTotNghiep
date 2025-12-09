import 'package:flutter/material.dart';
// Import các màn hình cần thiết
import '../../main_screen.dart'; // Màn hình chính chứa Bản đồ & Danh sách
import '../auth/screens/login_screen.dart'; // Màn hình Đăng nhập
import '../auth/services/auth_service.dart'; // Service để kiểm tra user

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Gọi hàm kiểm tra đăng nhập
  }

  // Hàm kiểm tra trạng thái đăng nhập
  _checkLoginStatus() async {
    // 1. Chờ 3 giây để hiển thị Logo cho đẹp
    await Future.delayed(const Duration(seconds: 3));

    // 2. Kiểm tra xem trong máy đã lưu thông tin người dùng chưa
    final authService = AuthService();
    final user = await authService.getCurrentUser();

    // Kiểm tra màn hình còn tồn tại không trước khi chuyển trang (tránh lỗi)
    if (!mounted) return;

    // 3. Điều hướng dựa trên kết quả
    if (user != null) {
      // Đã đăng nhập -> Vào thẳng Màn hình chính
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // Chưa đăng nhập (hoặc lần đầu mở) -> Vào màn hình Đăng nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- LOGO APP ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.redAccent,
              ),
            ),

            const SizedBox(height: 20),

            // --- TÊN APP ---
            const Text(
              "Disaster Warning",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              "Cảnh báo thiên tai & Cứu hộ",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 50),

            // --- VÒNG QUAY LOADING ---
            const CircularProgressIndicator(
              color: Colors.blueAccent,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
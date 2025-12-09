import 'package:flutter/material.dart';
import '../../splash/splash_screen.dart'; // Để chuyển về màn hình chào khi đăng xuất
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Lấy thông tin user từ bộ nhớ máy
  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  // Xử lý đăng xuất
  Future<void> _handleLogout() async {
    // Hiện hộp thoại xác nhận
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Đóng hộp thoại
              await _authService.logout(); // Xóa dữ liệu trong máy

              // Chuyển về màn hình Chờ (Splash) để nó tự điều hướng về Login
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                      (route) => false, // Xóa hết lịch sử các màn hình trước đó
                );
              }
            },
            child: const Text("Đồng ý", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tài khoản"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _currentUser == null
          ? const Center(child: Text("Chưa đăng nhập"))
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar mặc định
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // Thông tin cá nhân
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge, color: Colors.blue),
                    title: const Text("Họ tên"),
                    subtitle: Text(_currentUser!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: const Text("Số điện thoại"),
                    subtitle: Text(_currentUser!.phone, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Nút Đăng xuất
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50, // Nền đỏ nhạt
                  foregroundColor: Colors.red, // Chữ đỏ
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Đăng xuất", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
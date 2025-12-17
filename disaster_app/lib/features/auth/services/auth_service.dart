import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// ⚠️ QUAN TRỌNG: Hãy chắc chắn bạn đã import đúng file api_config.dart
// Nếu dòng dưới bị đỏ, hãy xóa đi và gõ lại "ApiConfig" để VS Code gợi ý import đúng.
import 'package:disaster_app/api_config.dart';
class AuthService {

  // --- SỬA ĐỔI QUAN TRỌNG TẠI ĐÂY ---
  // Không dùng link cứng IP 172... nữa.
  // Lấy link từ ApiConfig (nó sẽ tự biết khi nào dùng Render, khi nào dùng Local)
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';

  // 1. Đăng ký
  Future<bool> register(String name, String phone, String password) async {
    try {
      // In ra để kiểm tra xem nó đang gọi vào đâu
      print("Đang đăng ký tại: $baseUrl/register");

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'phone': phone, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Lỗi đăng ký: $e");
      return false;
    }
  }

  // 2. Đăng nhập
  Future<User?> login(String phone, String password) async {
    try {
      print("Đang đăng nhập tại: $baseUrl/login");

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);

        await _saveUserToLocal(user);
        return user;
      }
      return null;
    } catch (e) {
      print("Lỗi đăng nhập: $e");
      return null;
    }
  }

  // 3. Đăng xuất (Giữ nguyên)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  // 4. Lấy thông tin (Giữ nguyên)
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }
    return null;
  }

  // Hàm phụ (Giữ nguyên)
  Future<void> _saveUserToLocal(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
  }
}
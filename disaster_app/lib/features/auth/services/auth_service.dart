import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  // ⚠️ SỬA IP CHO ĐÚNG VỚI MÁY BẠN
  static const String baseUrl = 'http://172.16.9.38:3000/api/auth';

  // 1. Đăng ký
  Future<bool> register(String name, String phone, String password) async {
    try {
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
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);

        // Lưu thông tin người dùng vào máy để lần sau tự vào
        await _saveUserToLocal(user);
        return user;
      }
      return null;
    } catch (e) {
      print("Lỗi đăng nhập: $e");
      return null;
    }
  }

  // 3. Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  // 4. Lấy thông tin người dùng đang đăng nhập
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }
    return null;
  }

  // Hàm phụ: Lưu vào máy
  Future<void> _saveUserToLocal(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:disaster_app/api_config.dart'; // Import config của bạn

class AuthService {
  // Lấy link từ ApiConfig
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';

  // Key để lưu token vào bộ nhớ máy
  static const String _tokenKey = 'jwt_token';

  // --- 1. CÁC HÀM QUẢN LÝ TOKEN (MỚI THÊM) ---

  // Lưu Token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Lấy Token (Để kẹp vào Header gọi API)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Xóa Token (Đăng xuất)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // --- 2. CÁC HÀM API ---

  // Đăng ký
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

  // Đăng nhập (ĐÃ SỬA ĐỂ LƯU TOKEN)
  Future<User?> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        print("Server Response: ${response.body}");
        final data = json.decode(response.body);

        // 1. Trích xuất và Lưu Token (Quan trọng nhất)
        // Giả sử server trả về JSON dạng: { "token": "...", "user": {...} }
        // Hoặc nếu token nằm phẳng cùng user: { "token": "...", "name": "...", ... }
        if (data['token'] != null) {
          await saveToken(data['token']);
        }

        // 2. Lưu thông tin User như cũ
        if (data['user'] != null) {
          final user = User.fromJson(data['user']);
          await _saveUserToLocal(user);
          return user;
        }
      }
      return null;
    } catch (e) {
      print("Lỗi đăng nhập: $e");
      return null;
    }
  }

  // Đăng xuất (ĐÃ SỬA)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data'); // Xóa user
    await removeToken(); // Xóa token
  }

  // Lấy user hiện tại
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }
    return null;
  }

  Future<void> _saveUserToLocal(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
  }

  // Hàm gọi API đổi tên
  Future<bool> updateUserName(String userId, String newName) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId');

      final token = await getToken();

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': newName}),
      );

      if (response.statusCode == 200) {
        // Cập nhật lại SharedPreferences để lần sau vào app tên vẫn đúng
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user_data');
        if (userDataString != null) {
          final userData = json.decode(userDataString);
          userData['name'] = newName; // Sửa tên trong bộ nhớ máy
          await prefs.setString('user_data', json.encode(userData));
        }
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi đổi tên: $e");
      return false;
    }
  }

  // --- HÀM ĐỔI MẬT KHẨU (GỌI API NODEJS) ---
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final url = Uri.parse('$baseUrl/change-password'); // Đảm bảo baseUrl trỏ đúng file router kia

      // Lấy token đang lưu trong máy
      final token = await getToken();

      if (token == null) {
        print("Lỗi: Không tìm thấy token (chưa đăng nhập)");
        return false;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Gửi token để Server biết ai đang đổi
        },
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true; // Đổi thành công
      } else {
        // In ra lỗi từ server (ví dụ: "Mật khẩu cũ không đúng")
        print("Lỗi server: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối đổi pass: $e");
      return false;
    }
  }

}
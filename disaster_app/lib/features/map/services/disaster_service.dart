import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/disaster_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:disaster_app/api_config.dart';

// 👇 1. THÊM IMPORT NÀY
import '../../auth/services/auth_service.dart';

class DisasterService {
  static String get baseUrl => '${ApiConfig.baseUrl}/reports';

  // 👇 2. KHỞI TẠO AUTH SERVICE
  final AuthService _authService = AuthService();

  // 👇 3. VIẾT HÀM LẤY HEADER (CÓ TOKEN)
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken(); // Lấy token từ bộ nhớ
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token', // Kẹp token vào đây
    };
  }

  // 4. SỬA HÀM fetchReports
  Future<List<DisasterReport>> fetchReports() async {
    try {
      // 👇 Dùng _getHeaders() thay vì gọi trần
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.map((json) => DisasterReport(
          id: json['_id'],
          title: json['title'],
          description: json['description'] ?? '',
          type: _parseType(json['type']),
          location: LatLng(
            json['location']['latitude'].toDouble(),
            json['location']['longitude'].toDouble(),
          ),
          time: DateTime.parse(json['timestamp']),
          radius: (json['radius'] ?? 100).toDouble(),
          imagePath: json['imagePath'],
          userId: json['userId'] ?? '',
          userName: json['userName'],
        )).toList();
      } else if (response.statusCode == 401) {
        // Nếu Token hết hạn -> Đăng xuất (Tùy chọn)
        print("Token hết hạn!");
        return [];
      } else {
        throw Exception('Không tải được dữ liệu');
      }
    } catch (e) {
      print("Lỗi gọi API: $e");
      return [];
    }
  }

  // 5. SỬA HÀM createReport
  Future<bool> createReport(DisasterReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('user_data');
      String currentUserId = "anonymous";
      String currentUserName = "Ẩn danh";

      if (userData != null) {
        final userMap = json.decode(userData);
        currentUserId = userMap['_id'] ?? userMap['phone'];
        currentUserName = userMap['name'];
      }

      // 👇 Dùng _getHeaders()
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers, // <--- Đã thay thế header cứng
        body: json.encode({
          'title': report.title,
          'description': report.description,
          'type': report.type.name,
          'location': {
            'latitude': report.location.latitude,
            'longitude': report.location.longitude,
          },
          'radius': report.radius,
          'imagePath': report.imagePath,
          'userId': currentUserId,
          'userName': currentUserName,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("Lỗi: $e");
      return false;
    }
  }

  // 6. SỬA HÀM deleteReport
  Future<bool> deleteReport(String id) async {
    try {
      // 👇 Dùng _getHeaders()
      final headers = await _getHeaders();

      final response = await http.delete(
          Uri.parse('$baseUrl/$id'),
          headers: headers // <--- Thêm header vào lệnh xóa
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Lỗi xóa báo cáo: $e");
      return false;
    }
  }

  // 7. SỬA HÀM updateReport
  Future<bool> updateReport(DisasterReport report) async {
    try {
      // 👇 Dùng _getHeaders()
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/${report.id}'),
        headers: headers, // <--- Thay thế header cứng
        body: json.encode({
          'title': report.title,
          'description': report.description,
          'type': report.type.name,
          'location': {
            'latitude': report.location.latitude,
            'longitude': report.location.longitude,
          },
          'radius': report.radius,
          'imagePath': report.imagePath
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi cập nhật báo cáo: $e");
      return false;
    }
  }

  // Hàm upload ảnh giữ nguyên (Cloudinary không cần JWT của server mình)
  Future<String?> uploadImageToCloud(File imageFile) async {
    try {
      const cloudName = "dqz4kwlgq";
      const uploadPreset = "disaster_upload";

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        print('Lỗi upload ảnh Cloudinary: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print("Lỗi upload: $e");
      return null;
    }
  }

  DisasterType _parseType(String typeString) {
    return DisasterType.values.firstWhere(
          (e) => e.name == typeString,
      orElse: () => DisasterType.flood,
    );
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/disaster_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:disaster_app/api_config.dart';

class DisasterService {
  static String get baseUrl => '${ApiConfig.baseUrl}/reports';

  // 1. Lấy danh sách báo cáo từ Server
  Future<List<DisasterReport>> fetchReports() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Chuyển đổi JSON từ Server thành List<DisasterReport> của Flutter
        return data.map((json) => DisasterReport(
          id: json['_id'], // MongoDB dùng _id thay vì id
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
      } else {
        throw Exception('Không tải được dữ liệu');
      }
    } catch (e) {
      print("Lỗi gọi API: $e");
      return []; // Trả về rỗng nếu lỗi để App không bị chết
    }
  }

  // 2. Gửi báo cáo mới lên Server
  Future<bool> createReport(DisasterReport report) async {
    try {
      // 1. LẤY THÔNG TIN USER ĐANG ĐĂNG NHẬP
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('user_data');
      String currentUserId = "anonymous";
      String currentUserName = "Ẩn danh";

      if (userData != null) {
        final userMap = json.decode(userData);
        currentUserId = userMap['_id'] ?? userMap['phone']; // Lấy ID hoặc SĐT
        currentUserName = userMap['name'];
      }

      // 2. GỬI KÈM USER ID LÊN SERVER
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
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

          // --- THÊM 2 DÒNG NÀY ---
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


  Future<bool> deleteReport(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        return true; // Xóa thành công
      } else {
        return false;
      }
    } catch (e) {
      print("Lỗi xóa báo cáo: $e");
      return false;
    }
  }

  // 4. Cập nhật báo cáo
  Future<bool> updateReport(DisasterReport report) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${report.id}'), // Gọi vào đúng ID cần sửa
        headers: {'Content-Type': 'application/json'},
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

      return response.statusCode == 200; // 200 OK là thành công
    } catch (e) {
      print("Lỗi cập nhật báo cáo: $e");
      return false;
    }
  }


  Future<String?> uploadImageToCloud(File imageFile) async {
    try {
      // Tên Cloud lấy từ ảnh bạn gửi
      const cloudName = "dqz4kwlgq";
      // Tên Preset bạn vừa tạo ở BƯỚC 1 (nếu đặt tên khác thì sửa ở đây)
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
        return jsonMap['secure_url']; // Trả về link ảnh online (https://...)
      } else {
        print('Lỗi upload ảnh Cloudinary: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print("Lỗi upload: $e");
      return null;
    }
  }

  // Hàm phụ: Chuyển chuỗi từ Server thành Enum
  DisasterType _parseType(String typeString) {
    return DisasterType.values.firstWhere(
          (e) => e.name == typeString,
      orElse: () => DisasterType.flood,
    );
  }
}
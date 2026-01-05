import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // Chỉ dùng để upload ảnh lên Cloudinary
import '../models/disaster_model.dart';

class DisasterService {
  // Khởi tạo Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tên collection trên Firebase
  final String _collection = 'reports';

  // 1. LẤY DANH SÁCH BÁO CÁO (REAL-TIME hoặc GET 1 LẦN)
  // Ở đây mình dùng GET 1 lần cho giống logic cũ, nếu muốn tự động cập nhật thì dùng snapshots()
  Future<List<DisasterReport>> fetchReports() async {
    try {
      // Lấy dữ liệu, sắp xếp mới nhất lên đầu
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => DisasterReport.fromFirestore(doc)).toList();
    } catch (e) {
      print("Lỗi tải báo cáo: $e");
      return [];
    }
  }

  // 2. TẠO BÁO CÁO MỚI
  Future<bool> createReport(DisasterReport report) async {
    try {
      // Lấy thông tin người dùng hiện tại từ Firebase Auth
      final user = _auth.currentUser;

      // Nếu chưa đăng nhập thì đặt là ẩn danh hoặc chặn lại tùy bạn
      String userId = user?.uid ?? 'anonymous';
      String userName = 'Ẩn danh';

      // Lấy tên người dùng từ Firestore (nếu có)
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userName = userDoc['name'] ?? 'Người dùng';
        }
      }

      // Chuẩn bị dữ liệu
      final data = {
        'title': report.title,
        'description': report.description,
        'type': report.type.name,
        'location': {
          'latitude': report.location.latitude,
          'longitude': report.location.longitude,
        },
        'timestamp': FieldValue.serverTimestamp(), // Lấy giờ server cho chuẩn
        'radius': report.radius,
        'imagePath': report.imagePath,
        'userId': userId,
        'userName': userName,
      };

      // Đẩy lên Firestore
      await _firestore.collection(_collection).add(data);

      return true;
    } catch (e) {
      print("Lỗi tạo báo cáo: $e");
      return false;
    }
  }

  // 3. XÓA BÁO CÁO
  Future<bool> deleteReport(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print("Lỗi xóa báo cáo: $e");
      return false;
    }
  }

  // 4. CẬP NHẬT BÁO CÁO
  Future<bool> updateReport(DisasterReport report) async {
    try {
      final data = {
        'title': report.title,
        'description': report.description,
        'type': report.type.name,
        'location': {
          'latitude': report.location.latitude,
          'longitude': report.location.longitude,
        },
        'radius': report.radius,
        'imagePath': report.imagePath,
        // Không cập nhật userId, userName, timestamp để giữ nguyên gốc
      };

      await _firestore.collection(_collection).doc(report.id).update(data);
      return true;
    } catch (e) {
      print("Lỗi cập nhật báo cáo: $e");
      return false;
    }
  }

  // 5. UPLOAD ẢNH (Giữ nguyên Cloudinary vì nó độc lập với Database)
  Future<String?> uploadImageToCloud(File imageFile) async {
    try {
      const cloudName = "dqz4kwlgq"; // Thay bằng tên Cloud của bạn
      const uploadPreset = "disaster_upload"; // Thay bằng preset của bạn

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
}
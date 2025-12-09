import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum DisasterType {
  flood,      // Ngập lụt
  storm,      // Bão/Gió lốc
  fire,       // Cháy nổ
  landslide,  // Sạt lở đất
  traffic,    // Tắc đường
  sos         // Cứu hộ khẩn cấp
}

extension DisasterTypeExtension on DisasterType {
  String toVietnamese() {
    switch (this) {
      case DisasterType.flood: return "Ngập lụt";
      case DisasterType.storm: return "Bão / Lốc";
      case DisasterType.fire: return "Cháy nổ";
      case DisasterType.landslide: return "Sạt lở đất";
      case DisasterType.traffic: return "Tắc đường";
      case DisasterType.sos: return "CỨU HỘ KHẨN CẤP";
    }
  }
}

class DisasterReport {
  final String id;
  final String title;
  final String description;
  final LatLng location;
  final DisasterType type;
  final DateTime time;
  final double radius;
  final String? imagePath;

  // Thông tin người đăng (Quan trọng để phân quyền Xóa/Sửa)
  final String userId;
  final String? userName;

  DisasterReport({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.time,
    required this.radius,
    this.imagePath,
    required this.userId, // Bắt buộc phải có
    this.userName,
  });

  // Helper: Lấy màu sắc theo loại
  Color getColor() {
    switch (type) {
      case DisasterType.flood: return Colors.blue;
      case DisasterType.storm: return Colors.purple;
      case DisasterType.fire: return Colors.red;
      case DisasterType.landslide: return Colors.brown;
      case DisasterType.traffic: return Colors.orange;
      case DisasterType.sos: return Colors.redAccent.shade700;
    }
  }

  // Helper: Lấy Icon theo loại
  IconData getIcon() {
    switch (type) {
      case DisasterType.flood: return Icons.water;
      case DisasterType.storm: return Icons.cyclone;
      case DisasterType.fire: return Icons.local_fire_department;
      case DisasterType.landslide: return Icons.landscape;
      case DisasterType.traffic: return Icons.traffic;
      case DisasterType.sos: return Icons.sos;
    }
  }
}

// --- Mock Data (Dữ liệu giả lập - Đã sửa thêm userId) ---
// Lưu ý: Dữ liệu này chỉ dùng khi chưa kết nối Server hoặc khi mất mạng
final List<DisasterReport> fakeReports = [
  // Hồ Gươm - Ngập lụt
  DisasterReport(
    id: '1',
    title: 'Ngập sâu phố đi bộ',
    description: 'Nước ngập qua đầu gối, các phương tiện không thể di chuyển.',
    location: const LatLng(21.0285, 105.8542),
    type: DisasterType.flood,
    time: DateTime.now().subtract(const Duration(minutes: 30)),
    radius: 500,
    imagePath: null,
    userId: 'admin_fake_id', // Đã thêm
    userName: 'Admin Hệ Thống', // Đã thêm
  ),

  // Cầu Giấy - Tắc đường
  DisasterReport(
    id: '2',
    title: 'Tắc đường nghiêm trọng',
    description: 'Kẹt cứng do cây đổ chắn ngang đường.',
    location: const LatLng(21.0362, 105.7906),
    type: DisasterType.traffic,
    time: DateTime.now().subtract(const Duration(hours: 1)),
    radius: 100,
    userId: 'admin_fake_id', // Đã thêm
    userName: 'Admin Hệ Thống',
  ),

  // Bách Khoa - Cháy
  DisasterReport(
    id: '3',
    title: 'Cháy trạm biến áp',
    description: 'Khói đen bốc cao, cứu hỏa đang tiếp cận.',
    location: const LatLng(21.0050, 105.8450),
    type: DisasterType.fire,
    time: DateTime.now().subtract(const Duration(minutes: 5)),
    radius: 300,
    userId: 'admin_fake_id', // Đã thêm
    userName: 'Admin Hệ Thống',
  ),
];
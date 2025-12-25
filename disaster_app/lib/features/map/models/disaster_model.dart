import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// 1. ĐỊNH NGHĨA LẠI DANH SÁCH (Đã xóa Tắc đường, thêm Bão, Động đất...)
enum DisasterType {
  flood,      // Lũ lụt
  fire,       // Cháy rừng/hỏa hoạn
  landslide,  // Sạt lở đất
  storm,      // Bão/Giông lốc (MỚI)
  earthquake, // Động đất (MỚI)
  tsunami,    // Sóng thần (MỚI)
  drought,    // Hạn hán (MỚI)
  sos         // Cứu hộ khẩn cấp
}

// Extension để chuyển đổi dữ liệu dễ dàng
extension DisasterTypeExtension on DisasterType {
  // Chuyển sang tiếng Việt
  String toVietnamese() {
    switch (this) {
      case DisasterType.flood: return "Lũ lụt / Ngập úng";
      case DisasterType.fire: return "Cháy rừng / Hỏa hoạn";
      case DisasterType.landslide: return "Sạt lở đất / Đá lăn";
      case DisasterType.storm: return "Bão / Giông lốc";
      case DisasterType.earthquake: return "Động đất / Dư chấn"; // Mới
      case DisasterType.tsunami: return "Sóng thần"; // Mới
      case DisasterType.drought: return "Hạn hán / Nắng nóng"; // Mới
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
    required this.userId,
    this.userName,
  });

  // Helper: Lấy màu sắc theo loại
  Color getTypeColor() {
    switch (type) {
      case DisasterType.flood: return Colors.blue;
      case DisasterType.fire: return Colors.red;
      case DisasterType.landslide: return Colors.brown;
      case DisasterType.storm: return Colors.blueGrey; // Bão màu xám xanh
      case DisasterType.earthquake: return Colors.deepPurple; // Động đất màu tím đậm
      case DisasterType.tsunami: return Colors.indigo; // Sóng thần màu chàm
      case DisasterType.drought: return Colors.orangeAccent; // Hạn hán màu cam
      case DisasterType.sos: return Colors.redAccent.shade700;
    }
  }

  // Helper: Lấy Icon theo loại
  IconData getIcon() {
    switch (type) {
      case DisasterType.flood: return Icons.water; // Nước
      case DisasterType.fire: return Icons.local_fire_department; // Lửa
      case DisasterType.landslide: return Icons.landscape; // Núi
      case DisasterType.storm: return Icons.storm; // Bão
      case DisasterType.earthquake: return Icons.broken_image_outlined; // Nứt vỡ
      case DisasterType.tsunami: return Icons.tsunami; // Sóng thần (Hoặc Icons.waves)
      case DisasterType.drought: return Icons.wb_sunny; // Nắng
      case DisasterType.sos: return Icons.sos;
    }
  }

  // --- QUAN TRỌNG: Cần thêm 2 hàm này để giao tiếp với Server/Database ---

  // 1. Convert từ Object sang Map (để gửi lên Server)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'type': type.name, // Lưu tên enum (ví dụ: 'storm')
      'time': time.toIso8601String(),
      'radius': radius,
      'imagePath': imagePath,
      'userId': userId,
      'userName': userName,
    };
  }

  // 2. Convert từ Map sang Object (để đọc từ Server về)
  factory DisasterReport.fromJson(Map<String, dynamic> json) {
    return DisasterReport(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      // Chuyển string từ API thành Enum, nếu lỗi hoặc không tìm thấy (do data cũ là traffic) thì mặc định về flood
      type: DisasterType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => DisasterType.flood,
      ),
      time: DateTime.parse(json['time']),
      radius: (json['radius'] as num).toDouble(),
      imagePath: json['imagePath'],
      userId: json['userId'] ?? '',
      userName: json['userName'],
    );
  }
}

// --- Mock Data (Dữ liệu giả lập) ---
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
    userId: 'admin_fake_id',
    userName: 'Admin Hệ Thống',
  ),

  // Cầu Giấy - Sửa thành BÃO (Vì đã xóa Tắc đường)
  DisasterReport(
    id: '2',
    title: 'Cây đổ do bão',
    description: 'Gió giật mạnh làm cây đổ chắn ngang đường.',
    location: const LatLng(21.0362, 105.7906),
    type: DisasterType.storm, // Đã sửa từ traffic thành storm
    time: DateTime.now().subtract(const Duration(hours: 1)),
    radius: 100,
    userId: 'admin_fake_id',
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
    userId: 'admin_fake_id',
    userName: 'Admin Hệ Thống',
  ),
];
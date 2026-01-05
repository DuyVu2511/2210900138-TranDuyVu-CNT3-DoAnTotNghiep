import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart'; // Để dùng Colors

// Định nghĩa Enum loại thiên tai
enum DisasterType { flood, fire, landslide, storm, earthquake, other, sos }

// Extension để lấy tên tiếng Việt và Icon
extension DisasterTypeExtension on DisasterType {
  String toVietnamese() {
    switch (this) {
      case DisasterType.flood: return 'Lũ lụt';
      case DisasterType.fire: return 'Cháy rừng / Hỏa hoạn';
      case DisasterType.landslide: return 'Sạt lở đất';
      case DisasterType.storm: return 'Bão / Lốc xoáy';
      case DisasterType.earthquake: return 'Động đất';
      case DisasterType.sos: return 'CỨU HỘ KHẨN CẤP';
      default: return 'Khác';
    }
  }

  IconData getIcon() {
    switch (this) {
      case DisasterType.flood: return Icons.water;
      case DisasterType.fire: return Icons.local_fire_department;
      case DisasterType.landslide: return Icons.landscape;
      case DisasterType.storm: return Icons.storm;
      case DisasterType.earthquake: return Icons.broken_image;
      case DisasterType.sos: return Icons.sos;
      default: return Icons.warning;
    }
  }

  Color getTypeColor() {
    switch (this) {
      case DisasterType.flood: return Colors.blue;
      case DisasterType.fire: return Colors.orange;
      case DisasterType.landslide: return Colors.brown;
      case DisasterType.storm: return Colors.indigo;
      case DisasterType.earthquake: return Colors.purple;
      case DisasterType.sos: return Colors.red;
      default: return Colors.grey;
    }
  }
}

class DisasterReport {
  final String id;
  final String title;
  final String description;
  final DisasterType type;
  final LatLng location;
  final DateTime time;
  final double radius;
  final String? imagePath;
  final String userId;
  final String? userName;

  DisasterReport({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.location,
    required this.time,
    required this.radius,
    this.imagePath,
    required this.userId,
    this.userName,
  });

  // --- [QUAN TRỌNG] Hàm đọc dữ liệu từ Firestore ---
  factory DisasterReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Xử lý tọa độ (Firestore lưu dạng GeoPoint hoặc Map)
    double lat = 0;
    double lng = 0;
    if (data['location'] is GeoPoint) {
      lat = (data['location'] as GeoPoint).latitude;
      lng = (data['location'] as GeoPoint).longitude;
    } else if (data['location'] is Map) {
      lat = (data['location']['latitude'] ?? 0).toDouble();
      lng = (data['location']['longitude'] ?? 0).toDouble();
    }

    // Xử lý loại thiên tai
    DisasterType parsedType = DisasterType.values.firstWhere(
          (e) => e.name == (data['type'] ?? 'other'),
      orElse: () => DisasterType.other,
    );

    // Xử lý thời gian (Firestore lưu Timestamp)
    DateTime parsedTime = DateTime.now();
    if (data['timestamp'] != null) {
      parsedTime = (data['timestamp'] as Timestamp).toDate();
    }

    return DisasterReport(
      id: doc.id, // Lấy ID của document
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: parsedType,
      location: LatLng(lat, lng),
      time: parsedTime,
      radius: (data['radius'] ?? 0).toDouble(),
      imagePath: data['imagePath'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Ẩn danh',
    );
  }

  // Chuyển sang JSON để lưu lên Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'location': { // Lưu dạng Map đơn giản hoặc GeoPoint đều được
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': Timestamp.fromDate(time), // Lưu dạng Timestamp
      'radius': radius,
      'imagePath': imagePath,
      'userId': userId,
      'userName': userName,
    };
  }

  // Các hàm hỗ trợ UI giữ nguyên
  IconData getIcon() => type.getIcon();
  Color getTypeColor() => type.getTypeColor();
}
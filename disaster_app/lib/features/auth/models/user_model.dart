import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String phone;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }

  // --- [MỚI] Chuyển từ Firestore Document -> Object ---
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id, // Lấy ID của document
      name: data['name'] ?? '',
      phone: data['phone'] ?? '', // Lấy SĐT thật lưu trong data
      role: data['role'] ?? 'user',
    );
  }

  // Giữ lại cái này để lưu vào SharedPreferences (Cache cục bộ)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  // Chuyển Object -> Map (để lưu lên Firestore hoặc Local)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
    };
  }
}
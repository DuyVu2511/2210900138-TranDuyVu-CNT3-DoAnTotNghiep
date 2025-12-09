class User {
  final String id;
  final String name;
  final String phone;

  User({required this.id, required this.name, required this.phone});

  // Chuyển từ JSON (Server trả về) -> Object (Flutter dùng)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'], // MongoDB dùng _id
      name: json['name'],
      phone: json['phone'],
    );
  }

  // Chuyển từ Object -> JSON (Để lưu vào máy)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
    };
  }
}
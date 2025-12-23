class User {
  final String id;
  final String name;
  final String phone;
  final String role; // Nên thêm trường này vì Server của bạn có trả về

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  // Chuyển từ JSON (Server trả về) -> Object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // 1. Ưu tiên lấy '_id', nếu không có thì lấy 'id', nếu null thì lấy chuỗi rỗng ''
      id: json['_id'] ?? json['id'] ?? '',

      // 2. Thêm '?? ""' vào cuối. Nếu server trả về null, nó sẽ thành chuỗi rỗng.
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user', // Mặc định là user nếu thiếu
    );
  }

  // Chuyển từ Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'role': role,
    };
  }
}
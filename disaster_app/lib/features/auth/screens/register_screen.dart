import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // --- HÀM KIỂM TRA DỮ LIỆU ĐẦU VÀO (VALIDATE) ---
  bool _validateInput() {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String pass = _passController.text.trim();

    // 1. Kiểm tra rỗng
    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")));
      return false;
    }

    // 2. Kiểm tra độ dài mật khẩu (Ít nhất 6 ký tự)
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu phải có ít nhất 6 ký tự")));
      return false;
    }

    // 3. Kiểm tra độ phức tạp (Phải có cả Chữ và Số)
    bool hasLetter = pass.contains(RegExp(r'[a-zA-Z]')); // Có chứa chữ cái không?
    bool hasDigit = pass.contains(RegExp(r'[0-9]'));     // Có chứa số không?

    if (!hasLetter || !hasDigit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu phải bao gồm cả CHỮ và SỐ để bảo mật")));
      return false;
    }

    return true; // Dữ liệu hợp lệ
  }

  void _handleRegister() async {
    // Gọi hàm kiểm tra trước khi gửi
    if (!_validateInput()) return;

    setState(() => _isLoading = true);

    bool success = await _authService.register(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _passController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng ký thành công! Hãy đăng nhập.")));
      Navigator.pop(context); // Quay về màn hình đăng nhập
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng ký thất bại (SĐT có thể đã tồn tại)")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký tài khoản")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView( // Thêm cuộn để tránh bị che khi bàn phím hiện lên
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.person_add, size: 80, color: Colors.blue),
              const SizedBox(height: 20),

              TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Họ và tên", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))
              ),
              const SizedBox(height: 15),

              TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))
              ),
              const SizedBox(height: 15),

              TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock), helperText: "Tối thiểu 6 ký tự, gồm chữ và số")
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ĐĂNG KÝ NGAY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
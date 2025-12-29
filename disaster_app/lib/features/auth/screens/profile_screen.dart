import 'package:flutter/material.dart';
import '../../report/screens/my_reports_screen.dart';
import '../../splash/splash_screen.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../utils/event_bus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  String _currentLanguage = "Tiếng Việt";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- HÀM SỬA TÊN ---
  void _showEditNameDialog() {
    final nameController = TextEditingController(text: _currentUser!.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đổi tên hiển thị"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: "Nhập tên mới",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              bool success = await _authService.updateUserName(_currentUser!.id, nameController.text);
              if (success) {
                setState(() {
                  _currentUser = _currentUser!.copyWith(name: nameController.text);
                });
                Navigator.pop(ctx);
                EventBus.triggerRefreshMap();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã lưu tên mới thành công!")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lỗi: Không lưu được tên!")),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // --- [MỚI] HÀM ĐỔI MẬT KHẨU ---
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    // 1. Khai báo biến trạng thái ẩn/hiện cho 3 ô
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
        context: context,
        builder: (ctx) {
          // 2. Dùng StatefulBuilder để Dialog có thể update giao diện (ẩn/hiện)
          return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text("Đổi mật khẩu"),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- Ô MẬT KHẨU CŨ ---
                        TextField(
                          controller: oldPassController,
                          obscureText: obscureOld, // Biến trạng thái
                          decoration: InputDecoration(
                            labelText: "Mật khẩu cũ",
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            // Nút con mắt
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureOld ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                // Dùng setStateDialog thay vì setState thường
                                setStateDialog(() {
                                  obscureOld = !obscureOld;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // --- Ô MẬT KHẨU MỚI ---
                        TextField(
                          controller: newPassController,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: "Mật khẩu mới",
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.vpn_key),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNew ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setStateDialog(() {
                                  obscureNew = !obscureNew;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // --- Ô XÁC NHẬN ---
                        TextField(
                          controller: confirmPassController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: "Xác nhận mật khẩu mới",
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setStateDialog(() {
                                  obscureConfirm = !obscureConfirm;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        String oldPass = oldPassController.text.trim();
                        String newPass = newPassController.text.trim();
                        String confirmPass = confirmPassController.text.trim();

                        // Validate
                        if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
                          );
                          return;
                        }
                        if (oldPass == newPass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Mật khẩu mới không được trùng với mật khẩu cũ!")),
                          );
                          return;
                        }
                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Mật khẩu xác nhận không khớp")),
                          );
                          return;
                        }
                        if (newPass.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Mật khẩu mới phải từ 6 ký tự trở lên")),
                          );
                          return;
                        }

                        // Gọi API
                        bool success = await _authService.changePassword(oldPass, newPass);

                        if (success) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Đổi mật khẩu thành công!")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Mật khẩu cũ không đúng hoặc lỗi hệ thống")),
                          );
                        }
                      },
                      child: const Text("Cập nhật"),
                    ),
                  ],
                );
              },
          );
        },
    );
  }

  // --- [MỚI] HÀM CHỌN NGÔN NGỮ ---
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chọn ngôn ngữ"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Để dialog gọn lại
          children: [
            // Lựa chọn 1: Tiếng Việt
            ListTile(
              leading: const Text("🇻🇳", style: TextStyle(fontSize: 24)),
              title: const Text("Tiếng Việt"),
              trailing: _currentLanguage == "Tiếng Việt"
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() {
                  _currentLanguage = "Tiếng Việt";
                });
                Navigator.pop(ctx); // Đóng dialog
              },
            ),
            const Divider(),
            // Lựa chọn 2: English
            ListTile(
              leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
              title: const Text("English"),
              trailing: _currentLanguage == "English"
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() {
                  _currentLanguage = "English";
                });
                Navigator.pop(ctx);

                // Hiện thông báo khéo léo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Giao diện tiếng Anh sẽ được cập nhật sau..."),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleName(String? role) {
    if (role == 'admin') return "Quản trị viên";
    if (role == 'rescuer') return "Đội cứu hộ";
    return "Người dân";
  }

  Color _getRoleColor(String? role) {
    if (role == 'admin') return Colors.redAccent;
    if (role == 'rescuer') return Colors.orangeAccent;
    return Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Lỗi: Không tìm thấy thông tin người dùng")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER ---
            SizedBox(
              height: 350,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent, Colors.lightBlueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 50,
                    child: Text(
                      "Hồ sơ cá nhân",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 110,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            child: Text(
                              _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : "U",
                              style: const TextStyle(fontSize: 45, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 48),
                            Text(
                              _currentUser!.name,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                              onPressed: _showEditNameDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Text(
                            _getRoleName(_currentUser!.role),
                            style: TextStyle(
                              color: _getRoleColor(_currentUser!.role),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- NỘI DUNG ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionTitle("Thông tin liên hệ"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        _buildProfileItem(Icons.phone, "Số điện thoại", _currentUser!.phone, isLocked: true), // Đã thêm khóa
                        const Divider(height: 1, indent: 50),
                        _buildProfileItem(Icons.perm_identity, "ID Người dùng", _currentUser!.id.substring(0, 8) + "..."),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildSectionTitle("Cài đặt ứng dụng"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.history, color: Colors.orange, size: 20),
                          ),
                          title: const Text("Lịch sử báo cáo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyReportsScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 50),

                        // --- [MỚI] MỤC ĐỔI MẬT KHẨU ---
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.lock_reset, color: Colors.redAccent, size: 20),
                          ),
                          title: const Text("Đổi mật khẩu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: _showChangePasswordDialog,
                        ),

                        const Divider(height: 1, indent: 50),
                        _buildSettingsItem(
                          Icons.notifications_outlined,
                          "Thông báo",
                          "Bật",
                          onTap: () {
                            // Khi bấm vào thì hiện thông báo nhẹ nhàng
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Chức năng thông báo đang được phát triển")),
                            );
                          },
                        ),

                        const Divider(height: 1, indent: 50),

                        _buildSettingsItem(
                          Icons.language,
                          "Ngôn ngữ",
                          _currentLanguage,
                          onTap: _showLanguageDialog,
                        ),

                        const Divider(height: 1, indent: 50),

                        // --- MỤC PHIÊN BẢN ---
                        _buildSettingsItem(
                            Icons.info_outline,
                            "Phiên bản",
                            "1.0.0",
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: "Ứng dụng Cứu Hộ",
                                applicationVersion: "1.0.0",
                                applicationIcon: const Icon(Icons.shield, size: 50, color: Colors.blue),
                                children: [
                                  const Text("Đồ án tốt nghiệp 2025"),
                                  const Text("Sinh viên thực hiện: Trần Duy Vũ"),
                                  const Text("GVHD: Thầy Đinh Công Tùng"),
                                ],
                              );
                            }
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.red.shade100),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 10),
                          Text("Đăng xuất", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
        ),
      ),
    );
  }

  // Cập nhật hàm này để hỗ trợ icon Lock (như đã bàn trước đó)
  Widget _buildProfileItem(IconData icon, String title, String subtitle, {bool isLocked = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.blueAccent, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
      trailing: isLocked
          ? const Icon(Icons.lock_outline, size: 16, color: Colors.grey)
          : null,
      onTap: isLocked ? () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không thể thay đổi số điện thoại")),
        );
      } : null,
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String trailingText, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.black54, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
      // Nhận sự kiện onTap ở đây. Nếu không truyền gì thì làm hàm rỗng () {}
      onTap: onTap ?? () {},
    );
  }
}
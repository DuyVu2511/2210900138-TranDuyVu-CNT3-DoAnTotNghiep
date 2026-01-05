import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  // Khởi tạo các công cụ của Firebase
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- [QUAN TRỌNG] MẸO: Biến số điện thoại thành Email giả ---
  // Ví dụ: 09123 -> 09123@disasterapp.com
  String _emailFromPhone(String phone) {
    return "$phone@disasterapp.com";
  }

  // --- 1. ĐĂNG KÝ ---
  Future<bool> register(String name, String phone, String password) async {
    try {
      // Bước 1: Tạo tài khoản trên Firebase Authentication (Dùng mẹo Email giả)
      firebase_auth.UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: _emailFromPhone(phone),
        password: password,
      );

      // Bước 2: Lưu thông tin chi tiết (Tên, SĐT thật, Role) vào Firestore
      // Tạo một User Object mới
      User newUser = User(
        id: cred.user!.uid, // Lấy ID từ Auth
        name: name,
        phone: phone,       // Lưu SĐT gốc vào đây để hiển thị
        role: 'user',       // Mặc định là user thường
      );

      // Lưu lên Firestore collection 'users'
      await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());

      return true; // Đăng ký thành công
    } catch (e) {
      print("Lỗi đăng ký Firebase: $e");
      return false;
    }
  }

  // --- 2. ĐĂNG NHẬP ---
  Future<User?> login(String phone, String password) async {
    try {
      // Bước 1: Đăng nhập bằng Email giả + Mật khẩu
      firebase_auth.UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: _emailFromPhone(phone),
        password: password,
      );

      // Bước 2: Lấy thông tin chi tiết từ Firestore về
      DocumentSnapshot doc = await _firestore.collection('users').doc(cred.user!.uid).get();

      if (doc.exists) {
        // Bước 3: Chuyển đổi sang User Model
        User user = User.fromFirestore(doc);

        // Bước 4: Lưu vào bộ nhớ máy (để dùng offline hoặc load nhanh)
        await _saveUserToLocal(user);

        return user;
      }
      return null;
    } catch (e) {
      print("Lỗi đăng nhập Firebase: $e");
      return null;
    }
  }

  // --- 3. ĐĂNG XUẤT ---
  Future<void> logout() async {
    await _auth.signOut(); // Đăng xuất khỏi Firebase

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data'); // Xóa cache
  }

  // --- 4. LẤY USER HIỆN TẠI ---
  Future<User?> getCurrentUser() async {
    // Cách 1: Lấy từ Cache Local (Nhanh nhất)
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }

    // Cách 2: Nếu Cache trống, thử lấy từ Firebase Auth (Chắc chắn hơn)
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        User user = User.fromFirestore(doc);
        await _saveUserToLocal(user); // Lưu lại cache
        return user;
      }
    }

    return null;
  }

  // --- 5. ĐỔI TÊN (Cập nhật Firestore) ---
  Future<bool> updateUserName(String userId, String newName) async {
    try {
      // Cập nhật trên Firestore
      await _firestore.collection('users').doc(userId).update({'name': newName});

      // Cập nhật lại Cache Local
      User? currentUser = await getCurrentUser();
      if (currentUser != null) {
        User updatedUser = currentUser.copyWith(name: newName);
        await _saveUserToLocal(updatedUser);
      }

      return true;
    } catch (e) {
      print("Lỗi đổi tên: $e");
      return false;
    }
  }

  // --- 6. ĐỔI MẬT KHẨU ---
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Firebase bắt buộc phải xác thực lại (nhập pass cũ) trước khi đổi pass mới
      // Dùng email của user hiện tại để xác thực
      String email = user.email!;

      // Tạo credential từ pass cũ
      firebase_auth.AuthCredential credential = firebase_auth.EmailAuthProvider.credential(
          email: email,
          password: oldPassword
      );

      // Xác thực lại
      await user.reauthenticateWithCredential(credential);

      // Nếu OK thì đổi pass mới
      await user.updatePassword(newPassword);

      return true;
    } catch (e) {
      print("Lỗi đổi mật khẩu: $e");
      return false;
    }
  }

  // Hàm phụ: Lưu user vào máy
  Future<void> _saveUserToLocal(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
  }
}
import 'package:flutter/foundation.dart'; // Để dùng kReleaseMode

class ApiConfig {
  // Đây là cái "Công tắc tổng" cho toàn bộ App
  static String get baseUrl {
    if (kReleaseMode) {
      // --- LINK RENDER ONLINE (Chạy thật) ---
      // Lưu ý: KHÔNG có đuôi /api/reports ở đây nhé, chỉ để domain gốc thôi
      return 'https://disater-server.onrender.com/api';
    } else {
      // --- LINK MÁY TÍNH (Debug) ---
      return 'http://172.16.9.58:3000/api';
    }
  }
}
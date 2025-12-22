import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class WeatherService {
  // Thay API Key của bạn vào đây
  final String apiKey = '2e04b3f5e10e62c6b3e19725a72ced95';

  Future<Map<String, dynamic>?> fetchWeather(LatLng location) async {
    // URL gọi API: Lấy thời tiết theo tọa độ, đơn vị độ C (metric), ngôn ngữ tiếng Việt (vi)
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${location.latitude}&lon=${location.longitude}&appid=$apiKey&units=metric&lang=vi');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Lỗi API Thời tiết: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi kết nối thời tiết: $e");
    }
    return null;
  }
}
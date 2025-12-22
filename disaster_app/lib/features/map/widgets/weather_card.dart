import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  // Nhận dữ liệu thời tiết từ bên ngoài truyền vào
  final Map<String, dynamic>? weatherData;

  const WeatherCard({super.key, this.weatherData});

  @override
  Widget build(BuildContext context) {
    // Nếu chưa có dữ liệu (đang tải hoặc lỗi) thì ẩn đi, không hiện gì cả
    if (weatherData == null) return const SizedBox.shrink();

    // Trích xuất dữ liệu từ JSON trả về
    final temp = weatherData!['main']['temp'].toInt(); // Nhiệt độ (VD: 28)
    final description = weatherData!['weather'][0]['description']; // Mô tả (VD: mưa nhẹ)
    // Viết hoa chữ cái đầu của mô tả
    final displayDesc = description[0].toUpperCase() + description.substring(1);
    final city = weatherData!['name']; // Tên thành phố
    final iconCode = weatherData!['weather'][0]['icon']; // Mã icon (VD: 10d)

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withOpacity(0.9), Colors.lightBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Load icon từ server của OpenWeather
          Image.network(
            'https://openweathermap.org/img/wn/$iconCode@2x.png',
            width: 40, height: 40,
            errorBuilder: (_, __, ___) => const Icon(Icons.cloud, color: Colors.white),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$city | $temp°C",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                displayDesc,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
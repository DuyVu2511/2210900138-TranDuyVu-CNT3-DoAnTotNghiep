import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // Import để dùng LatLng
import 'dart:io';
import '../../map/models/disaster_model.dart';
import '../../map/services/disaster_service.dart';
import '../../../core/widgets/full_screen_image.dart';

class AlertListScreen extends StatefulWidget {
  // Biến này để nhận lệnh từ bên ngoài
  final Function(LatLng) onNavigateToMap;

  const AlertListScreen({
    super.key,
    // Bắt buộc phải truyền hàm này vào khi gọi màn hình này
    required this.onNavigateToMap,
  });

  @override
  State<AlertListScreen> createState() => _AlertListScreenState();
}

class _AlertListScreenState extends State<AlertListScreen> {
  final DisasterService _disasterService = DisasterService();

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin tức cảnh báo', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],

      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<DisasterReport>>(
          future: _disasterService.fetchReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi kết nối: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Chưa có cảnh báo nào. Hãy gửi báo cáo đầu tiên!"));
            }

            final reports = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: report.getTypeColor().withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(report.getIcon(), color: report.getTypeColor()),
                    ),
                    title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(report.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),

                        // --- SỬA ĐOẠN HIỂN THỊ THỜI GIAN ---
                        Text(
                          // Dùng .toLocal() để chuyển sang giờ VN
                          // Dùng .padLeft(2, '0') để 9:5 thành 09:05
                          "${report.time.toLocal().hour.toString().padLeft(2, '0')}:${report.time.toLocal().minute.toString().padLeft(2, '0')} - ${report.time.toLocal().day}/${report.time.toLocal().month}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        // ------------------------------------
                      ],
                    ),
                    // Khi bấm vào dòng tin -> Gọi hàm callback để chuyển Map
                    onTap: () {
                      widget.onNavigateToMap(report.location);
                    },

                    trailing: report.imagePath != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: report.imagePath!.startsWith('http')
                          ? Image.network(
                        report.imagePath!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                      )
                          : Image.file(
                        File(report.imagePath!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
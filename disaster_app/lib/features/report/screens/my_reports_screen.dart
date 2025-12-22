import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // Import intl để format ngày tháng

import '../../map/models/disaster_model.dart';
import '../../map/services/disaster_service.dart';
import 'create_report_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final DisasterService _disasterService = DisasterService();
  List<DisasterReport> _myReports = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Lấy ID user và tải danh sách báo cáo
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      final userMap = json.decode(userData);
      _currentUserId = userMap['_id'];
    }

    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Tải tất cả và lọc bài của mình
    final allReports = await _disasterService.fetchReports();
    if (mounted) {
      setState(() {
        _myReports = allReports.where((r) => r.userId == _currentUserId).toList();
        // Sắp xếp mới nhất lên đầu
        _myReports.sort((a, b) => b.time.compareTo(a.time));
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReport(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Xóa tin cảnh báo này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await _disasterService.deleteReport(id);
      if (success) {
        _loadData(); // Tải lại danh sách
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tin đã đăng"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myReports.isEmpty
          ? const Center(child: Text("Bạn chưa đăng tin nào.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _myReports.length,
        itemBuilder: (context, index) {
          final report = _myReports[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () async {
                // Bấm vào để sửa
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateReportScreen(
                      currentLocation: report.location,
                      existingReport: report,
                    ),
                  ),
                );
                if (result == true) _loadData();
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Ảnh thumbnail
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (report.imagePath != null && report.imagePath!.isNotEmpty)
                          ? Image.network(report.imagePath!, fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Icon(report.getIcon(), color: report.getColor()))
                          : Icon(report.getIcon(), color: report.getColor(), size: 30),
                    ),
                    const SizedBox(width: 15),

                    // Nội dung chữ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(report.time),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: report.getColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              report.type.toVietnamese(),
                              style: TextStyle(color: report.getColor(), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nút xóa nhanh
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteReport(report.id),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
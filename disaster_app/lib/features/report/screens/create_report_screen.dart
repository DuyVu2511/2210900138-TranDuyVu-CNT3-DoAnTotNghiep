import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../map/models/disaster_model.dart';
import '../../map/services/disaster_service.dart';

class CreateReportScreen extends StatefulWidget {
  final LatLng currentLocation;
  // Biến này quyết định chế độ màn hình:
  // - Nếu null: Chế độ THÊM MỚI.
  // - Nếu có dữ liệu: Chế độ CHỈNH SỬA.
  final DisasterReport? existingReport;

  const CreateReportScreen({
    super.key,
    required this.currentLocation,
    this.existingReport,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Khởi tạo Service để gọi API
  final DisasterService _disasterService = DisasterService();

  DisasterType _selectedType = DisasterType.flood;
  double _radius = 100.0;
  File? _selectedImage;
  bool _isSending = false; // Biến để hiện vòng quay loading khi đang gửi

  @override
  void initState() {
    super.initState();
    // LOGIC: Nếu đang sửa, tự động điền thông tin cũ vào các ô nhập
    if (widget.existingReport != null) {
      final report = widget.existingReport!;
      _titleController.text = report.title;
      _descController.text = report.description;
      _selectedType = report.type;
      _radius = report.radius;
      if (report.imagePath != null) {
        _selectedImage = File(report.imagePath!);
      }
    }
  }

  // Hàm chọn ảnh từ Camera hoặc Thư viện
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh mới'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // LOGIC GỬI BÁO CÁO (QUAN TRỌNG NHẤT)
  Future<void> _submitReport() async {
    // 1. Kiểm tra dữ liệu đầu vào (Validate)
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề')));
      return;
    }

    setState(() => _isSending = true); // Bắt đầu loading

    String? imageUrl; // Biến để chứa link ảnh sau khi upload

    // 1. XỬ LÝ ẢNH (LOGIC MỚI)
    if (_selectedImage != null) {
      // Nếu đang Sửa và ảnh đó là link online cũ (chưa chọn ảnh mới) -> Giữ nguyên link cũ
      if (widget.existingReport != null && _selectedImage!.path.startsWith('http')) {
        imageUrl = _selectedImage!.path;
      } else {
        // Nếu là ảnh mới chụp (đường dẫn local) -> Upload lên Cloud
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang tải ảnh lên...')));

        imageUrl = await _disasterService.uploadImageToCloud(_selectedImage!);

        if (imageUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi upload ảnh, vui lòng thử lại!')));
          setState(() => _isSending = false);
          return; // Dừng lại không gửi báo cáo nếu upload ảnh thất bại
        }
      }
    }

    // 2. Đóng gói dữ liệu để chuẩn bị gửi
    final newReport = DisasterReport(
      // Nếu sửa: Dùng ID cũ. Nếu mới: Để rỗng (Server tự tạo ID)
      id: widget.existingReport?.id ?? '',
      title: _titleController.text,
      description: _descController.text,
      // Nếu sửa: Giữ nguyên vị trí cũ. Nếu mới: Lấy vị trí GPS hiện tại
      location: widget.existingReport?.location ?? widget.currentLocation,
      type: _selectedType,
      time: DateTime.now(),
      radius: _radius,
      imagePath: imageUrl,
      userId: widget.existingReport?.userId ?? '',
    );

    // 3. Gửi lên Server
    bool success;
    if (widget.existingReport != null) {
      // --- CHẾ ĐỘ SỬA ---
      // Gọi API cập nhật thật sự
      success = await _disasterService.updateReport(newReport);
    } else {
      // --- CHẾ ĐỘ THÊM MỚI ---
      // Gọi API thật lên Server
      success = await _disasterService.createReport(newReport);
    }

    // Kiểm tra màn hình còn tồn tại không trước khi update UI (tránh lỗi)
    if (!mounted) return;
    setState(() => _isSending = false); // Tắt loading

    // 4. Xử lý kết quả
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thành công!')));
      Navigator.pop(context, true); // Trả về true để màn hình Bản đồ biết mà reload lại
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối Server')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReport != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa báo cáo' : 'Gửi báo cáo thiên tai'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị vị trí
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        isEditing
                            ? "Vị trí: Đang giữ nguyên vị trí cũ"
                            : "Vị trí: ${widget.currentLocation.latitude}, ${widget.currentLocation.longitude}"
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown chọn loại thiên tai
            const Text("Loại thiên tai", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<DisasterType>(
              value: _selectedType,
              isExpanded: true,
              items: DisasterType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()))).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 20),

            // Slider chọn bán kính
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Vùng ảnh hưởng:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${_radius.toInt()}m", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _radius, min: 50, max: 2000, divisions: 40, label: "${_radius.toInt()}m",
              onChanged: (value) => setState(() => _radius = value),
            ),
            const SizedBox(height: 10),

            // Các ô nhập liệu
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder())),
            const SizedBox(height: 16),

            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Mô tả chi tiết...', border: OutlineInputBorder())),
            const SizedBox(height: 20),

            // Khu vực chọn ảnh
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  image: _selectedImage != null
                      ? DecorationImage(
                    image: _selectedImage!.path.startsWith('http')
                        ? NetworkImage(_selectedImage!.path) // Nếu là link online
                        : FileImage(_selectedImage!) as ImageProvider, // Nếu là file máy
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.camera_alt, color: Colors.grey, size: 40), Text("Thêm/Sửa ảnh hiện trường")],
                )
                    : null,
              ),
            ),
            const SizedBox(height: 30),

            // Nút Gửi (Có hiệu ứng Loading)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submitReport,
                style: ElevatedButton.styleFrom(backgroundColor: isEditing ? Colors.orange : Colors.blueAccent, foregroundColor: Colors.white),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white) // Hiện vòng quay khi đang gửi
                    : Text(isEditing ? "CẬP NHẬT" : "GỬI BÁO CÁO", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
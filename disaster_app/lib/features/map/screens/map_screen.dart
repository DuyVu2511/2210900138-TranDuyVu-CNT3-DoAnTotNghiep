import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as location_pkg;
import 'package:geocoding/geocoding.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert'; // Import thêm để decode user
import 'package:shared_preferences/shared_preferences.dart'; // Import thêm để lấy user ID

import '../models/disaster_model.dart';
import '../services/disaster_service.dart';
import '../../report/screens/create_report_screen.dart';
import '../../../core/widgets/full_screen_image.dart';
import '../widgets/sos_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLocating = false;

  List<DisasterReport> _reports = [];
  final DisasterService _disasterService = DisasterService();

  // BIẾN LƯU ID NGƯỜI DÙNG
  String? _currentUserId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // Lấy User ID
    _loadReports();
  }

  // HÀM LẤY ID NGƯỜI DÙNG TỪ MÁY
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      final userMap = json.decode(userData);
      setState(() {
        _currentUserId = userMap['_id'];
      });
    }
  }

  Future<void> _loadReports() async {
    final reports = await _disasterService.fetchReports();
    if (mounted) {
      setState(() {
        _reports = reports;
      });
    }
  }

  // Hàm public để MainScreen gọi
  void animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _sendSosSignal() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa lấy được vị trí!')));
      _myLocation();
      return;
    }

    final sosReport = DisasterReport(
      id: '',
      title: "CỨU HỘ KHẨN CẤP!",
      description: "Người dùng cần hỗ trợ y tế/cứu nạn ngay lập tức tại vị trí này.",
      location: _currentPosition!,
      type: DisasterType.sos,
      time: DateTime.now(),
      radius: 50,
      imagePath: null,
      userId: _currentUserId ?? 'unknown', // Gửi kèm ID
    );

    bool success = await _disasterService.createReport(sosReport);

    if (success) {
      _loadReports();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("TÍN HIỆU ĐÃ ĐƯỢC GỬI!", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi gửi tín hiệu!")));
    }
  }

  Future<void> _myLocation() async {
    setState(() => _isLocating = true);
    try {
      location_pkg.Location location = location_pkg.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn chưa bật GPS')));
          setState(() => _isLocating = false);
          return;
        }
      }

      location_pkg.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == location_pkg.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != location_pkg.PermissionStatus.granted) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có quyền vị trí')));
          setState(() => _isLocating = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLocating = false;
        });
        animatedMapMove(_currentPosition!, 16.0);
      }
    } catch (e) {
      debugPrint("Lỗi: $e");
      setState(() => _isLocating = false);
    }
  }

  void _showMyLocationInfo(LatLng location) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  FutureBuilder<List<Placemark>>(
                    future: placemarkFromCoordinates(location.latitude, location.longitude),
                    builder: (context, snapshot) {
                      String title = "Đang tải vị trí...";
                      String subtitle = "${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}";

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        Placemark place = snapshot.data![0];
                        title = place.street ?? "Vị trí chưa xác định";
                        subtitle = "${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}";
                        if (subtitle.startsWith(", ")) subtitle = subtitle.substring(2);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text(subtitle, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text("${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}", style: const TextStyle(fontSize: 14, color: Colors.blueAccent)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionBtn(
                        icon: Icons.add_alert, label: "Báo cáo", color: Colors.blue,
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CreateReportScreen(currentLocation: location)),
                          );
                          if (result == true) _loadReports();
                        },
                      ),
                      _buildActionBtn(
                        icon: Icons.copy, label: "Sao chép", color: Colors.grey,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã sao chép: ${location.latitude}, ${location.longitude}")));
                          Navigator.pop(context);
                        },
                      ),
                      _buildActionBtn(
                        icon: Icons.share, label: "Chia sẻ", color: Colors.green,
                        onTap: () {
                          final String googleUrl = "http://googleusercontent.com/maps.google.com/?q=${location.latitude},${location.longitude}";
                          Share.share("Cứu hộ khẩn cấp! Vị trí của tôi: $googleUrl");
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  )
                ]
            )
        )
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              color: color == Colors.blue ? Colors.blue.withOpacity(0.1) : Colors.white,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- HÀM TẠO MARKER ---
  Widget _buildReportMarkerContent(DisasterReport report, {bool isSos = false}) {
    return GestureDetector(
      onTap: () {
        _showReportDetailModal(report);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: isSos ? Colors.red : report.getColor(), width: isSos ? 4 : 2),
          boxShadow: [BoxShadow(color: isSos ? Colors.red.withOpacity(0.5) : Colors.black38, blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Icon(report.getIcon(), color: report.getColor(), size: isSos ? 28 : 20),
      ),
    );
  }

  // --- HÀM HIỂN THỊ CHI TIẾT BÁO CÁO (CÓ PHÂN QUYỀN) ---
  void _showReportDetailModal(DisasterReport report) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(report.getIcon(), color: report.getColor(), size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              report.title,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- KIỂM TRA QUYỀN: CHỈ HIỆN NÚT NẾU LÀ CHÍNH CHỦ ---
                    if (_currentUserId != null && _currentUserId == report.userId) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateReportScreen(
                                currentLocation: report.location,
                                existingReport: report,
                              ),
                            ),
                          );
                          if (result == true) _loadReports();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Xóa cảnh báo?"),
                              content: const Text("Hành động này sẽ xóa vĩnh viễn khỏi hệ thống."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    bool success = await _disasterService.deleteReport(report.id);
                                    if (success) {
                                      _loadReports();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa thành công.")));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Không xóa được!")));
                                    }
                                  },
                                  child: const Text("Xóa vĩnh viễn", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    // ----------------------------------------------------
                  ],
                ),

                if (report.userName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text("Đăng bởi: ${report.userName}", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 12)),
                  ),

                const Divider(),
                Text("Loại: ${report.type.toVietnamese()}", style: TextStyle(color: report.getColor(), fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(report.description, style: const TextStyle(fontSize: 16)),

                if (report.imagePath != null && report.imagePath!.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  const Text("Ảnh hiện trường:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageScreen(
                            imagePath: report.imagePath!,
                            heroTag: report.id,
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: report.id,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: report.imagePath!.startsWith('http')
                            ? Image.network(
                          report.imagePath!,
                          height: 150, width: double.infinity, fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, loading) => loading == null ? child : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        )
                            : Image.file(
                          File(report.imagePath!),
                          height: 150, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Center(child: Text("Ảnh gốc không tồn tại")),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                Text(
                  "Thời gian: ${report.time.toLocal().hour.toString().padLeft(2, '0')}:${report.time.toLocal().minute.toString().padLeft(2, '0')} - ${report.time.toLocal().day}/${report.time.toLocal().month}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        )
        );
    }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 1. TÁCH DANH SÁCH BÁO CÁO THÀNH 2 NHÓM: SOS và THƯỜNG
    final List<DisasterReport> sosReports = _reports.where((r) => r.type == DisasterType.sos).toList();
    final List<DisasterReport> regularReports = _reports.where((r) => r.type != DisasterType.sos).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảnh báo thiên tai'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // LỚP 1: BẢN ĐỒ (PHẢI Ở DƯỚI CÙNG)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(21.0285, 105.8542),
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              backgroundColor: Colors.grey[200]!,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.disaster_app',
                retinaMode: true,
              ),

              CircleLayer(
                circles: _reports.map((report) {
                  return CircleMarker(
                    point: report.location,
                    radius: report.radius,
                    useRadiusInMeter: true,
                    color: report.getColor().withOpacity(0.2),
                    borderColor: report.getColor().withOpacity(0.6),
                    borderStrokeWidth: 1.5,
                  );
                }).toList(),
              ),

              // MARKER LAYER 1: VỊ TRÍ HIỆN TẠI (Nên để đầu tiên để tránh bị đè)
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 24, height: 24, alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () => _showMyLocationInfo(_currentPosition!),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))]),
                        ),
                      ),
                    ),
                  ],
                ),

              // MARKER LAYER 2: BÁO CÁO THƯỜNG (Nằm dưới Marker SOS)
              MarkerLayer(
                markers: regularReports.map((report) {
                  return Marker(
                    point: report.location,
                    width: 40, height: 40, alignment: Alignment.topCenter,
                    child: _buildReportMarkerContent(report),
                  );
                }).toList(),
              ),

              // MARKER LAYER 3: BÁO CÁO SOS (Luôn nằm TRÊN CÙNG của các Marker)
              MarkerLayer(
                markers: sosReports.map((report) {
                  return Marker(
                    point: report.location,
                    width: 50, // Kích thước lớn hơn
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: _buildReportMarkerContent(report, isSos: true),
                  );
                }).toList(),
              ),
            ],
          ),

          // LỚP 2: NÚT SOS (ĐẶT Ở GÓC TRÊN TRÁI VÀ NỔI LÊN TRÊN CÙNG CỦA MỌI THỨ)
          Positioned(
            top: 20,
            left: 15,
            child: Material(
              color: Colors.transparent,
              child: SosButton(
                onSosPressed: _sendSosSignal,
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn_location",
            mini: true,
            onPressed: _isLocating ? null : _myLocation,
            backgroundColor: Colors.white,
            child: _isLocating
                ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, color: Colors.blue),
          ),
          const SizedBox(height: 10),

          FloatingActionButton.extended(
            heroTag: "btn_report",
            onPressed: () async {
              if (_currentPosition == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cần định vị trước khi báo cáo!')));
                _myLocation(); return;
              }
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateReportScreen(currentLocation: _currentPosition!)));
              if (result == true) {
                _loadReports();
              }
            },
            backgroundColor: Colors.redAccent,
            icon: const Icon(Icons.add_alert, color: Colors.white),
            label: const Text("BÁO CÁO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
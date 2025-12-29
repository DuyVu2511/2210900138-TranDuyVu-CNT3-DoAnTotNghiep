import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as location_pkg;
import 'package:geocoding/geocoding.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// --- CÁC IMPORT CẦN THIẾT ---
import '../models/disaster_model.dart';
import '../services/disaster_service.dart';
import '../../report/screens/create_report_screen.dart';
import '../../../core/widgets/full_screen_image.dart';
import '../widgets/sos_button.dart';
import '../widgets/weather_card.dart';
import '../services/weather_service.dart';
import '../../report/screens/my_reports_screen.dart';
import '../../auth/models/user_model.dart';   // <--- QUAN TRỌNG: Để dùng object User
import '../../auth/services/auth_service.dart'; // <--- QUAN TRỌNG: Để lấy quyền Admin
import '../../../utils/event_bus.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  DisasterType? _selectedType;
  StreamSubscription? _refreshSubscription;

  // Lọc danh sách theo loại thiên tai
  List<DisasterReport> get _filteredReports {
    if (_selectedType == null) {
      return _reports;
    }
    return _reports.where((r) => r.type == _selectedType).toList();
  }

  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLocating = false;

  List<DisasterReport> _reports = [];
  final DisasterService _disasterService = DisasterService();

  // ✅ DÙNG BIẾN USER OBJECT (CHỨA ROLE) THAY VÌ CHỈ STRING ID
  User? _currentUser;

  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherInfo;

  final TextEditingController _searchController = TextEditingController();

  LatLng? _searchResultLocation;
  bool _isSearchingAddress = false;

  List<LatLng> _routePoints = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadReports();
    _myLocation();
    _refreshSubscription = EventBus.onRefreshMap.listen((_) {
      print("Map đã nhận tín hiệu đổi tên -> Đang tự động tải lại...");
      _loadCurrentUser(); // Lấy lại tên mới
      _loadReports();     // Lấy lại danh sách báo cáo
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ✅ HÀM LẤY USER MỚI (GỌI AUTH SERVICE)
  Future<void> _loadCurrentUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
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

  Future<void> _fetchWeather(LatLng location) async {
    final data = await _weatherService.fetchWeather(location);
    if (mounted && data != null) {
      setState(() {
        _weatherInfo = data;
      });
    }
  }

  // --- HÀM VẼ ĐƯỜNG ĐI (ĐÃ SỬA SANG HTTPS) ---
  Future<void> _drawRoute(LatLng destination) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang lấy vị trí của bạn...")));
      return;
    }

    // ✅ QUAN TRỌNG: Dùng https:// thay vì http:// để không bị chặn trên Android
    final String url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${_currentPosition!.longitude},${_currentPosition!.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;

          setState(() {
            _routePoints = coordinates.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
          });

          // Đóng modal để nhìn thấy đường đi
          // Navigator.pop(context); // (Tùy chọn: Có thể đóng hoặc không)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang vẽ đường đi...")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy đường đi!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối server bản đồ")));
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
    });
  }

  // ... (Hàm hiển thị thời tiết giữ nguyên) ...
  void _showWeatherDetail() {
    if (_weatherInfo == null) return;
    final data = _weatherInfo!;
    final humidity = "${data['main']['humidity']}%";
    final pressure = "${data['main']['pressure']} hPa";
    final windSpeed = "${data['wind']['speed']} m/s";
    final visibility = "${(data['visibility'] / 1000).toStringAsFixed(1)} km";
    final city = data['name'];
    final temp = data['main']['temp'].toInt();
    final description = data['weather'][0]['description'];
    final displayDesc = description[0].toUpperCase() + description.substring(1);
    final iconCode = data['weather'][0]['icon'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 550,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Text(city, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            Text(displayDesc, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.network('https://openweathermap.org/img/wn/$iconCode@4x.png', width: 100, height: 100, fit: BoxFit.contain),
                Text("$temp°", style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w300, color: Colors.blueAccent, height: 1.0)),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildDetailCard(Icons.water_drop, "Độ ẩm", humidity, Colors.blue)),
                const SizedBox(width: 15),
                Expanded(child: _buildDetailCard(Icons.air, "Tốc độ gió", windSpeed, Colors.teal)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildDetailCard(Icons.visibility, "Tầm nhìn", visibility, Colors.orange)),
                const SizedBox(width: 15),
                Expanded(child: _buildDetailCard(Icons.speed, "Áp suất", pressure, Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  List<DisasterReport> _findNearbyReports(LatLng targetPoint) {
    const Distance distance = Distance();
    return _reports.where((report) {
      return distance.as(LengthUnit.Meter, targetPoint, report.location) < 20;
    }).toList();
  }

  void animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)), zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) controller.dispose();
    });

    controller.forward();
  }

  Future<void> _myLocation() async {
    setState(() => _isLocating = true);
    try {
      // --- [QUAN TRỌNG] TÁCH RIÊNG XỬ LÝ CHO WEB VÀ APP ---

      // NẾU LÀ APP (ANDROID/IOS)
      if (!kIsWeb) {
        // Chỉ App mới cần kiểm tra service GPS bật hay chưa
        location_pkg.Location location = location_pkg.Location();
        bool serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) {
            setState(() => _isLocating = false);
            return;
          }
        }

        // Kiểm tra quyền theo kiểu của gói 'location' (để kích hoạt popup tốt hơn trên Android)
        location_pkg.PermissionStatus permissionGranted = await location.hasPermission();
        if (permissionGranted == location_pkg.PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
          if (permissionGranted != location_pkg.PermissionStatus.granted) {
            setState(() => _isLocating = false);
            return;
          }
        }
      }

      // NẾU LÀ WEB (HOẶC APP ĐÃ QUA BƯỚC TRÊN)
      // Dùng Geolocator để lấy vị trí (Thằng này chạy Web rất mượt)
      else {
        // Kiểm tra quyền trên Web
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn từ chối quyền, không định vị được!")));
            setState(() => _isLocating = false);
            return;
          }
        }
      }

      // --- ĐOẠN LẤY VỊ TRÍ (CHUNG CHO CẢ 2) ---
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: kIsWeb ? LocationAccuracy.low : LocationAccuracy.high, // Web thì lấy thấp thôi
        timeLimit: const Duration(seconds: 10), // Chờ 10s
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLocating = false;
        });
        animatedMapMove(_currentPosition!, 16.0);
        _fetchWeather(_currentPosition!);
      }
    } catch (e) {
      debugPrint("Lỗi định vị: $e");
      // Trên web đôi khi lỗi Timeout, hãy thử lại
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      setState(() => _isLocating = false);
    }
  }

  Future<void> _searchPlace() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSearchingAddress = true);

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        LatLng target = LatLng(loc.latitude, loc.longitude);
        setState(() => _searchResultLocation = target);
        animatedMapMove(target, 15.0);
        _fetchWeather(target);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã tìm thấy: $query")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy địa điểm này!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Không tìm thấy địa danh")));
    } finally {
      setState(() => _isSearchingAddress = false);
    }
  }

  String _calculateDistance(LatLng target) {
    if (_currentPosition == null) return "? km";
    final Distance distance = const Distance();
    final double meters = distance.as(LengthUnit.Meter, _currentPosition!, target);
    if (meters < 1000) return "${meters.toInt()}m";
    return "${(meters / 1000).toStringAsFixed(1)}km";
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
      // ✅ SỬA: Lấy ID từ User Object
      userId: _currentUser?.id ?? 'unknown',
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

  // --- UI COMPONENTS ---
  void _showMyLocationInfo(LatLng location) {
    // (Giữ nguyên logic của bạn, chỉ rút gọn để dễ nhìn)
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  // ... (Phần PlaceMark giữ nguyên) ...
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionBtn(icon: Icons.add_alert, label: "Báo cáo", color: Colors.blue, onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateReportScreen(currentLocation: location)));
                        if (result == true) _loadReports();
                      }),
                      _buildActionBtn(icon: Icons.copy, label: "Sao chép", color: Colors.grey, onTap: () => Navigator.pop(context)),
                      _buildActionBtn(icon: Icons.share, label: "Chia sẻ", color: Colors.green, onTap: () => Navigator.pop(context)),
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
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300), color: color == Colors.blue ? Colors.blue.withOpacity(0.1) : Colors.white),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ✅ ĐÃ SỬA getTypeColor()
  Widget _buildReportMarkerContent(DisasterReport report, {bool isSos = false}) {
    return GestureDetector(
      onTap: () {
        final nearbyReports = _findNearbyReports(report.location);
        _showReportsModal(nearbyReports);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          // ✅ SỬA: getTypeColor()
          border: Border.all(color: isSos ? Colors.red : report.getTypeColor(), width: isSos ? 4 : 2),
          boxShadow: [BoxShadow(color: isSos ? Colors.red.withOpacity(0.5) : Colors.black38, blurRadius: 8, offset: const Offset(0, 3))],
        ),
        // ✅ SỬA: getTypeColor()
        child: Icon(report.getIcon(), color: report.getTypeColor(), size: isSos ? 28 : 20),
      ),
    );
  }

  // ✅ HÀM HIỂN THỊ DANH SÁCH BÁO CÁO (NÂNG CẤP: Chỉ đường + Nút chữ)
  void _showReportsModal(List<DisasterReport> nearbyReports) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 500,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 15),

            Text(
              "Tìm thấy ${nearbyReports.length} báo cáo",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
            ),
            const Divider(),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: nearbyReports.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final report = nearbyReports[index];

                  // LOGIC PHÂN QUYỀN
                  final isMyReport = _currentUser != null && _currentUser!.id == report.userId;
                  final isAdmin = _currentUser?.role == 'admin';
                  final canDelete = isAdmin || isMyReport;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              // ✅ SỬA: getTypeColor()
                                color: report.getTypeColor().withOpacity(0.1),
                                shape: BoxShape.circle
                            ),
                            // ✅ SỬA: getTypeColor()
                            child: Icon(report.getIcon(), color: report.getTypeColor()),
                          ),
                          title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Dòng Loại thiên tai • Người đăng (Cũ)
                              Text(
                                "${report.type.toVietnamese()} • ${report.userName ?? 'Ẩn danh'}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),

                              // 2. Dòng Mô tả chi tiết (Mới)
                              if (report.description.isNotEmpty) ...[
                                const SizedBox(height: 4), // Cách ra một chút
                                Text(
                                  "Mô tả: ${report.description}",
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  maxLines: 3, // Hiện tối đa 3 dòng
                                  overflow: TextOverflow.ellipsis, // Dài quá thì hiện dấu ...
                                ),
                              ]
                            ],
                          ),
                        ),

                        if (report.imagePath != null && report.imagePath!.isNotEmpty)
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageScreen(imagePath: report.imagePath!, heroTag: "map_${report.id}"))),
                            child: Container(
                              height: 120, width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: report.imagePath!.startsWith('http')
                                    ? Image.network(report.imagePath!, fit: BoxFit.cover)
                                    : Image.file(File(report.imagePath!), fit: BoxFit.cover),
                              ),
                            ),
                          ),

                        // --- KHU VỰC NÚT BẤM (ACTION BAR) ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn đều 2 bên
                            children: [
                              // 1. NÚT CHỈ ĐƯỜNG (LUÔN HIỆN)
                              TextButton.icon(
                                icon: const Icon(Icons.directions, color: Colors.blueAccent),
                                label: const Text("Chỉ đường", style: TextStyle(color: Colors.blueAccent)),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _drawRoute(report.location);
                                },
                              ),

                              // 2. NÚT ADMIN/USER (BÊN PHẢI)
                              Row(
                                children: [
                                  if (isMyReport && report.type != DisasterType.sos)
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                      label: const Text("Sửa", style: TextStyle(color: Colors.orange)),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateReportScreen(currentLocation: report.location, existingReport: report)));
                                        if (result == true) _loadReports();
                                      },
                                    ),

                                  if (canDelete)
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      label: const Text("Xóa", style: TextStyle(color: Colors.red)),
                                      onPressed: () => _confirmDelete(report),
                                    ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(DisasterReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa cảnh báo?"),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              bool success = await _disasterService.deleteReport(report.id);
              if (success) {
                _loadReports();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa thành công.")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Không xóa được!")));
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final List<DisasterReport> displayList = _filteredReports;
    final List<DisasterReport> sosReports = _reports.where((r) => r.type == DisasterType.sos).toList();
    final List<DisasterReport> regularReports = _reports.where((r) => r.type != DisasterType.sos).toList();

    // KIỂM TRA: Đang chạy trên Web hay Mobile?
    final bool isWebLayout = kIsWeb;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảnh báo thiên tai'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        // Trên web có thể ẩn nút back nếu không cần thiết
        automaticallyImplyLeading: !isWebLayout,
      ),
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // 1. LỚP BẢN ĐỒ (NỀN - GIỮ NGUYÊN CHO CẢ 2)
          // ---------------------------------------------------------
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(21.0285, 105.8542),
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              backgroundColor: Colors.grey[200]!,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom | InteractiveFlag.scrollWheelZoom),
              onTap: (_, __) { FocusScope.of(context).unfocus(); },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.disaster_app',
                retinaMode: true,
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(polylines: [Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.blueAccent)]),
              CircleLayer(
                circles: displayList.map((r) => CircleMarker(
                  point: r.location,
                  radius: r.radius,
                  useRadiusInMeter: true,
                  color: r.getTypeColor().withOpacity(0.2),
                  borderColor: r.getTypeColor().withOpacity(0.6),
                  borderStrokeWidth: 1.5,
                )).toList(),
              ),
              if (_currentPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 24, height: 24, alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => _showMyLocationInfo(_currentPosition!),
                      child: Container(decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))])),
                    ),
                  ),
                ]),
              MarkerLayer(markers: regularReports.map((report) => Marker(point: report.location, width: 40, height: 40, alignment: Alignment.topCenter, child: _buildReportMarkerContent(report))).toList()),
              MarkerLayer(markers: sosReports.map((report) => Marker(point: report.location, width: 50, height: 50, alignment: Alignment.topCenter, child: _buildReportMarkerContent(report, isSos: true))).toList()),
              if (_searchResultLocation != null)
                MarkerLayer(markers: [Marker(point: _searchResultLocation!, width: 50, height: 50, child: Column(children: [const Icon(Icons.location_on, color: Colors.purpleAccent, size: 40), Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle))]))]),
            ],
          ),

          // Nút tắt chỉ đường (Logic chung)
          if (_routePoints.isNotEmpty)
            Positioned(
                top: isWebLayout ? 150 : 190, // Web thì để cao hơn chút
                right: 15,
                child: FloatingActionButton.small(onPressed: _clearRoute, backgroundColor: Colors.white, child: const Icon(Icons.close, color: Colors.red))
            ),

          // ---------------------------------------------------------
          // 2. KHU VỰC TÌM KIẾM & BỘ LỌC (PHÂN LUỒNG APP/WEB)
          // ---------------------------------------------------------
          // Nếu là WEB: Căn giữa màn hình
          if (isWebLayout)
            Positioned(
              top: 20, left: 0, right: 0, // Neo top, full ngang
              child: Column( // Dùng Column để xếp Tìm kiếm trên, Lọc dưới
                children: [
                  // Thanh tìm kiếm Web (Rộng tối đa 600)
                  Container(
                    width: 600,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
                    child: _buildSearchField(), // (Đã tách hàm bên dưới cho gọn)
                  ),
                  const SizedBox(height: 15),
                  // Thanh bộ lọc Web (Rộng tối đa 800)
                  SizedBox(
                    height: 40, width: 800,
                    child: Center( // Căn giữa các chip
                      child: _buildFilterList(), // (Đã tách hàm)
                    ),
                  ),
                ],
              ),
            )
          // Nếu là MOBILE: Giữ nguyên vị trí cũ (Positioned)
          else ...[
            Positioned(
              top: 10, left: 15, right: 15,
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
                child: _buildSearchField(),
              ),
            ),
            Positioned(
              top: 70, left: 0, right: 0,
              child: SizedBox(
                height: 40,
                child: _buildFilterList(),
              ),
            ),
          ],

          // ---------------------------------------------------------
          // 3. CÁC NÚT CHỨC NĂNG (History, SOS, Weather)
          // ---------------------------------------------------------

          // Nút Lịch sử:
          // Mobile: Top 120, Left 15.
          // Web: Top 20, Left 20 (Góc trái trên cùng cho thoáng)
          Positioned(
            top: isWebLayout ? 20 : 120,
            left: isWebLayout ? 20 : 15,
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReportsScreen()));
                _loadReports();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)]),
                child: const Icon(Icons.history, color: Colors.blueAccent),
                // Tooltip cho Web dễ dùng hơn
              ),
            ),
          ),

          // Nút SOS:
          // Mobile: Top 180 (dưới nút lịch sử).
          // Web: Bottom 30, Left 30 (Góc trái dưới cùng - Vị trí chiến lược)
          isWebLayout
              ? Positioned(bottom: 30, left: 30, child: Material(color: Colors.transparent, child: SosButton(onSosPressed: _sendSosSignal)))
              : Positioned(top: 180, left: 15, child: Material(color: Colors.transparent, child: SosButton(onSosPressed: _sendSosSignal))),

          // Thời tiết:
          // Mobile: Top 120, Right 05.
          // Web: Top 20, Right 20 (Góc phải trên cùng)
          Positioned(
              top: isWebLayout ? 20 : 120,
              right: isWebLayout ? 20 : 5,
              child: GestureDetector(onTap: _showWeatherDetail, child: WeatherCard(weatherData: _weatherInfo))
          ),
        ],
      ),

      // 4. FLOATING BUTTON (Góc phải dưới cùng)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn_location",
            mini: true,
            onPressed: _isLocating ? null : _myLocation,
            backgroundColor: Colors.white,
            // Thêm Tooltip cho Web
            tooltip: "Vị trí của tôi",
            child: _isLocating ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, color: Colors.blue),
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
              if (result == true) _loadReports();
            },
            backgroundColor: Colors.redAccent,
            icon: const Icon(Icons.add_alert, color: Colors.white),
            label: const Text("BÁO CÁO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- HÀM TÁCH RIÊNG (để code đỡ rối) ---

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _searchPlace(),
      decoration: InputDecoration(
        hintText: "Tìm kiếm (VD: Hà Nội...)",
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
        suffixIcon: _isSearchingAddress
            ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() => _searchResultLocation = null); FocusScope.of(context).unfocus(); }),
      ),
    );
  }

  Widget _buildFilterList() {
    // Trên Mobile thì Scroll ngang, Trên Web thì căn giữa
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      shrinkWrap: kIsWeb, // Web: co lại cho vừa nội dung
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: const Text("Tất cả"),
            selected: _selectedType == null,
            onSelected: (bool selected) { setState(() => _selectedType = null); },
            selectedColor: Colors.blueAccent,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(color: _selectedType == null ? Colors.white : Colors.black),
            elevation: 3,
          ),
        ),
        ...DisasterType.values.map((type) {
          if (type == DisasterType.sos) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type.toVietnamese()),
              selected: _selectedType == type,
              onSelected: (bool selected) { setState(() => _selectedType = selected ? type : null); },
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(color: _selectedType == type ? Colors.white : Colors.black),
              elevation: 3,
            ),
          );
        }).toList(),
      ],
    );
  }
}
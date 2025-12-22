import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as location_pkg;
import 'package:geocoding/geocoding.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/disaster_model.dart';
import '../services/disaster_service.dart';
import '../../report/screens/create_report_screen.dart';
import '../../../core/widgets/full_screen_image.dart';
import '../widgets/sos_button.dart';
import '../widgets/weather_card.dart';
import '../services/weather_service.dart';

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

  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherInfo;

  final TextEditingController _searchController = TextEditingController();

  LatLng? _searchResultLocation;
  bool _isSearchingAddress = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadReports();
    _myLocation();
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

  Future<void> _fetchWeather(LatLng location) async {
    final data = await _weatherService.fetchWeather(location);
    if (mounted && data != null) {
      setState(() {
        _weatherInfo = data;
      });
    }
  }

  void _showWeatherDetail() {
    if (_weatherInfo == null) return;

    final data = _weatherInfo!;

    // Lấy dữ liệu và thêm đơn vị
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
            // Thanh gạch ngang
            Center(
              child: Container(
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 25),

            // HEADER
            Text(city, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            Text(displayDesc, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic)),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/$iconCode@4x.png', // Icon to nét hơn
                  width: 100, height: 100,
                  fit: BoxFit.contain,
                ),
                Text(
                  "$temp°",
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w300,
                    color: Colors.blueAccent,
                    height: 1.0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // GRID THÔNG SỐ (2 hàng)
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

  // --- WIDGET CON (PHIÊN BẢN ĐẸP) ---
  Widget _buildDetailCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
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

  // Hàm tìm tất cả báo cáo gần một vị trí (xử lý việc marker đè nhau)
  List<DisasterReport> _findNearbyReports(LatLng targetPoint) {
    const Distance distance = Distance();
    // Lọc ra những báo cáo nằm trong bán kính 20 mét so với điểm được bấm
    return _reports.where((report) {
      return distance.as(LengthUnit.Meter, targetPoint, report.location) < 20;
    }).toList();
  }

  // --- MAP MOVEMENT & LOCATION ---
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
        _fetchWeather(_currentPosition!);
      }
    } catch (e) {
      debugPrint("Lỗi: $e");
      setState(() => _isLocating = false);
    }
  }

  Future<void> _searchPlace() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    // 1. Bắt đầu tìm -> Hiện loading
    setState(() => _isSearchingAddress = true);

    try {
      // Tìm tọa độ từ tên địa điểm
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        Location loc = locations.first;
        LatLng target = LatLng(loc.latitude, loc.longitude);

        // 2. Cập nhật vị trí tìm được
        setState(() {
          _searchResultLocation = target; // Lưu để vẽ marker
        });

        // Bay đến địa điểm đó (Zoom 14)
        animatedMapMove(target, 15.0);
        _fetchWeather(target);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã tìm thấy: $query")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy địa điểm này!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Không tìm thấy địa danh")));
    } finally {
      // 4. Kết thúc tìm -> Tắt loading dù thành công hay thất bại
      setState(() => _isSearchingAddress = false);
    }
  }

  // Hàm tính và định dạng khoảng cách từ chỗ mình đến điểm thiên tai
  String _calculateDistance(LatLng target) {
    if (_currentPosition == null) return "? km";

    final Distance distance = const Distance();
    final double meters = distance.as(LengthUnit.Meter, _currentPosition!, target);

    if (meters < 1000) {
      return "${meters.toInt()}m"; // Dưới 1km thì hiện mét (VD: 500m)
    } else {
      return "${(meters / 1000).toStringAsFixed(1)}km"; // Trên 1km thì hiện km (VD: 2.5km)
    }
  }

  // --- SOS SIGNAL ---
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
      userId: _currentUserId ?? 'unknown',
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

  // --- HÀM TẠO MARKER (ĐÃ SỬA ĐỂ GỌI DANH SÁCH) ---
  Widget _buildReportMarkerContent(DisasterReport report, {bool isSos = false}) {
    return GestureDetector(
      onTap: () {
        // Thay đổi: Tìm các báo cáo lân cận và hiển thị danh sách
        final nearbyReports = _findNearbyReports(report.location);
        _showReportsModal(nearbyReports);
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

  // --- HÀM HIỂN THỊ DANH SÁCH BÁO CÁO (MỚI) ---
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
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            Text(
              "Tìm thấy ${nearbyReports.length} báo cáo tại đây",
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
                  final isMyReport = _currentUserId != null && _currentUserId == report.userId;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: report.getColor().withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(report.getIcon(), color: report.getColor()),
                          ),
                          // Dùng Row để hiện Tiêu đề + Khoảng cách ---
                          title: Row(
                            children: [
                              Expanded(
                                  child: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold))
                              ),
                              // Badge hiển thị khoảng cách
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.directions_walk, size: 12, color: Colors.deepOrange),
                                    const SizedBox(width: 4),
                                    Text(
                                      _calculateDistance(report.location), // Gọi hàm tính toán
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // ---------------------------------------------------------
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "${report.type.toVietnamese()} • ${report.userName ?? 'Ẩn danh'}",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                          trailing: isMyReport
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
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
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _confirmDelete(report),
                              ),
                            ],
                          )
                              : null,
                        ),
                        if (report.imagePath != null && report.imagePath!.isNotEmpty)
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageScreen(imagePath: report.imagePath!, heroTag: "map_${report.id}"))),
                            child: Container(
                              height: 120, width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: report.imagePath!.startsWith('http')
                                    ? Image.network(report.imagePath!, fit: BoxFit.cover)
                                    : Image.file(
                                  File(report.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                ),
                              ),
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

  // --- HÀM XÁC NHẬN XÓA (MỚI) ---
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
              Navigator.pop(ctx); // Đóng dialog
              Navigator.pop(context); // Đóng bottom sheet
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

    // TÁCH DANH SÁCH BÁO CÁO
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
          // --- LỚP 1: BẢN ĐỒ ---
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
              onTap: (_, __) {
                FocusScope.of(context).unfocus();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.disaster_app',
                retinaMode: true,
              ),

              // Vòng tròn bán kính
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

              // Marker: Vị trí của tôi
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

              // Marker: Báo cáo thường
              MarkerLayer(
                markers: regularReports.map((report) {
                  return Marker(
                    point: report.location,
                    width: 40, height: 40, alignment: Alignment.topCenter,
                    child: _buildReportMarkerContent(report),
                  );
                }).toList(),
              ),

              // Marker: Báo cáo SOS
              MarkerLayer(
                markers: sosReports.map((report) {
                  return Marker(
                    point: report.location,
                    width: 50, height: 50,
                    alignment: Alignment.topCenter,
                    child: _buildReportMarkerContent(report, isSos: true),
                  );
                }).toList(),
              ),

              // --- MARKER KẾT QUẢ TÌM KIẾM (ĐẶT Ở ĐÂY LÀ ĐÚNG) ---
              if (_searchResultLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _searchResultLocation!,
                      width: 50, height: 50,
                      child: Column(
                        children: [
                          const Icon(Icons.location_on, color: Colors.purpleAccent, size: 40),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // (Kết thúc FlutterMap ở đây)

          // --- LỚP 2: THANH TÌM KIẾM ---
          Positioned(
            top: 10, left: 15, right: 15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchPlace(),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm (VD: Hà Nội...)",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                  suffixIcon: _isSearchingAddress
                      ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                      : IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchResultLocation = null);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ),
            ),
          ),

          // --- LỚP 3: NÚT SOS ---
          Positioned(
            top: 80, left: 15,
            child: Material(
              color: Colors.transparent,
              child: SosButton(onSosPressed: _sendSosSignal),
            ),
          ),
          // --- LỚP 4: THẺ THỜI TIẾT ---
          Positioned(
            top: 80,
            right: 05,
            child: GestureDetector(
              onTap: _showWeatherDetail,
              child: WeatherCard(weatherData: _weatherInfo),
          ),
          ),
        ],
      ),

      // Floating Action Button
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
}
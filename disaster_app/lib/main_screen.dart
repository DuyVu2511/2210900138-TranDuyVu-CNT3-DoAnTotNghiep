import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // Nhớ import cái này để dùng LatLng
import 'features/map/screens/map_screen.dart';
import 'features/list/screens/alert_list_screen.dart';
import 'features/auth/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 0 = Bản đồ, 1 = Danh sách

  // 1. TẠO CHÌA KHÓA ĐỂ ĐIỀU KHIỂN MAP SCREEN TỪ XA
  // GlobalKey giúp MainScreen "thò tay" vào bên trong MapScreen để gọi hàm
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giúp giữ trạng thái các màn hình (Map không bị load lại)
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // TAB 0: BẢN ĐỒ
          // Gắn chìa khóa _mapKey vào đây
          MapScreen(key: _mapKey),

          // TAB 1: DANH SÁCH
          AlertListScreen(
            key: UniqueKey(), // Giữ nguyên để refresh danh sách khi vào
            // 2. XỬ LÝ KHI BẤM VÀO 1 DÒNG CẢNH BÁO
            onNavigateToMap: (LatLng location) {
              // Bước A: Chuyển ngay sang tab Bản đồ (Index 0)
              setState(() {
                _selectedIndex = 0;
              });
              // Bước B: Ra lệnh cho bản đồ bay đến vị trí đó
              // Dùng Future.delayed 100ms để đảm bảo giao diện Map hiện lên xong mới bắt đầu bay
              Future.delayed(const Duration(milliseconds: 100), () {
                // Gọi hàm animatedMapMove thông qua chìa khóa
                _mapKey.currentState?.animatedMapMove(location, 17.0);
              });
            },
          ),
          // Tab 2: Profile
          const ProfileScreen(),
        ],
      ),

      // THANH MENU DƯỚI ĐÁY
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Bản đồ',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Danh sách',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân'),
        ],
      ),
    );
  }
}
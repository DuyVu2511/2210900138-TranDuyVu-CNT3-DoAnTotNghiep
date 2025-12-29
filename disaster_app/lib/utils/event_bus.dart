import 'dart:async';

class EventBus {
  // Tạo một luồng phát sóng (Broadcast) để các màn hình nghe nhau
  static final StreamController<bool> _refreshMapController = StreamController<bool>.broadcast();

  // Màn hình Map sẽ lắng nghe cái này
  static Stream<bool> get onRefreshMap => _refreshMapController.stream;

  // Màn hình Profile sẽ gọi cái này để báo tin
  static void triggerRefreshMap() {
    _refreshMapController.sink.add(true);
  }
}
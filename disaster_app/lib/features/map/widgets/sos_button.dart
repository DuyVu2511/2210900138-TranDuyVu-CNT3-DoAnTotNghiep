import 'package:flutter/material.dart';
import 'dart:async';

class SosButton extends StatefulWidget {
  final VoidCallback onSosPressed;

  const SosButton({super.key, required this.onSosPressed});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  int _secondsHeld = 0; // Đếm số giây đã giữ

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startHolding() {
    _secondsHeld = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsHeld++;
      if (_secondsHeld >= 3) { // ĐỦ 3 GIÂY
        timer.cancel();
        widget.onSosPressed(); // Gửi SOS
      } else {
        // Hiện thông báo đếm ngược (Optional)
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Giữ thêm ${3 - _secondsHeld} giây để gửi SOS...", style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 900),
          ),
        );
      }
    });
  }

  void _stopHolding() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Ẩn thông báo nếu thả tay sớm
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Bắt đầu giữ
      onTapDown: (_) => _startHolding(),
      // Thả tay ra (hủy đếm)
      onTapUp: (_) => _stopHolding(),
      onTapCancel: () => _stopHolding(),

      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.4)),
            ),
          ),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.red,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sos, color: Colors.white, size: 24),
                Text("3s", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
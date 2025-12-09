import 'dart:io';
import 'package:flutter/material.dart';

class FullScreenImageScreen extends StatelessWidget {
  final String imagePath;
  final String heroTag; // Tag để tạo hiệu ứng phóng to mượt mà

  const FullScreenImageScreen({
    super.key,
    required this.imagePath,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Nền đen để xem ảnh rõ hơn
      // Appbar trong suốt có nút X để đóng
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      // Sử dụng extendBodyBehindAppBar để ảnh tràn lên cả khu vực status bar
      extendBodyBehindAppBar: true,
      body: Center(
        // InteractiveViewer cho phép dùng 2 ngón tay để ZOOM ảnh
        child: InteractiveViewer(
          panEnabled: true, // Cho phép kéo ảnh khi đã zoom
          minScale: 0.5,
          maxScale: 4.0, // Zoom tối đa 4 lần
          child: Hero(
            tag: heroTag, // Tag phải trùng với ảnh nhỏ bên ngoài
            child: imagePath.startsWith('http')
                ? Image.network(imagePath, fit: BoxFit.contain)
                : Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'features/map/screens/map_screen.dart';
import 'features/splash/splash_screen.dart';
import 'main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Warning',
      debugShowCheckedModeBanner: false, // Tắt chữ debug ở góc
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
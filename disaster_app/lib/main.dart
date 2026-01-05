import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/map/screens/map_screen.dart';
import 'features/splash/splash_screen.dart';
import 'main_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
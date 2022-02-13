import 'package:camera/camera.dart';
import 'package:candrink/screens/camera_screen.dart';
import 'package:candrink/services/permission_service.dart';
import 'package:flutter/material.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  getPermission();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: CameraScreen(cameras),
    );
  }
}

import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermissions() async {
  final permissions = [
    await Permission.bluetooth.request(),
    await Permission.bluetoothConnect.request(),
    await Permission.bluetoothScan.request(),
    await Permission.camera.request(),
    await Permission.microphone.request(),
  ];

  return permissions.every((status) => status == PermissionStatus.granted);
}

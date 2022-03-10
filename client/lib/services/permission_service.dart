import 'package:permission_handler/permission_handler.dart';

Future<bool> getPermission() async {
  await Permission.camera.request();
  await Permission.microphone.request();

  if (await Permission.camera.isGranted &&
      await Permission.microphone.isGranted) {
    return Future.value(true);
  } else {
    return Future.value(false);
  }
}

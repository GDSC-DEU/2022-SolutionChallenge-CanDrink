import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

Future loadModel() async {
  await Tflite.loadModel(
      model: "assets/tflite/ssd_mobilenet.tflite",
      labels: "assets/tflite/ssd_mobilenet.txt");
}

runModel(CameraImage? cameraImage, List recognitionsList) async {
  recognitionsList = (await Tflite.detectObjectOnFrame(
    bytesList: cameraImage!.planes.map((plane) {
      return plane.bytes;
    }).toList(),
    imageHeight: cameraImage.height,
    imageWidth: cameraImage.width,
    imageMean: 127.5,
    imageStd: 127.5,
    numResultsPerClass: 1,
    threshold: 0.4,
  ))!;

  return recognitionsList;
}

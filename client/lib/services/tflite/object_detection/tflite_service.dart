import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

Future loadModel() async {
  await Tflite.loadModel(
    model: "assets/tflite/ssd_mobilenet.tflite",
    labels: "assets/tflite/ssd_mobilenet.txt",
  );
}

runModel(CameraImage? cameraImage, List recognitionsList) async {
  recognitionsList = (await Tflite.detectObjectOnFrame(
    bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
    imageHeight: cameraImage.height,
    imageWidth: cameraImage.width,
    imageMean: 127.5,
    imageStd: 127.5,
    numResultsPerClass: 1,
    threshold: 0.4,
  ))!;

  recognitionsList = filterRecognitions(recognitionsList);

  return recognitionsList;
}

List filterRecognitions(List recognitionsList) {
  var newRecognitionsList = [];
  for (var result in recognitionsList) {
    if (result['detectedClass'] == 'can' || result['detectedClass'] == 'bottle') {
      newRecognitionsList.add(result);
    }
  }
  return newRecognitionsList;
}

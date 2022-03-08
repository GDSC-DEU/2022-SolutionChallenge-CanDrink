import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

Future<List<Barcode>> scanBarcode(CameraImage? cameraImage) async {
  final WriteBuffer allBytes = WriteBuffer();

  for (Plane plane in cameraImage!.planes) {
    allBytes.putUint8List(plane.bytes);
  }

  final bytes = allBytes.done().buffer.asUint8List();

  final Size imageSize =
      Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());

  const InputImageRotation imageRotation = InputImageRotation.Rotation_0deg;

  final InputImageFormat inputImageFormat =
      InputImageFormatMethods.fromRawValue(cameraImage.format.raw) ??
          InputImageFormat.NV21;

  final planeData = cameraImage.planes.map(
    (Plane plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    },
  ).toList();

  final inputImageData = InputImageData(
    size: imageSize,
    imageRotation: imageRotation,
    inputImageFormat: inputImageFormat,
    planeData: planeData,
  );

  final inputImage =
      InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

  final barcodeScanner = GoogleMlKit.vision.barcodeScanner();

  final List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);

  return barcodes;
}

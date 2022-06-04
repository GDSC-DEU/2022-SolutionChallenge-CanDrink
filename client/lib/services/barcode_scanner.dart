import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:http/http.dart' as http;

Future<String?> getProductNameFromBarcode(String barcode) async {
  final url = Uri.parse('https://www.beepscan.com/barcode/$barcode');
  final response = await http.get(url);
  final doc = htmlparser.parse(response.body);

  try {
    var name = doc.getElementsByClassName('container')[0].getElementsByTagName('b')[0].innerHtml;
    return name;
  } catch (e) {}

  return null;
}

String? getExpirationFromBarcode(String barcode) {
  final regex = RegExp(r'^\d{13}(\d{1})(\d{2})(\d{2})$');
  final match = regex.firstMatch(barcode);
  if (match == null) return null;

  final values = match.groups([1, 2, 3]);
  final digit = int.parse(values[0]!);
  final time1 = int.parse(values[1]!);
  final time2 = int.parse(values[2]!);

  switch (digit) {
    case 1: // GS25 DDMM
      return '$time2월 $time1일';
    case 2: // GS25 HHDD
      return '$time2일 $time1시';
    case 4: // CU DDHH
      return '$time1일 $time2시';
  }
  return null;
}

Future<List<String>> scanBarcodes(CameraImage? cameraImage) async {
  final WriteBuffer allBytes = WriteBuffer();

  for (Plane plane in cameraImage!.planes) {
    allBytes.putUint8List(plane.bytes);
  }

  final bytes = allBytes.done().buffer.asUint8List();

  final Size imageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());

  const InputImageRotation imageRotation = InputImageRotation.Rotation_0deg;

  final InputImageFormat inputImageFormat = InputImageFormatMethods.fromRawValue(cameraImage.format.raw) ?? InputImageFormat.NV21;

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

  final inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

  final barcodeScanner = GoogleMlKit.vision.barcodeScanner();

  final List<String> barcodes =
      (await barcodeScanner.processImage(inputImage)).map((barcode) => barcode.value.rawValue).whereType<String>().toList();

  return barcodes;
}

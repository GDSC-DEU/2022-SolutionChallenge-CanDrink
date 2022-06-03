import 'package:candrink/services/tflite/recognition.dart';
import 'package:candrink/ui/camera_view_singleton.dart';
import 'package:flutter/material.dart';

/// Individual bounding box
class BoundingBox extends StatelessWidget {
  final Recognition recognition;

  const BoundingBox({required this.recognition, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (recognition.location == null) return Container();
    // Color for bounding box
    Color color = Colors.primaries[(recognition.label.length + recognition.label.codeUnitAt(0) + recognition.id) % Colors.primaries.length];

    final location = recognition.renderLocation!;
    final actualWidth = CameraViewSingleton.actualPreviewSize.width;
    final actualHeight = CameraViewSingleton.actualPreviewSize.height;

    print('${actualWidth}, ${actualHeight}');

    print('renderLocation=${recognition.renderLocation!}');

    return Positioned(
      left: location.left,
      top: location.top,
      width: location.width,
      height: location.height,
      child: Container(
        width: location.width,
        height: location.height,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: const BorderRadius.all(Radius.circular(2)),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: color,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(recognition.label),
                  Text(" " + recognition.score.toStringAsFixed(2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

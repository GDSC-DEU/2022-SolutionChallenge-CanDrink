import 'dart:math';

import 'package:candrink/ui/camera_view_singleton.dart';
import 'package:flutter/cupertino.dart';

/// Represents the recognition output from the model
class Recognition {
  /// Index of the result
  int id;

  /// Label of the result
  String label;

  /// Confidence [0.0, 1.0]
  double score;

  /// Location of bounding box rect
  ///
  /// The rectangle corresponds to the raw input image
  /// passed for inference
  Rect? location;

  Recognition({required this.id, required this.label, required this.score, this.location});

  /// Returns bounding box rectangle corresponding to the
  /// displayed image on screen
  ///
  /// This is the actual location where rectangle is rendered on
  /// the screen
  Rect? get renderLocation {
    if (location == null) return null;

    // ratioX = screenWidth / imageInputWidth
    // ratioY = ratioX if image fits screenWidth with aspectRatio = constant

    final actualWidth = CameraViewSingleton.screenSize.width;
    final actualHeight = CameraViewSingleton.screenSize.height;

    Rect transformedRect = Rect.fromCenter(
      center: Offset(
        location!.center.dx * actualWidth,
        location!.center.dy * actualHeight,
      ),
      width: location!.width * actualHeight,
      height: location!.height * actualHeight,
    );
    return transformedRect;
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}

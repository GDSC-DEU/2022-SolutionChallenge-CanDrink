import 'package:camera/camera.dart';
import 'package:image/image.dart';

class ImageUtils {
  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static Image convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return convertYUV420toImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return convertBGRA8888ToImage(cameraImage);
    }
    throw Exception('Image format ${cameraImage.format.group} does not support');
  }

  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static Image convertYUV420toImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel;

    final image = Image(width, height);

    for (var w = 0; w < width; w++) {
      for (var h = 0; h < height; h++) {
        final uvIndex = uvPixelStride! * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final index = h * width + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.data[index] = yuv2rgb(y, u, v);
      }
    }
    return image;
  }

  /// Converts a [CameraImage] in BGRA888 format to [imageLib.Image] in RGB format
  static Image convertBGRA8888ToImage(CameraImage cameraImage) {
    Image image = Image.fromBytes(
      cameraImage.planes[0].width!,
      cameraImage.planes[0].height!,
      cameraImage.planes[0].bytes,
      format: Format.bgra,
    );
    return image;
  }

  /// Convert a single YUV pixel to RGB
  static int yuv2rgb(int y, int u, int v) {
    // Convert yuv pixel to rgb
    int r = (y + v * 1436 / 1024 - 179).round();
    int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    int b = (y + u * 1814 / 1024 - 227).round();

    // Clipping RGB values to be inside boundaries [ 0 , 255 ]
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    return 0xff000000 | ((b << 16) & 0xff0000) | ((g << 8) & 0xff00) | (r & 0xff);
  }
}

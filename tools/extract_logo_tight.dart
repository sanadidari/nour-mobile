import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/logo.jpeg');
  if (!file.existsSync()) {
    print("logo.jpeg not found!");
    return;
  }
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  int minX = image.width;
  int minY = image.height;
  int maxX = 0;
  int maxY = 0;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      var p = image.getPixel(x, y);
      if (p.r < 250 || p.g < 250 || p.b < 250) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  print("Bounding box: \$minX, \$minY to \$maxX, \$maxY");

  int boxWidth = maxX - minX;
  int boxHeight = maxY - minY;
  int size = boxWidth > boxHeight ? boxWidth : boxHeight;
  int cx = minX + boxWidth ~/ 2;
  int cy = minY + boxHeight ~/ 2;

  // slightly reduce radius to cut off remaining anti-aliasing white pixels
  double r = (size / 2.0) - 2;

  var newImage = img.Image(width: size, height: size, numChannels: 4);

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      int srcX = cx - size ~/ 2 + x;
      int srcY = cy - size ~/ 2 + y;

      double cx_new = size / 2.0;
      double cy_new = size / 2.0;
      double dist = (x - cx_new) * (x - cx_new) + (y - cy_new) * (y - cy_new);

      if (dist <= r * r &&
          srcX >= 0 &&
          srcX < image.width &&
          srcY >= 0 &&
          srcY < image.height) {
        newImage.setPixel(x, y, image.getPixel(srcX, srcY));
      } else {
        newImage.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  File('assets/logo.png').writeAsBytesSync(img.encodePng(newImage));
  print("Tight circle extracted!");
}

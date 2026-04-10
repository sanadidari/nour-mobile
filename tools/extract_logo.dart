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

  var newImage = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 4,
  );

  double cx = image.width / 2.0;
  double cy = image.height / 2.0;
  double r = image.width / 2.0 - 2; // small inset to avoid white edges if any

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      double dist = (x - cx) * (x - cx) + (y - cy) * (y - cy);
      if (dist <= r * r) {
        // Check if color is pure white, if so, we can optionally make it transparent.
        // But the user just asked to extract the circle. The code inside the circle stays.
        var p = image.getPixel(x, y);
        newImage.setPixel(x, y, p);
      } else {
        newImage.setPixelRgba(x, y, 0, 0, 0, 0); // transparent background
      }
    }
  }

  File('assets/logo.png').writeAsBytesSync(img.encodePng(newImage));
  print("Circle extracted!");
}

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/logo.png');
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return;

  // Add 15% padding
  final padding = (image.width * 0.15).toInt();
  final newSize = image.width + padding * 2;
  
  final canvas = img.Image(width: newSize, height: newSize);
  // Fill with white
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  
  img.compositeImage(canvas, image, dstX: padding, dstY: padding);
  
  file.writeAsBytesSync(img.encodePng(canvas));
  print('Logo resized with padding.');
}

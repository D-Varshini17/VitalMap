import 'dart:io';
import 'package:image/image.dart';

void main(List<String> args) {
  final srcPath = 'assets/images/logo/logo_medid.png';
  final paddedPath = 'assets/images/logo/app_icon_padded.png';
  final fgPath = 'assets/images/logo/app_icon_foreground.png';

  if (!File(srcPath).existsSync()) {
    print('Source logo not found at $srcPath');
    exit(2);
  }

  final data = File(srcPath).readAsBytesSync();
  final src = decodeImage(data);
  if (src == null) {
    print('Could not decode source image');
    exit(3);
  }

  const int canvas = 1024;
  // Target logo occupies ~37.5% of canvas width
  final int targetWidth = (canvas * 0.375).round();

  // Resize maintaining aspect ratio
  Image resized;
  if (src.width >= src.height) {
    resized = copyResize(src, width: targetWidth);
  } else {
    resized = copyResize(src, height: targetWidth);
  }

  final int px = ((canvas - resized.width) / 2).round();
  final int py = ((canvas - resized.height) / 2).round();

  // Padded icon: solid background #F8FBFF and centered logo
  final padded = Image(canvas, canvas);
  // Background color: #F8FBFF
  fill(padded, getColor(0xF8, 0xFB, 0xFF));
  drawImage(padded, resized, dstX: px, dstY: py);
  File(paddedPath).createSync(recursive: true);
  File(paddedPath).writeAsBytesSync(encodePng(padded));
  print('Wrote $paddedPath');

  // Foreground icon: transparent background with centered logo only
  final fg = Image(canvas, canvas);
  // Make fully transparent
  fill(fg, getColor(0, 0, 0, 0));
  drawImage(fg, resized, dstX: px, dstY: py);
  File(fgPath).createSync(recursive: true);
  File(fgPath).writeAsBytesSync(encodePng(fg));
  print('Wrote $fgPath');
}

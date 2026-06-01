import 'dart:io';
import 'package:image/image.dart';

void main(List<String> args) {
  final srcPath = 'assets/images/logo/logo_medid.png';
  final paddedPath = 'assets/images/logo/app_icon_padded.png';
  final fgPath = 'assets/images/logo/app_icon_foreground.png';

  if (!File(srcPath).existsSync()) {
    stderr.writeln('Source logo not found at $srcPath');
    exit(2);
  }

  final data = File(srcPath).readAsBytesSync();
  final src = decodeImage(data);
  if (src == null) {
    stderr.writeln('Could not decode source image');
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
  final padded = Image(width: canvas, height: canvas);
  // Background color: #F8FBFF
  fill(padded, color: ColorRgb8(0xF8, 0xFB, 0xFF));
  compositeImage(padded, resized, dstX: px, dstY: py);
  File(paddedPath).createSync(recursive: true);
  File(paddedPath).writeAsBytesSync(encodePng(padded));
  stdout.writeln('Wrote $paddedPath');

  // Foreground icon: transparent background with centered logo only
  final fg = Image(width: canvas, height: canvas, numChannels: 4);
  // Make fully transparent
  fill(fg, color: ColorRgba8(0, 0, 0, 0));
  compositeImage(fg, resized, dstX: px, dstY: py);
  File(fgPath).createSync(recursive: true);
  File(fgPath).writeAsBytesSync(encodePng(fg));
  stdout.writeln('Wrote $fgPath');
}

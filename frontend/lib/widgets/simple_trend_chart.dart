import 'dart:math' as math;

import 'package:flutter/material.dart';

class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class SimpleTrendChart extends StatelessWidget {
  const SimpleTrendChart({
    super.key,
    required this.points,
    this.height = 210,
    this.valueSuffix = '',
  });

  final List<TrendPoint> points;
  final double height;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No trend data yet.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _TrendPainter(
          points: points,
          lineColor: scheme.primary,
          gridColor: scheme.outlineVariant,
          textColor: scheme.onSurfaceVariant,
          surfaceColor: scheme.surface,
          valueSuffix: valueSuffix,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
    required this.surfaceColor,
    required this.valueSuffix,
  });

  final List<TrendPoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;
  final Color surfaceColor;
  final String valueSuffix;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 42.0;
    const top = 16.0;
    const right = 12.0;
    const bottom = 34.0;
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    if (plot.width <= 0 || plot.height <= 0) return;

    var minValue = points.first.value;
    var maxValue = points.first.value;
    for (final point in points.skip(1)) {
      minValue = math.min(minValue, point.value);
      maxValue = math.max(maxValue, point.value);
    }
    if ((maxValue - minValue).abs() < 0.0001) {
      minValue -= 1;
      maxValue += 1;
    } else {
      final padding = (maxValue - minValue) * 0.15;
      minValue -= padding;
      maxValue += padding;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final value = maxValue - (maxValue - minValue) * i / 4;
      _drawText(
        canvas,
        '${_format(value)}$valueSuffix',
        Offset(0, y - 7),
        const Size(38, 16),
        TextAlign.right,
      );
    }

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? plot.center.dx
          : plot.left + plot.width * i / (points.length - 1);
      final normalized = (points[i].value - minValue) / (maxValue - minValue);
      final y = plot.bottom - normalized * plot.height;
      offsets.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (offsets.length > 1) {
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final point in offsets.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final dotPaint = Paint()..color = lineColor;
    final ringPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    for (final point in offsets) {
      canvas.drawCircle(point, 5.5, dotPaint);
      canvas.drawCircle(point, 2.2, ringPaint);
    }

    if (points.isNotEmpty) {
      final labels = points.length <= 4
          ? List<int>.generate(points.length, (index) => index)
          : <int>[0, points.length ~/ 2, points.length - 1];
      for (final index in labels.toSet()) {
        final x = offsets[index].dx;
        _drawText(
          canvas,
          points[index].label,
          Offset(x - 38, plot.bottom + 8),
          const Size(76, 22),
          TextAlign.center,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Size maxSize,
    TextAlign align,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxSize.width);
    painter.paint(canvas, offset + Offset((maxSize.width - painter.width) / 2, 0));
  }

  static String _format(double value) {
    if (value.abs() >= 100) return value.toStringAsFixed(0);
    if (value.abs() >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.valueSuffix != valueSuffix;
  }
}

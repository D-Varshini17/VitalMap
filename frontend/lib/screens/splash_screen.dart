import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../styles.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;
  late final AnimationController _heartbeatController;
  bool _logoVisible = false;
  bool _titleVisible = false;
  bool _taglineVisible = false;
  bool _fadeOut = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat();
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..forward();

    _after(220, () => _logoVisible = true);
    _after(980, () => _titleVisible = true);
    _after(1320, () => _taglineVisible = true);
    _after(2920, () => _fadeOut = true);
  }

  void _after(int milliseconds, VoidCallback action) {
    Future.delayed(Duration(milliseconds: milliseconds), () {
      if (!mounted) return;
      setState(action);
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  void _finish() {
    if (_completed || !_fadeOut) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: _fadeOut ? 0 : 1,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOut,
        onEnd: _finish,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.35, -0.42),
                  radius: 1.15,
                  colors: [
                    Color(0xFF123B66),
                    Color(0xFF071D39),
                    Color(0xFF020A18),
                  ],
                ),
              ),
            ),
            const _DepthGlowLayer(),
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticleFieldPainter(_particleController.value),
                );
              },
            ),
            _FloatingMedicalTile(
              alignment: const Alignment(-0.78, -0.58),
              icon: Icons.monitor_heart_outlined,
              delay: 120,
              angle: -0.18,
            ),
            _FloatingMedicalTile(
              alignment: const Alignment(0.74, -0.36),
              icon: Icons.biotech_outlined,
              delay: 340,
              angle: 0.16,
            ),
            _FloatingMedicalTile(
              alignment: const Alignment(-0.62, 0.54),
              icon: Icons.health_and_safety_outlined,
              delay: 560,
              angle: 0.12,
            ),
            _FloatingMedicalTile(
              alignment: const Alignment(0.68, 0.48),
              icon: Icons.water_drop_outlined,
              delay: 720,
              angle: -0.14,
            ),
            Align(
              alignment: const Alignment(0, 0.34),
              child: AnimatedBuilder(
                animation: _heartbeatController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(280, 58),
                    painter: _HeartbeatPainter(_heartbeatController.value),
                  );
                },
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      opacity: _logoVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 680),
                      curve: Curves.easeOut,
                      child: AnimatedScale(
                        scale: _logoVisible ? 1 : 0.58,
                        duration: const Duration(milliseconds: 820),
                        curve: Curves.easeOutBack,
                        child: const _SplashLogo(),
                      ),
                    ),
                    const SizedBox(height: 26),
                    AnimatedOpacity(
                      opacity: _titleVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOut,
                      child: AnimatedScale(
                        scale: _titleVisible ? 1 : 0.92,
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeOutCubic,
                        child: const Text(
                          'VitalMap',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _taglineVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOut,
                      child: const Text(
                        'Organ Health Risk Indicator',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB9F2FF),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      height: 138,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0x665DE8FF),
            Color(0x3329B8E6),
            Color(0x0007132B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5DE8FF).withValues(alpha: 0.36),
            blurRadius: 46,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: const Color(0xFF7B61FF).withValues(alpha: 0.22),
            blurRadius: 68,
            spreadRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 104,
          height: 104,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x99B9F2FF), width: 1.4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(AppStyles.logoAsset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _DepthGlowLayer extends StatelessWidget {
  const _DepthGlowLayer();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -90,
          top: 90,
          child: _GlowOrb(
            size: 250,
            color: const Color(0xFF3CE1F5).withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          right: -70,
          bottom: 120,
          child: _GlowOrb(
            size: 220,
            color: const Color(0xFF7C6CFF).withValues(alpha: 0.14),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size * 0.46, spreadRadius: 18),
        ],
      ),
    );
  }
}

class _FloatingMedicalTile extends StatelessWidget {
  final Alignment alignment;
  final IconData icon;
  final int delay;
  final double angle;

  const _FloatingMedicalTile({
    required this.alignment,
    required this.icon,
    required this.delay,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 1100 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final floatOffset = math.sin(value * math.pi) * 10;
        return Align(
          alignment: alignment,
          child: Opacity(
            opacity: value * 0.9,
            child: Transform.translate(
              offset: Offset(0, 18 - (value * 18) - floatOffset),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateZ(angle)
                  ..rotateY(angle * 0.8),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF102B4E).withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF86ECFF).withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38DDF4).withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Icon(icon,
            color: const Color(0xFFB8F4FF).withValues(alpha: 0.92), size: 32),
      ),
    );
  }
}

class _ParticleFieldPainter extends CustomPainter {
  final double progress;

  const _ParticleFieldPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 42; i++) {
      final baseX = ((i * 73) % 100) / 100 * size.width;
      final baseY = ((i * 41) % 100) / 100 * size.height;
      final phase = progress * math.pi * 2 + i;
      final x = baseX + math.sin(phase) * 10;
      final y =
          (baseY + progress * 28 + math.cos(phase * 0.8) * 8) % size.height;
      final radius = 1.1 + ((i % 5) * 0.34);
      final alpha = 0.2 + ((i % 4) * 0.08);
      paint.color = const Color(0xFF9AF5FF).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _HeartbeatPainter extends CustomPainter {
  final double progress;

  const _HeartbeatPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final y = size.height * 0.55;
    path.moveTo(size.width * 0.05, y);
    path.lineTo(size.width * 0.22, y);
    path.lineTo(size.width * 0.28, size.height * 0.34);
    path.lineTo(size.width * 0.35, size.height * 0.76);
    path.lineTo(size.width * 0.43, size.height * 0.42);
    path.lineTo(size.width * 0.49, y);
    path.lineTo(size.width * 0.66, y);
    path.quadraticBezierTo(
        size.width * 0.76, size.height * 0.18, size.width * 0.85, y);
    path.lineTo(size.width * 0.95, y);

    final visibleProgress =
        Curves.easeInOutCubic.transform((progress * 1.18).clamp(0.0, 1.0));
    final activePath = Path();
    for (final metric in path.computeMetrics()) {
      activePath.addPath(
        metric.extractPath(0, metric.length * visibleProgress),
        Offset.zero,
      );
    }

    final glowPaint = Paint()
      ..color = const Color(0xFF5DE8FF).withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final linePaint = Paint()
      ..color = const Color(0xFFB8F4FF).withValues(alpha: 0.94)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(activePath, glowPaint);
    canvas.drawPath(activePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

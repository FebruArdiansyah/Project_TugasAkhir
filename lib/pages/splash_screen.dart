import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  double _clampDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFEFF),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: ElegantSplashBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;

                final logoWidth = _clampDouble(
                  screenWidth * 0.66,
                  220,
                  315,
                );

                final loadingBarWidth = _clampDouble(
                  screenWidth * 0.58,
                  220,
                  320,
                );

                return SizedBox(
                  width: screenWidth,
                  height: screenHeight,
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.30),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: logoWidth,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Loading...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          color: Color(0xFF2F3192),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.8,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return _ElegantLoadingBar(
                            width: loadingBarWidth,
                            value: _progressController.value,
                          );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.078),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ElegantLoadingBar extends StatelessWidget {
  final double width;
  final double value;

  const _ElegantLoadingBar({
    required this.width,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8F5),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF08A9E8),
                    Color(0xFF63CDF7),
                    Color(0xFFD9EFFF),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ElegantSplashBackgroundPainter extends CustomPainter {
  const ElegantSplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFDFEFF),
          Color(0xFFF6FAFF),
        ],
        stops: [0.0, 0.58, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, basePaint);

    final topGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.0,
        colors: [
          const Color(0xFFD7E9FF).withValues(alpha: 0.95),
          const Color(0xFFEAF4FF).withValues(alpha: 0.58),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(
        Rect.fromLTWH(
          -size.width * 0.55,
          -size.height * 0.24,
          size.width * 1.20,
          size.height * 0.58,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * 0.58,
        -size.height * 0.24,
        size.width * 1.25,
        size.height * 0.60,
      ),
      topGlowPaint,
    );

    final topCurvePaint = Paint()
      ..color = const Color(0xFFEAF4FF).withValues(alpha: 0.38);

    final topCurvePath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.26)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.22,
        size.width * 0.40,
        size.height * 0.04,
      )
      ..quadraticBezierTo(
        size.width * 0.45,
        -size.height * 0.02,
        size.width * 0.62,
        0,
      )
      ..close();

    canvas.drawPath(topCurvePath, topCurvePaint);

    final bottomGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.05,
        colors: [
          const Color(0xFFD8EAFF).withValues(alpha: 0.98),
          const Color(0xFFEAF4FF).withValues(alpha: 0.78),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.62,
          size.width * 1.18,
          size.height * 0.66,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.61,
        size.width * 1.18,
        size.height * 0.68,
      ),
      bottomGlowPaint,
    );

    final bottomWavePaint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEFF6FF).withValues(alpha: 0.18),
          const Color(0xFFD7E9FF).withValues(alpha: 0.56),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          size.height * 0.76,
          size.width,
          size.height * 0.24,
        ),
      );

    final bottomWavePath1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.82,
        size.width * 0.48,
        size.height * 0.87,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.93,
        size.width,
        size.height * 0.80,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(bottomWavePath1, bottomWavePaint1);

    final bottomWavePaint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEAF4FF).withValues(alpha: 0.10),
          const Color(0xFFD3E7FF).withValues(alpha: 0.34),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          size.height * 0.83,
          size.width,
          size.height * 0.17,
        ),
      );

    final bottomWavePath2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.97)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.90,
        size.width * 0.52,
        size.height * 0.93,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.96,
        size.width,
        size.height * 0.87,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(bottomWavePath2, bottomWavePaint2);

    final accentPaint = Paint()
      ..color = const Color(0xFFBFDFFF).withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final accentPath = Path()
      ..moveTo(size.width * 0.06, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.76,
        size.width * 0.64,
        size.height * 0.81,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.84,
        size.width * 1.04,
        size.height * 0.74,
      );

    canvas.drawPath(accentPath, accentPaint);

    final smallGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFBEE7FF).withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.86, size.height * 0.19),
          radius: size.width * 0.22,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.19),
      size.width * 0.22,
      smallGlowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE8F8),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: SplashWavePainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  _buildLogo(),
                  const SizedBox(height: 34),

                  const Text(
                    'NSA MOBILE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F3C9E),
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2F3C9E),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(flex: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo.png',
      width: 210,
      fit: BoxFit.contain,
    );
  }
}

class SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFFAAC6F7);
    final paint2 = Paint()..color = const Color(0xFF5E8DF2);
    final paint3 = Paint()..color = const Color(0xFF2F3C9E);

    final path1 = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.66,
        size.width * 0.5,
        size.height * 0.71,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.76,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.73,
        size.width * 0.50,
        size.height * 0.81,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.88,
        size.width,
        size.height * 0.75,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path3 = Path()
      ..moveTo(0, size.height * 0.93)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.86,
        size.width * 0.52,
        size.height * 0.92,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.98,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
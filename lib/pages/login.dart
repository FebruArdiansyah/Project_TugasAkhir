import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;

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
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage('Email wajib diisi');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Password wajib diisi');
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      await AuthService.login(
        login: email,
        password: password,
        deviceName: 'flutter-web',
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Login gagal: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  double _limit(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: LoginMockupBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                final safeHeight = height < 640 ? 640.0 : height;
                final contentWidth = _limit(width * 0.84, 270, 390);
                final logoWidth = _limit(width * 0.74, 230, 330);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: SizedBox(
                    width: width,
                    height: safeHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: safeHeight * 0.105,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: logoWidth,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          )
                              .animate()
                              .fadeIn(
                                duration: 700.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .slideY(
                                begin: -0.05,
                                end: 0,
                                duration: 700.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ),
                        Positioned(
                          top: safeHeight * 0.385,
                          width: contentWidth,
                          child: const Column(
                            children: [
                              Text(
                                'Selamat datang!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  height: 1.08,
                                  color: Color(0xFF2F3192),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 9),
                              Text(
                                'Silakan masuk untuk melanjutkan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.28,
                                  color: Color(0xFF667085),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(
                                delay: 160.ms,
                                duration: 650.ms,
                                curve: Curves.easeOut,
                              )
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                delay: 160.ms,
                                duration: 650.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ),
                        Positioned(
                          top: safeHeight * 0.535,
                          width: contentWidth,
                          child: AutofillGroup(
                            child: Column(
                              children: [
                                _buildInputField(
                                  controller: emailController,
                                  hintText: 'Email',
                                  prefixIcon: Icons.person_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.email,
                                  ],
                                )
                                    .animate()
                                    .fadeIn(
                                      delay: 260.ms,
                                      duration: 600.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .slideY(
                                      begin: 0.12,
                                      end: 0,
                                      delay: 260.ms,
                                      duration: 600.ms,
                                      curve: Curves.easeOutCubic,
                                    ),
                                const SizedBox(height: 18),
                                _buildInputField(
                                  controller: passwordController,
                                  hintText: 'Password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  keyboardType: TextInputType.visiblePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.password,
                                  ],
                                  onSubmitted: (_) => _handleLogin(),
                                )
                                    .animate()
                                    .fadeIn(
                                      delay: 340.ms,
                                      duration: 600.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .slideY(
                                      begin: 0.12,
                                      end: 0,
                                      delay: 340.ms,
                                      duration: 600.ms,
                                      curve: Curves.easeOutCubic,
                                    ),
                                const SizedBox(height: 30),
                                _buildLoginButton()
                                    .animate()
                                    .fadeIn(
                                      delay: 430.ms,
                                      duration: 650.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .slideY(
                                      begin: 0.14,
                                      end: 0,
                                      delay: 430.ms,
                                      duration: 650.ms,
                                      curve: Curves.easeOutCubic,
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE1E8F2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.065),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: !isLoading,
        obscureText: isPassword ? isPasswordHidden : false,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        autocorrect: false,
        enableSuggestions: !isPassword,
        keyboardAppearance: Brightness.dark,
        onSubmitted: onSubmitted,
        cursorColor: const Color(0xFF005BEA),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF111827),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: Color(0xFF8B96A8),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 24,
            color: const Color(0xFF8B96A8),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            isPasswordHidden = !isPasswordHidden;
                          });
                        },
                  icon: Icon(
                    isPasswordHidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 24,
                    color: const Color(0xFF8B96A8),
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: isLoading ? null : _handleLogin,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isLoading
                  ? const [
                      Color(0xFF94A3B8),
                      Color(0xFF94A3B8),
                    ]
                  : const [
                      Color(0xFF0EA5E9),
                      Color(0xFF0062F5),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0062F5).withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Masuk',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class LoginMockupBackgroundPainter extends CustomPainter {
  const LoginMockupBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFBFDFF),
          Color(0xFFF1F7FF),
        ],
        stops: [0.0, 0.54, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, basePaint);

    _drawTopLeftPattern(canvas, size);
    _drawMainSoftCurve(canvas, size);
    _drawRightGlow(canvas, size);
    _drawBottomRightPattern(canvas, size);
  }

  void _drawTopLeftPattern(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.05,
        colors: [
          const Color(0xFFD9EAFF).withValues(alpha: 0.92),
          const Color(0xFFEAF4FF).withValues(alpha: 0.48),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(
        Rect.fromLTWH(
          -size.width * 0.38,
          -size.height * 0.18,
          size.width * 0.95,
          size.height * 0.48,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * 0.42,
        -size.height * 0.18,
        size.width * 1.02,
        size.height * 0.50,
      ),
      glowPaint,
    );

    final patternPaint = Paint()
      ..color = const Color(0xFFDCEBFF).withValues(alpha: 0.42);

    canvas.save();
    canvas.translate(-size.width * 0.07, size.height * 0.02);
    canvas.rotate(-0.55);

    for (int i = 0; i < 3; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          i * 50,
          size.width * 0.40,
          37,
        ),
        const Radius.circular(18),
      );

      canvas.drawRRect(rect, patternPaint);
    }

    canvas.restore();
  }

  void _drawMainSoftCurve(Canvas canvas, Size size) {
    final curvePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withValues(alpha: 0),
          const Color(0xFFEAF4FF).withValues(alpha: 0.48),
          const Color(0xFFDDEEFF).withValues(alpha: 0.22),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromLTWH(
          0,
          size.height * 0.22,
          size.width,
          size.height * 0.78,
        ),
      );

    final path = Path()
      ..moveTo(size.width, size.height * 0.34)
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.48,
        size.width * 0.80,
        size.height * 0.68,
        size.width * 0.48,
        size.height * 0.83,
      )
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.92,
        size.width * 0.10,
        size.height * 0.97,
        0,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, curvePaint);
  }

  void _drawRightGlow(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.centerRight,
        radius: 1.0,
        colors: [
          const Color(0xFFD8EAFF).withValues(alpha: 0.62),
          const Color(0xFFEAF4FF).withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(
        Rect.fromLTWH(
          size.width * 0.52,
          size.height * 0.30,
          size.width * 0.70,
          size.height * 0.48,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.54,
        size.height * 0.29,
        size.width * 0.78,
        size.height * 0.52,
      ),
      glowPaint,
    );
  }

  void _drawBottomRightPattern(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.05,
        colors: [
          const Color(0xFFD8EAFF).withValues(alpha: 0.76),
          const Color(0xFFEAF4FF).withValues(alpha: 0.36),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(
        Rect.fromLTWH(
          size.width * 0.42,
          size.height * 0.72,
          size.width * 0.82,
          size.height * 0.42,
        ),
      );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.42,
        size.height * 0.70,
        size.width * 0.90,
        size.height * 0.48,
      ),
      glowPaint,
    );

    final patternPaint = Paint()
      ..color = const Color(0xFFDCEBFF).withValues(alpha: 0.44);

    canvas.save();
    canvas.translate(size.width * 0.72, size.height * 0.82);
    canvas.rotate(-0.52);

    for (int i = 0; i < 3; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          i * 46,
          size.width * 0.40,
          34,
        ),
        const Radius.circular(18),
      );

      canvas.drawRRect(rect, patternPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
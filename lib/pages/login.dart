import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final login = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (login.isEmpty) {
      _showMessage('Username / email wajib diisi');
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
        login: login,
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
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3F6FB),
              Color(0xFFD8E6FB),
              Color(0xFF0E78FF),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        Center(child: _buildLogo()),

                        const SizedBox(height: 40),

                        const Center(
                          child: Text(
                            'Selamat Datang !',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3342A3),
                            ),
                          ),
                        ),

                        const SizedBox(height: 44),

                        const Text(
                          'Username / Email',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF617194),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: usernameController,
                          hintText: 'Masukkan username atau email',
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF617194),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: passwordController,
                          hintText: 'Masukkan password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                        ),

                        const SizedBox(height: 36),

                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3342A3),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFF9AA5BD),
                                disabledForegroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(0x33000000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'MASUK',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const Column(
      children: [
        Text(
          'NSA',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3342A3),
            letterSpacing: 3,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'P.T. NAURA SUKSES ABADI',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5F6675),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: !isLoading,
        obscureText: isPassword ? isPasswordHidden : false,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF3342A3),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9AA5BD),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF6A78A8),
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
                    color: const Color(0xFF6A78A8),
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF3342A3),
              width: 1.2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
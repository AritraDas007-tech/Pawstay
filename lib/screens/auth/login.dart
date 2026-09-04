import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/core/theme/pawstay_theme.dart';
import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter_application_1/screens/auth/signup.dart';
import 'package:flutter_application_1/screens/auth/verify_otp.dart';
import 'package:flutter_application_1/screens/auth/forgot_password.dart';
import 'package:flutter_application_1/screens/user/home_screen.dart';
import 'package:flutter_application_1/screens/provider/dashboard/provider_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  late AnimationController _buttonScaleController;

  @override
  void initState() {
    super.initState();
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: isError ? PawStayTheme.error : PawStayTheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    debugPrint('[AUTH] Login Button Clicked');
    _buttonScaleController.reverse().then(
      (_) => _buttonScaleController.forward(),
    );

    if (!_formKey.currentState!.validate()) {
      debugPrint('[AUTH] Login validation failed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final identifier = _emailController.text.trim();
      final body = jsonEncode({
        'email_or_username': identifier,
        'password': _passwordController.text,
      });

      debugPrint('[AUTH] Calling Login API: ${ApiConfig.baseUrl}/login');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/login'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 12));

      debugPrint(
        '[AUTH] Login Response: ${response.statusCode} - ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        String role = (decoded['role'] as String? ?? '').trim();

        // Fallback to fetch profile if role not in login payload
        if (role.isEmpty) {
          try {
            final profRes = await http
                .get(
                  Uri.parse(
                    '${ApiConfig.baseUrl}/profile?lookup=${Uri.encodeComponent(identifier)}',
                  ),
                )
                .timeout(const Duration(seconds: 4));
            if (profRes.statusCode == 200) {
              final profData = jsonDecode(profRes.body) as Map<String, dynamic>;
              role = (profData['role'] as String? ?? '').trim();
            }
          } catch (_) {}
        }

        if (!mounted) return;
        debugPrint('[AUTH] Login Success: user role is "$role"');
        _showSnack(decoded['message'] ?? 'Login successful!');

        final isProvider =
            role.toLowerCase().contains('service') ||
            role.toLowerCase().contains('provider') ||
            role.toLowerCase().contains('doctor') ||
            role.toLowerCase().contains('seller');

        if (isProvider) {
          debugPrint('[AUTH] Redirecting to Provider Dashboard');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderDashboardScreen(providerLookup: identifier),
            ),
          );
        } else {
          debugPrint('[AUTH] Redirecting to Customer Home');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(userLookup: identifier),
            ),
          );
        }
      } else {
        final decoded = jsonDecode(response.body);
        final detail =
            decoded['detail']?.toString() ??
            'Login failed. Please check credentials.';
        debugPrint('[AUTH] Login Failed: $detail');
        _showSnack(detail, isError: true);

        if (response.statusCode == 403 ||
            detail.toLowerCase().contains('unverified')) {
          debugPrint(
            '[AUTH] Account unverified, redirecting to OTP verification',
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyOtpScreen(email: identifier),
            ),
          );
        }
      }
    } on TimeoutException {
      debugPrint('[AUTH] Login Timeout');
      _showSnack('Connection timed out. Is backend running?', isError: true);
    } catch (e, st) {
      debugPrint('[AUTH] Login Exception: $e\n$st');
      _showSnack('Could not connect to server: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: PawStayTheme.background,
      body: Stack(
        children: [
          // Background Gradient Circles for Visual Aesthetics
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.1,
            child: Container(
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PawStayTheme.primaryContainer.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.15,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PawStayTheme.secondaryContainer.withValues(alpha: 0.12),
              ),
            ),
          ),

          // Central container layout
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: PawStayTheme.marginMobile,
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: PawStayTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(PawStayTheme.radiusLg),
                  border: Border.all(
                    color: PawStayTheme.surfaceDim,
                    width: 1.0,
                  ),
                  boxShadow: PawStayTheme.ambientShadow2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: PawStayTheme.gutter,
                  vertical: PawStayTheme.gutter * 1.5,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Logo Area
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PawStayTheme.primaryContainer,
                          boxShadow: PawStayTheme.ambientShadow1,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.pets,
                            color: PawStayTheme.primary,
                            size: 40,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'PawStay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: PawStayTheme.primary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Welcome back! Please login to continue.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: PawStayTheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // Email input field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email or Username',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: PawStayTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: PawStayTheme.onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter your email or username',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: PawStayTheme.outlineVariant,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email or username';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Password input field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Password',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: PawStayTheme.onSurface,
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: PawStayTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              color: PawStayTheme.onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: PawStayTheme.outlineVariant,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Login button with press bounce
                      ScaleTransition(
                        scale: _buttonScaleController,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _onLoginPressed,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: PawStayTheme.primary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  PawStayTheme.radiusDefault,
                                ),
                              ),
                              shadowColor: PawStayTheme.primary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Navigation check
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: PawStayTheme.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: PawStayTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

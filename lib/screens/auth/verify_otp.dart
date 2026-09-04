import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/core/config/api_config.dart';
import 'package:flutter_application_1/core/theme/pawstay_theme.dart';
import 'package:flutter_application_1/screens/auth/login.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String? developmentOtp;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.fullName = '',
    this.developmentOtp,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;

  String get _normalizedEmail => widget.email.trim().toLowerCase();

  Widget _developmentOtpNotice() {
    final code = widget.developmentOtp;
    if (code == null || code.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PawStayTheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Development code: $code',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          color: PawStayTheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _otpCode =>
      _controllers.map((controller) => controller.text).join();

  Future<http.Response> _postWithFallback(
    String path,
    String body, {
    Duration primaryTimeout = const Duration(seconds: 10),
  }) async {
    return await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(primaryTimeout);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: isError ? PawStayTheme.error : PawStayTheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      final characters = value.split('');
      for (int i = 0; i < _controllers.length; i++) {
        _controllers[i].text = i < characters.length ? characters[i] : '';
      }
      _focusNodes[_controllers.length - 1].requestFocus();
      return;
    }

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      debugPrint('[AUTH] Invalid OTP length: ${_otpCode.length}');
      _showSnack('Please enter the 6-digit OTP.', isError: true);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      debugPrint(
        '[AUTH] Calling Verify OTP API for $_normalizedEmail with code $_otpCode',
      );
      final response = await _postWithFallback(
        '/verify-otp',
        jsonEncode({'email': _normalizedEmail, 'otp': _otpCode}),
      );

      debugPrint(
        '[AUTH] Verify OTP Response: ${response.statusCode} - ${response.body}',
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        debugPrint('[AUTH] OTP Verified');
        debugPrint('[AUTH] Redirecting to Login');
        _showSnack('Email verified successfully! Please log in.');
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted) {
          return;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      final decoded = jsonDecode(response.body);
      final detail =
          decoded['detail']?.toString() ?? 'OTP verification failed.';
      debugPrint('[AUTH] Verify OTP failed: $detail');
      _showSnack(detail, isError: true);
    } on TimeoutException {
      debugPrint('[AUTH] Verify OTP Timeout');
      _showSnack(
        'Request timed out. Check if the backend is running.',
        isError: true,
      );
    } catch (e, st) {
      debugPrint('[AUTH] Verify OTP Exception: $e\n$st');
      _showSnack('Could not connect to server: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending) {
      return;
    }

    setState(() => _isResending = true);

    try {
      debugPrint('[AUTH] Calling Resend OTP API for $_normalizedEmail');
      final response = await _postWithFallback(
        '/resend-otp',
        jsonEncode({'email': _normalizedEmail}),
      );

      debugPrint(
        '[AUTH] Resend OTP Response: ${response.statusCode} - ${response.body}',
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        for (final controller in _controllers) {
          controller.clear();
        }
        _focusNodes.first.requestFocus();
        _showSnack('A new OTP has been sent to your email.');
        return;
      }

      final decoded = jsonDecode(response.body);
      final detail = decoded['detail']?.toString() ?? 'Failed to resend OTP.';
      debugPrint('[AUTH] Resend OTP failed: $detail');
      _showSnack(detail, isError: true);
    } on TimeoutException {
      debugPrint('[AUTH] Resend OTP timeout');
      _showSnack('Request timed out.', isError: true);
    } catch (e, st) {
      debugPrint('[AUTH] Resend OTP exception: $e\n$st');
      _showSnack('Could not connect to server: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: PawStayTheme.onSurface,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: PawStayTheme.surfaceContainerLow,
          hintText: '-',
          hintStyle: const TextStyle(color: PawStayTheme.outlineVariant),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PawStayTheme.radiusMd),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PawStayTheme.radiusMd),
            borderSide: const BorderSide(color: PawStayTheme.primary, width: 2),
          ),
        ),
        onChanged: (value) => _onOtpChanged(index, value),
        onTap: () => _controllers[index].selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controllers[index].text.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawStayTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: PawStayTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(PawStayTheme.radiusXl),
                  boxShadow: PawStayTheme.ambientShadow2,
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PawStayTheme.primaryContainer,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 28,
                        color: PawStayTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Verify your email',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: PawStayTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit verification code sent to',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: PawStayTheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PawStayTheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _developmentOtpNotice(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, _buildOtpBox),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PawStayTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.0),
                          ),
                          elevation: 0,
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Verify Code',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _isResending ? null : _resendOtp,
                      child: _isResending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Resend Code',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: PawStayTheme.primary,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

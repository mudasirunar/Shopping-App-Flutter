import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'reset_password_screen.dart';
import '../../core/utils/app_snackbar.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCooldown = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _handleVerify() {
    final otp = _otpCode.trim();
    if (otp.length != 6) {
      AppSnackBar.show(
        context,
        message: 'Please enter all 6 digits of your OTP',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(
          email: widget.email,
          otp: otp,
        ),
      ),
    );
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.sendResetOtp(widget.email);

    if (success && mounted) {
      _startCooldown();
      AppSnackBar.show(
        context,
        message: 'New verification code sent! Check your inbox.',
        backgroundColor: AppTheme.emeraldSuccess,
      );
    } else if (mounted && auth.errorMessage != null) {
      AppSnackBar.show(
        context,
        message: auth.errorMessage!,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 32,
                      color: AppTheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Verify Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'We have sent a 6-digit code to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.secondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 28),

                // 6-digit OTP Box Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 44,
                      height: 52,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppTheme.surfaceContainerLowest,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (val.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          setState(() {});
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // Expiry info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.timer_outlined, size: 14, color: AppTheme.secondary),
                    SizedBox(width: 4),
                    Text(
                      'Code expires in 10 minutes',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondary),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _otpCode.length == 6 ? _handleVerify : null,
                  child: const Text(
                    'Verify & Continue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend Action with cooldown
                TextButton(
                  onPressed: _resendCooldown == 0 ? _handleResend : null,
                  child: Text(
                    _resendCooldown > 0
                        ? 'Resend code in ${_resendCooldown}s'
                        : 'Did not receive code? Resend',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _resendCooldown > 0 ? AppTheme.outline : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

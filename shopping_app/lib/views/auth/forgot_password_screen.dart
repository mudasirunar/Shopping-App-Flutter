import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import '../../core/utils/app_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    final success = await auth.sendResetOtp(email);

    if (success && mounted) {
      AppSnackBar.show(
        context,
        message: '6-digit verification code sent to $email',
        backgroundColor: AppTheme.emeraldSuccess,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email),
        ),
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
    final auth = context.watch<AuthProvider>();

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 32,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Reset your password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Enter the email address registered with your account. We will send a single-use 6-digit verification code via Brevo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Registered Email',
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.mail_outline, size: 20, color: AppTheme.secondary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter your email';
                      if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Action Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: auth.isLoading ? null : _handleSendOtp,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Send Verification Code',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

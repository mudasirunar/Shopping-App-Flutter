import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';
import '../../core/utils/app_snackbar.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  String _lastNameText = '';
  String _lastEmailText = '';
  String _lastPasswordText = '';
  String _lastConfirmPasswordText = '';

  @override
  void initState() {
    super.initState();
    _lastNameText = _nameController.text;
    _lastEmailText = _emailController.text;
    _lastPasswordText = _passwordController.text;
    _lastConfirmPasswordText = _confirmPasswordController.text;
    _nameController.addListener(_onNameChanged);
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  void _onNameChanged() {
    if (_nameController.text != _lastNameText) {
      _lastNameText = _nameController.text;
      if (_nameError != null) setState(() => _nameError = null);
    }
  }

  void _onEmailChanged() {
    if (_emailController.text != _lastEmailText) {
      _lastEmailText = _emailController.text;
      if (_emailError != null) setState(() => _emailError = null);
    }
  }

  void _onPasswordChanged() {
    if (_passwordController.text != _lastPasswordText) {
      _lastPasswordText = _passwordController.text;
      if (_passwordError != null) setState(() => _passwordError = null);
    }
  }

  void _onConfirmPasswordChanged() {
    if (_confirmPasswordController.text != _lastConfirmPasswordText) {
      _lastConfirmPasswordText = _confirmPasswordController.text;
      if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _emailController.removeListener(_onEmailChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    String? nameErr;
    if (name.isEmpty) {
      nameErr = 'Enter your name';
    }

    String? emailErr;
    if (email.isEmpty) {
      emailErr = 'Enter your email';
    } else if (!email.contains('@') || !email.contains('.')) {
      emailErr = 'Enter a valid email';
    }

    String? passwordErr;
    if (password.isEmpty) {
      passwordErr = 'Enter a password';
    } else if (password.length < 8) {
      passwordErr = 'Password must be at least 8 characters';
    }

    String? confirmPasswordErr;
    if (confirmPassword.isEmpty) {
      confirmPasswordErr = 'Confirm your password';
    } else if (confirmPassword != password) {
      confirmPasswordErr = 'Passwords do not match';
    }

    if (nameErr != null ||
        emailErr != null ||
        passwordErr != null ||
        confirmPasswordErr != null) {
      _lastNameText = _nameController.text;
      _lastEmailText = _emailController.text;
      _lastPasswordText = _passwordController.text;
      _lastConfirmPasswordText = _confirmPasswordController.text;
      setState(() {
        _nameError = nameErr;
        _emailError = emailErr;
        _passwordError = passwordErr;
        _confirmPasswordError = confirmPasswordErr;
      });
      return;
    }

    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      name: name,
      email: email,
      password: password,
    );

    if (success && mounted) {
      FocusScope.of(context).unfocus();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainShell(
            initialIndex: 0,
            welcomeUserName: name,
            isNewUser: true,
          ),
        ),
        (route) => false,
      );
    } else if (mounted && auth.errorMessage != null) {
      AppSnackBar.show(context, message: auth.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<AuthProvider>().cancelCurrentOperation();
        }
      },
      child: Scaffold(
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
            onPressed: () {
              context.read<AuthProvider>().cancelCurrentOperation();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create an account to track orders and save your delivery addresses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.secondary),
                  ),

                  const SizedBox(height: 24),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    onChanged: (val) {
                      _lastNameText = val;
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      errorText: _nameError,
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (val) {
                      _lastEmailText = val;
                      if (_emailError != null) setState(() => _emailError = null);
                    },
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'name@example.com',
                      errorText: _emailError,
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        size: 20,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (val) {
                      _lastPasswordText = val;
                      if (_passwordError != null) setState(() => _passwordError = null);
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: 'Must be at least 8 characters long',
                      helperStyle: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondary,
                      ),
                      errorText: _passwordError,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: AppTheme.secondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppTheme.secondary,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (val) {
                      _lastConfirmPasswordText = val;
                      if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      errorText: _confirmPasswordError,
                      prefixIcon: const Icon(
                        Icons.lock_reset_outlined,
                        size: 20,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: auth.isLoading ? null : _handleSignUp,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (auth.isLoading) return;
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
    );
  }
}

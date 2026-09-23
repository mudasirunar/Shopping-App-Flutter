import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({FirebaseAuth? auth}) {
    try {
      _auth = auth ?? FirebaseAuth.instance;
      _currentUser = _auth?.currentUser;
      _auth?.authStateChanges().listen((user) {
        _currentUser = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AuthProvider initialization notice: $e');
    }
  }

  FirebaseAuth? get _safeAuth {
    if (_auth != null) return _auth;
    try {
      _auth = FirebaseAuth.instance;
      return _auth;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAnonymous => _currentUser?.isAnonymous ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int _activeOperationId = 0;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Cancels any active in-flight authentication operation, immediately
  /// resetting loading state and discarding subsequent results.
  void cancelCurrentOperation() {
    _activeOperationId++;
    if (_isLoading) {
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    final opId = ++_activeOperationId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final auth = _safeAuth;
      if (auth == null) {
        if (opId == _activeOperationId) {
          _errorMessage = 'Authentication service is currently unavailable.';
        }
        return false;
      }

      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (opId != _activeOperationId) {
        // Cancelled while awaiting network response
        await auth.signOut();
        return false;
      }

      _currentUser = credential.user;
      return true;
    } on FirebaseAuthException catch (e) {
      if (opId == _activeOperationId) {
        _errorMessage = _mapAuthError(e.code);
      }
      return false;
    } catch (e) {
      if (opId == _activeOperationId) {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      }
      return false;
    } finally {
      if (opId == _activeOperationId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (password.length < 8) {
      _errorMessage = 'Password must be at least 8 characters long.';
      notifyListeners();
      return false;
    }

    final opId = ++_activeOperationId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final auth = _safeAuth;
      if (auth == null) {
        if (opId == _activeOperationId) {
          _errorMessage = 'Authentication service is currently unavailable.';
        }
        return false;
      }

      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (opId != _activeOperationId) {
        await auth.signOut();
        return false;
      }

      await credential.user?.updateDisplayName(name.trim());
      if (opId != _activeOperationId) {
        await auth.signOut();
        return false;
      }

      _currentUser = auth.currentUser;
      return true;
    } on FirebaseAuthException catch (e) {
      if (opId == _activeOperationId) {
        _errorMessage = _mapAuthError(e.code);
      }
      return false;
    } catch (e) {
      if (opId == _activeOperationId) {
        _errorMessage = 'Failed to create account. Please try again.';
      }
      return false;
    } finally {
      if (opId == _activeOperationId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> signOut() async {
    final auth = _safeAuth;
    if (auth != null) {
      await auth.signOut();
    }
    _currentUser = null;
    notifyListeners();
  }

  /// Updates the display name of the currently authenticated user.
  Future<bool> updateProfileName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Name cannot be empty.';
      notifyListeners();
      return false;
    }

    final user = _safeAuth?.currentUser;
    if (user == null) {
      _errorMessage = 'No user signed in.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await user.updateDisplayName(trimmed);
      await user.reload();
      _currentUser = _safeAuth?.currentUser;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile name. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a 6-digit OTP code to the given email using the Brevo Vercel serverless endpoint.
  Future<bool> sendResetOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.backendBaseUrl}${ApiConstants.sendResetOtpEndpoint}'),
        headers: ApiConstants.authHeaders,
        body: json.encode({'email': email.trim()}),
      );

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return true;
      } else {
        _errorMessage = body['error'] as String? ?? 'Failed to send verification email.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection failed. Please verify your internet.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifies the OTP and resets user password securely via the Vercel backend.
  Future<bool> verifyResetOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      _errorMessage = 'New password must be at least 8 characters long.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.backendBaseUrl}${ApiConstants.verifyResetOtpEndpoint}'),
        headers: ApiConstants.authHeaders,
        body: json.encode({
          'email': email.trim(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        }),
      );

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return true;
      } else {
        _errorMessage = body['error'] as String? ?? 'Invalid verification code or expired session.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Verification request failed. Please check your network connection.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 8 characters long.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

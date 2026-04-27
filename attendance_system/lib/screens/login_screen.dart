// lib/screens/login_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'dashboard_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Use GoogleSignIn.instance for version 7.x
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    // Initialize Google Sign-In exactly once.
    _googleSignIn.initialize(
      clientId: "38187875378-fblpl6cjg3steo47skmfji77mro72d6i.apps.googleusercontent.com",
    );
  }

  void _showSnack(String text, {Color? background}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(text), backgroundColor: background),
    );
  }

  /// Handle Google sign-in flow
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);

    try {
      // 1. Trigger Google Sign-In using authenticate() (v7 API replaces signIn)
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      // 2. Obtain Auth Tokens
      final auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        _showSnack("Failed to fetch idToken from Google", background: Colors.red);
        setState(() => _isSigningIn = false);
        return;
      }

      // 3. Exchange idToken for backend JWT
      final response = await _apiService.googleLogin(idToken);

      if (response.statusCode == 200) {
        final data = response.data;
        final String? jwtToken = data['access_token'];

        if (jwtToken != null) {
          // 4. Store JWT securely
          await _secureStorage.write(key: 'jwt_token', value: jwtToken);
          
          _showSnack("Login successful!", background: Colors.green);

          if (!mounted) return;
          // 5. Navigate to Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardRouter()),
          );
        } else {
          _showSnack("Invalid response from server", background: Colors.red);
        }
      } else {
        _showSnack("Backend login failed: ${response.statusMessage}", background: Colors.red);
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _showSnack("Google sign-in cancelled.");
      } else {
        _showSnack("Google sign-in error: ${e.code}", background: Colors.red);
      }
    } catch (e) {
      debugPrint("Google sign in error: $e");
      _showSnack("Google sign-in failed: $e", background: Colors.red);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  // ------------------ Dev bypass ------------------

  Future<void> _showDevRoleSelector() async {
    if (!kDebugMode) return;
    final roles = ["admin", "faculty", "hod", "director", "student", "parent"];
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("DEV LOGIN BYPASS"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((role) => ListTile(
            title: Text(role.toUpperCase()),
            onTap: () => Navigator.pop(context, role),
          )).toList(),
        ),
      ),
    );
    if (selectedRole != null) await _loginAsRole(selectedRole);
  }

  String _createFakeJwt(String role) {
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'email': 'dev@$role.test',
      'role': role,
      'exp': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000
    }))).replaceAll('=', '');
    return 'eyJhbGciOiJub25lIn0.$payload.';
  }

  Future<void> _loginAsRole(String role) async {
    await _secureStorage.write(key: "jwt_token", value: _createFakeJwt(role));
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardRouter()));
  }

  Future<void> _openParentDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ParentOtpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 700 ? 520.0 : width * 0.94;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: SizedBox(
            width: cardWidth,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', width: 96, height: 96, fit: BoxFit.contain),
                    const SizedBox(height: 12),
                    const Text('Facial Recognition Attendance',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onLongPress: kDebugMode ? _showDevRoleSelector : null,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: _isSigningIn
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    SizedBox(width: 12),
                                    Text("Signing in...")
                                  ],
                                )
                              : const Text('Sign in with Institute Google account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Or "),
                        TextButton(
                          onPressed: _openParentDialog,
                          child: const Text("Sign in as a parent",
                            style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Use your institute Google account to sign in. Parents use OTP.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13)),
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

class ParentOtpDialog extends StatefulWidget {
  const ParentOtpDialog({super.key});
  @override
  State<ParentOtpDialog> createState() => _ParentOtpDialogState();
}

class _ParentOtpDialogState extends State<ParentOtpDialog> {
  final TextEditingController _wardEmailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  Timer? _resendTimer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _wardEmailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSnack(String text, {Color? background}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: background));
  }

  Future<void> _sendOtp() async {
    final email = _wardEmailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _isSending = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate
    if (mounted) {
      setState(() { _isSending = false; _otpSent = true; _secondsLeft = 30; });
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 0) setState(() => _secondsLeft--); else timer.cancel();
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate
    if (mounted) {
      Navigator.pop(context);
      _showSnack("Login successful", background: Colors.green);
      // In real app, save JWT and route
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Parent Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _wardEmailController, decoration: const InputDecoration(labelText: "Ward's Email", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _otpSent ? null : _sendOtp, child: Text(_isSending ? 'Sending...' : 'Send OTP'))),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(controller: _otpController, decoration: const InputDecoration(labelText: "OTP", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isVerifying ? null : _verifyOtp, child: const Text('Verify'))),
            ],
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}

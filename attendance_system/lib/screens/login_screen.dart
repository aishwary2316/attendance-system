// lib/screens/login_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; /// for dev bypass etc.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dashboard_router.dart'; // adjust path if your router is elsewhere

/// Login Screen with:
/// - App logo & title
/// - Sign in with Institute Google account (google_sign_in v7 API)
/// - "Sign in as parent" dialog which requests ward email, sends OTP,
///   verifies OTP and implements a 30s disabled "Resend OTP" with countdown.
///
/// NOTE:
/// - Replace TODO sections with real backend integration.
/// - Add assets/logo.png in pubspec.yaml (flutter: assets:)
/// - Ensure google_sign_in is configured for Android/iOS/Web and use the correct client IDs.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Use the v7 singleton API:
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isSigningIn = false;

  // secure storage for JWT
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Snack helper
  void _showSnack(String text, {Color? background}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(text), backgroundColor: background),
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize with the web client id so web sign-in works.
    // Replace with your web client id from Google Cloud Console.
    // For Android/iOS, configure the native client ids in their platform configs.
    _googleSignIn.initialize(
      clientId: "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
    );
  }

  @override
  void dispose() {
    // If you add controllers here later, dispose them.
    super.dispose();
  }

  /// Handle Google sign-in flow (v7)
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);

    try {
      // authenticate() opens account chooser and returns a GoogleSignInAccount or null.
      final account = await _googleSignIn.authenticate();

      if (account == null) {
        // user cancelled
        _showSnack("Google sign-in cancelled.");
        setState(() => _isSigningIn = false);
        return;
      }

      // authentication contains tokens (idToken)
      final auth = await account.authentication;
      final idToken = auth.idToken; // send this to backend

      if (idToken == null) {
        _showSnack("Failed to fetch idToken from Google", background: Colors.red);
        setState(() => _isSigningIn = false);
        return;
      }

      // TODO: POST idToken to your backend endpoint /auth/google
      // Example pseudo:
      // final resp = await ApiService.googleLogin(idToken);
      // if resp success -> save JWT, navigate to DashboardRouter

      // For now show quick success message (remove in production)
      _showSnack("Signed in as ${account.email}");

      // TODO: After backend verification and JWT stored, navigate to dashboard
    } catch (e, st) {
      debugPrint("Google sign in error: $e\n$st");
      _showSnack("Google sign-in failed: $e", background: Colors.red);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  // ------------------ Dev bypass implementation ------------------

  /// Show role selector dialog — only active in debug builds
  Future<void> _showDevRoleSelector() async {
    if (!kDebugMode) return;

    final roles = [
      "admin",
      "faculty",
      "hod",
      "director",
      "student",
      "parent"
    ];

    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("DEV LOGIN BYPASS"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: roles.map((role) {
              return ListTile(
                title: Text(role.toUpperCase()),
                onTap: () {
                  Navigator.pop(context, role);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedRole == null) return;

    await _loginAsRole(selectedRole);
  }

  /// Create a fake JWT (header.payload.signature) where signature is empty.
  /// jwt_decoder will be able to decode the payload without signature verification.
  String _createFakeJwt(String role) {
    final header = {'alg': 'none', 'typ': 'JWT'};
    final payload = {
      'email': 'dev@$role.test',
      'role': role,
      'exp': (DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000)
    };

    String encodeNoPadding(Object obj) {
      return base64UrlEncode(utf8.encode(jsonEncode(obj))).replaceAll('=', '');
    }

    final h = encodeNoPadding(header);
    final p = encodeNoPadding(payload);
    // signature intentionally left empty (alg none). Keep trailing dot to form 3 segments.
    return '$h.$p.';
  }

  Future<void> _loginAsRole(String role) async {
    // Only allow in debug mode
    if (!kDebugMode) return;

    final fakeToken = _createFakeJwt(role);

    await _secureStorage.write(
      key: "jwt",
      value: fakeToken,
    );

    if (!mounted) return;

    // Navigate to router (which will read the token and route by role)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardRouter(),
      ),
    );
  }

  // ------------------ Parent dialog (unchanged) ------------------

  Future<void> _openParentDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ParentOtpDialog(),
    );
  }

  // ------------------ Build UI ------------------

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
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 28.0, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                      semanticLabel: 'App Logo',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Facial Recognition Attendance',
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),

                    // Google Sign-in button with long-press dev bypass (debug only)
                    GestureDetector(
                      onLongPress: kDebugMode ? _showDevRoleSelector : null,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: _isSigningIn
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text("Signing in...")
                            ],
                          )
                              : const Text(
                              'Sign in with Institute Google account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            textStyle:
                            const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Small text + Parent button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Or "),
                        TextButton(
                          onPressed: _openParentDialog,
                          child: const Text(
                            "Sign in as a parent",
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Use your institute Google account to sign in (students, faculty, staff). Parents can sign in using OTP linked to guardian email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 14),
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

/// Parent OTP Dialog (full-featured)
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(text), backgroundColor: background),
    );
  }

  void _startResendCountdown({int seconds = 30}) {
    _resendTimer?.cancel();
    setState(() {
      _secondsLeft = seconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
      });
      if (_secondsLeft <= 0) {
        timer.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      }
    });
  }

  Future<void> _sendOtp() async {
    final wardEmail = _wardEmailController.text.trim();

    if (wardEmail.isEmpty) {
      _showSnack("Enter ward's institute email");
      return;
    }
    if (!wardEmail.contains('@')) {
      _showSnack("Enter a valid email address");
      return;
    }

    setState(() => _isSending = true);
    try {
      // TODO: Call backend to request parent OTP
      // Example:
      // await ApiService.requestParentOtp(wardEmail);
      // Backend will find the student by wardEmail and send OTP to the guardian email on file.

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() {
        _otpSent = true;
      });

      _startResendCountdown(seconds: 30);
      _showSnack("OTP sent to guardian's registered email.");
    } catch (e) {
      _showSnack("Failed to send OTP: $e", background: Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return; // still locked

    setState(() => _isSending = true);
    try {
      // TODO: Call backend to resend OTP
      await Future.delayed(const Duration(milliseconds: 800));
      _startResendCountdown(seconds: 30);
      _showSnack("OTP resent to guardian's registered email.");
    } catch (e) {
      _showSnack("Failed to resend OTP: $e", background: Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    final wardEmail = _wardEmailController.text.trim();

    if (otp.isEmpty) {
      _showSnack("Enter OTP");
      return;
    }

    setState(() => _isVerifying = true);
    try {
      // TODO: Call backend to verify OTP and return JWT + parent profile
      // Example:
      // final resp = await ApiService.verifyParentOtp(wardEmail, otp);
      // if success -> save JWT and navigate to parent dashboard

      // Simulate network delay + success
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      _showSnack("OTP verified. Logging in...");
      // Close dialog and continue
      Navigator.of(context).pop();

      // TODO: after pop, save JWT and navigate to parent dashboard
    } catch (e) {
      _showSnack("OTP verification failed: $e", background: Colors.red);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth =
    MediaQuery.of(context).size.width > 600 ? 520.0 : MediaQuery.of(context).size.width * 0.94;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Parent / Guardian Access',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text(
                "Enter your ward's institute email. An OTP will be sent to the guardian email on file.",
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Ward email field
              TextField(
                controller: _wardEmailController,
                decoration: const InputDecoration(
                  labelText: "Ward's Institute Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_otpSent,
              ),
              const SizedBox(height: 12),

              // Continue / Send OTP button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: (_isSending || _otpSent) ? null : _sendOtp,
                  child: _isSending
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Continue'),
                ),
              ),

              const SizedBox(height: 12),

              if (_otpSent) ...[
                const Divider(),
                const SizedBox(height: 12),
                const Text('Enter OTP sent to guardian email'),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyOtp,
                        child: _isVerifying
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Verify OTP'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: (_secondsLeft == 0 && !_isSending) ? _resendOtp : null,
                      child: _secondsLeft == 0
                          ? const Text('Resend OTP')
                          : Text('Resend (${_secondsLeft}s)'),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _resendTimer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
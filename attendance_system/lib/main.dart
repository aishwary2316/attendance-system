import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_router.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),

      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  // Later this will check JWT storage
  Future<bool> checkLogin() async {

    // TODO: check stored JWT token
    await Future.delayed(const Duration(seconds: 1));

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkLogin(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const DashboardRouter();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
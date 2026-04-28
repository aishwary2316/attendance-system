import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Required for kDebugMode
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'login_screen.dart';

/// Dashboards
import 'dashboard/admin_dashboard.dart';
import 'dashboard/faculty_dashboard.dart';
import 'dashboard/student_dashboard.dart';
import 'dashboard/hod_dashboard.dart';
import 'dashboard/director_dashboard.dart';
import 'dashboard/parent_dashboard.dart';

class DashboardRouter extends StatefulWidget {
  const DashboardRouter({super.key});

  @override
  State<DashboardRouter> createState() => _DashboardRouterState();
}

class _DashboardRouterState extends State<DashboardRouter> {
  final storage = const FlutterSecureStorage();

  /// Retrieves auth info and determines if the app should run in Mock Mode.
  Future<Map<String, dynamic>?> getAuthInfo() async {
    final token = await storage.read(key: "jwt_token");

    if (token == null) return null;

    if (JwtDecoder.isExpired(token)) {
      await storage.delete(key: "jwt_token");
      return null;
    }

    Map<String, dynamic> decoded = JwtDecoder.decode(token);

    // SAFETY CHECK: Force isMock to false in Release builds.
    bool isMock = false;
    if (kDebugMode) {
      // Only in debug apks, check if the email ends with .test
      isMock = decoded["email"]?.endsWith(".test") ?? false;
    }

    return {
      "role": decoded["role"],
      "isMock": isMock,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getAuthInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authData = snapshot.data;
        if (authData == null || authData["role"] == null) {
          return const LoginScreen();
        }

        final String role = authData["role"];
        final bool isMock = authData["isMock"] ?? false;

        switch (role) {
          case "admin":
            return AdminDashboard(isMock: isMock);
          case "faculty":
            return FacultyDashboard(isMock: isMock);
          case "hod":
            return HodDashboard(isMock: isMock);
          case "director":
            return DirectorDashboard(isMock: isMock);
          case "student":
            return StudentDashboard(isMock: isMock);
          case "parent":
            return ParentDashboard(isMock: isMock);
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
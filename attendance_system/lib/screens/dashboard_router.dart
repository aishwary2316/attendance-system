import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'login_screen.dart';

/// dashboards (create these later)
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

  Future<String?> getUserRole() async {

    final token = await storage.read(key: "jwt");

    if (token == null) {
      return null;
    }

    if (JwtDecoder.isExpired(token)) {
      await storage.delete(key: "jwt");
      return null;
    }

    Map<String, dynamic> decoded = JwtDecoder.decode(token);

    return decoded["role"];
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<String?>(
      future: getUserRole(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final role = snapshot.data;

        if (role == null) {
          return const LoginScreen();
        }

        switch (role) {

          case "admin":
            return const AdminDashboard();

          case "faculty":
            return const FacultyDashboard();

          case "hod":
            return const HodDashboard();

          case "director":
            return const DirectorDashboard();

          case "student":
            return const StudentDashboard();

          case "parent":
            return const ParentDashboard();

          default:
            return const LoginScreen();
        }
      },
    );
  }
}









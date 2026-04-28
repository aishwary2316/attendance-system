// lib/screens/dashboard/hod_dashboard.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// HoD Dashboard
///
/// Features implemented (mock):
/// - Department KPIs (avg attendance, low-attendance count, courses running)
/// - Faculty list with quick view & notify actions
/// - Low-attendance students list (flagged for review)
/// - Course performance section
/// - Grievance triage area
/// - Date range filters, export, refresh
///
/// Replace TODO sections with real API calls (e.g., ApiService.fetchDeptMetrics()).
class HodDashboard extends StatefulWidget {
  final bool isMock;
  const HodDashboard({super.key, this.isMock = false});

  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  // ----- Mock KPI data (replace via API) -----
  double deptAvgAttendance = 86.4;
  int lowAttendanceCount = 24;
  int activeCourses = 12;
  DateTime lastUpdated = DateTime.now().subtract(const Duration(hours: 1));

  // Mock lists
  List<Map<String, dynamic>> faculty = List.generate(6, (i) {
    return {
      "id": "F00${i + 1}",
      "name": ["Dr. Sharma","Dr. Das","Prof. Roy","Dr. Mehta","Dr. Kaur","Dr. Sengupta"][i],
      "email": ["sharma","das","roy","mehta","kaur","sengupta"][i] + "@iiitmanipur.ac.in",
      "avgAttendance": 75 + Random().nextInt(20)
    };
  });

  List<Map<String, dynamic>> lowStudents = List.generate(8, (i) {
    return {
      "roll": "ECE2023${120 + i}",
      "name": ["Aman","Priya","Sita","Rahul","Karan","Nisha","Arjun","Maya"][i],
      "attendance": 60 + Random().nextInt(14),
      "course": ["Digital","Signals","Micro","AI","VLSI","Embedded","Networks","Power"][i % 8]
    };
  });

  List<Map<String, String>> courses = [
    {"code": "ECE201", "name": "Digital Electronics"},
    {"code": "ECE305", "name": "Signals & Systems"},
    {"code": "ECE412", "name": "VLSI"},
    {"code": "ECE323", "name": "Embedded Systems"},
  ];

  List<Map<String, String>> grievances = [
    {"id": "G101", "roll": "ECE2023123", "student":"Priya", "reason":"Marked absent", "status":"Pending"},
    {"id": "G102", "roll": "ECE2023126", "student":"Karan", "reason":"Face not detected", "status":"Under review"},
  ];

  // UI state
  DateTimeRange? _range;
  bool _isExporting = false;
  bool _isNotifying = false;

  @override
  void initState() {
    super.initState();
    // TODO: initial fetch from backend
    // _fetchDeptData();
  }

  Future<void> _fetchDeptData() async {
    // TODO: fetch real data from backend
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {});
  }

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);
    try {
      // TODO: request backend to prepare export (CSV/PDF) and download/open
      await Future.delayed(Duration(seconds: 1 + Random().nextInt(2)));
      _showSnack("Export ready (demo).");
    } catch (e) {
      _showSnack("Export failed: $e", background: Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showSnack(String text, {Color? background}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(text), backgroundColor: background));
  }

  Future<void> _notifyFaculty(String facultyEmail) async {
    setState(() => _isNotifying = true);
    try {
      // TODO: call backend notify endpoint (email/push) for faculty
      await Future.delayed(const Duration(milliseconds: 800));
      _showSnack("Notification sent to $facultyEmail");
    } catch (e) {
      _showSnack("Notify failed: $e", background: Colors.red);
    } finally {
      setState(() => _isNotifying = false);
    }
  }

  void _viewFaculty(String id) {
    // TODO: navigate to faculty profile / performance page
    _showSnack("Open faculty profile $id");
  }

  void _openStudentProfile(String roll) {
    // TODO: navigate to student profile
    _showSnack("Open student profile $roll");
  }

  void _acknowledgeGrievance(String id) {
    // TODO: backend call
    setState(() {
      for (var g in grievances) {
        if (g["id"] == id) {
          g["status"] = "Acknowledged";
        }
      }
    });
    _showSnack("Acknowledged $id");
  }

  void _resolveGrievance(String id) {
    // TODO: backend call
    setState(() {
      grievances.removeWhere((g) => g["id"] == id);
    });
    _showSnack("Resolved $id");
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (r != null) {
      setState(() => _range = r);
      _showSnack("Selected ${r.start.toIso8601String().split('T').first} - ${r.end.toIso8601String().split('T').first}");
      // TODO: refetch for selected range
    }
  }

  Widget _kpiCard(String title, String value, {IconData? icon, Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 200,
        child: Row(
          children: [
            if (icon != null)
              CircleAvatar(
                backgroundColor: (color ?? Colors.indigo).withOpacity(0.12),
                child: Icon(icon, color: color ?? Colors.indigo),
              ),
            if (icon != null) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyTile(Map<String, dynamic> f) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(f["name"][0])),
        title: Text(f["name"]),
        subtitle: Text("${f["email"]}\nAvg Attendance: ${f["avgAttendance"]}%"),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == "view") _viewFaculty(f["id"]);
            if (v == "notify") _notifyFaculty(f["email"]);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: "view", child: Text("View Profile")),
            PopupMenuItem(value: "notify", child: Text(_isNotifying ? "Notifying..." : "Notify")),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStudentRow(Map<String, dynamic> s) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(s["name"][0])),
        title: Text("${s["roll"]} • ${s["name"]}"),
        subtitle: Text("${s["course"]} — ${s["attendance"]}%"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: "Open profile",
              onPressed: () => _openStudentProfile(s["roll"]),
            ),
            IconButton(
              icon: const Icon(Icons.mail),
              tooltip: "Contact guardian",
              onPressed: () => _showSnack("Contact guardian for ${s["roll"]} (TODO)"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, String> c) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(c["code"]!.split(RegExp(r'\d'))[0])),
        title: Text(c["name"]!),
        subtitle: Text(c["code"]!),
        trailing: ElevatedButton(
          onPressed: () {
            // TODO: open course detail & performance
            _showSnack("Open ${c["code"]}");
          },
          child: const Text("Open"),
        ),
      ),
    );
  }

  Widget _buildGrievanceTile(Map<String, String> g) {
    return Card(
      color: g["status"] == "Pending" ? Colors.orange[50] : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(g["student"]![0])),
        title: Text("${g["id"]} • ${g["student"]}"),
        subtitle: Text("${g["reason"]}"),
        trailing: Wrap(
          spacing: 8,
          children: [
            Text(g["status"]!, style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(icon: const Icon(Icons.check), onPressed: () => _acknowledgeGrievance(g["id"]!)),
            IconButton(icon: const Icon(Icons.done_all), onPressed: () => _resolveGrievance(g["id"]!)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 950;

    return Scaffold(
      appBar: AppBar(
        title: const Text("HoD Dashboard"),
        actions: [
          IconButton(onPressed: _fetchDeptData, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _exportReport, icon: _isExporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: isWide ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT: main (KPIs, faculty, courses)
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // KPI row
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _kpiCard("Dept avg attendance", "${deptAvgAttendance.toStringAsFixed(1)}%", icon: Icons.bar_chart, color: Colors.blue),
                        const SizedBox(width: 12),
                        _kpiCard("Low attendance students", "$lowAttendanceCount", icon: Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12),
                        _kpiCard("Active courses", "$activeCourses", icon: Icons.book, color: Colors.indigo),
                        const SizedBox(width: 12),
                        _kpiCard("Last updated", "${lastUpdated.toLocal().toString().split('.').first}", icon: Icons.update, color: Colors.grey),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filters
                  Row(
                    children: [
                      ElevatedButton.icon(onPressed: _pickRange, icon: const Icon(Icons.date_range), label: Text(_range == null ? "Select Range" : "${_range!.start.toIso8601String().split('T').first} - ${_range!.end.toIso8601String().split('T').first}")),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(onPressed: () => _showSnack("Filter courses (TODO)"), icon: const Icon(Icons.filter_list), label: const Text("Filters")),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(onPressed: () => _showSnack("Open analytics"), icon: const Icon(Icons.analytics), label: const Text("Analytics")),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Faculty list
                  Align(alignment: Alignment.centerLeft, child: Text("Faculty", style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: faculty.map((f) => _buildFacultyTile(f)).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 18),

            // RIGHT: sidebar (low students, courses, grievances)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Low Attendance Students", style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          const Text("Students below minimum threshold for the selected range"),
                          const SizedBox(height: 8),
                          ...lowStudents.take(4).map((s) => _buildLowStudentRow(s)).toList(),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(onPressed: () => _showSnack("Open full low-attendance list"), icon: const Icon(Icons.list), label: const Text("View All"))
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Courses", style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ...courses.map((c) => _buildCourseCard(c)).toList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Align(alignment: Alignment.centerLeft, child: Text("Grievances", style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: grievances.map((g) => _buildGrievanceTile(g)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ) : Column(
          children: [
            // Mobile stacked layout
            Row(
              children: [
                Expanded(child: _kpiCard("Dept avg", "${deptAvgAttendance.toStringAsFixed(1)}%", icon: Icons.bar_chart, color: Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _kpiCard("Low students", "$lowAttendanceCount", icon: Icons.warning, color: Colors.orange)),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: _pickRange, icon: const Icon(Icons.date_range), label: const Text("Date range"))),
                const SizedBox(width: 8),
                ElevatedButton.icon(onPressed: _exportReport, icon: _isExporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download), label: const Text("Export")),
              ],
            ),

            const SizedBox(height: 12),

            Align(alignment: Alignment.centerLeft, child: Text("Faculty", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView(
                children: faculty.map((f) => _buildFacultyTile(f)).toList(),
              ),
            ),

            const SizedBox(height: 12),

            Align(alignment: Alignment.centerLeft, child: Text("Low Attendance", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView(
                children: lowStudents.map((s) => _buildLowStudentRow(s)).toList(),
              ),
            ),

            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: Text("Grievances", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListView(
                children: grievances.map((g) => _buildGrievanceTile(g)).toList(),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
// lib/screens/dashboard/director_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class DirectorDashboard extends StatefulWidget {
  final bool isMock;
  const DirectorDashboard({super.key, this.isMock = false});

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  // ----- Mock KPI data (replace with API data) -----
  double overallAttendance = 89.2;
  int departmentsMeetingThreshold = 5; // out of totalDepartments
  int totalDepartments = 8;
  int flaggedStudents = 18;
  DateTime lastUpdated = DateTime.now().subtract(const Duration(hours: 2));

  // Mock department data
  List<Map<String, dynamic>> departments = [
    {"name": "CSE", "attendance": 92.1},
    {"name": "ECE", "attendance": 90.5},
    {"name": "ME", "attendance": 85.2},
    {"name": "Civil", "attendance": 82.7},
    {"name": "AI", "attendance": 88.4},
    {"name": "Math", "attendance": 86.9},
    {"name": "Physics", "attendance": 84.6},
    {"name": "Chemistry", "attendance": 80.3},
  ];

  // Mock flagged students
  List<Map<String, String>> flagged = List.generate(6, (i) {
    return {
      "roll": "CSE2023${100 + i}",
      "name": ["Amit", "Neha", "Sunil", "Pooja", "Rakesh", "Tina"][i],
      "dept": ["CSE", "ECE", "ME", "CSE", "AI", "ME"][i],
      "reason": (i % 2 == 0) ? "Low attendance" : "Repeated absences"
    };
  });

  // UI state
  DateTimeRange? _selectedRange;
  String _sortBy = "attendance_desc";
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // TODO: load real metrics from backend
    // _fetchDirectorMetrics();
  }

  Future<void> _fetchDirectorMetrics() async {
    // TODO: Call backend API to fetch:
    // - overallAttendance
    // - departments list
    // - flagged students
    // - departmentsMeetingThreshold
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {});
  }

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);
    try {
      // TODO: call backend to generate CSV/PDF and download it.
      await Future.delayed(Duration(seconds: 1 + Random().nextInt(2)));
      _showSnack("Report exported (demo).");
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

  // sorting helper
  List<Map<String, dynamic>> _sortedDepartments() {
    List<Map<String, dynamic>> d = List.from(departments);
    if (_sortBy == "attendance_asc") {
      d.sort((a, b) => (a["attendance"] as double).compareTo(b["attendance"] as double));
    } else {
      d.sort((a, b) => (b["attendance"] as double).compareTo(a["attendance"] as double));
    }
    return d;
  }

  Widget _kpiCard(String title, String value, {IconData? icon, Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(14),
        width: 220,
        child: Row(
          children: [
            if (icon != null)
              CircleAvatar(
                radius: 22,
                backgroundColor: (color ?? Colors.indigo).withOpacity(0.12),
                child: Icon(icon, color: color ?? Colors.indigo),
              ),
            if (icon != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentRow(Map<String, dynamic> dept) {
    final att = (dept["attendance"] as double);
    // color scale: green >90, amber 80-90, red <80
    Color barColor;
    if (att >= 90) barColor = Colors.green;
    else if (att >= 80) barColor = Colors.orange;
    else barColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(dept["name"][0])),
        title: Text(dept["name"]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: LinearProgressIndicator(
            value: att / 100.0,
            backgroundColor: Colors.grey.shade200,
            color: barColor,
            minHeight: 10,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${att.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("${(att >= 75) ? 'OK' : 'Below threshold'}", style: TextStyle(color: att >= 75 ? Colors.green : Colors.red)),
          ],
        ),
        onTap: () {
          // TODO: navigate to department detail page
          _showSnack("Open ${dept["name"]} department details");
        },
      ),
    );
  }

  Widget _buildFlaggedTile(Map<String, String> f) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(f["name"]![0])),
        title: Text("${f["roll"]} • ${f["name"]}"),
        subtitle: Text("${f["dept"]} — ${f["reason"]}"),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == "view") _showSnack("View ${f["roll"]}");
            if (v == "export") _showSnack("Export report for ${f["roll"]}");
            if (v == "resolve") {
              setState(() => flagged.removeWhere((x) => x["roll"] == f["roll"]));
              _showSnack("Marked ${f["roll"]} as reviewed.");
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: "view", child: Text("View")),
            PopupMenuItem(value: "export", child: Text("Export")),
            PopupMenuItem(value: "resolve", child: Text("Mark reviewed")),
          ],
        ),
      ),
    );
  }

  // Date range picker
  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange: _selectedRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    );
    if (r != null) {
      setState(() {
        _selectedRange = r;
      });
      // TODO: refetch metrics for new range
      _showSnack("Selected ${r.start.toIso8601String().split('T').first} - ${r.end.toIso8601String().split('T').first}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Director Dashboard"),
        actions: [
          IconButton(
            onPressed: _fetchDirectorMetrics,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
          IconButton(
            onPressed: _exportReport,
            icon: _isExporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
            tooltip: "Export report",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: isWide
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left main column
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // KPI cards row
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _kpiCard("Overall Attendance", "${overallAttendance.toStringAsFixed(1)}%", icon: Icons.bar_chart, color: Colors.blue),
                        const SizedBox(width: 12),
                        _kpiCard("Departments above threshold", "$departmentsMeetingThreshold / $totalDepartments", icon: Icons.apartment, color: Colors.indigo),
                        const SizedBox(width: 12),
                        _kpiCard("Flagged students", "$flaggedStudents", icon: Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12),
                        _kpiCard("Last updated", "${lastUpdated.toLocal().toString().split('.').first}", icon: Icons.update, color: Colors.grey),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filters row
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_selectedRange == null ? "Select Date Range" : "${_selectedRange!.start.toIso8601String().split('T').first} - ${_selectedRange!.end.toIso8601String().split('T').first}"),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: "attendance_desc", child: Text("Sort: Attendance (desc)")),
                          DropdownMenuItem(value: "attendance_asc", child: Text("Sort: Attendance (asc)")),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _sortBy = v ?? "attendance_desc";
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _fetchDirectorMetrics,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Refresh"),
                      )
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Trend / chart placeholder
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      height: 300,
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Institute Attendance Trend", style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 12),
                          Expanded(child: Center(child: Text("Chart placeholder — integrate fl_chart or charts_flutter here"))),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Department comparison
                  Align(alignment: Alignment.centerLeft, child: Text("Department Comparison", style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: _sortedDepartments().map(_buildDepartmentRow).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 18),

            // Right sidebar
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
                          const Text("Alerts & Actions", style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          const Text("Students below minimum attendance threshold are flagged here for review."),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => _showSnack("Open institute-level report"),
                            icon: const Icon(Icons.analytics),
                            label: const Text("Open Full Report"),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showSnack("Notify departments"),
                            icon: const Icon(Icons.notifications),
                            label: const Text("Notify Departments"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Align(alignment: Alignment.centerLeft, child: Text("Flagged Students", style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: flagged.map(_buildFlaggedTile).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : Column(
          children: [
            // stacked view for narrow screens
            Row(
              children: [
                Expanded(child: _kpiCard("Overall Attendance", "${overallAttendance.toStringAsFixed(1)}%", icon: Icons.bar_chart, color: Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _kpiCard("Flagged students", "$flaggedStudents", icon: Icons.warning, color: Colors.orange)),
              ],
            ),

            const SizedBox(height: 12),

            // Filters and actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range),
                    label: const Text("Select range"),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _exportReport,
                  icon: _isExporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
                  label: const Text("Export"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Trend placeholder
            Card(
              child: Container(
                padding: const EdgeInsets.all(12),
                height: 220,
                child: const Center(child: Text("Trend chart placeholder")),
              ),
            ),

            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: Text("Department Comparison", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView(
                children: _sortedDepartments().map(_buildDepartmentRow).toList(),
              ),
            ),

            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: Text("Flagged Students", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView(
                children: flagged.map(_buildFlaggedTile).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
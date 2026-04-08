// lib/screens/dashboard/admin_dashboard.dart
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // ----- MOCK DATA (replace with real API data) -----
  int totalStudents = 324;
  int presentToday = 289;
  double avgAttendance = 88.6;
  int pendingGrievances = 6;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, String>> students = List.generate(8, (i) {
    return {
      "roll": "ECE2023${100 + i}",
      "name": ["Rahul Sharma", "Aman Patel", "Sita Devi", "Priya Roy", "Karan Mehta", "Nisha Lal", "Arjun Das", "Maya Sen"][i % 8],
      "course": ["Digital", "Signals", "Micro", "Embedded", "AI", "Networks", "VLSI", "Power"][i % 8],
      "status": i % 4 == 0 ? "Absent" : "Present"
    };
  });

  List<Map<String, String>> grievances = List.generate(4, (i) {
    return {
      "id": "G00${i + 1}",
      "roll": "ECE2023${101 + i}",
      "student": ["Rahul Sharma", "Aman Patel", "Sita Devi", "Priya Roy"][i],
      "reason": i % 2 == 0 ? "False absent" : "Missing attendance",
      "status": i % 2 == 0 ? "Pending" : "Under review"
    };
  });

  // ----- UI state -----
  String selectedCourse = "All courses";
  DateTime? selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ----- Placeholders for API actions -----
  Future<void> _refreshDashboard() async {
    // TODO: call backend to fetch real KPIs + lists
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      // update state with API results
    });
  }

  void _openImportDialog() {
    // TODO: open file picker or open dataset uploader modal
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Import dataset"),
        content: const Text(
            "Hook this to your dataset downloader or CSV importer. (TODO)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _openStudentProfile(String roll) {
    // TODO: navigate to student profile screen (full details, images)
    _showSnack("Open profile for $roll");
  }

  void _editAttendanceQuick(String roll) {
    // TODO: implement edit attendance modal (log changes for audit)
    _showSnack("Edit attendance: $roll (open editor)");
  }

  void _acknowledgeGrievance(String id) {
    // TODO: call backend to change grievance status
    _showSnack("Acknowledged grievance $id");
    setState(() {
      grievances = grievances.map((g) {
        if (g['id'] == id) {
          return {...g, "status": "Acknowledged"};
        }
        return g;
      }).toList();
    });
  }

  void _resolveGrievance(String id) {
    // TODO: call backend to mark resolved and update attendance if required
    _showSnack("Resolved grievance $id");
    setState(() {
      grievances.removeWhere((g) => g['id'] == id);
    });
  }

  void _showSnack(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  // ----- UI Widgets -----
  Widget _buildKpiCard(String title, String value, {Color? color, IconData? icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(14),
        width: 200,
        child: Row(
          children: [
            if (icon != null)
              CircleAvatar(
                radius: 22,
                backgroundColor: color?.withOpacity(0.12) ?? Colors.indigo.withOpacity(0.12),
                child: Icon(icon, color: color ?? Colors.indigo),
              ),
            if (icon != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search by name / roll / course",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) {
              setState(() {
                // optional: search locally or call backend
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.filter_alt),
          label: const Text("Filters"),
          onPressed: () async {
            // show simple filter sheet
            await showModalBottomSheet(
              context: context,
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text("Course"),
                        trailing: DropdownButton<String>(
                          value: selectedCourse,
                          items: <String>["All courses", "Digital", "Signals", "Micro", "AI"]
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedCourse = val ?? "All courses";
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text("Date"),
                        trailing: TextButton(
                          child: Text(selectedDate == null ? "Any" : selectedDate!.toIso8601String().split("T").first),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) {
                              setState(() => selectedDate = d);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _refreshDashboard();
                        },
                        child: const Text("Apply Filters"),
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _openImportDialog,
          icon: const Icon(Icons.upload_file),
          label: const Text("Import"),
        ),
      ],
    );
  }

  Widget _buildStudentRow(Map<String, String> s) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(s['name']![0])),
        title: Text("${s['roll']} • ${s['name']}"),
        subtitle: Text("${s['course']} • ${s['status']}"),
        trailing: PopupMenuButton<String>(
          onSelected: (choice) {
            if (choice == "view") _openStudentProfile(s['roll']!);
            if (choice == "edit") _editAttendanceQuick(s['roll']!);
            if (choice == "folder") _showSnack("Open folder for ${s['roll']}");
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: "view", child: Text("View profile")),
            PopupMenuItem(value: "edit", child: Text("Edit attendance")),
            PopupMenuItem(value: "folder", child: Text("Open files")),
          ],
        ),
        onTap: () => _openStudentProfile(s['roll']!),
      ),
    );
  }

  Widget _buildGrievanceCard(Map<String, String> g) {
    return Card(
      color: g['status'] == "Pending" ? Colors.orange[50] : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent.shade100,
          child: Text(g['student']![0]),
        ),
        title: Text("${g['id']} • ${g['student']}"),
        subtitle: Text("${g['reason']}"),
        trailing: Wrap(
          spacing: 8,
          children: [
            Text(g['status']!, style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: "Acknowledge",
              onPressed: () => _acknowledgeGrievance(g['id']!),
            ),
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: "Resolve",
              onPressed: () => _resolveGrievance(g['id']!),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Layout -----
  @override
  Widget build(BuildContext context) {
    // Responsive layout: show two-column on wide screens
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // TODO: logout -> clear JWT and navigate to login
              _showSnack("Logout (TODO)");
            },
          )
        ],
      ),
      drawer: isWide ? null : Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("Admin", style: Theme.of(context).textTheme.titleLarge)),
            ListTile(leading: const Icon(Icons.people), title: const Text("Students")),
            ListTile(leading: const Icon(Icons.school), title: const Text("Courses")),
            ListTile(leading: const Icon(Icons.report), title: const Text("Reports")),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: isWide
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column (main)
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // KPI row
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildKpiCard("Total students", "$totalStudents", icon: Icons.people, color: Colors.indigo),
                        const SizedBox(width: 12),
                        _buildKpiCard("Present today", "$presentToday", icon: Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        _buildKpiCard("Avg Attendance", "${avgAttendance.toStringAsFixed(1)}%", icon: Icons.bar_chart, color: Colors.blue),
                        const SizedBox(width: 12),
                        _buildKpiCard("Pending grievances", "$pendingGrievances", icon: Icons.report_problem, color: Colors.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search & filters
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  // Students list
                  Align(alignment: Alignment.centerLeft, child: Text("Students", style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (_, idx) => _buildStudentRow(students[idx]),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(width: 18),

            // Right column (sidebar)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(onPressed: _openImportDialog, icon: const Icon(Icons.upload), label: const Text("Import dataset")),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(onPressed: () => _showSnack("Open user management"), icon: const Icon(Icons.manage_accounts), label: const Text("Manage users")),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(onPressed: () => _showSnack("Open courses"), icon: const Icon(Icons.book), label: const Text("Manage courses")),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Placeholder chart area
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      height: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Attendance trend", style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 12),
                          Expanded(
                            child: Center(child: Text("Chart placeholder\n(plug in charts_flutter or fl_chart)")),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Grievances
                  Align(alignment: Alignment.centerLeft, child: Text("Recent Grievances", style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: grievances.length,
                      itemBuilder: (_, idx) => _buildGrievanceCard(grievances[idx]),
                    ),
                  ),
                ],
              ),
            )
          ],
        )
            : Column(
          children: [
            // small screens: stacked
            Row(
              children: [
                Expanded(child: _buildKpiCard("Total students", "$totalStudents", icon: Icons.people, color: Colors.indigo)),
                const SizedBox(width: 8),
                Expanded(child: _buildKpiCard("Present today", "$presentToday", icon: Icons.check_circle, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: Text("Students", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (_, idx) => _buildStudentRow(students[idx]),
              ),
            ),

            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: Text("Recent Grievances", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: grievances.length,
                itemBuilder: (_, idx) => _buildGrievanceCard(grievances[idx]),
              ),
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _openImportDialog, icon: const Icon(Icons.upload), label: const Text("Import dataset")),
          ],
        ),
      ),
    );
  }
}
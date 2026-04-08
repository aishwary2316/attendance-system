import 'package:flutter/material.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {

  // ----- MOCK DATA (replace with API data) -----
  List<Map<String, dynamic>> sessions = [
    {"course": "Digital Electronics", "time": "10:00 AM", "room": "LH-201"},
    {"course": "Signals & Systems", "time": "12:00 PM", "room": "LH-105"},
  ];

  List<Map<String, dynamic>> students = [
    {"roll": "ECE2023001", "name": "Rahul Sharma", "status": "Present"},
    {"roll": "ECE2023002", "name": "Aman Patel", "status": "Absent"},
    {"roll": "ECE2023003", "name": "Priya Roy", "status": "Present"},
    {"roll": "ECE2023004", "name": "Neha Lal", "status": "Present"},
  ];

  List<Map<String, String>> grievances = [
    {
      "roll": "ECE2023002",
      "student": "Aman Patel",
      "reason": "Marked absent incorrectly"
    },
    {
      "roll": "ECE2023007",
      "student": "Karan Mehta",
      "reason": "Attendance not updated"
    }
  ];

  int presentCount = 3;
  int absentCount = 1;

  // ----- Placeholder API actions -----
  void startAttendance(String course) {
    // TODO start face-recognition attendance
    _showSnack("Starting attendance for $course");
  }

  void markAttendance(String roll, String status) {
    setState(() {
      students = students.map((s) {
        if (s["roll"] == roll) {
          s["status"] = status;
        }
        return s;
      }).toList();
    });
  }

  void exportAttendance() {
    // TODO export CSV
    _showSnack("Export attendance");
  }

  void _showSnack(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  // ----- UI widgets -----

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildSessionCard(Map session) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.class_),
        title: Text(session["course"]),
        subtitle: Text("${session["time"]} • ${session["room"]}"),
        trailing: ElevatedButton(
          child: const Text("Start Attendance"),
          onPressed: () => startAttendance(session["course"]),
        ),
      ),
    );
  }

  Widget buildStudentRow(Map student) {
    Color color =
    student["status"] == "Present" ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text(student["name"][0])),
        title: Text("${student["roll"]} • ${student["name"]}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => markAttendance(student["roll"], "Present"),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => markAttendance(student["roll"], "Absent"),
            ),
          ],
        ),
        subtitle: Text(student["status"], style: TextStyle(color: color)),
      ),
    );
  }

  Widget buildGrievance(Map g) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.report_problem, color: Colors.orange),
        title: Text("${g["roll"]} • ${g["student"]}"),
        subtitle: Text(g["reason"]),
        trailing: ElevatedButton(
          child: const Text("Resolve"),
          onPressed: () {
            setState(() {
              grievances.remove(g);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: exportAttendance,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: isWide
            ? Row(
          children: [

            /// LEFT PANEL
            Expanded(
              flex: 3,
              child: Column(
                children: [

                  /// stats
                  Row(
                    children: [
                      Expanded(
                          child: statCard("Present", "$presentCount",
                              Icons.check_circle, Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: statCard("Absent", "$absentCount",
                              Icons.cancel, Colors.red)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// sessions
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Today's Sessions",
                          style: Theme.of(context).textTheme.titleMedium)),

                  const SizedBox(height: 8),

                  ...sessions.map(buildSessionCard),

                  const SizedBox(height: 16),

                  /// students
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Student Attendance",
                          style: Theme.of(context).textTheme.titleMedium)),

                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView(
                      children: students.map(buildStudentRow).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            /// RIGHT PANEL
            Expanded(
              flex: 2,
              child: Column(
                children: [

                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Student Grievances",
                          style: Theme.of(context).textTheme.titleMedium)),

                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView(
                      children: grievances.map(buildGrievance).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )

        /// MOBILE VIEW
            : Column(
          children: [

            Row(
              children: [
                Expanded(
                    child: statCard("Present", "$presentCount",
                        Icons.check_circle, Colors.green)),
                const SizedBox(width: 8),
                Expanded(
                    child: statCard("Absent", "$absentCount",
                        Icons.cancel, Colors.red)),
              ],
            ),

            const SizedBox(height: 16),

            Align(
                alignment: Alignment.centerLeft,
                child: Text("Today's Sessions",
                    style: Theme.of(context).textTheme.titleMedium)),

            const SizedBox(height: 8),

            ...sessions.map(buildSessionCard),

            const SizedBox(height: 16),

            Align(
                alignment: Alignment.centerLeft,
                child: Text("Students",
                    style: Theme.of(context).textTheme.titleMedium)),

            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                children: students.map(buildStudentRow).toList(),
              ),
            ),

            const SizedBox(height: 12),

            Align(
                alignment: Alignment.centerLeft,
                child: Text("Grievances",
                    style: Theme.of(context).textTheme.titleMedium)),

            const SizedBox(height: 8),

            SizedBox(
              height: 200,
              child: ListView(
                children: grievances.map(buildGrievance).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
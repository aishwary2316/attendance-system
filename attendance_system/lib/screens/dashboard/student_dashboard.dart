// lib/screens/dashboard/student_dashboard.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// Student Dashboard
///
/// Features:
/// - Overall attendance percentage card
/// - Course-wise attendance with progress bars
/// - Monthly calendar view with day-level present/absent/holiday markers
/// - Attendance history list (recent sessions)
/// - Grievance submission modal
/// - Quick actions: export report, raise grievance, view profile
///
/// Replace TODO blocks with real API integration (ApiService etc.)
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  // MOCK DATA (replace with API)
  double overallAttendance = 87.3;
  final List<Map<String, dynamic>> courses = [
    {"code": "ECE201", "name": "Digital Electronics", "attendance": 91.2},
    {"code": "ECE305", "name": "Signals & Systems", "attendance": 88.0},
    {"code": "ECE412", "name": "VLSI", "attendance": 79.5},
    {"code": "ECE323", "name": "Embedded Systems", "attendance": 85.6},
  ];

  // calendar map -> date string (yyyy-mm-dd) : status
  // status: "present", "absent", "holiday", "unknown"
  Map<String, String> monthStatus = {};

  // recent attendance history
  List<Map<String, String>> recentHistory = List.generate(8, (i) {
    final dt = DateTime.now().subtract(Duration(days: i));
    return {
      "date": dt.toIso8601String().split('T').first,
      "course": ["Digital Electronics", "Signals & Systems", "VLSI", "Embedded Systems"][i % 4],
      "status": i % 5 == 0 ? "Absent" : "Present"
    };
  });

  // UI state
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isSubmittingGrievance = false;

  @override
  void initState() {
    super.initState();
    _populateMockMonthStatus();
    // TODO: fetch real user data (overallAttendance, courses, monthStatus, history) from backend
  }

  void _populateMockMonthStatus() {
    monthStatus.clear();
    final rng = Random();
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, d);
      final key = _dateKey(date);
      // random pick status for demo
      final r = rng.nextInt(100);
      if (r < 70) monthStatus[key] = "present";
      else if (r < 88) monthStatus[key] = "absent";
      else if (r < 93) monthStatus[key] = "holiday";
      else monthStatus[key] = "unknown";
    }
  }

  String _dateKey(DateTime d) => "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  // navigate months
  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _populateMockMonthStatus();
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _populateMockMonthStatus();
    });
  }

  Future<void> _exportAttendance() async {
    // TODO: call backend to generate CSV/PDF and download or show link
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export started (demo)')));
  }

  Future<void> _openGrievanceModal() async {
    await showDialog(context: context, builder: (_) => GrievanceDialog(onSubmit: _submitGrievance));
  }

  Future<void> _submitGrievance(String courseCode, String reason, String details) async {
    setState(() => _isSubmittingGrievance = true);
    try {
      // TODO: POST /grievances { roll, courseCode, reason, details }
      await Future.delayed(const Duration(seconds: 1)); // simulate network
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grievance submitted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmittingGrievance = false);
    }
  }

  // calendar cell widget
  Widget _buildCalendarCell(DateTime date) {
    final key = _dateKey(date);
    final status = monthStatus[key] ?? "unknown";
    Color bg;
    String label;
    switch (status) {
      case "present":
        bg = Colors.green.shade200;
        label = "P";
        break;
      case "absent":
        bg = Colors.red.shade200;
        label = "A";
        break;
      case "holiday":
        bg = Colors.blue.shade100;
        label = "H";
        break;
      default:
        bg = Colors.grey.shade100;
        label = "";
    }

    final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;

    return GestureDetector(
      onTap: () {
        // quick info
        final snack = "$key — ${status.toUpperCase()}";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack), duration: const Duration(seconds: 1)));
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: isToday ? Colors.indigo : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        width: 44,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${date.day}", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isToday ? Colors.indigo[900] : Colors.black87)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // month calendar grid
  Widget _buildCalendar(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = first.weekday; // 1 = Mon, we want Sun..Sat? We'll render Mon..Sun
    final weeks = <Widget>[];

    final totalCells = ((firstWeekday - 1) + daysInMonth);
    final rows = (totalCells / 7).ceil();

    int day = 1;
    for (int r = 0; r < rows; r++) {
      final cells = <Widget>[];
      for (int c = 0; c < 7; c++) {
        final cellIndex = r * 7 + c;
        final dayOfMonth = cellIndex - (firstWeekday - 1) + 1;
        if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
          cells.add(Container(width: 44, height: 48, margin: const EdgeInsets.all(4)));
        } else {
          final date = DateTime(month.year, month.month, dayOfMonth);
          cells.add(_buildCalendarCell(date));
        }
      }
      weeks.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: cells));
    }

    return Column(
      children: [
        // Weekday header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((d) => SizedBox(
            width: 44,
            child: Center(child: Text(d, style: TextStyle(fontSize: 12, color: Colors.black54))),
          ))
              .toList(),
        ),
        const SizedBox(height: 6),
        ...weeks,
      ],
    );
  }

  // course attendance row
  Widget _buildCourseRow(Map<String, dynamic> c) {
    final att = (c["attendance"] as double);
    final color = att >= 90 ? Colors.green : (att >= 75 ? Colors.orange : Colors.red);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(c["code"].substring(0, 3))),
        title: Text(c["name"]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
          child: LinearProgressIndicator(
            value: att / 100.0,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 10,
          ),
        ),
        trailing: Text("${att.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () {
          // TODO: navigate to course attendance detail
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Open ${c['code']} details (TODO)")));
        },
      ),
    );
  }

  Widget _buildHistoryRow(Map<String, String> h) {
    final status = h["status"] ?? "Unknown";
    final color = status == "Present" ? Colors.green : (status == "Absent" ? Colors.red : Colors.grey);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(h["date"]!.split('-').last)),
        title: Text(h["course"]!),
        subtitle: Text(h["date"]!),
        trailing: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(onPressed: _exportAttendance, icon: const Icon(Icons.download)),
          IconButton(onPressed: _openGrievanceModal, icon: const Icon(Icons.report_problem)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Top summary
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Overall Attendance', style: TextStyle(color: Colors.black54)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text("${overallAttendance.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _openGrievanceModal,
                                          icon: const Icon(Icons.report_problem),
                                          label: const Text('Raise Grievance'),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View full attendance (TODO)'))), child: const Text('View details'))
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // quick stats card
                      Card(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          width: 220,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Status', style: TextStyle(color: Colors.black54)),
                              SizedBox(height: 8),
                              Text('Active', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              SizedBox(height: 6),
                              Text('No restrictions'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Courses section
                  Align(alignment: Alignment.centerLeft, child: Text('Course-wise Attendance', style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  ...courses.map(_buildCourseRow),

                  const SizedBox(height: 12),

                  // Attendance history
                  Align(alignment: Alignment.centerLeft, child: Text('Recent Attendance', style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: recentHistory.map(_buildHistoryRow).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 18),

            // Right column
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Calendar card
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('${_currentMonth.year} - ${_currentMonth.month.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w700))),
                              IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                              IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildCalendar(_currentMonth),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _legendChip('Present', Colors.green.shade200),
                              _legendChip('Absent', Colors.red.shade200),
                              _legendChip('Holiday', Colors.blue.shade100),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick links / actions
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download certificate (TODO)'))), icon: const Icon(Icons.file_download), label: const Text('Download Attendance Report')),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View profile (TODO)'))), icon: const Icon(Icons.account_circle), label: const Text('View Profile')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        )
            : Column(
          children: [
            // mobile layout stacked
            Card(
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Overall Attendance', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text("${overallAttendance.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ])),
                    ElevatedButton.icon(onPressed: _openGrievanceModal, icon: const Icon(Icons.report_problem), label: const Text('Raise Grievance'))
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Align(alignment: Alignment.centerLeft, child: Text('Course-wise Attendance', style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: ListView(children: courses.map(_buildCourseRow).toList()),
            ),

            const SizedBox(height: 10),

            Align(alignment: Alignment.centerLeft, child: Text('Attendance History', style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(height: 220, child: ListView(children: recentHistory.map(_buildHistoryRow).toList())),

            const SizedBox(height: 10),

            Card(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('${_currentMonth.year} - ${_currentMonth.month.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w700))),
                        IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                        IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildCalendar(_currentMonth),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      _legendChip('Present', Colors.green.shade200),
                      _legendChip('Absent', Colors.red.shade200),
                      _legendChip('Holiday', Colors.blue.shade100),
                    ]),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _legendChip(String label, Color color) {
    return Chip(
      backgroundColor: color,
      label: Text(label),
    );
  }
}

/// Grievance submission dialog
class GrievanceDialog extends StatefulWidget {
  final Future<void> Function(String courseCode, String reason, String details) onSubmit;
  const GrievanceDialog({required this.onSubmit, super.key});

  @override
  State<GrievanceDialog> createState() => _GrievanceDialogState();
}

class _GrievanceDialogState extends State<GrievanceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCourse;
  String _reason = '';
  String _details = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // default pick first available course in demo
    _selectedCourse = 'ECE201';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_selectedCourse!, _reason, _details);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Replace course list with API-driven list later
    final courseOptions = const [
      {'code': 'ECE201', 'label': 'Digital Electronics'},
      {'code': 'ECE305', 'label': 'Signals & Systems'},
      {'code': 'ECE412', 'label': 'VLSI'},
      {'code': 'ECE323', 'label': 'Embedded Systems'},
    ];

    return AlertDialog(
      title: const Text('Raise Grievance'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCourse,
                items: courseOptions.map((c) => DropdownMenuItem(value: c['code'], child: Text(c['label']!))).toList(),
                onChanged: (v) => setState(() => _selectedCourse = v),
                decoration: const InputDecoration(labelText: 'Select Course'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Reason (short)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter short reason' : null,
                onSaved: (v) => _reason = v!.trim(),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Details (optional)'),
                maxLines: 4,
                onSaved: (v) => _details = v ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
        ),
      ],
    );
  }
}
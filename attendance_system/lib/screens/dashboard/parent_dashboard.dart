// lib/screens/dashboard/parent_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// Parent Dashboard
///
/// - Select ward (if multiple)
/// - See overall attendance, course-wise bars, recent history
/// - Notifications / messages (mock)
/// - Raise grievance for ward (opens grievance dialog)
/// - Quick actions: download report, contact faculty, view profile
///
/// TODO: replace mock data + simulated delays with real ApiService calls
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  // ---- Mock guardian wards (replace by backend response tied to parent JWT) ----
  final List<Map<String, dynamic>> _wards = [
    {
      "roll": "ECE2023001",
      "name": "Rahul Sharma",
      "overall": 88.2,
      "department": "ECE",
      "guardian": {"name": "Mr Sharma", "phone": "+91-9876543210", "email": "father@gmail.com"},
      "courses": [
        {"code": "ECE201", "name": "Digital Electronics", "attendance": 92.1},
        {"code": "ECE305", "name": "Signals & Systems", "attendance": 89.0},
        {"code": "ECE323", "name": "Embedded Systems", "attendance": 82.5},
      ],
      "recent": [
        {"date": "2026-02-28", "course": "Digital Electronics", "status": "Present"},
        {"date": "2026-02-27", "course": "Signals & Systems", "status": "Present"},
        {"date": "2026-02-26", "course": "Embedded Systems", "status": "Absent"},
      ],
    },
    {
      "roll": "CSE2023005",
      "name": "Priya Roy",
      "overall": 91.4,
      "department": "CSE",
      "guardian": {"name": "Mrs Roy", "phone": "+91-9123456780", "email": "mother@gmail.com"},
      "courses": [
        {"code": "CSE201", "name": "Data Structures", "attendance": 95.3},
        {"code": "CSE305", "name": "OS", "attendance": 90.0},
      ],
      "recent": [
        {"date": "2026-02-28", "course": "Data Structures", "status": "Present"},
        {"date": "2026-02-27", "course": "OS", "status": "Present"},
      ],
    },
  ];

  // UI state
  int _selectedWardIndex = 0;
  bool _isLoading = false;
  bool _isExporting = false;
  List<Map<String, String>> _notifications = [
    {"time": "2026-02-28 09:00", "text": "Attendance for Digital Electronics updated."},
    {"time": "2026-02-25 15:00", "text": "New grievance update: Rahul Sharma - G101."},
  ];

  // Grievance modal state handled inside dialog below

  // ---- Lifecycle ----
  @override
  void initState() {
    super.initState();
    // TODO: initial fetch: load wards linked to logged-in parent (via API)
    // e.g., await ApiService.getParentWards(parentId)
  }

  // ---- Helpers ----
  Map<String, dynamic> get _currentWard => _wards[_selectedWardIndex];

  Future<void> _refreshWardData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: fetch latest attendance / recent / courses for selected ward
      await Future.delayed(const Duration(milliseconds: 700));
      // setState with updated data when response arrives
    } catch (e) {
      _showSnack("Failed to refresh: $e", background: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String t, {Color? background}) {
    final m = ScaffoldMessenger.of(context);
    m.removeCurrentSnackBar();
    m.showSnackBar(SnackBar(content: Text(t), backgroundColor: background));
  }

  Future<void> _exportAttendanceReport() async {
    setState(() => _isExporting = true);
    try {
      // TODO: call backend: GET /reports/student/{roll}/export -> returns presigned URL or bytes
      await Future.delayed(const Duration(seconds: 1));
      _showSnack("Report ready (demo). Check downloads.");
    } catch (e) {
      _showSnack("Export failed: $e", background: Colors.red);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _openContactOptions() async {
    final guardian = _currentWard["guardian"] as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      builder: (c) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              runSpacing: 8,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(guardian["name"]),
                  subtitle: Text(guardian["email"]),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text("Send email to faculty"),
                  subtitle: Text("Faculty & admin emails will be used"),
                  onTap: () {
                    Navigator.pop(c);
                    _showSnack("Open email composer (TODO)");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text("Send message"),
                  onTap: () {
                    Navigator.pop(c);
                    _showSnack("Open messaging (TODO)");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text("Call guardian: ${guardian["phone"]}"),
                  onTap: () {
                    Navigator.pop(c);
                    _showSnack("Initiate call (TODO)");
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => Navigator.pop(c), child: const Text("Close")),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGrievanceDialog() async {
    await showDialog(
      context: context,
      builder: (_) => ParentRaiseGrievanceDialog(
        wardRoll: _currentWard["roll"] as String,
        onSubmit: (reason, details) async {
          // TODO: call backend POST /grievances with parent identity
          await Future.delayed(const Duration(seconds: 1));
          _showSnack("Grievance submitted (demo)");
          // optionally add a notification
          setState(() {
            _notifications.insert(0, {"time": DateTime.now().toString().split('.').first, "text": "Grievance submitted for ${_currentWard["name"]}"});
          });
        },
      ),
    );
  }

  // ---- UI Elements ----
  Widget _kpiCard(String title, String value, {IconData? icon, Color? color}) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 200,
        child: Row(
          children: [
            if (icon != null) CircleAvatar(backgroundColor: (color ?? Colors.indigo).withOpacity(0.1), child: Icon(icon, color: color ?? Colors.indigo)),
            if (icon != null) const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]))
          ],
        ),
      ),
    );
  }

  Widget _courseRow(Map<String, dynamic> c) {
    final att = (c["attendance"] as double);
    final color = att >= 90 ? Colors.green : (att >= 75 ? Colors.orange : Colors.red);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(c["code"].toString().substring(0, 3))),
        title: Text("${c["name"]}"),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(value: att / 100.0, minHeight: 10, color: color, backgroundColor: Colors.grey.shade200),
        ),
        trailing: Text("${att.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.w700)),
        onTap: () {
          _showSnack("Open course details (TODO)");
        },
      ),
    );
  }

  Widget _historyRow(Map<String, dynamic> h) {
    final status = h["status"] as String;
    final color = status == "Present" ? Colors.green : (status == "Absent" ? Colors.red : Colors.grey);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(h["date"].split('-').last)),
        title: Text(h["course"]),
        subtitle: Text(h["date"]),
        trailing: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _notificationsColumn() {
    if (_notifications.isEmpty) {
      return const Center(child: Text("No notifications"));
    }
    return Column(
      children: _notifications.map((n) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: const Icon(Icons.notifications),
          title: Text(n["text"]!),
          subtitle: Text(n["time"]!),
          onTap: () {
            _showSnack("Open notification (TODO)");
          },
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parent Dashboard"),
        actions: [
          IconButton(onPressed: _refreshWardData, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _openContactOptions, icon: const Icon(Icons.contact_mail)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isWide ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT: main area
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Ward selector + top actions
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedWardIndex,
                          decoration: const InputDecoration(labelText: "Select ward"),
                          items: List.generate(_wards.length, (i) {
                            final w = _wards[i];
                            return DropdownMenuItem(value: i, child: Text("${w["name"]} • ${w["roll"]}"));
                          }),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectedWardIndex = v);
                            _refreshWardData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isExporting ? null : _exportAttendanceReport,
                        icon: _isExporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
                        label: const Text("Download Report"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _openGrievanceDialog,
                        icon: const Icon(Icons.report_problem),
                        label: const Text("Raise Grievance"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Top KPIs
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _kpiCard("Overall Attendance", "${_currentWard["overall"].toStringAsFixed(1)}%", icon: Icons.bar_chart, color: Colors.blue),
                        const SizedBox(width: 12),
                        _kpiCard("Department", _currentWard["department"], icon: Icons.apartment, color: Colors.indigo),
                        const SizedBox(width: 12),
                        _kpiCard("Guardian", (_currentWard["guardian"]["name"] as String), icon: Icons.person, color: Colors.teal),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Course-wise list
                  Align(alignment: Alignment.centerLeft, child: Text("Course-wise Attendance", style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  ...(_currentWard["courses"] as List<dynamic>).map((c) => _courseRow(c as Map<String, dynamic>)).toList(),

                  const SizedBox(height: 12),

                  // Recent history
                  Align(alignment: Alignment.centerLeft, child: Text("Recent Attendance", style: Theme.of(context).textTheme.titleMedium)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: (_currentWard["recent"] as List<dynamic>).map((r) => _historyRow(r as Map<String, dynamic>)).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // RIGHT: sidebar (notifications + contact & profile)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Notifications", style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        _notificationsColumn(),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Quick Info", style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Text("Ward: ${_currentWard["name"]}"),
                        const SizedBox(height: 4),
                        Text("Roll: ${_currentWard["roll"]}"),
                        const SizedBox(height: 8),
                        Text("Guardian: ${_currentWard["guardian"]["name"]}"),
                        const SizedBox(height: 4),
                        SelectableText("Contact: ${_currentWard["guardian"]["phone"]}"),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(onPressed: () => _showSnack("Open ward profile (TODO)"), icon: const Icon(Icons.account_circle), label: const Text("View Profile")),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(onPressed: _openContactOptions, icon: const Icon(Icons.contact_mail), label: const Text("Contact Support")),
                      ]),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ) : // MOBILE LAYOUT
        Column(
          children: [
            // Ward selector + actions
            DropdownButtonFormField<int>(
              value: _selectedWardIndex,
              decoration: const InputDecoration(labelText: "Select ward"),
              items: List.generate(_wards.length, (i) {
                final w = _wards[i];
                return DropdownMenuItem(value: i, child: Text("${w["name"]} • ${w["roll"]}"));
              }),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedWardIndex = v);
                _refreshWardData();
              },
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: _openGrievanceDialog, icon: const Icon(Icons.report_problem), label: const Text("Raise Grievance"))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(onPressed: _openContactOptions, icon: const Icon(Icons.contact_mail), label: const Text("Contact"))),
              ],
            ),

            const SizedBox(height: 12),

            // KPIs
            Row(
              children: [
                Expanded(child: _kpiCard("Overall", "${_currentWard["overall"].toStringAsFixed(1)}%", icon: Icons.bar_chart)),
                const SizedBox(width: 8),
                Expanded(child: _kpiCard("Dept", _currentWard["department"], icon: Icons.apartment)),
              ],
            ),

            const SizedBox(height: 12),

            Align(alignment: Alignment.centerLeft, child: Text("Course-wise Attendance", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(height: 180, child: ListView(children: (_currentWard["courses"] as List<dynamic>).map((c) => _courseRow(c as Map<String, dynamic>)).toList())),

            const SizedBox(height: 12),

            Align(alignment: Alignment.centerLeft, child: Text("Recent Attendance", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(height: 200, child: ListView(children: (_currentWard["recent"] as List<dynamic>).map((r) => _historyRow(r as Map<String, dynamic>)).toList())),

            const SizedBox(height: 12),

            Align(alignment: Alignment.centerLeft, child: Text("Notifications", style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            SizedBox(height: 140, child: SingleChildScrollView(child: _notificationsColumn())),
          ],
        ),
      ),
    );
  }
}

/// Dialog for parent to raise a grievance for a ward
class ParentRaiseGrievanceDialog extends StatefulWidget {
  final String wardRoll;
  final Future<void> Function(String reason, String details) onSubmit;
  const ParentRaiseGrievanceDialog({required this.wardRoll, required this.onSubmit, super.key});

  @override
  State<ParentRaiseGrievanceDialog> createState() => _ParentRaiseGrievanceDialogState();
}

class _ParentRaiseGrievanceDialogState extends State<ParentRaiseGrievanceDialog> {
  final _formKey = GlobalKey<FormState>();
  String _reason = '';
  String _details = '';
  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_reason, _details);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Raise grievance for ${widget.wardRoll}"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              decoration: const InputDecoration(labelText: "Short reason"),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Enter reason" : null,
              onSaved: (v) => _reason = v!.trim(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: "Details (optional)"),
              maxLines: 4,
              onSaved: (v) => _details = v ?? '',
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
        ElevatedButton(onPressed: _submitting ? null : _submit, child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Submit")),
      ],
    );
  }
}
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../services/api_service.dart';
import '../../utils/safe_log.dart';
import '../../config/api_config.dart';

// ============================================================
// DESIGN TOKENS — Light Theme
// ============================================================
class _DS {
  // Palette – Clean White + Indigo accent (modern institutional)
  static const bg = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F2F5);
  static const border = Color(0xFFE2E8F0);
  static const primary = Color(0xFF4361EE);
  static const primaryDim = Color(0x1A4361EE);
  static const accent = Color(0xFFF59E0B);
  static const accentDim = Color(0x1AF59E0B);
  static const success = Color(0xFF10B981);
  static const successDim = Color(0x1510B981);
  static const danger = Color(0xFFEF4444);
  static const dangerDim = Color(0x15EF4444);
  static const textPrimary = Color(0xFF1A202C);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFCBD5E1);
  static const shimmerBase = Color(0xFFE2E8F0);
  static const shimmerHighlight = Color(0xFFF8FAFC);

  static TextStyle heading1 = const TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5,
  );
  static TextStyle heading2 = const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.3,
  );
  static TextStyle heading3 = const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.2,
  );
  static TextStyle body = const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary,
  );
  static TextStyle bodySmall = const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary,
  );
  static TextStyle label = const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 0.8,
  );
  static TextStyle mono = const TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary, fontFamily: 'monospace',
  );

  static const r4 = BorderRadius.all(Radius.circular(4));
  static const r6 = BorderRadius.all(Radius.circular(6));
  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r10 = BorderRadius.all(Radius.circular(10));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));
  static const rFull = BorderRadius.all(Radius.circular(999));

  static List<BoxShadow> shadowSm = [
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> shadowMd = [
    BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> glowPrimary = [
    BoxShadow(color: primary.withOpacity(0.18), blurRadius: 16, spreadRadius: 0),
  ];
}

// ============================================================
// SHIMMER LOADING WIDGET
// ============================================================
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? _DS.r8,
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [_DS.shimmerBase, _DS.shimmerHighlight, _DS.shimmerBase],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GLASS CARD (Light variant)
// ============================================================
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const _GlassCard({
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? _DS.surface,
        borderRadius: borderRadius ?? _DS.r16,
        border: border ?? Border.all(color: _DS.border, width: 1),
        boxShadow: boxShadow ?? _DS.shadowSm,
      ),
      child: child,
    );
  }
}

// ============================================================
// ANIMATED PROGRESS BAR
// ============================================================
class _AnimatedProgressBar extends StatefulWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const _AnimatedProgressBar({
    required this.value,
    this.height = 8,
    this.color,
    this.backgroundColor,
  });

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.value.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _effectiveColor {
    if (widget.color != null) return widget.color!;
    final v = widget.value;
    if (v >= 0.75) return _DS.success;
    if (v >= 0.5) return _DS.accent;
    return _DS.danger;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => LayoutBuilder(
        builder: (_, constraints) => ClipRRect(
          borderRadius: _DS.rFull,
          child: SizedBox(
            height: widget.height,
            child: Stack(children: [
              Container(
                color: widget.backgroundColor ?? _DS.surfaceAlt,
                width: constraints.maxWidth,
              ),
              Container(
                width: constraints.maxWidth * _anim.value,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_effectiveColor.withOpacity(0.7), _effectiveColor],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION MODEL
// ============================================================
class _AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final _NotifType type;
  bool isRead;

  _AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

enum _NotifType { grievanceResponse, info, warning }

// ============================================================
// NOTIFICATION BELL ICON
// ============================================================
class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: _DS.r10,
              border: Border.all(color: _DS.border),
              boxShadow: _DS.shadowSm,
            ),
            child: const Icon(Icons.notifications_outlined, color: _DS.textSecondary, size: 18),
          ),
          if (count > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: _DS.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// MAIN DASHBOARD
// ============================================================
class StudentDashboard extends StatefulWidget {
  final bool isMock;
  const StudentDashboard({super.key, this.isMock = false});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _mainScrollController = ScrollController();
  final TextEditingController _courseSearchController = TextEditingController();

  // Data State — partial loading supported
  Map<String, dynamic>? studentData;
  List<dynamic> attendanceRecords = [];
  List<dynamic> courses = [];
  List<dynamic> filteredCourses = [];
  String? profileImageUrl;

  // Loading flags per section
  bool _isProfileLoading = true;
  bool _isStatsLoading = true;
  bool _isCoursesLoading = true;
  bool _isAttendanceLoading = true;
  bool _isImageLoading = true;

  String? _profileError;
  String? _statsError;
  String? _coursesError;

  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedCalendarDate;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Notifications
  final List<_AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _initDashboard();
    _courseSearchController.addListener(_filterCourses);
    _loadMockNotifications();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _courseSearchController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _loadMockNotifications() {
    _notifications.addAll([
      _AppNotification(
        id: 'n1',
        title: 'Grievance Resolved',
        body: 'Your grievance for Digital Electronics on 15 Apr has been reviewed and marked as resolved by the faculty.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: _NotifType.grievanceResponse,
      ),
      _AppNotification(
        id: 'n2',
        title: 'Attendance Warning',
        body: 'Your attendance in Signals & Systems has dropped below 75%. Please attend upcoming classes.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: _NotifType.warning,
      ),
      _AppNotification(
        id: 'n3',
        title: 'Grievance Pending',
        body: 'Your grievance filed for VLSI Design session on 10 Apr is under review.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        type: _NotifType.grievanceResponse,
        isRead: true,
      ),
    ]);
  }

  int get _unreadNotifCount => _notifications.where((n) => !n.isRead).length;

  // =========================================================
  // DATA LOGIC — Partial loading
  // =========================================================

  Future<void> _initDashboard() async {
    setState(() {
      _isProfileLoading = true;
      _isStatsLoading = true;
      _isCoursesLoading = true;
      _isAttendanceLoading = true;
      _isImageLoading = true;
      _profileError = null;
      _statsError = null;
      _coursesError = null;
    });

    if (kDebugMode && widget.isMock) {
      await _loadMockState();
    } else {
      await _loadProductionState();
    }
    _fadeCtrl.forward(from: 0);
  }

  Future<void> _loadProductionState() async {
    // Step 1: Load profile
    try {
      final userRes = await _apiService.getMe();
      if (mounted) {
        setState(() {
          studentData = userRes.data;
          _isProfileLoading = false;
          _isStatsLoading = false;
        });
      }
    } catch (e) {
      devLog("Profile load error: $e");
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
          _isStatsLoading = false;
          _profileError = 'Could not load profile';
        });
      }
    }

    final userId = studentData?['_id'];
    final roll = studentData?['roll'] ?? studentData?['idCode'] ?? '';

    // Step 2: Load courses and attendance in parallel
    if (userId != null) {
      // Load courses
      _apiService.listCourses().then((res) {
        if (mounted) {
          final courseData = res.data;
          setState(() {
            courses = courseData is List ? courseData : [];
            filteredCourses = List.from(courses);
            _isCoursesLoading = false;
          });
        }
      }).catchError((e) {
        devLog("Courses load error: $e");
        if (mounted) setState(() { _isCoursesLoading = false; _coursesError = 'Could not load courses'; });
      });

      // Load attendance
      _apiService.getAttendanceByStudent(userId).then((res) {
        if (mounted) {
          setState(() {
            attendanceRecords = res.data is List ? res.data : [];
            _isAttendanceLoading = false;
          });
        }
      }).catchError((e) {
        devLog("Attendance load error: $e");
        if (mounted) setState(() => _isAttendanceLoading = false);
      });
    } else {
      if (mounted) {
        setState(() {
          _isCoursesLoading = false;
          _isAttendanceLoading = false;
        });
      }
    }

    // Step 3: Load profile image independently
    if (roll.isNotEmpty) {
      _loadProfileImage(roll);
    } else {
      if (mounted) setState(() => _isImageLoading = false);
    }
  }

  Future<void> _loadProfileImage(String roll) async {
    try {
      final imgListRes = await _apiService.listStudentImages(roll);
      final dynamic imgData = imgListRes.data;
      List images = [];
      if (imgData is Map) {
        images = imgData['images'] ?? imgData['files'] ?? [];
      } else if (imgData is List) {
        images = imgData;
      }
      if (images.isNotEmpty && mounted) {
        final firstImg = images.first;
        final fileName = firstImg is Map
            ? (firstImg['file_name'] ?? firstImg['filename'] ?? firstImg.toString())
            : firstImg.toString();
        final url = _apiService.getImageUrl(roll, fileName);
        setState(() {
          profileImageUrl = url;
          _isImageLoading = false;
        });
      } else {
        if (mounted) setState(() => _isImageLoading = false);
      }
    } catch (e) {
      devLog("Profile image fetch error for roll=$roll: $e");
      if (mounted) setState(() => _isImageLoading = false);
    }
  }

  Future<void> _loadMockState() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      studentData = {
        "_id": "mock_user_001",
        "name": "Aishwary Raj",
        "roll": "230104023",
        "email": "aish230104023@iiitmanipur.ac.in",
      };
      _isProfileLoading = false;
      _isStatsLoading = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final mockCourses = [
      {"_id": "c1", "name": "Digital Electronics", "code": "ECE201"},
      {"_id": "c2", "name": "Signals & Systems", "code": "ECE305"},
      {"_id": "c3", "name": "VLSI Design", "code": "ECE412"},
      {"_id": "c4", "name": "Microprocessors", "code": "ECE318"},
      {"_id": "c5", "name": "Embedded Systems", "code": "ECE430"},
    ];
    setState(() {
      courses = mockCourses;
      filteredCourses = List.from(courses);
      _isCoursesLoading = false;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final rng = Random(42);
    setState(() {
      attendanceRecords = List.generate(80, (i) {
        final date = DateTime.now().subtract(Duration(days: i));
        final cIdx = i % 5;
        final status = rng.nextDouble() > 0.22 ? "present" : "absent";
        return {
          "status": status,
          "course_id": mockCourses[cIdx]['_id'],
          "course_name": mockCourses[cIdx]['name'],
          "timestamp": date.toIso8601String(),
          "_id": "att_$i",
        };
      });
      _isAttendanceLoading = false;
      _isImageLoading = false;
    });
  }

  void _filterCourses() {
    final query = _courseSearchController.text.toLowerCase();
    setState(() {
      filteredCourses = query.isEmpty
          ? List.from(courses)
          : courses.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final code = (c['code'] ?? '').toString().toLowerCase();
        return name.contains(query) || code.contains(query);
      }).toList();
    });
  }

  double _getCoursePercentage(String courseId) {
    final courseAtt = attendanceRecords.where((r) => r['course_id'] == courseId).toList();
    if (courseAtt.isEmpty) return 0.0;
    final present = courseAtt.where((r) => r['status'] == 'present').length;
    return (present / courseAtt.length) * 100;
  }

  int get _totalSessions => attendanceRecords.length;
  int get _presentCount => attendanceRecords.where((r) => r['status'] == 'present').length;
  int get _absentCount => _totalSessions - _presentCount;
  double get _overallPct => _totalSessions == 0 ? 0.0 : (_presentCount / _totalSessions) * 100;

  String _getDateStatus(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final recs = attendanceRecords.where((r) {
      final ts = r['timestamp']?.toString() ?? '';
      return ts.startsWith(key);
    }).toList();
    if (recs.isEmpty) return "none";
    return recs.any((r) => r['status'] == 'present') ? "present" : "absent";
  }

  // =========================================================
  // PDF GENERATION — saves to Downloads
  // =========================================================

  Future<void> _generateAttendancePdf() async {
    _showSnack("Generating PDF...", icon: Icons.hourglass_top, color: _DS.primary);
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
      final fileNameDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final studentName = (studentData?['name'] ?? 'Student')
          .toString()
          .replaceAll(' ', '_');

      final courseStats = courses.map((c) {
        final pct = _getCoursePercentage(c['_id']);
        return [
          c['code'] ?? '-',
          c['name'] ?? '-',
          '${_getCourseAttCount(c['_id'], 'present')}',
          '${_getCourseAttCount(c['_id'], 'absent')}',
          '${pct.toStringAsFixed(1)}%',
        ];
      }).toList();

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'IIIT Manipur – Attendance Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Generated: $dateStr', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Student: ${studentData?['name'] ?? 'N/A'}',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Roll No: ${studentData?['roll'] ?? 'N/A'}',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Email: ${studentData?['email'] ?? 'N/A'}',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Overall Attendance: ${_overallPct.toStringAsFixed(1)}%',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ]),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Course-wise Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Code', 'Course', 'Present', 'Absent', '%'],
            data: courseStats,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 20),
          pw.Text('Session Log',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Day', 'Course', 'Status'],
            data: attendanceRecords.map((r) {
              final d = DateTime.tryParse(r['timestamp'] ?? '') ?? DateTime.now();
              return [
                DateFormat('yyyy-MM-dd').format(d),
                DateFormat('EEE').format(d),
                r['course_name'] ?? r['course_id'] ?? '-',
                (r['status'] ?? '').toString().toUpperCase(),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ));

      // Save to Downloads directory
      Directory? saveDir;

      if (Platform.isAndroid) {
        // Try Downloads folder first
        try {
          saveDir = Directory('/storage/emulated/0/Download');
          if (!await saveDir.exists()) {
            saveDir = await getExternalStorageDirectory();
          }
        } catch (_) {
          saveDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        saveDir = await getApplicationDocumentsDirectory();
      } else {
        saveDir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      }

      saveDir ??= await getTemporaryDirectory();

      final fileName = 'Attendance_${studentName}_$fileNameDate.pdf';
      final file = File('${saveDir.path}/$fileName');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      devLog("PDF saved at: ${file.path}");

      final result = await OpenFilex.open(file.path);
      devLog("OpenFilex result: ${result.type} - ${result.message}");

      if (result.type == ResultType.done) {
        _showSnack("PDF saved to Downloads: $fileName",
            icon: Icons.check_circle, color: _DS.success);
      } else {
        // File saved but could not open — still success
        _showSnack("PDF saved: $fileName", icon: Icons.check_circle, color: _DS.success);
      }
    } catch (e) {
      devLog("PDF generation error: $e");
      _showSnack("Could not generate PDF: ${e.toString().split('\n').first}",
          icon: Icons.error, color: _DS.danger);
    }
  }

  int _getCourseAttCount(String courseId, String status) =>
      attendanceRecords.where((r) => r['course_id'] == courseId && r['status'] == status).length;

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _showSnack(String msg, {IconData? icon, Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _DS.surface,
      shape: RoundedRectangleBorder(
        borderRadius: _DS.r12,
        side: BorderSide(color: color ?? _DS.border),
      ),
      margin: const EdgeInsets.all(16),
      content: Row(children: [
        if (icon != null) ...[Icon(icon, color: color, size: 18), const SizedBox(width: 10)],
        Flexible(child: Text(msg, style: _DS.body.copyWith(color: _DS.textPrimary))),
      ]),
    ));
  }

  // =========================================================
  // NOTIFICATION PANEL
  // =========================================================

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        builder: (__, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: _DS.border),
          ),
          child: Column(children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: _DS.border, borderRadius: _DS.rFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                const Icon(Icons.notifications_outlined, color: _DS.primary, size: 22),
                const SizedBox(width: 10),
                Text('Notifications', style: _DS.heading2),
                const Spacer(),
                if (_unreadNotifCount > 0)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        for (final n in _notifications) n.isRead = true;
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Mark all read',
                        style: _DS.label.copyWith(color: _DS.primary)),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            const Divider(color: _DS.border, height: 1),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.notifications_off_outlined,
                      color: _DS.textMuted, size: 40),
                  const SizedBox(height: 12),
                  Text('No notifications yet', style: _DS.bodySmall),
                ]),
              )
                  : ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) =>
                const Divider(color: _DS.border, height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final notif = _notifications[i];
                  return _NotificationTile(
                    notification: notif,
                    onTap: () {
                      setState(() => notif.isRead = true);
                    },
                    onDismiss: () {
                      setState(() => _notifications.removeAt(i));
                      Navigator.pop(context);
                      _showNotificationPanel();
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    ).then((_) => setState(() {})); // refresh bell badge
  }

  // =========================================================
  // GRIEVANCE MODAL
  // =========================================================

  void _showGrievanceModal(dynamic record) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: _DS.r20,
            border: Border.all(color: _DS.border),
            boxShadow: _DS.shadowMd,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _DS.accentDim, borderRadius: _DS.r8),
                child: const Icon(Icons.report_problem_outlined, color: _DS.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Raise Grievance', style: _DS.heading2),
            ]),
            const SizedBox(height: 6),
            Text(
              record != null
                  ? 'Session on ${DateFormat('EEE, dd MMM yyyy').format(DateTime.tryParse(record['timestamp'] ?? '') ?? DateTime.now())}'
                  : 'General Attendance Grievance',
              style: _DS.bodySmall,
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: _DS.surfaceAlt,
                borderRadius: _DS.r12,
                border: Border.all(color: _DS.border),
              ),
              child: TextField(
                controller: ctrl,
                maxLines: 4,
                style: _DS.body,
                decoration: InputDecoration(
                  hintText: 'Describe your grievance clearly...',
                  hintStyle: _DS.bodySmall,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DS.textSecondary,
                  side: const BorderSide(color: _DS.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: _DS.r10),
                ),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Add a mock notification for submission
                  setState(() {
                    _notifications.insert(0, _AppNotification(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: 'Grievance Submitted',
                      body: 'Your grievance has been submitted and is under review.',
                      timestamp: DateTime.now(),
                      type: _NotifType.grievanceResponse,
                    ));
                  });
                  _showSnack("Grievance submitted successfully",
                      icon: Icons.check_circle, color: _DS.success);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: _DS.r10),
                ),
                child: const Text('Submit'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  // =========================================================
  // COURSE DETAIL MODAL
  // =========================================================

  void _showCourseDetail(dynamic course) {
    final recs = attendanceRecords
        .where((r) => r['course_id'] == course['_id'])
        .toList()
      ..sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));
    final pct = _getCoursePercentage(course['_id']);
    final present = recs.where((r) => r['status'] == 'present').length;
    final absent = recs.length - present;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (__, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: _DS.border),
            boxShadow: _DS.shadowMd,
          ),
          child: Column(children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: _DS.border, borderRadius: _DS.rFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: _DS.primaryDim, borderRadius: _DS.r8),
                    child: Text(course['code'] ?? '',
                        style: _DS.label.copyWith(color: _DS.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(course['name'] ?? '', style: _DS.heading2)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _courseStatChip('${pct.toStringAsFixed(0)}%', 'Attendance', _getStatusColor(pct)),
                  const SizedBox(width: 10),
                  _courseStatChip('$present', 'Present', _DS.success),
                  const SizedBox(width: 10),
                  _courseStatChip('$absent', 'Absent', _DS.danger),
                ]),
                const SizedBox(height: 12),
                _AnimatedProgressBar(value: pct / 100, height: 6),
                const SizedBox(height: 16),
                Text('Session History', style: _DS.heading3),
                const SizedBox(height: 4),
              ]),
            ),
            const Divider(color: _DS.border, height: 1),
            Expanded(
              child: recs.isEmpty
                  ? Center(child: Text('No sessions found', style: _DS.bodySmall))
                  : ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: recs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (_, i) {
                  final r = recs[i];
                  final date = DateTime.tryParse(r['timestamp'] ?? '') ?? DateTime.now();
                  final isP = r['status'] == 'present';
                  return ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isP ? _DS.successDim : _DS.dangerDim,
                        borderRadius: _DS.r8,
                      ),
                      child: Icon(
                        isP ? Icons.check_rounded : Icons.close_rounded,
                        color: isP ? _DS.success : _DS.danger,
                        size: 18,
                      ),
                    ),
                    title: Text(DateFormat('EEEE, dd MMMM yyyy').format(date), style: _DS.body),
                    subtitle: Text(DateFormat('hh:mm a').format(date), style: _DS.bodySmall),
                    trailing: GestureDetector(
                      onTap: () { Navigator.pop(context); _showGrievanceModal(r); },
                      child: Tooltip(
                        message: 'Raise grievance',
                        child: const Icon(Icons.flag_outlined, color: _DS.textMuted, size: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _courseStatChip(String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: _DS.r10,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value, style: _DS.heading2.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: _DS.label),
      ]),
    ));
  }

  Color _getStatusColor(double pct) {
    if (pct >= 75) return _DS.success;
    if (pct >= 50) return _DS.accent;
    return _DS.danger;
  }

  // =========================================================
  // MAIN BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: _DS.bg,
        colorScheme: const ColorScheme.light(primary: _DS.primary, surface: _DS.surface),
        appBarTheme: const AppBarTheme(backgroundColor: _DS.bg, elevation: 0),
      ),
      child: Scaffold(
        backgroundColor: _DS.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _buildProfileSection(),
                    const SizedBox(height: 24),
                    _buildOverallStatsCard(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('COURSES'),
                    const SizedBox(height: 12),
                    _buildCourseSearch(),
                    const SizedBox(height: 12),
                    _buildCourseList(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('CALENDAR'),
                    const SizedBox(height: 12),
                    _buildCalendarCard(),
                    const SizedBox(height: 28),
                    _buildRecentActivityHeader(),
                    const SizedBox(height: 12),
                    _buildRecentActivity(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SLIVER APP BAR
  // =========================================================

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 90,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _DS.bg,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
        title: Row(children: [
          Container(
            width: 6, height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_DS.primary, _DS.accent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: _DS.rFull,
            ),
          ),
          const SizedBox(width: 10),
          Text('Dashboard', style: _DS.heading2.copyWith(fontSize: 16, color: _DS.textPrimary)),
        ]),
        background: Container(color: _DS.bg),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _NotificationBell(
            count: _unreadNotifCount,
            onTap: _showNotificationPanel,
          ),
        ),
        _AppBarAction(
          icon: Icons.picture_as_pdf_outlined,
          tooltip: 'Export PDF',
          onTap: _generateAttendancePdf,
        ),
        _AppBarAction(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: _initDashboard,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // =========================================================
  // PROFILE SECTION (with skeleton)
  // =========================================================

  Widget _buildProfileSection() {
    if (_isProfileLoading) return _buildProfileSkeleton();

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _DS.primary.withOpacity(0.4), width: 2),
              boxShadow: _DS.glowPrimary,
            ),
            child: ClipOval(
              child: _isImageLoading
                  ? Container(
                color: _DS.surfaceAlt,
                child: const Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_DS.primary),
                    ),
                  ),
                ),
              )
                  : profileImageUrl != null
                  ? Image.network(
                profileImageUrl!,
                fit: BoxFit.cover,
                // headers: _apiService.authHeaders, // pass auth headers for image
                errorBuilder: (_, __, ___) => _avatarFallback,
                loadingBuilder: (_, child, loadingProgress) =>
                loadingProgress == null
                    ? child
                    : Container(
                  color: _DS.surfaceAlt,
                  child: const Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_DS.primary),
                      ),
                    ),
                  ),
                ),
              )
                  : _avatarFallback,
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: _DS.success,
                shape: BoxShape.circle,
                border: Border.all(color: _DS.surface, width: 2),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            studentData?['name'] ?? (_profileError != null ? 'Could not load' : 'Student'),
            style: _DS.heading2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _DS.primaryDim, borderRadius: _DS.rFull),
              child: Text(
                studentData?['roll'] ?? 'N/A',
                style: _DS.label.copyWith(color: _DS.primary, fontFamily: 'monospace'),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            studentData?['email'] ?? '',
            style: _DS.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ])),
        IconButton(
          onPressed: () => _showGrievanceModal(null),
          tooltip: 'Raise Grievance',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _DS.surfaceAlt, borderRadius: _DS.r8),
            child: const Icon(Icons.flag_outlined, color: _DS.textSecondary, size: 18),
          ),
        ),
      ]),
    );
  }

  Widget _buildProfileSkeleton() {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        _ShimmerBox(width: 70, height: 70, borderRadius: const BorderRadius.all(Radius.circular(35))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ShimmerBox(width: 140, height: 16),
          const SizedBox(height: 8),
          _ShimmerBox(width: 100, height: 12),
          const SizedBox(height: 8),
          _ShimmerBox(width: 180, height: 12),
        ])),
      ]),
    );
  }

  Widget get _avatarFallback => Container(
    color: _DS.surfaceAlt,
    child: const Icon(Icons.person_rounded, size: 36, color: _DS.textMuted),
  );

  // =========================================================
  // OVERALL STATS CARD (with skeleton)
  // =========================================================

  Widget _buildOverallStatsCard() {
    if (_isStatsLoading || _isAttendanceLoading) return _buildStatsSkeleton();

    final pct = _overallPct;
    final statusColor = _getStatusColor(pct);

    return _GlassCard(
      padding: const EdgeInsets.all(24),
      boxShadow: [
        BoxShadow(color: statusColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4)),
        ..._DS.shadowSm,
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Overall Attendance', style: _DS.label),
            const SizedBox(height: 4),
            Text('${pct.toStringAsFixed(1)}%', style: TextStyle(
              fontSize: 40, fontWeight: FontWeight.w800, color: statusColor, height: 1,
            )),
          ]),
          _AttendanceGauge(percentage: pct, size: 80),
        ]),
        const SizedBox(height: 20),
        _AnimatedProgressBar(value: pct / 100, height: 8),
        const SizedBox(height: 6),
        Row(children: [
          Text('${pct.toStringAsFixed(1)}% attended', style: _DS.bodySmall),
          const Spacer(),
          if (pct < 75)
            Text(
              '${(_totalSessions * 0.75 - _presentCount).ceil()} more to reach 75%',
              style: _DS.bodySmall.copyWith(color: _DS.accent),
            ),
        ]),
        const SizedBox(height: 20),
        const Divider(color: _DS.border, height: 1),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatColumn(_presentCount.toString(), 'Present', _DS.success),
          _verticalDivider(),
          _StatColumn(_absentCount.toString(), 'Absent', _DS.danger),
          _verticalDivider(),
          _StatColumn(_totalSessions.toString(), 'Total', _DS.primary),
          _verticalDivider(),
          _StatColumn('${courses.length}', 'Courses', _DS.accent),
        ]),
      ]),
    );
  }

  Widget _buildStatsSkeleton() {
    return _GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ShimmerBox(width: 120, height: 12),
            const SizedBox(height: 10),
            _ShimmerBox(width: 80, height: 40),
          ]),
          _ShimmerBox(width: 80, height: 80, borderRadius: const BorderRadius.all(Radius.circular(40))),
        ]),
        const SizedBox(height: 20),
        _ShimmerBox(width: double.infinity, height: 8, borderRadius: _DS.rFull),
        const SizedBox(height: 20),
        const Divider(color: _DS.border, height: 1),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ShimmerBox(width: 50, height: 40),
          _ShimmerBox(width: 50, height: 40),
          _ShimmerBox(width: 50, height: 40),
          _ShimmerBox(width: 50, height: 40),
        ]),
      ]),
    );
  }

  Widget _verticalDivider() =>
      Container(width: 1, height: 36, color: _DS.border);

  // =========================================================
  // SECTION LABEL
  // =========================================================

  Widget _buildSectionLabel(String label) {
    return Text(label, style: _DS.label.copyWith(letterSpacing: 1.5));
  }

  // =========================================================
  // COURSE SEARCH
  // =========================================================

  Widget _buildCourseSearch() {
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: _DS.r12,
        border: Border.all(color: _DS.border),
        boxShadow: _DS.shadowSm,
      ),
      child: TextField(
        controller: _courseSearchController,
        style: _DS.body,
        decoration: InputDecoration(
          hintText: 'Search by course name or code...',
          hintStyle: _DS.bodySmall,
          prefixIcon: const Icon(Icons.search_rounded, color: _DS.textMuted, size: 20),
          suffixIcon: _courseSearchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, color: _DS.textMuted, size: 18),
            onPressed: () {
              _courseSearchController.clear();
              _filterCourses();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // =========================================================
  // COURSE LIST (with skeleton)
  // =========================================================

  Widget _buildCourseList() {
    if (_isCoursesLoading) {
      return Column(
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _ShimmerBox(width: 4, height: 48, borderRadius: _DS.rFull),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _ShimmerBox(width: 60, height: 12),
                  const Spacer(),
                  _ShimmerBox(width: 40, height: 14),
                ]),
                const SizedBox(height: 8),
                _ShimmerBox(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                _ShimmerBox(width: double.infinity, height: 4, borderRadius: _DS.rFull),
              ])),
            ]),
          ),
        )),
      );
    }

    if (_coursesError != null && courses.isEmpty) {
      return _GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              const Icon(Icons.cloud_off_rounded, color: _DS.textMuted, size: 32),
              const SizedBox(height: 8),
              Text(_coursesError!, style: _DS.bodySmall),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _initDashboard,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ]),
          ),
        ),
      );
    }

    if (filteredCourses.isEmpty) {
      return _GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              const Icon(Icons.search_off_rounded, color: _DS.textMuted, size: 32),
              const SizedBox(height: 8),
              Text('No courses found', style: _DS.bodySmall),
            ]),
          ),
        ),
      );
    }

    return Column(
      children: filteredCourses.asMap().entries.map((entry) {
        final i = entry.key;
        final course = entry.value;
        final pct = _isAttendanceLoading ? -1.0 : _getCoursePercentage(course['_id']);
        final statusColor = pct < 0 ? _DS.textMuted : _getStatusColor(pct);

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + i * 50),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 8),
          child: _GlassCard(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => _showCourseDetail(course),
              borderRadius: _DS.r16,
              child: Row(children: [
                Container(
                  width: 4, height: 48,
                  decoration: BoxDecoration(
                    color: pct < 0 ? _DS.shimmerBase : statusColor,
                    borderRadius: _DS.rFull,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: _DS.surfaceAlt, borderRadius: _DS.r4),
                      child: Text(course['code'] ?? '',
                          style: _DS.mono.copyWith(fontSize: 11)),
                    ),
                    const Spacer(),
                    if (_isAttendanceLoading)
                      _ShimmerBox(width: 36, height: 14)
                    else
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Text(course['name'] ?? '', style: _DS.body,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  _isAttendanceLoading
                      ? _ShimmerBox(width: double.infinity, height: 4, borderRadius: _DS.rFull)
                      : _AnimatedProgressBar(value: (pct / 100).clamp(0.0, 1.0), height: 4),
                ])),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right_rounded,
                    color: _DS.textMuted, size: 20),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================
  // CALENDAR
  // =========================================================

  Widget _buildCalendarCard() {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _CalNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => setState(() => _currentMonth =
                DateTime(_currentMonth.year, _currentMonth.month - 1)),
          ),
          Text(DateFormat('MMMM yyyy').format(_currentMonth), style: _DS.heading3),
          _CalNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => setState(() => _currentMonth =
                DateTime(_currentMonth.year, _currentMonth.month + 1)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
              .map((d) => SizedBox(
            width: 36,
            child: Text(d,
                textAlign: TextAlign.center, style: _DS.label),
          ))
              .toList(),
        ),
        const SizedBox(height: 8),
        _buildCalendarGrid(),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 8, children: [
          _CalLegend(color: _DS.success, label: 'Present'),
          _CalLegend(color: _DS.danger, label: 'Absent'),
          _CalLegend(color: _DS.surfaceAlt, label: 'No Data'),
        ]),
        if (_selectedCalendarDate != null) ...[
          const SizedBox(height: 16),
          const Divider(color: _DS.border, height: 1),
          const SizedBox(height: 16),
          _buildSelectedDateDetail(),
        ],
      ]),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
    DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startWeekday = firstDay.weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, crossAxisSpacing: 4, mainAxisSpacing: 4,
      ),
      itemCount: startWeekday + daysInMonth,
      itemBuilder: (_, i) {
        if (i < startWeekday) return const SizedBox.shrink();
        final dayNum = i - startWeekday + 1;
        final date =
        DateTime(_currentMonth.year, _currentMonth.month, dayNum);
        final status = _isAttendanceLoading ? 'loading' : _getDateStatus(date);
        final isSelected = _selectedCalendarDate != null &&
            DateUtils.isSameDay(_selectedCalendarDate!, date);
        final isToday = DateUtils.isSameDay(date, DateTime.now());

        if (status == 'loading') {
          return _ShimmerBox(width: 36, height: 36, borderRadius: _DS.r8);
        }

        Color bg;
        Color textColor;
        if (isSelected) {
          bg = _DS.primary;
          textColor = Colors.white;
        } else {
          switch (status) {
            case 'present':
              bg = _DS.successDim;
              textColor = _DS.success;
              break;
            case 'absent':
              bg = _DS.dangerDim;
              textColor = _DS.danger;
              break;
            default:
              bg = _DS.surfaceAlt;
              textColor = _DS.textSecondary;
          }
        }

        return GestureDetector(
          onTap: () => setState(() {
            _selectedCalendarDate =
            DateUtils.isSameDay(_selectedCalendarDate, date) ? null : date;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: _DS.r8,
              border: isToday
                  ? Border.all(color: _DS.primary, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: isToday || isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedDateDetail() {
    final date = _selectedCalendarDate!;
    final key = DateFormat('yyyy-MM-dd').format(date);
    final recs = attendanceRecords
        .where((r) => (r['timestamp'] ?? '').toString().startsWith(key))
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(DateFormat('EEEE, dd MMMM yyyy').format(date), style: _DS.heading3),
      const SizedBox(height: 10),
      if (recs.isEmpty)
        Text('No sessions recorded', style: _DS.bodySmall)
      else
        ...recs.map((r) {
          final isP = r['status'] == 'present';
          final courseName = r['course_name'] ??
              courses.firstWhere((c) => c['_id'] == r['course_id'],
                  orElse: () => {})['name'] ??
              r['course_id'] ??
              'Unknown';
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isP ? _DS.successDim : _DS.dangerDim,
                  borderRadius: _DS.r6,
                ),
                child: Icon(
                  isP ? Icons.check_rounded : Icons.close_rounded,
                  color: isP ? _DS.success : _DS.danger,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(courseName.toString(), style: _DS.body,
                  overflow: TextOverflow.ellipsis)),
            ]),
          );
        }),
    ]);
  }

  // =========================================================
  // RECENT ACTIVITY (with skeleton)
  // =========================================================

  Widget _buildRecentActivityHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('RECENT ACTIVITY', style: _DS.label.copyWith(letterSpacing: 1.5)),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullAttendanceLog(
              records: attendanceRecords,
              courses: courses,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _DS.primaryDim,
            borderRadius: _DS.rFull,
          ),
          child: Row(children: [
            Text('View All', style: _DS.label.copyWith(color: _DS.primary)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, color: _DS.primary, size: 14),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildRecentActivity() {
    if (_isAttendanceLoading) {
      return _GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: List.generate(5, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              _ShimmerBox(width: 38, height: 38, borderRadius: _DS.r10),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ShimmerBox(width: 160, height: 14),
                const SizedBox(height: 6),
                _ShimmerBox(width: 100, height: 11),
              ])),
            ]),
          )),
        ),
      );
    }

    final recent = attendanceRecords.take(12).toList();
    if (recent.isEmpty) {
      return _GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No attendance records yet', style: _DS.bodySmall),
          ),
        ),
      );
    }
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: recent.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          final isLast = i == recent.length - 1;
          return _ActivityTile(
            record: r,
            courses: courses,
            showDivider: !isLast,
            onGrievance: () => _showGrievanceModal(r),
          );
        }).toList(),
      ),
    );
  }
}

// =========================================================
// NOTIFICATION TILE
// =========================================================
class _NotificationTile extends StatelessWidget {
  final _AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  Color get _iconColor {
    switch (notification.type) {
      case _NotifType.grievanceResponse:
        return _DS.primary;
      case _NotifType.warning:
        return _DS.accent;
      case _NotifType.info:
        return _DS.success;
    }
  }

  IconData get _iconData {
    switch (notification.type) {
      case _NotifType.grievanceResponse:
        return Icons.gavel_rounded;
      case _NotifType.warning:
        return Icons.warning_amber_rounded;
      case _NotifType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: _DS.dangerDim,
        child: const Icon(Icons.delete_outline_rounded, color: _DS.danger),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: notification.isRead ? Colors.transparent : _DS.primaryDim,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: _DS.r8,
              ),
              child: Icon(_iconData, color: _iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(notification.title,
                      style: _DS.body.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w400
                            : FontWeight.w600,
                      )),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: _DS.primary, shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(notification.body,
                  style: _DS.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(
                _formatTimestamp(notification.timestamp),
                style: _DS.label.copyWith(fontSize: 10),
              ),
            ])),
          ]),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(dt);
  }
}

// =========================================================
// FULL ATTENDANCE LOG
// =========================================================

class FullAttendanceLog extends StatefulWidget {
  final List<dynamic> records;
  final List<dynamic> courses;

  const FullAttendanceLog({
    required this.records,
    this.courses = const [],
    super.key,
  });

  @override
  State<FullAttendanceLog> createState() => _FullAttendanceLogState();
}

class _FullAttendanceLogState extends State<FullAttendanceLog> {
  final ScrollController _scrollController = ScrollController();
  String _floatingLabel = '';
  bool _showFloatingLabel = false;
  _FilterStatus _filter = _FilterStatus.all;

  late List<dynamic> _sortedRecords;
  Map<String, List<dynamic>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _prepareData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _prepareData() {
    _sortedRecords = List.from(widget.records)
      ..sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

    final filtered = _filter == _FilterStatus.all
        ? _sortedRecords
        : _sortedRecords.where((r) => r['status'] == _filter.name).toList();

    _grouped = {};
    for (final r in filtered) {
      final ts = r['timestamp']?.toString() ?? '';
      final date = DateTime.tryParse(ts) ?? DateTime.now();
      final key = DateFormat('MMMM yyyy').format(date);
      _grouped.putIfAbsent(key, () => []).add(r);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _grouped.isEmpty) return;
    final offset = _scrollController.offset;
    final total = _scrollController.position.maxScrollExtent;
    final pct = (offset / total).clamp(0.0, 1.0);
    final keys = _grouped.keys.toList();
    final idx = (pct * (keys.length - 1)).round().clamp(0, keys.length - 1);
    setState(() {
      _floatingLabel = keys[idx];
      _showFloatingLabel = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showFloatingLabel = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(scaffoldBackgroundColor: _DS.bg),
      child: Scaffold(
        backgroundColor: _DS.bg,
        appBar: AppBar(
          backgroundColor: _DS.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _DS.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Attendance History', style: _DS.heading2),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _FilterChips(
                current: _filter,
                onChange: (f) => setState(() {
                  _filter = f;
                  _prepareData();
                }),
              ),
            ),
          ),
        ),
        body: Stack(children: [
          if (_grouped.isEmpty)
            Center(child: Text('No records found', style: _DS.bodySmall))
          else
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              physics: const BouncingScrollPhysics(),
              itemCount: _grouped.length,
              itemBuilder: (_, i) {
                final monthKey = _grouped.keys.elementAt(i);
                final recs = _grouped[monthKey]!;
                return _MonthGroup(
                  monthLabel: monthKey,
                  records: recs,
                  courses: widget.courses,
                );
              },
            ),
          AnimatedOpacity(
            opacity: _showFloatingLabel ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.35,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _DS.primary,
                    borderRadius: _DS.r12,
                    boxShadow: _DS.shadowMd,
                  ),
                  child: Text(_floatingLabel,
                      style: _DS.body.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// =========================================================
// SUPPORTING WIDGETS
// =========================================================

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _AppBarAction(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: _DS.r10,
            border: Border.all(color: _DS.border),
            boxShadow: _DS.shadowSm,
          ),
          child: Icon(icon, color: _DS.textSecondary, size: 18),
        ),
      ),
    ),
  );
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatColumn(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label, style: _DS.label),
  ]);
}

class _AttendanceGauge extends StatelessWidget {
  final double percentage;
  final double size;

  const _AttendanceGauge({required this.percentage, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 75
        ? _DS.success
        : percentage >= 50
        ? _DS.accent
        : _DS.danger;
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _GaugePainter(percentage / 100, color),
        child: Center(
          child: Text(
            '${percentage.toInt()}%',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.22),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _GaugePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 6.0;
    final bgPaint = Paint()
      ..color = _DS.surfaceAlt
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const startAngle = -pi / 2;
    const fullSweep = pi * 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, fullSweep, false, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, fullSweep * value, false, fgPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

class _CalNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CalNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: _DS.surfaceAlt, borderRadius: _DS.r8),
      child: Icon(icon, color: _DS.textSecondary, size: 18),
    ),
  );
}

class _CalLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _CalLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, borderRadius: _DS.r4)),
        const SizedBox(width: 6),
        Text(label, style: _DS.bodySmall),
      ]);
}

class _ActivityTile extends StatelessWidget {
  final dynamic record;
  final List<dynamic> courses;
  final bool showDivider;
  final VoidCallback onGrievance;

  const _ActivityTile({
    required this.record,
    required this.courses,
    required this.showDivider,
    required this.onGrievance,
  });

  @override
  Widget build(BuildContext context) {
    final ts = record['timestamp']?.toString() ?? '';
    final date = DateTime.tryParse(ts) ?? DateTime.now();
    final isP = record['status'] == 'present';
    final courseName = record['course_name']?.toString() ??
        courses
            .firstWhere(
              (c) => c['_id'] == record['course_id'],
          orElse: () => {},
        )['name']
            ?.toString() ??
        record['course_id']?.toString() ??
        'Unknown Course';

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isP ? _DS.successDim : _DS.dangerDim,
              borderRadius: _DS.r10,
            ),
            child: Icon(
              isP ? Icons.check_rounded : Icons.close_rounded,
              color: isP ? _DS.success : _DS.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(courseName, style: _DS.body, overflow: TextOverflow.ellipsis),
            Text(DateFormat('EEE, dd MMM · hh:mm a').format(date),
                style: _DS.bodySmall),
          ])),
          GestureDetector(
            onTap: onGrievance,
            child: const Icon(Icons.flag_outlined, color: _DS.textMuted, size: 16),
          ),
        ]),
      ),
      if (showDivider)
        const Divider(color: _DS.border, height: 1, indent: 16, endIndent: 16),
    ]);
  }
}

enum _FilterStatus { all, present, absent }

class _FilterChips extends StatelessWidget {
  final _FilterStatus current;
  final ValueChanged<_FilterStatus> onChange;

  const _FilterChips({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) => Row(children: [
    _Chip('All', _FilterStatus.all, current, onChange),
    const SizedBox(width: 8),
    _Chip('Present', _FilterStatus.present, current, onChange),
    const SizedBox(width: 8),
    _Chip('Absent', _FilterStatus.absent, current, onChange),
  ]);
}

class _Chip extends StatelessWidget {
  final String label;
  final _FilterStatus value;
  final _FilterStatus current;
  final ValueChanged<_FilterStatus> onChange;

  const _Chip(this.label, this.value, this.current, this.onChange);

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onChange(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _DS.primary : _DS.surface,
          borderRadius: _DS.rFull,
          border: Border.all(color: selected ? _DS.primary : _DS.border),
          boxShadow: selected ? _DS.shadowSm : null,
        ),
        child: Text(
          label,
          style: _DS.label.copyWith(
            color: selected ? Colors.white : _DS.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MonthGroup extends StatelessWidget {
  final String monthLabel;
  final List<dynamic> records;
  final List<dynamic> courses;

  const _MonthGroup({
    required this.monthLabel,
    required this.records,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          Text(monthLabel,
              style: _DS.label.copyWith(color: _DS.primary, letterSpacing: 1.2)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _DS.border)),
          const SizedBox(width: 10),
          Text('${records.length} sessions', style: _DS.label),
        ]),
      ),
      _GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: records.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return _ActivityTile(
              record: r,
              courses: courses,
              showDivider: i < records.length - 1,
              onGrievance: () {},
            );
          }).toList(),
        ),
      ),
    ]);
  }
}
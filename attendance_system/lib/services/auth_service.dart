import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  String? _token;

// =========================
// 🔐 AUTH
// =========================

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/google/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_token": idToken}),
    );

    
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
    _token = data["access_token"];
    return data;
    } else {
    throw Exception(data["detail"] ?? "Login failed");
    }
    

  }

  Map<String, String> _headers() {
    if (_token == null) {
      throw Exception("User not authenticated");
    }
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_token"
    };
  }

// =========================
// 👤 USERS
// =========================

  Future<List<dynamic>> getStudents() async {
    final res = await http.get(
      Uri.parse("$baseUrl/students"),
      headers: _headers(),
    );

    
    return jsonDecode(res.body);
    

  }

  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> student) async {
    final res = await http.post(
      Uri.parse("$baseUrl/students"),
      headers: _headers(),
      body: jsonEncode(student),
    );

    
    return jsonDecode(res.body);
    

  }

// =========================
// 📚 COURSES
// =========================

  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> course) async {
    final res = await http.post(
      Uri.parse("$baseUrl/courses"),
      headers: _headers(),
      body: jsonEncode(course),
    );

    
    return jsonDecode(res.body);
    

  }

// =========================
// 👥 GROUPS
// =========================

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> group) async {
    final res = await http.post(
      Uri.parse("$baseUrl/groups"),
      headers: _headers(),
      body: jsonEncode(group),
    );

    
    return jsonDecode(res.body);
    

  }

// =========================
// 🕒 SESSIONS
// =========================

  Future<Map<String, dynamic>> createSession(Map<String, dynamic> session) async {
    final res = await http.post(
      Uri.parse("$baseUrl/sessions"),
      headers: _headers(),
      body: jsonEncode(session),
    );

    
    return jsonDecode(res.body);
    

  }

  Future<void> startSession(String sessionId) async {
    await http.post(
      Uri.parse("$baseUrl/sessions/$sessionId/start"),
      headers: _headers(),
    );
  }

  Future<void> endSession(String sessionId) async {
    await http.post(
      Uri.parse("$baseUrl/sessions/$sessionId/end"),
      headers: _headers(),
    );
  }

// =========================
// 📸 IMAGE UPLOAD
// =========================

  Future<Map<String, dynamic>> uploadStudentImage(
      String roll, File imageFile) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/images/students/$roll/upload"),
    );

    
    request.headers["Authorization"] = "Bearer $_token";

    request.files.add(
    await http.MultipartFile.fromPath("file", imageFile.path),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    return jsonDecode(resBody);
    

  }

  Future<Map<String, dynamic>> enrollFace(
      String studentId, File imageFile) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/images/students/$studentId/enroll-face"),
    );

    
    request.headers["Authorization"] = "Bearer $_token";

    request.files.add(
    await http.MultipartFile.fromPath("file", imageFile.path),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    return jsonDecode(resBody);
    

  }

// =========================
// 🎯 ATTENDANCE
// =========================

  Future<Map<String, dynamic>> markAttendance({
    required String sessionId,
    required String studentId,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/attendance/mark"),
      headers: _headers(),
      body: jsonEncode({
        "session_id": sessionId,
        "student_id": studentId,
        "status": "present",
        "method": "manual"
      }),
    );

    
    return jsonDecode(res.body);
    

  }

  Future<Map<String, dynamic>> recognizeAndMark({
    required String sessionId,
    required String groupId,
    required File imageFile,
  }) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/attendance/recognize"),
    );

    
    request.headers["Authorization"] = "Bearer $_token";

    request.fields["session_id"] = sessionId;
    request.fields["group_id"] = groupId;

    request.files.add(
    await http.MultipartFile.fromPath("file", imageFile.path),
    );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    return jsonDecode(resBody);
    

  }

// =========================
// 📊 FETCH ATTENDANCE
// =========================

  Future<List<dynamic>> getSessionAttendance(String sessionId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/attendance/session/$sessionId"),
      headers: _headers(),
    );

    
    return jsonDecode(res.body);
    

  }
}

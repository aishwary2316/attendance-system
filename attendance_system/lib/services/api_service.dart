import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../utils/safe_log.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor for Authentication and Logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        devLog("API REQUEST[${options.method}] => PATH: ${options.path}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        devLog("API RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}");
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        devLog("API ERROR[${e.response?.statusCode}] => MESSAGE: ${e.message}");
        return handler.next(e);
      },
    ));
  }

  // ===========================================================================
  // AUTH & HEALTH
  // ===========================================================================

  // Changed from /auth/google/login to /auth/google based on common backend patterns
  Future<Response> googleLogin(String idToken) =>
      _dio.post('/auth/google', data: {'id_token': idToken});

  Future<Response> getMe() => _dio.get('/auth/me');

  Future<Response> checkHealth() => _dio.get('/health');

  // ===========================================================================
  // USER MANAGEMENT (GENERIC)
  // ===========================================================================

  Future<Response> listUsers({int skip = 0, int limit = 100}) =>
      _dio.get('/users/', queryParameters: {'skip': skip, 'limit': limit});

  Future<Response> createUser(Map<String, dynamic> data) => _dio.post('/users/', data: data);

  Future<Response> getUser(String userId) => _dio.get('/users/$userId');

  Future<Response> updateUser(String userId, Map<String, dynamic> data) =>
      _dio.put('/users/$userId', data: data);

  Future<Response> deleteUser(String userId) => _dio.delete('/users/$userId');

  Future<Response> overrideUserPermissions(String userId, List<String> permissions) =>
      _dio.patch('/users/$userId/permissions', data: permissions);

  Future<Response> grantUserRole(String userId, String roleId) =>
      _dio.post('/users/$userId/roles/$roleId');

  Future<Response> revokeUserRole(String userId, String roleId) =>
      _dio.delete('/users/$userId/roles/$roleId');

  // ===========================================================================
  // MODULE SPECIFIC USERS (STUDENTS, FACULTY, ADMINS)
  // ===========================================================================

  // Students
  Future<Response> listStudents({int skip = 0, int limit = 100}) =>
      _dio.get('/students/', queryParameters: {'skip': skip, 'limit': limit});
  Future<Response> createStudent(Map<String, dynamic> data) => _dio.post('/students/', data: data);
  Future<Response> getStudent(String userId) => _dio.get('/students/$userId');
  Future<Response> updateStudent(String userId, Map<String, dynamic> data) => _dio.put('/students/$userId', data: data);
  Future<Response> deleteStudent(String userId) => _dio.delete('/students/$userId');
  Future<Response> overrideStudentPermissions(String userId, List<String> permissions) => _dio.patch('/students/$userId/permissions', data: permissions);
  Future<Response> grantStudentRole(String userId, String roleId) => _dio.post('/students/$userId/roles/$roleId');
  Future<Response> revokeStudentRole(String userId, String roleId) => _dio.delete('/students/$userId/roles/$roleId');

  // Faculty
  Future<Response> listFaculty({int skip = 0, int limit = 100}) =>
      _dio.get('/faculty/', queryParameters: {'skip': skip, 'limit': limit});
  Future<Response> createFaculty(Map<String, dynamic> data) => _dio.post('/faculty/', data: data);
  Future<Response> getFacultyMember(String userId) => _dio.get('/faculty/$userId');
  Future<Response> updateFaculty(String userId, Map<String, dynamic> data) => _dio.put('/faculty/$userId', data: data);
  Future<Response> deleteFaculty(String userId) => _dio.delete('/faculty/$userId');

  // Admins
  Future<Response> listAdmins({int skip = 0, int limit = 100}) =>
      _dio.get('/admins/', queryParameters: {'skip': skip, 'limit': limit});
  Future<Response> createAdmin(Map<String, dynamic> data) => _dio.post('/admins/', data: data);
  Future<Response> getAdmin(String userId) => _dio.get('/admins/$userId');
  Future<Response> updateAdmin(String userId, Map<String, dynamic> data) => _dio.put('/admins/$userId', data: data);
  Future<Response> deleteAdmin(String userId) => _dio.delete('/admins/$userId');

  // ===========================================================================
  // ROLES & PERMISSIONS
  // ===========================================================================

  Future<Response> listPermissions() => _dio.get('/permissions');
  Future<Response> createPermission(Map<String, dynamic> data) => _dio.post('/permissions', data: data);
  Future<Response> getPermission(String permissionId) => _dio.get('/permissions/$permissionId');
  Future<Response> updatePermission(String permissionId, Map<String, dynamic> data) => _dio.put('/permissions/$permissionId', data: data);
  Future<Response> deletePermission(String permissionId) => _dio.delete('/permissions/$permissionId');

  Future<Response> listRoles() => _dio.get('/roles');
  Future<Response> createRole(Map<String, dynamic> data) => _dio.post('/roles', data: data);
  Future<Response> getRole(String roleId) => _dio.get('/roles/$roleId');
  Future<Response> updateRole(String roleId, Map<String, dynamic> data) => _dio.put('/roles/$roleId', data: data);
  Future<Response> deleteRole(String roleId) => _dio.delete('/roles/$roleId');
  Future<Response> addPermissionToRole(String roleId, String permissionId) => _dio.post('/roles/$roleId/permissions/$permissionId');
  Future<Response> removePermissionFromRole(String roleId, String permissionId) => _dio.delete('/roles/$roleId/permissions/$permissionId');

  Future<Response> listUserRoles() => _dio.get('/user-roles');
  Future<Response> createUserRole(Map<String, dynamic> data) => _dio.post('/user-roles', data: data);
  Future<Response> getUserRole(String userRoleId) => _dio.get('/user-roles/$userRoleId');
  Future<Response> updateUserRole(String userRoleId, Map<String, dynamic> data) => _dio.put('/user-roles/$userRoleId', data: data);
  Future<Response> deleteUserRole(String userRoleId) => _dio.delete('/user-roles/$userRoleId');

  // ===========================================================================
  // COURSES & GROUPS
  // ===========================================================================

  Future<Response> listCourses() => _dio.get('/courses');
  Future<Response> createCourse(Map<String, dynamic> data) => _dio.post('/courses', data: data);
  Future<Response> getCourse(String courseId) => _dio.get('/courses/$courseId');
  Future<Response> updateCourse(String courseId, Map<String, dynamic> data) => _dio.put('/courses/$courseId', data: data);
  Future<Response> deleteCourse(String courseId) => _dio.delete('/courses/$courseId');

  Future<Response> listGroups() => _dio.get('/groups');
  Future<Response> createGroup(Map<String, dynamic> data) => _dio.post('/groups', data: data);
  Future<Response> getGroup(String groupId) => _dio.get('/groups/$groupId');
  Future<Response> updateGroup(String groupId, Map<String, dynamic> data) => _dio.put('/groups/$groupId', data: data);
  Future<Response> deleteGroup(String groupId) => _dio.delete('/groups/$groupId');
  Future<Response> resolveGroup(String groupId) => _dio.get('/groups/$groupId/resolve');

  // ===========================================================================
  // SESSIONS & TEMPLATES
  // ===========================================================================

  Future<Response> listSessionTemplates() => _dio.get('/session-templates');
  Future<Response> createSessionTemplate(Map<String, dynamic> data) => _dio.post('/session-templates', data: data);
  Future<Response> getSessionTemplate(String templateId) => _dio.get('/session-templates/$templateId');
  Future<Response> updateSessionTemplate(String templateId, Map<String, dynamic> data) => _dio.put('/session-templates/$templateId', data: data);
  Future<Response> deleteSessionTemplate(String templateId) => _dio.delete('/session-templates/$templateId');

  Future<Response> listSessions() => _dio.get('/sessions');
  Future<Response> createSession(Map<String, dynamic> data) => _dio.post('/sessions', data: data);
  Future<Response> getSession(String sessionId) => _dio.get('/sessions/$sessionId');
  Future<Response> updateSession(String sessionId, Map<String, dynamic> data) => _dio.put('/sessions/$sessionId', data: data);
  Future<Response> deleteSession(String sessionId) => _dio.delete('/sessions/$sessionId');

  Future<Response> startSession(String sessionId) => _dio.post('/sessions/$sessionId/start');
  Future<Response> endSession(String sessionId) => _dio.post('/sessions/$sessionId/end');
  Future<Response> rescheduleSession(String sessionId, String newStart, String newEnd) =>
      _dio.post('/sessions/$sessionId/reschedule', queryParameters: {'new_start_time': newStart, 'new_end_time': newEnd});
  Future<Response> extendSession(String sessionId, int extraMinutes) =>
      _dio.post('/sessions/$sessionId/extend', queryParameters: {'extra_minutes': extraMinutes});
  Future<Response> generateSessionsFromTemplate(String templateId, {int count = 10}) =>
      _dio.post('/sessions/generate-from-template/$templateId', queryParameters: {'count': count});

  // ===========================================================================
  // ATTENDANCE
  // ===========================================================================

  Future<Response> listAllAttendance() => _dio.get('/attendance');
  Future<Response> getAttendanceBySession(String sessionId) => _dio.get('/attendance/session/$sessionId');
  Future<Response> getAttendanceByStudent(String studentId) => _dio.get('/attendance/student/$studentId');
  Future<Response> getAttendanceByCourse(String courseId) => _dio.get('/attendance/course/$courseId');
  Future<Response> markAttendance(Map<String, dynamic> data) => _dio.post('/attendance/mark', data: data);
  Future<Response> updateAttendance(String attendanceId, String status) =>
      _dio.patch('/attendance/$attendanceId', queryParameters: {'status': status});
  Future<Response> deleteAttendance(String attendanceId) => _dio.delete('/attendance/$attendanceId');
  Future<Response> finalizeAttendance(String sessionId) => _dio.post('/attendance/session/$sessionId/finalize');

  // Recognize with Face (Multipart)
  Future<Response> recognizeFaceAttendance({
    required String sessionId,
    required String groupId,
    required List<int> fileBytes,
    String? deviceId,
  }) async {
    FormData formData = FormData.fromMap({
      "session_id": sessionId,
      "group_id": groupId,
      if (deviceId != null) "device_id": deviceId,
      "file": MultipartFile.fromBytes(fileBytes, filename: "recognize.jpg"),
    });
    return _dio.post('/attendance/recognize', data: formData);
  }

  // ===========================================================================
  // DEVICES
  // ===========================================================================

  Future<Response> listDevices() => _dio.get('/devices');
  Future<Response> createDevice(Map<String, dynamic> data) => _dio.post('/devices', data: data);
  Future<Response> getDevice(String deviceId) => _dio.get('/devices/$deviceId');
  Future<Response> updateDevice(String deviceId, Map<String, dynamic> data) => _dio.put('/devices/$deviceId', data: data);
  Future<Response> deleteDevice(String deviceId) => _dio.delete('/devices/$deviceId');
  Future<Response> authenticateDevice(String deviceId, String rawKey) =>
      _dio.post('/devices/$deviceId/authenticate', queryParameters: {'raw_key': rawKey});

  // ===========================================================================
  // IMAGES & ENROLLMENT
  // ===========================================================================

  Future<Response> uploadStudentImage(String roll, List<int> fileBytes) async {
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(fileBytes, filename: "student_$roll.jpg"),
    });
    return _dio.post('/images/students/$roll/upload', data: formData);
  }

  Future<Response> listStudentImages(String roll) => _dio.get('/images/students/$roll');

  Future<Response> fetchStudentImage(String roll, String fileName) => _dio.get('/images/students/$roll/$fileName');

  Future<Response> deleteStudentImage(String roll, String fileName) => _dio.delete('/images/students/$roll/$fileName');

  Future<Response> enrollFace(String studentId, List<int> fileBytes) async {
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(fileBytes, filename: "enroll.jpg"),
    });
    return _dio.post('/images/students/$studentId/enroll-face', data: formData);
  }
}
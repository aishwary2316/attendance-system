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

  // Added trailing slash which is often required by FastAPI routers
  Future<Response> googleLogin(String idToken) =>
      _dio.post('/auth/google/', data: {'id_token': idToken});

  Future<Response> getMe() => _dio.get('/auth/me/');

  Future<Response> checkHealth() => _dio.get('/health/');

  // ===========================================================================
  // USER MANAGEMENT (GENERIC)
  // ===========================================================================

  Future<Response> listUsers({int skip = 0, int limit = 100}) =>
      _dio.get('/users/', queryParameters: {'skip': skip, 'limit': limit});

  Future<Response> createUser(Map<String, dynamic> data) => _dio.post('/users/', data: data);

  Future<Response> getUser(String userId) => _dio.get('/users/$userId/');

  Future<Response> updateUser(String userId, Map<String, dynamic> data) =>
      _dio.put('/users/$userId/', data: data);

  Future<Response> deleteUser(String userId) => _dio.delete('/users/$userId/');

  Future<Response> overrideUserPermissions(String userId, List<String> permissions) =>
      _dio.patch('/users/$userId/permissions/', data: permissions);

  Future<Response> grantUserRole(String userId, String roleId) =>
      _dio.post('/users/$userId/roles/$roleId/');

  Future<Response> revokeUserRole(String userId, String roleId) =>
      _dio.delete('/users/$userId/roles/$roleId/');

  // ===========================================================================
  // MODULE SPECIFIC USERS (STUDENTS, FACULTY, ADMINS)
  // ===========================================================================

  // Students
  Future<Response> listStudents({int skip = 0, int limit = 100}) =>
      _dio.get('/students/', queryParameters: {'skip': skip, 'limit': limit});
  Future<Response> createStudent(Map<String, dynamic> data) => _dio.post('/students/', data: data);
  Future<Response> getStudent(String userId) => _dio.get('/students/$userId/');
  Future<Response> updateStudent(String userId, Map<String, dynamic> data) => _dio.put('/students/$userId/', data: data);
  Future<Response> deleteStudent(String userId) => _dio.delete('/students/$userId/');
  Future<Response> overrideStudentPermissions(String userId, List<String> permissions) => _dio.patch('/students/$userId/permissions/', data: permissions);
  Future<Response> grantStudentRole(String userId, String roleId) => _dio.post('/students/$userId/roles/$roleId/');
  Future<Response> revokeStudentRole(String userId, String roleId) => _dio.delete('/students/$userId/roles/$roleId/');

  // Faculty
  Future<Response> listAdmins({int skip = 0, int limit = 100}) =>
      _dio.get('/admins/', queryParameters: {'skip': skip, 'limit': limit});
  Future<Response> createAdmin(Map<String, dynamic> data) => _dio.post('/admins/', data: data);
  Future<Response> getAdmin(String userId) => _dio.get('/admins/$userId/');
  Future<Response> updateAdmin(String userId, Map<String, dynamic> data) => _dio.put('/admins/$userId/', data: data);
  Future<Response> deleteAdmin(String userId) => _dio.delete('/admins/$userId/');

  // ===========================================================================
  // ROLES & PERMISSIONS
  // ===========================================================================

  Future<Response> listPermissions() => _dio.get('/permissions/');
  Future<Response> createPermission(Map<String, dynamic> data) => _dio.post('/permissions/', data: data);
  Future<Response> getPermission(String permissionId) => _dio.get('/permissions/$permissionId/');
  Future<Response> updatePermission(String permissionId, Map<String, dynamic> data) => _dio.put('/permissions/$permissionId/', data: data);
  Future<Response> deletePermission(String permissionId) => _dio.delete('/permissions/$permissionId/');

  Future<Response> listRoles() => _dio.get('/roles/');
  Future<Response> createRole(Map<String, dynamic> data) => _dio.post('/roles/', data: data);
  Future<Response> getRole(String roleId) => _dio.get('/roles/$roleId/');
  Future<Response> updateRole(String roleId, Map<String, dynamic> data) => _dio.put('/roles/$roleId/', data: data);
  Future<Response> deleteRole(String roleId) => _dio.delete('/roles/$roleId/');
  Future<Response> addPermissionToRole(String roleId, String permissionId) => _dio.post('/roles/$roleId/permissions/$permissionId/');
  Future<Response> removePermissionFromRole(String roleId, String permissionId) => _dio.delete('/roles/$roleId/permissions/$permissionId/');

  // ===========================================================================
  // COURSES & GROUPS
  // ===========================================================================

  Future<Response> listCourses() => _dio.get('/courses/');
  Future<Response> createCourse(Map<String, dynamic> data) => _dio.post('/courses/', data: data);
  Future<Response> getCourse(String courseId) => _dio.get('/courses/$courseId/');
  Future<Response> updateCourse(String courseId, Map<String, dynamic> data) => _dio.put('/courses/$courseId/', data: data);
  Future<Response> deleteCourse(String courseId) => _dio.delete('/courses/$courseId/');

  Future<Response> listGroups() => _dio.get('/groups/');
  Future<Response> createGroup(Map<String, dynamic> data) => _dio.post('/groups/', data: data);
  Future<Response> getGroup(String groupId) => _dio.get('/groups/$groupId/');
  Future<Response> updateGroup(String groupId, Map<String, dynamic> data) => _dio.put('/groups/$groupId/', data: data);
  Future<Response> deleteGroup(String groupId) => _dio.delete('/groups/$groupId/');

  // ===========================================================================
  // SESSIONS
  // ===========================================================================

  Future<Response> listSessions() => _dio.get('/sessions/');
  Future<Response> createSession(Map<String, dynamic> data) => _dio.post('/sessions/', data: data);
  Future<Response> getSession(String sessionId) => _dio.get('/sessions/$sessionId/');
  Future<Response> updateSession(String sessionId, Map<String, dynamic> data) => _dio.put('/sessions/$sessionId/', data: data);
  Future<Response> deleteSession(String sessionId) => _dio.delete('/sessions/$sessionId/');

  Future<Response> startSession(String sessionId) => _dio.post('/sessions/$sessionId/start/');
  Future<Response> endSession(String sessionId) => _dio.post('/sessions/$sessionId/end/');

  // ===========================================================================
  // ATTENDANCE
  // ===========================================================================

  Future<Response> markAttendance(Map<String, dynamic> data) => _dio.post('/attendance/mark/', data: data);
  Future<Response> getAttendanceBySession(String sessionId) => _dio.get('/attendance/session/$sessionId/');

  // Recognize with Face (Multipart)
  Future<Response> recognizeFaceAttendance({
    required String sessionId,
    required String groupId,
    required List<int> fileBytes,
  }) async {
    FormData formData = FormData.fromMap({
      "session_id": sessionId,
      "group_id": groupId,
      "file": MultipartFile.fromBytes(fileBytes, filename: "recognize.jpg"),
    });
    return _dio.post('/attendance/recognize/', data: formData);
  }

  // ===========================================================================
  // IMAGES & ENROLLMENT
  // ===========================================================================

  Future<Response> uploadStudentImage(String roll, List<int> fileBytes) async {
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(fileBytes, filename: "student_$roll.jpg"),
    });
    return _dio.post('/images/students/$roll/upload/', data: formData);
  }

  Future<Response> enrollFace(String studentId, List<int> fileBytes) async {
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(fileBytes, filename: "enroll.jpg"),
    });
    return _dio.post('/images/students/$studentId/enroll-face/', data: formData);
  }
}
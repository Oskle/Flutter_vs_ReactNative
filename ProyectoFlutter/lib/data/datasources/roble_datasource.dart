import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/roble_config.dart';

class RobleException implements Exception {
  final String message;
  final int? statusCode;

  RobleException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UserData {
  final String? id;
  final String? uid;
  final String email;
  final String name;
  final String role;

  UserData({
    this.id,
    this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    String rawRole = json['rol'] ?? json['role'] ?? 'student';
    String normalizedRole = _normalizeRole(rawRole);

    return UserData(
      id: (json['_id'] ?? json['id'])?.toString(),
      uid: (json['uid'] ?? json['userId'] ?? json['id'] ?? json['_id'])
          ?.toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: normalizedRole,
    );
  }

  static String _normalizeRole(String role) {
    switch (role.toLowerCase()) {
      case 'student':
      case 'estudiante':
        return 'student';
      case 'teacher':
      case 'profesor':
      case 'professor':
        return 'teacher';
      default:
        return 'student';
    }
  }

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    if (uid != null) 'uid': uid,
    'email': email,
    'name': name,
    'rol': role,
  };

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
}

class AuthResult {
  final String accessToken;
  final String? refreshToken;
  final UserData? user;

  AuthResult({required this.accessToken, this.refreshToken, this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    UserData? userData;
    if (json['user'] != null) {
      userData = UserData.fromJson(json['user']);
    }

    return AuthResult(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'],
      user: userData,
    );
  }
}

class RobleDatasource {
  // Modificación Nivel 3: Cliente inyectable para pruebas de integración
  // http.Client client = http.Client(); // Línea original comentada (simulada)
  http.Client client = http.Client(); 

  final String dbName = RobleConfig.dbName;
  final String authUrl = RobleConfig.authBaseUrl;
  final String databaseUrl = RobleConfig.databaseBaseUrl;

  final String usersTable = "users";

  String? _currentToken;

  String? get currentToken => _currentToken;

  void setToken(String? token) {
    _currentToken = token;
  }

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_currentToken != null) 'Authorization': 'Bearer $_currentToken',
  };

  void _log(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  Future<bool> registerUser(String email, String password, String name) async {
    final url = Uri.parse('$authUrl/$dbName/signup-direct');

    try {
      // final response = await http.post( // Línea original
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password, "name": name}),
      );

      _log('REGISTER', 'Status: ${response.statusCode}');
      _log('REGISTER', 'Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      if (response.statusCode == 409 ||
          response.body.contains('already exists')) {
        throw RobleException(
          'Este correo ya está registrado',
          statusCode: response.statusCode,
        );
      }

      final errorBody = _parseErrorBody(response.body);
      throw RobleException(
        errorBody ?? 'Error al registrar usuario',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is RobleException) rethrow;
      throw RobleException('Error de conexión: $e');
    }
  }

  Future<bool> saveUserData(
    String email,
    String name,
    String role,
    String uid,
  ) async {
    final url = Uri.parse('$databaseUrl/$dbName/insert');

    try {
      final record = {"uid": uid, "email": email, "name": name, "rol": role};

      record.remove('_id');

      final body = jsonEncode({
        "tableName": usersTable,
        "records": [record],
      });

      _log('SAVE_USER', 'URL: $url');
      _log('SAVE_USER', 'Body: $body');

      // final response = await http.post(url, headers: _authHeaders, body: body); // Línea original
      final response = await client.post(url, headers: _authHeaders, body: body);

      _log('SAVE_USER', 'Status: ${response.statusCode}');
      _log('SAVE_USER', 'Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final inserted =
            data is Map<String, dynamic> && data['inserted'] is List
            ? data['inserted'] as List
            : const [];

        final skipped = data is Map<String, dynamic> && data['skipped'] is List
            ? data['skipped'] as List
            : const [];

        if (skipped.isNotEmpty) {
          _log('SAVE_USER', 'Skipped rows: $skipped');
        }

        return inserted.isNotEmpty;
      }

      _log('SAVE_USER', 'Failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      _log('SAVE_USER', 'Error: $e');
      return false;
    }
  }

  String? extractUidFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return null;
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final Map<String, dynamic> claims = jsonDecode(payload);

      return claims['sub']?.toString() ??
          claims['uid']?.toString() ??
          claims['id']?.toString() ??
          claims['userId']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<AuthResult> loginUser(String email, String password) async {
    final url = Uri.parse('$authUrl/$dbName/login');

    try {
      final body = jsonEncode({"email": email, "password": password});

      _log('LOGIN', 'URL: $url');
      _log('LOGIN', 'Request: $body');

      // final response = await http.post( // Línea original
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      _log('LOGIN', 'Status: ${response.statusCode}');
      _log('LOGIN', 'Body: ${response.body}');

      // API returns 200 or 201 on success
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final result = AuthResult.fromJson(data);
        _currentToken = result.accessToken;
        return result;
      }

      final errorBody = _parseErrorBody(response.body);
      throw RobleException(
        errorBody ?? 'Credenciales incorrectas',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is RobleException) rethrow;
      _log('LOGIN', 'Exception: $e');
      throw RobleException('Error de conexión: $e');
    }
  }

  Future<UserData?> getUserData(String email) async {
    final url = Uri.parse(
      '$databaseUrl/$dbName/read?tableName=$usersTable&email=${Uri.encodeQueryComponent(email)}',
    );

    try {
      _log('GET_USER', 'URL: $url');

      // final response = await http.get(url, headers: _authHeaders); // Línea original
      final response = await client.get(url, headers: _authHeaders);

      _log('GET_USER', 'Status: ${response.statusCode}');
      _log('GET_USER', 'Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          return UserData.fromJson(data[0]);
        } else if (data is Map<String, dynamic> && data.isNotEmpty) {
          if (data.containsKey('data') && data['data'] is List) {
            final list = data['data'] as List;
            if (list.isNotEmpty) {
              return UserData.fromJson(list[0]);
            }
          }
          if (data.containsKey('email')) {
            return UserData.fromJson(data);
          }
        }

        return null;
      }

      return null;
    } catch (e) {
      _log('GET_USER', 'Error: $e');
      return null;
    }
  }

  Future<bool> logout() async {
    if (_currentToken == null) return true;

    final url = Uri.parse('$authUrl/$dbName/logout');

    try {
      // final response = await http.post(url, headers: _authHeaders); // Línea original
      final response = await client.post(url, headers: _authHeaders);

      _currentToken = null;
      return response.statusCode == 200;
    } catch (e) {
      _currentToken = null;
      return false;
    }
  }

  Future<bool> verifyToken() async {
    if (_currentToken == null) return false;

    final url = Uri.parse('$authUrl/$dbName/verify-token');

    try {
      // final response = await http.get(url, headers: _authHeaders); // Línea original
      final response = await client.get(url, headers: _authHeaders);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<AuthResult?> refreshToken(String refreshToken) async {
    final url = Uri.parse('$authUrl/$dbName/refresh-token');

    try {
      // final response = await http.post( // Línea original
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = AuthResult.fromJson(data);
        _currentToken = result.accessToken;
        return result;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('$authUrl/$dbName/forgot-password');

    try {
      // final response = await http.post( // Línea original
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      _log('FORGOT_PASSWORD', 'Status: ${response.statusCode}');
      _log('FORGOT_PASSWORD', 'Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      final errorBody = _parseErrorBody(response.body);
      throw RobleException(
        errorBody ?? 'Error al enviar el correo de recuperación',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is RobleException) rethrow;
      throw RobleException('Error de conexión: $e');
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    final url = Uri.parse('$authUrl/$dbName/reset-password');

    try {
      // final response = await http.post( // Línea original
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"token": token, "newPassword": newPassword}),
      );

      _log('RESET_PASSWORD', 'Status: ${response.statusCode}');
      _log('RESET_PASSWORD', 'Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      final errorBody = _parseErrorBody(response.body);
      throw RobleException(
        errorBody ?? 'Error al restablecer la contraseña',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is RobleException) rethrow;
      throw RobleException('Error de conexión: $e');
    }
  }

  String? _parseErrorBody(String body) {
    try {
      final data = jsonDecode(body);
      return data['message'] ?? data['error'] ?? data['msg'];
    } catch (e) {
      return null;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../utils/constants.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';


  Future<LoginResponse?> login(LoginRequest request) async {
    final url = Uri.parse('${Constants.baseUrl}/api/v1/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
      await _saveToken(loginResponse.token);
      return loginResponse;
    } else {
      print('Erro de login: ${response.statusCode} - ${response.body}');
      return null;
    }
  }


  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      return {'Content-Type': 'application/json'};
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${Constants.baseUrl}/$endpoint');
    final headers = await _getAuthHeaders();
    return http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, {required Map<String, dynamic> body}) async {
    final url = Uri.parse('${Constants.baseUrl}/$endpoint');
    final headers = await _getAuthHeaders();
    return http.post(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, {required Map<String, dynamic> body}) async {
    final url = Uri.parse('${Constants.baseUrl}/$endpoint');
    final headers = await _getAuthHeaders();
    return http.put(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${Constants.baseUrl}/$endpoint');
    final headers = await _getAuthHeaders();
    return http.delete(url, headers: headers);
  }


  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

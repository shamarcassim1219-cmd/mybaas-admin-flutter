import 'api_client.dart';

/// Confirmed against the real backend: POST /api/admin/login takes
/// {username, password} (not the mobile/OTP flow the customer and
/// Baas apps use) - it's a separate admin-credential table, but
/// returns the same JWT shape every other login does, so every
/// existing admin-gated endpoint just works once this token is
/// saved.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await _api.post(
      '/api/admin/login',
      body: {'username': username, 'password': password},
      auth: false,
    );
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveToken(token);
    await _api.saveUser(user);
    return user;
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() => _api.clearSession();
}

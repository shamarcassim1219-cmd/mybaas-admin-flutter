/// Single source of truth for the backend URL - same backend the
/// customer and Baas apps talk to, since this is the same GOBAAS
/// platform, just the admin-facing side of it.
class ApiConfig {
  static const String baseUrl = 'https://api.findbass.store';
}

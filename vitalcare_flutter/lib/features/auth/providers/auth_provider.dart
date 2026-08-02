import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class AuthProvider extends BaseProvider {
  bool get isLoggedIn => ApiClient.isLoggedIn;

  Future<bool> login(String email, String password) => guard(() async {
        final res = await ApiClient.post(ApiConstants.login, body: {
          'email': email,
          'password': password,
        });
        await ApiClient.setSession(res['user'] as Map<String, dynamic>, res['session'] as Map<String, dynamic>);
      }, errorMessage: 'Connection failed. Check your server.');

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    String address = '',
    String gender = '',
    String? dateOfBirth,
  }) =>
      guard(() async {
        final res = await ApiClient.post(ApiConstants.register, body: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'address': address,
          'gender': gender,
          'date_of_birth': dateOfBirth,
        });
        await ApiClient.setSession(res['user'] as Map<String, dynamic>, res['session'] as Map<String, dynamic>);
      }, errorMessage: 'Connection failed. Check your server.');

  Future<void> logout() async {
    await ApiClient.logout();
    notifyListeners();
  }
}

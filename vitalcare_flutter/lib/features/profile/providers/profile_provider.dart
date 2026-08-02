import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class ProfileProvider extends BaseProvider {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _emergencyContacts = [];

  Map<String, dynamic>? get profile => _profile;
  List<Map<String, dynamic>> get emergencyContacts => _emergencyContacts;

  Future<void> load() => guard(() async {
        _profile = await ApiClient.get(ApiConstants.profile);
        _emergencyContacts = unwrapList(await ApiClient.get(ApiConstants.emergencyContacts));
      }, errorMessage: 'Failed to load profile');

  Future<bool> updateProfile(Map<String, dynamic> body) => guard(() async {
        await ApiClient.patch(ApiConstants.profile, body: body);
        await load();
      });

  Future<bool> addEmergencyContact(Map<String, dynamic> body) => guard(() async {
        await ApiClient.post(ApiConstants.emergencyContacts, body: body);
        await load();
      });

  Future<bool> deleteEmergencyContact(String id) async {
    try {
      await ApiClient.delete('${ApiConstants.emergencyContacts}/$id');
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }
}

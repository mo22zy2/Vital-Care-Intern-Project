import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class LaboratoryProvider extends BaseProvider {
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _bookings = [];

  List<Map<String, dynamic>> get tests => _tests;
  List<Map<String, dynamic>> get bookings => _bookings;

  Future<void> loadTests() => guard(() async {
        _tests = unwrapList(await ApiClient.get(ApiConstants.labTests));
      }, errorMessage: 'Failed to load lab tests');

  Future<void> loadBookings() => guard(() async {
        _bookings = unwrapList(await ApiClient.get(ApiConstants.labBookings));
      }, errorMessage: 'Failed to load bookings');

  Future<bool> bookTest(Map<String, dynamic> body) => guard(() async {
        await ApiClient.post(ApiConstants.labBookings, body: body);
        await loadBookings();
      });
}

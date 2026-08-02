import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class DashboardProvider extends BaseProvider {
  Map<String, dynamic>? _data;

  Map<String, dynamic>? get data => _data;

  Future<void> load() => guard(() async {
        _data = await ApiClient.get(ApiConstants.patientDashboard);
      }, errorMessage: 'Failed to load dashboard');
}

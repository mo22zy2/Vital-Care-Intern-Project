import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class PrescriptionsProvider extends BaseProvider {
  List<Map<String, dynamic>> _prescriptions = [];
  String _statusFilter = '';

  List<Map<String, dynamic>> get prescriptions => _prescriptions;

  Future<void> load() => guard(() async {
        final params = <String, String>{};
        if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
        final res = await ApiClient.get(ApiConstants.prescriptions, queryParams: params.isNotEmpty ? params : null);
        _prescriptions = unwrapList(res);
      }, errorMessage: 'Failed to load prescriptions');

  void setStatusFilter(String status) {
    _statusFilter = status;
    load();
  }
}

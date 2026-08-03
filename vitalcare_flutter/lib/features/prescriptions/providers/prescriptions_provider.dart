import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class PrescriptionsProvider extends BaseProvider {
  List<Map<String, dynamic>> _prescriptions = [];
  List<Map<String, dynamic>> _refills = [];
  String _statusFilter = '';

  List<Map<String, dynamic>> get prescriptions => _prescriptions;
  List<Map<String, dynamic>> get refills => _refills;

  Future<void> load() => guard(() async {
        final params = <String, String>{};
        if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
        final res = await ApiClient.get(ApiConstants.prescriptions, queryParams: params.isNotEmpty ? params : null);
        _prescriptions = unwrapList(res);
      }, errorMessage: 'Failed to load prescriptions');

  Future<void> loadRefills() => guard(() async {
        _refills = unwrapList(await ApiClient.get('${ApiConstants.prescriptions}/refills'));
      }, errorMessage: 'Failed to load refills');

  Future<bool> requestRefill(String itemId) => guard(() async {
        await ApiClient.post('${ApiConstants.prescriptions}/refills', body: {
          'prescription_item_id': itemId,
        });
        await loadRefills();
      }, errorMessage: 'Refill request failed');

  void setStatusFilter(String status) {
    _statusFilter = status;
    load();
  }
}

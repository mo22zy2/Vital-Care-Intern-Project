import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class LabtechProvider extends BaseProvider {
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _bookings = [];
  String _statusFilter = '';

  Map<String, dynamic>? get dashboard => _dashboard;
  List<Map<String, dynamic>> get bookings => _bookings;
  String get statusFilter => _statusFilter;

  Future<void> loadDashboard() => guard(() async {
        _dashboard = await ApiClient.get(ApiConstants.labDashboard);
        final params = <String, String>{};
        if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
        final res = await ApiClient.get(ApiConstants.labBookings, queryParams: params.isNotEmpty ? params : null);
        _bookings = unwrapList(res);
      }, errorMessage: 'Failed to load dashboard');

  void setStatusFilter(String status) {
    _statusFilter = status;
    loadDashboard();
  }

  Future<bool> updateBookingStatus(String id, String action) => guard(() async {
        await ApiClient.patch('${ApiConstants.labBookings}/$id/status', body: {'action': action});
        await loadDashboard();
      });

  Future<bool> releaseResult(String id, String summary, String details) => guard(() async {
        await ApiClient.post('${ApiConstants.labBookings}/$id/release-result',
            body: {'result_summary': summary, 'result_details': details});
        await loadDashboard();
      });
}

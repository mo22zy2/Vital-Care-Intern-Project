import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class DoctorProvider extends BaseProvider {
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _availability = [];
  String _statusFilter = '';
  String _search = '';

  Map<String, dynamic>? get dashboard => _dashboard;
  List<Map<String, dynamic>> get appointments => _appointments;
  List<Map<String, dynamic>> get availability => _availability;
  String get statusFilter => _statusFilter;

  Future<void> loadDashboard() => guard(() async {
        _dashboard = await ApiClient.get(ApiConstants.doctorDashboard);
      }, errorMessage: 'Failed to load dashboard');

  Future<void> loadAppointments() => guard(() async {
        final params = <String, String>{};
        if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
        if (_search.isNotEmpty) params['q'] = _search;
        final res = await ApiClient.get(ApiConstants.doctorAppointments, queryParams: params.isNotEmpty ? params : null);
        _appointments = unwrapList(res);
      }, errorMessage: 'Failed to load appointments');

  Future<void> loadAvailability() => guard(() async {
        _availability = unwrapList(await ApiClient.get(ApiConstants.doctorAvailability));
      }, errorMessage: 'Failed to load availability');

  void setStatusFilter(String status) {
    _statusFilter = status;
    loadAppointments();
  }

  void setSearch(String q) {
    _search = q;
    loadAppointments();
  }

  Future<bool> updateAppointmentStatus(String id, String action) => guard(() async {
        await ApiClient.patch('${ApiConstants.appointments}/$id/status', body: {'action': action});
        await loadAppointments();
      });

  Future<bool> saveAvailability(Map<String, dynamic> slot) => guard(() async {
        await ApiClient.post(ApiConstants.doctorAvailability, body: slot);
        await loadAvailability();
      });

  Future<bool> deleteAvailabilitySlot(String id) => guard(() async {
        await ApiClient.delete('${ApiConstants.doctorAvailability}/$id');
        await loadAvailability();
      });
}

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class AppointmentsProvider extends BaseProvider {
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _specialties = [];
  String _statusFilter = '';
  String _search = '';

  List<Map<String, dynamic>> get appointments => _appointments;
  List<Map<String, dynamic>> get doctors => _doctors;
  List<Map<String, dynamic>> get specialties => _specialties;

  Future<void> loadAppointments() => guard(() async {
        final params = <String, String>{};
        if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
        if (_search.isNotEmpty) params['q'] = _search;
        final res = await ApiClient.get(ApiConstants.appointments, queryParams: params.isNotEmpty ? params : null);
        _appointments = unwrapList(res);
      }, errorMessage: 'Failed to load appointments');

  Future<void> loadDoctorsAndSpecialties() async {
    try {
      _specialties = unwrapList(await ApiClient.get(ApiConstants.doctorSpecialties));
      _doctors = unwrapList(await ApiClient.get(ApiConstants.doctors));
      notifyListeners();
    } catch (_) {}
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    loadAppointments();
  }

  void setSearch(String q) {
    _search = q;
    loadAppointments();
  }

  Future<bool> bookAppointment(Map<String, dynamic> body) => guard(() async {
        await ApiClient.post(ApiConstants.appointments, body: body);
        await loadAppointments();
      });

  Future<bool> cancelAppointment(String id, String reason) => guard(() async {
        await ApiClient.patch('${ApiConstants.appointments}/$id/cancel', body: {'reason': reason});
        await loadAppointments();
      });
}

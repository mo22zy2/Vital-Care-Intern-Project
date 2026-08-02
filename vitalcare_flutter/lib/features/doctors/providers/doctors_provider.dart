import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class DoctorsProvider extends BaseProvider {
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _specialties = [];
  String _search = '';
  String _specialtyId = '';

  List<Map<String, dynamic>> get doctors => _filtered;
  List<Map<String, dynamic>> get specialties => _specialties;

  Future<void> load() => guard(() async {
        _specialties = unwrapList(await ApiClient.get(ApiConstants.doctorSpecialties));
        final params = <String, String>{};
        if (_specialtyId.isNotEmpty) params['specialty_id'] = _specialtyId;
        final res = await ApiClient.get(ApiConstants.doctors, queryParams: params.isNotEmpty ? params : null);
        _allDoctors = unwrapList(res);
        _applyFilter();
      }, errorMessage: 'Failed to load doctors');

  void setSearch(String q) {
    _search = q.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void setSpecialty(String id) {
    _specialtyId = id;
    load();
  }

  void _applyFilter() {
    _filtered = _allDoctors.where((d) {
      final name = (d['full_name']?.toString() ?? '').toLowerCase();
      final matchesSearch = _search.isEmpty || name.contains(_search);
      return matchesSearch;
    }).toList();
  }
}

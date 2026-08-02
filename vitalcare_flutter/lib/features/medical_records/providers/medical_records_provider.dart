import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class MedicalRecordsProvider extends BaseProvider {
  List<Map<String, dynamic>> _records = [];
  String _search = '';

  List<Map<String, dynamic>> get records => _records;

  Future<void> load() => guard(() async {
        final params = <String, String>{};
        if (_search.isNotEmpty) params['q'] = _search;
        final res = await ApiClient.get(ApiConstants.medicalRecords, queryParams: params.isNotEmpty ? params : null);
        _records = unwrapList(res);
      }, errorMessage: 'Failed to load records');

  void setSearch(String q) {
    _search = q;
    load();
  }
}

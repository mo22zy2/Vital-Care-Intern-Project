import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class BillingProvider extends BaseProvider {
  List<Map<String, dynamic>> _invoices = [];
  String _statusFilter = '';
  String _search = '';

  List<Map<String, dynamic>> get invoices => _invoices;

  Future<void> load() => guard(() async {
        final params = <String, String>{};
        if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
        if (_search.isNotEmpty) params['q'] = _search;
        final res = await ApiClient.get(ApiConstants.invoices, queryParams: params.isNotEmpty ? params : null);
        _invoices = unwrapList(res);
      }, errorMessage: 'Failed to load invoices');

  void setStatusFilter(String status) {
    _statusFilter = status;
    load();
  }

  void setSearch(String q) {
    _search = q;
    load();
  }
}

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/base_provider.dart';

class BillingProvider extends BaseProvider {
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _payments = [];
  String _statusFilter = '';
  String _search = '';

  List<Map<String, dynamic>> get invoices => _invoices;
  List<Map<String, dynamic>> get payments => _payments;

  Future<void> load() => guard(() async {
        final params = <String, String>{};
        if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
        if (_search.isNotEmpty) params['q'] = _search;
        final res = await ApiClient.get(ApiConstants.invoices, queryParams: params.isNotEmpty ? params : null);
        _invoices = unwrapList(res);
      }, errorMessage: 'Failed to load invoices');

  Future<void> loadPayments() => guard(() async {
        _payments = unwrapList(await ApiClient.get(ApiConstants.payments));
      }, errorMessage: 'Failed to load payments');

  Future<bool> payInvoice(String invoiceId, String method, String amount) => guard(() async {
        await ApiClient.post('/payments/invoices/$invoiceId/pay', body: {
          'invoice_id': invoiceId,
          'method': method,
          'amount': amount,
        });
        await load();
        await loadPayments();
      }, errorMessage: 'Payment failed');

  void setStatusFilter(String status) {
    _statusFilter = status;
    load();
  }

  void setSearch(String q) {
    _search = q;
    load();
  }
}

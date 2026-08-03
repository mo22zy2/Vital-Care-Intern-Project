import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_date_time_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/insurance_provider.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<InsuranceProvider>();
      p.load();
      p.loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InsuranceProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Text('Insurance', style: Theme.of(context).textTheme.displayMedium),
              const Spacer(),
              if (_tab == 0)
                AppButton.primary('+ Add Policy', expanded: false,
                    onPressed: () => _showAddPolicy(context)),
              if (_tab == 1)
                AppButton.primary('+ Submit Claim', expanded: false,
                    onPressed: () => _showClaimForm(context)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Policies')),
              ButtonSegment(value: 1, label: Text('Claims')),
              ButtonSegment(value: 2, label: Text('Providers')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
            style: SegmentedButton.styleFrom(
              foregroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tab == 0
                  ? _policyList(prov)
                  : _tab == 1
                      ? _claimList(prov)
                      : _providerList(prov),
        ),
      ],
    );
  }

  Widget _policyList(InsuranceProvider prov) {
    if (prov.policies.isEmpty) {
      return const EmptyState(icon: Icons.verified_user, title: 'No insurance policies');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      itemCount: prov.policies.length,
      itemBuilder: (context, i) {
        final p = prov.policies[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(p['provider_name']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    AppBadge(
                      label: p['verification_status']?.toString() ?? '',
                      color: p['verification_status'] == 'VERIFIED' ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Policy #${p['policy_number'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'JetBrains Mono')),
                Text('${p['valid_from']}  →  ${p['valid_to']}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Text('Coverage: ${p['coverage_percentage']}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                if (p['coverage_details']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(p['coverage_details'].toString(),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _claimList(InsuranceProvider prov) {
    if (prov.claims.isEmpty) {
      return const EmptyState(icon: Icons.request_quote, title: 'No claims submitted');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      itemCount: prov.claims.length,
      itemBuilder: (context, i) {
        final c = prov.claims[i];
        final approved = c['approved_amount']?.toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice ${c['invoice_number'] ?? ''}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Claimed: E£${c['claim_amount']}  ·  ${c['submitted_at']?.toString().substring(0, 10) ?? ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (approved != null)
                        Text('Approved: E£$approved',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                      if (c['notes']?.toString().isNotEmpty == true)
                        Text(c['notes'].toString(),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                AppBadge(label: c['status']?.toString() ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _providerList(InsuranceProvider prov) {
    if (prov.providers.isEmpty) {
      return const EmptyState(icon: Icons.local_hospital, title: 'No providers');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      itemCount: prov.providers.length,
      itemBuilder: (context, i) {
        final p = prov.providers[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name']?.toString() ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(p['contact_email']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(p['contact_phone']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const _AddPolicySheet(),
      ),
    );
  }

  void _showClaimForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const _ClaimSheet(),
      ),
    );
  }
}

class _AddPolicySheet extends StatefulWidget {
  const _AddPolicySheet();

  @override
  State<_AddPolicySheet> createState() => _AddPolicySheetState();
}

class _AddPolicySheetState extends State<_AddPolicySheet> {
  final _formKey = GlobalKey<FormState>();
  final _policyCtl = TextEditingController();
  final _groupCtl = TextEditingController();
  final _detailsCtl = TextEditingController();
  final _coverageCtl = TextEditingController(text: '80');
  final _fromCtl = TextEditingController();
  final _toCtl = TextEditingController();
  String? _providerId;
  bool _loading = false;

  @override
  void dispose() {
    _policyCtl.dispose();
    _groupCtl.dispose();
    _detailsCtl.dispose();
    _coverageCtl.dispose();
    _fromCtl.dispose();
    _toCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InsuranceProvider>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Insurance Policy', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Provider *'),
                items: prov.providers.map((p) => DropdownMenuItem(
                  value: p['id'].toString(),
                  child: Text(p['name']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                )).toList(),
                onChanged: (v) => _providerId = v,
                validator: (v) => v == null ? 'Required' : null,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _policyCtl,
                decoration: const InputDecoration(labelText: 'Policy Number *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _groupCtl,
                decoration: const InputDecoration(labelText: 'Group Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coverageCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Coverage % *'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 0 || n > 100 ? '0–100' : null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppDateField(
                      controller: _fromCtl,
                      label: 'Valid From *',
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDateField(
                      controller: _toCtl,
                      label: 'Valid To *',
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailsCtl,
                decoration: const InputDecoration(labelText: 'Coverage Details'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton.primary('Add Policy', isLoading: _loading, onPressed: _submit),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.outline('Cancel', onPressed: () => Navigator.pop(context)),
                  ),
                ],
              ),
              if (prov.error != null) ...[
                const SizedBox(height: 10),
                Text(prov.error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await context.read<InsuranceProvider>().addPolicy({
      'provider_id': int.parse(_providerId!),
      'policy_number': _policyCtl.text.trim(),
      'group_number': _groupCtl.text.trim(),
      'coverage_details': _detailsCtl.text.trim(),
      'coverage_percentage': int.parse(_coverageCtl.text.trim()),
      'valid_from': _fromCtl.text.trim(),
      'valid_to': _toCtl.text.trim(),
    });
    setState(() => _loading = false);
    if (ok && mounted) Navigator.pop(context);
  }
}

class _ClaimSheet extends StatefulWidget {
  const _ClaimSheet();

  @override
  State<_ClaimSheet> createState() => _ClaimSheetState();
}

class _ClaimSheetState extends State<_ClaimSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  String? _policyId;
  String? _invoiceId;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<InsuranceProvider>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submit Insurance Claim', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Policy *'),
                items: prov.policies.map((p) => DropdownMenuItem(
                  value: p['id'].toString(),
                  child: Text('${p['provider_name']} (#${p['policy_number']})', style: const TextStyle(fontSize: 14)),
                )).toList(),
                onChanged: (v) => _policyId = v,
                validator: (v) => v == null ? 'Required' : null,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Invoice *'),
                items: prov.invoices.map((i) => DropdownMenuItem(
                  value: i['id'].toString(),
                  child: Text('${i['invoice_number']}  (E£${i['total_amount']})', style: const TextStyle(fontSize: 14)),
                )).toList(),
                onChanged: (v) => _invoiceId = v,
                validator: (v) => v == null ? 'Required' : null,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Claim Amount (E£) *'),
                validator: (v) => v == null || double.tryParse(v.trim()) == null ? 'Enter a valid amount' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton.primary('Submit Claim', isLoading: _loading, onPressed: _submit),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.outline('Cancel', onPressed: () => Navigator.pop(context)),
                  ),
                ],
              ),
              if (prov.error != null) ...[
                const SizedBox(height: 10),
                Text(prov.error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await context.read<InsuranceProvider>().submitClaim({
      'policy_id': _policyId,
      'invoice_id': _invoiceId,
      'claim_amount': double.parse(_amountCtl.text.trim()),
      'notes': _notesCtl.text.trim(),
    });
    setState(() => _loading = false);
    if (ok && mounted) Navigator.pop(context);
  }
}

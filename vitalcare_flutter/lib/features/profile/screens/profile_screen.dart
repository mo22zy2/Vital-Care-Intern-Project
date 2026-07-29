import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/network/api_client.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fnCtl = TextEditingController();
  final _lnCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  bool _saving = false;

  // New EC form
  final _ecNameCtl = TextEditingController();
  final _ecRelCtl = TextEditingController();
  final _ecPhoneCtl = TextEditingController();
  String? _addingEc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().load().then((_) => _populate());
    });
  }

  void _populate() {
    final p = context.read<ProfileProvider>().profile;
    if (p != null) {
      _fnCtl.text = p['first_name']?.toString() ?? '';
      _lnCtl.text = p['last_name']?.toString() ?? '';
      _phoneCtl.text = p['phone']?.toString() ?? '';
      _addressCtl.text = p['address']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _fnCtl.dispose();
    _lnCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _ecNameCtl.dispose();
    _ecRelCtl.dispose();
    _ecPhoneCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<ProfileProvider>().updateProfile({
      'first_name': _fnCtl.text.trim(),
      'last_name': _lnCtl.text.trim(),
      'phone': _phoneCtl.text.trim(),
      'address': _addressCtl.text.trim(),
    });
    setState(() => _saving = false);
  }

  Future<void> _addEc() async {
    await context.read<ProfileProvider>().addEmergencyContact({
      'full_name': _ecNameCtl.text.trim(),
      'relationship': _ecRelCtl.text.trim(),
      'phone': _ecPhoneCtl.text.trim(),
    });
    _ecNameCtl.clear();
    _ecRelCtl.clear();
    _ecPhoneCtl.clear();
    setState(() => _addingEc = null);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();
    final user = ApiClient.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: user?['email']?.toString() ?? '',
                          decoration: const InputDecoration(labelText: 'Email'),
                          enabled: false,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: user?['role']?.toString() ?? '',
                          decoration: const InputDecoration(labelText: 'Role'),
                          enabled: false,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _fnCtl,
                          decoration: const InputDecoration(labelText: 'First Name'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lnCtl,
                          decoration: const InputDecoration(labelText: 'Last Name'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneCtl,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressCtl,
                          decoration: const InputDecoration(labelText: 'Address'),
                        ),
                        const SizedBox(height: 20),
                        AppButton.primary('Save Changes', isLoading: _saving, onPressed: _save),
                        if (prov.error != null) ...[
                          const SizedBox(height: 8),
                          Text(prov.error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Emergency Contacts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                                onPressed: () => setState(() => _addingEc = 'new'),
                              ),
                            ],
                          ),
                          prov.emergencyContacts.isEmpty
                              ? const EmptyState(icon: Icons.contact_phone, title: 'No emergency contacts')
                              : Column(
                                  children: prov.emergencyContacts.map((ec) => Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(ec['full_name']?.toString() ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                              Text('${ec['relationship']}  |  ${ec['phone']}',
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                          onPressed: () => prov.deleteEmergencyContact(ec['id'].toString()),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                          if (_addingEc != null) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _ecNameCtl,
                              decoration: const InputDecoration(labelText: 'Full Name', isDense: true),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ecRelCtl,
                              decoration: const InputDecoration(labelText: 'Relationship', isDense: true),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ecPhoneCtl,
                              decoration: const InputDecoration(labelText: 'Phone', isDense: true),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: AppButton.primary('Save', onPressed: _addEc)),
                                const SizedBox(width: 8),
                                Expanded(child: AppButton.outline('Cancel', onPressed: () => setState(() => _addingEc = null))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Activity Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Text('Member since: ${user?['date_joined']?.toString().substring(0, 10) ?? 'N/A'}',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

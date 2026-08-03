import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtl = TextEditingController();
  final _newCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _currentCtl.dispose();
    _newCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await ApiClient.post(ApiConstants.changePassword, body: {
        'current_password': _currentCtl.text,
        'new_password': _newCtl.text,
      });
      setState(() {
        _success = 'Password changed successfully';
        _loading = false;
      });
      _currentCtl.clear();
      _newCtl.clear();
      _confirmCtl.clear();
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: AppCard(
          maxWidth: 440,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _currentCtl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current Password *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newCtl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password *'),
                  validator: (v) =>
                      v == null || v.length < 8 ? 'At least 8 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm New Password *'),
                  validator: (v) => v != _newCtl.text ? 'Passwords do not match' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ],
                if (_success != null) ...[
                  const SizedBox(height: 12),
                  Text(_success!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: AppButton.primary('Update Password', isLoading: _loading, onPressed: _submit)),
                    const SizedBox(width: 12),
                    Expanded(child: AppButton.outline('Cancel', onPressed: () => Navigator.pop(context))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

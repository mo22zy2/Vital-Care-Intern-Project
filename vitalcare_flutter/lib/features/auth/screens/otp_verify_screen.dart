import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;

  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _codeCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.post(ApiConstants.verifyOtp, body: {
        'email': widget.email,
        'code': _codeCtl.text.trim(),
        'new_password': _passwordCtl.text,
      });
      setState(() {
        _success = (res['message'] ?? 'Password reset successfully').toString();
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_success!)));
        context.go('/login');
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppCard(
          maxWidth: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset Password', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Enter the code sent to ${widget.email}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _codeCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'One-Time Code *'),
                  validator: (v) =>
                      v == null || v.trim().length < 6 ? 'Enter the 6-digit code' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtl,
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
                  validator: (v) => v != _passwordCtl.text ? 'Passwords do not match' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary('Reset Password', isLoading: _loading, onPressed: _submit),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.outline('Back to Login', onPressed: () => context.go('/login')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

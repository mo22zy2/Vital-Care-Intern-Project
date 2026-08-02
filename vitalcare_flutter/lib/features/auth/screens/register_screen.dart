import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_date_time_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  String _gender = '';
  final _dobCtl = TextEditingController();

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _dobCtl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtl.text.trim(),
      password: _passwordCtl.text,
      firstName: _firstNameCtl.text.trim(),
      lastName: _lastNameCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      address: _addressCtl.text.trim(),
      gender: _gender,
      dateOfBirth: _dobCtl.text.trim().isEmpty ? null : _dobCtl.text.trim(),
    );
    if (ok && mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 680),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('V', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Create Account', style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColors.text, fontFamily: 'InterTight',
                    )),
                    const SizedBox(height: 24),
                    if (auth.error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(auth.error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
                      ),
                    _section('Account'),
                    const SizedBox(height: 12),
                    _row([
                      _textField(_emailCtl, 'Email *', keyboardType: TextInputType.emailAddress, expanded: true),
                      _textField(_passwordCtl, 'Password *', obscure: true, expanded: true),
                    ]),
                    const SizedBox(height: 16),
                    _section('Personal Information'),
                    const SizedBox(height: 12),
                    _row([
                      _textField(_firstNameCtl, 'First Name *', expanded: true),
                      _textField(_lastNameCtl, 'Last Name *', expanded: true),
                    ]),
                    const SizedBox(height: 12),
                    _row([
                      _textField(_phoneCtl, 'Phone *', expanded: true),
                      _textField(_addressCtl, 'Address', expanded: true),
                    ]),
                    const SizedBox(height: 12),
                    _row([
                      DropdownButtonFormField<String>(
                        initialValue: _gender.isEmpty ? null : _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: ['', 'MALE', 'FEMALE'].map((g) => DropdownMenuItem(
                          value: g.isEmpty ? null : g,
                          child: Text(g.isEmpty ? 'Select' : g, style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (v) => setState(() => _gender = v ?? ''),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: AppDateField(
                            controller: _dobCtl,
                            label: 'Date of Birth',
                            firstDate: DateTime(DateTime.now().year - 120, 12, 31),
                            lastDate: DateTime.now(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    AppButton.primary('Create Account', onPressed: _register, isLoading: auth.isLoading),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text('Already have an account? Sign in',
                        style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.primary, fontFamily: 'InterTight',
      )),
    );
  }

  Widget _row(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: children.map((w) => Flexible(child: w)).toList(),
        );
      },
    );
  }

  Widget _textField(TextEditingController ctl, String label, {bool obscure = false, bool expanded = false, String? hint, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextFormField(
        controller: ctl,
        decoration: InputDecoration(labelText: label, hintText: hint),
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: label.contains('*') ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
      ),
    );
  }
}

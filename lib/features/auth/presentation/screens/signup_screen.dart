import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/phone_normalizer.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  bool _sendingPhoneCode = false;
  String? _phoneVerificationId;
  String? _requestedPhoneNumber;
  PhoneAuthCredential? _automaticPhoneCredential;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _phoneCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendPhoneVerificationCode() async {
    final phone = PhoneNormalizer.normalize(_phoneController.text.trim());
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number first.')),
      );
      return;
    }

    setState(() {
      _sendingPhoneCode = true;
      _phoneVerificationId = null;
      _automaticPhoneCredential = null;
      _requestedPhoneNumber = phone;
      _phoneCodeController.clear();
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) {
          if (!mounted || _requestedPhoneNumber != phone) return;
          setState(() => _automaticPhoneCredential = credential);
        },
        verificationFailed: (error) {
          if (!mounted || _requestedPhoneNumber != phone) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? 'Could not verify phone.')),
          );
        },
        codeSent: (verificationId, _) {
          if (!mounted || _requestedPhoneNumber != phone) return;
          setState(() => _phoneVerificationId = verificationId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification code sent.')),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted || _requestedPhoneNumber != phone) return;
          setState(() => _phoneVerificationId = verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Could not send code.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingPhoneCode = false);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      // Normalize phone number
      final rawPhone = _phoneController.text.trim();
      final normalizedPhone = PhoneNormalizer.normalize(rawPhone) ?? rawPhone;
      final verificationId = _phoneVerificationId;
      final phoneCredential = kIsWeb
          ? null
          : _automaticPhoneCredential ??
                (verificationId != null &&
                        _phoneCodeController.text.trim().length == 6
                    ? PhoneAuthProvider.credential(
                        verificationId: verificationId,
                        smsCode: _phoneCodeController.text.trim(),
                      )
                    : null);
      if (!kIsWeb &&
          (phoneCredential == null ||
              _requestedPhoneNumber != normalizedPhone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verify your phone number to continue.'),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      await ref
          .read(authRepositoryProvider)
          .signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: phoneCredential == null ? '' : normalizedPhone,
            phoneCredential: phoneCredential,
          );
      // await ref.read(authRepositoryProvider).pfirebase_auth_datasource();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Please verify your email before logging in.',
          ),
        ),
      );

      context.go(AppRouter.login);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Unable to create an account with those details.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password authentication is disabled.';
          break;
        default:
          message = e.message ?? 'Signup failed.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong.')));
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Account",
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                AppSpacing.gapSM,

                Text(
                  "Create your Velora account.",
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                AppSpacing.gapXXL,

                // Full Name
                TextFormField(
                  controller: _nameController,
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: AppRadius.lg),
                  ),
                ),

                AppSpacing.gapLG,

                // Email
                TextFormField(
                  controller: _emailController,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: AppRadius.lg),
                  ),
                ),

                AppSpacing.gapLG,

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  onChanged: (_) {
                    setState(() {
                      _phoneVerificationId = null;
                      _requestedPhoneNumber = null;
                      _automaticPhoneCredential = null;
                      _phoneCodeController.clear();
                    });
                  },
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (kIsWeb && (value == null || value.trim().isEmpty)) {
                      return null;
                    }
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    final normalized = PhoneNormalizer.normalize(value.trim());
                    if (normalized == null) {
                      return 'Enter a valid 10-digit Indian number';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: kIsWeb
                        ? 'Phone Number (optional on web)'
                        : 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '98765 43210',
                    border: OutlineInputBorder(borderRadius: AppRadius.lg),
                  ),
                ),

                if (!kIsWeb)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _sendingPhoneCode || _loading
                          ? null
                          : _sendPhoneVerificationCode,
                      child: Text(
                        _sendingPhoneCode
                            ? 'Sending code...'
                            : _phoneVerificationId == null
                            ? 'Verify phone'
                            : 'Resend code',
                      ),
                    ),
                  ),
                if (!kIsWeb &&
                    _phoneVerificationId != null &&
                    _automaticPhoneCredential == null) ...[
                  TextFormField(
                    controller: _phoneCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'SMS verification code',
                      prefixIcon: Icon(Icons.sms_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.lg),
                    ),
                  ),
                ],
                if (!kIsWeb && _automaticPhoneCredential != null)
                  const Text('Phone number verified automatically.'),

                AppSpacing.gapLG,

                // Password
                TextFormField(
                  controller: _passwordController,
                  validator: Validators.password,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(
                      borderRadius: AppRadius.lg,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),

                AppSpacing.gapLG,

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signup(),
                  validator: (value) => Validators.confirmPassword(
                    _passwordController.text,
                    value,
                  ),
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(
                      borderRadius: AppRadius.lg,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),

                AppSpacing.gapXXL,

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    onPressed: _loading ? null : _signup,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Create Account"),
                  ),
                ),

                AppSpacing.gapXL,

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => context.go(AppRouter.login),
                      child: const Text("Login"),
                    ),
                  ],
                ),

                AppSpacing.gapLG,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

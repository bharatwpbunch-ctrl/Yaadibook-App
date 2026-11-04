import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/yb_primary_button.dart';
import '../../../core/widgets/yb_text_input.dart';
import '../providers/auth_controller.dart';

/// Password recovery request screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    ref.read(authControllerProvider.notifier).clearError();
    ref.read(authControllerProvider.notifier).clearInfo();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPasswordForEmail(email: _emailController.text);

    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenHorizontalPadding,
          child: _emailSent
              ? _buildSuccessView(context)
              : _buildFormView(context, authState),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, AuthFormState authState) {
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.authForgotPasswordTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          AppSpacing.gapV8,
          Text(
            l10n.authForgotPasswordSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          AppSpacing.gapV24,

          // Error Banner
          if (authState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  AppSpacing.gapH8,
                  Expanded(
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapV16,
          ],

          // Email
          YbTextInput(
            label: l10n.authEmail,
            hint: l10n.authEmailHint,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.valRequired;
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return l10n.valInvalidEmail;
              }
              return null;
            },
          ),
          AppSpacing.gapV24,

          // Submit Button
          YbPrimaryButton(
            label: l10n.authSendResetLink,
            isLoading: authState.isLoading,
            onPressed: _handleSendResetLink,
          ),
          AppSpacing.gapV16,

          // Back to login
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                l10n.authBackToLogin,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.gapV32,
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.mark_email_read_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        AppSpacing.gapV24,
        Text(
          l10n.authResetLinkSentTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.gapV12,
        Text(
          l10n.authResetLinkSentMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        AppSpacing.gapV32,
        YbPrimaryButton(
          label: l10n.authBackToLogin,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}

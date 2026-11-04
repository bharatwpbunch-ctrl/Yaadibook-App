import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';

/// Modal bottom sheet container conforming to Yaadibook design system.
class YbBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool showCloseButton;

  const YbBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.showCloseButton = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    bool isScrollControlled = true,
    bool showCloseButton = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => YbBottomSheet(
        title: title,
        showCloseButton: showCloseButton,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.bottomSheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpacing.gapV12,
              // Drag indicator handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadii.borderPill,
                ),
              ),
              if (title != null || showCloseButton) ...[
                AppSpacing.gapV12,
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      if (showCloseButton)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: AppColors.textSecondary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
              ],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

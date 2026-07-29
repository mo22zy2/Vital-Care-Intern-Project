import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;
  final Color? color;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.expanded = true,
    this.color,
    this.icon,
  });

  factory AppButton.primary(String label, {VoidCallback? onPressed, bool isLoading = false}) =>
      AppButton(label: label, onPressed: onPressed, isLoading: isLoading, color: AppColors.primary);

  factory AppButton.accent(String label, {VoidCallback? onPressed, bool isLoading = false}) =>
      AppButton(label: label, onPressed: onPressed, isLoading: isLoading, color: AppColors.accent);

  factory AppButton.danger(String label, {VoidCallback? onPressed, bool isLoading = false}) =>
      AppButton(label: label, onPressed: onPressed, isLoading: isLoading, color: AppColors.danger);

  factory AppButton.outline(String label, {VoidCallback? onPressed}) =>
      AppButton(label: label, onPressed: onPressed, color: Colors.transparent);

  @override
  Widget build(BuildContext context) {
    final isOutline = color == Colors.transparent;
    return SizedBox(
      width: expanded ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutline ? Colors.transparent : (color ?? AppColors.primary),
          foregroundColor: isOutline ? AppColors.primary : Colors.white,
          side: isOutline ? BorderSide(color: AppColors.border) : BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: isOutline ? 0 : 0,
        ),
        child: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

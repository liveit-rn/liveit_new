import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            : icon,
        label: Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            color: textColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.surface,
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SoftInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const SoftInput({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark
        ? colors.outline.withOpacity(0.6)
        : Colors.grey.shade300;

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: colors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colors.onSurface.withOpacity(0.8),
        ),
        floatingLabelStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: icon != null
            ? Icon(
          icon,
          color: colors.primary,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

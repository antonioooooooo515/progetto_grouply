import 'package:flutter/material.dart';

class TinyTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Alignment alignment;

  const TinyTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: alignment,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

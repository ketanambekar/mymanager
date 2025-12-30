import 'package:flutter/material.dart';
import 'package:mymanager/theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const AppButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // ripple follows border
        splashColor: Colors.purple.withOpacity(0.3), // optional
        highlightColor: Colors.purple.withOpacity(0.1), // optional
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.purpleAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(text, style: AppTextStyles.bodyLarge)),
        ),
      ),
    );
  }
}

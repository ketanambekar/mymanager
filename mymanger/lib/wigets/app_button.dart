import 'package:flutter/material.dart';
import 'package:mymanger/theme/app_colors.dart';
import 'package:mymanger/wigets/app_image.dart';

enum AppButtonType {
  primary,
  secondary
}

class AppButton extends StatelessWidget {
  final String? text;
  final String? icon;
  final bool iconRight;
  final VoidCallback onPressed;
  final AppButtonType type;
  final double height;
  final double borderRadius;
  final double? width;

  const AppButton({
    super.key,
    this.text,
    this.icon,
    this.iconRight = false,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.height = 48,
    this.borderRadius = 50,
    this.width
  });

  bool get _isIconOnly => icon != null && text == null;

  @override
  Widget build(BuildContext context) {
    final isPrimary = type == AppButtonType.primary;

    final backgroundColor =
    isPrimary ? AppColors.primary : AppColors.yellow;

    final foregroundColor =
    isPrimary ? Colors.white : AppColors.yellow;

    final borderColor = isPrimary ?  AppColors.primary: AppColors.yellow;

    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: isPrimary
              ? BorderSide.none
              : BorderSide(
            color: borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (_isIconOnly) {
      return AppImage(imagePath: icon!, width: 50, height: 50,);
    }

    if (icon == null) {
      return Text(text!);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!iconRight) ...[
          AppImage(imagePath: icon!),
          const SizedBox(width: 8),
        ],
        Text(text!),
        if (iconRight) ...[
          const SizedBox(width: 8),
          AppImage(imagePath: icon!),
        ],
      ],
    );
  }
}
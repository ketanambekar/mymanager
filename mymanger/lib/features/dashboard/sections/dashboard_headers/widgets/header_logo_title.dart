import 'package:flutter/material.dart';
import 'package:mymanger/constants/app_assets_constants.dart';
import 'package:mymanger/theme/app_text_style.dart';
import 'package:mymanger/wigets/app_image.dart';

class HeaderLogoTitle extends StatelessWidget {
  const HeaderLogoTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppImage(imagePath: AppAssets.appLogo, height: 45, width: 45),
        Padding(
          padding: const EdgeInsets.only(left: 19.0),
          child: Text('MyManGer', style: AppTextStyles.textSemiBold24),
        ),
      ],
    );
  }
}

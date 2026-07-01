import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanger/constants/app_assets_constants.dart';
import 'package:mymanger/services/auth_service.dart';
import 'package:mymanger/wigets/app_button.dart';

class HeaderLoginSection extends StatelessWidget {
  const HeaderLoginSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.to;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // AppImage(imagePath: AppAssets.search, height: 22, width: 22),
        // SizedBox(width: 30),
        // AppImage(imagePath: AppAssets.cart, height: 24, width: 24),
        // SizedBox(width: 30),
        Obx(
          () => AppButton(
            text: authService.isLoggedIn ? 'Logout' : 'Login',
            icon: AppAssets.login,
            onPressed: () async {
              if (authService.isLoggedIn) {
                await authService.signOutFromGoogle();
                return;
              }

              final user = await authService.signInWithGoogle();
              if (kDebugMode) {
                print('Google user: ${user?.email}');
              }
            },
          ),
        ),
      ],
    );
  }
}

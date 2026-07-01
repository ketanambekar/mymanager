import 'package:flutter/material.dart';
import 'package:mymanger/constants/app_assets_constants.dart';
import 'package:mymanger/theme/app_colors.dart';
import 'package:mymanger/theme/app_text_style.dart';
import 'package:mymanger/wigets/app_image.dart';


class HeaderButtons extends StatelessWidget {
  const HeaderButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 55),
          child: Text(
            'Why MyManGer?',
            style: AppTextStyles.textMedium14.copyWith(
                color: AppColors.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 55),
          child: Row(
            children: [
              Text(
                'Services',
                style: AppTextStyles.textMedium14,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: AppImage(imagePath: AppAssets.dropDownArrow, height: 10, width: 10,),
              )
            ],
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.only(right: 55),
        //
        //   child: Row(
        //     children: [
        //       Text(
        //         'Menu',
        //         style: AppTextStyles.textMedium14,
        //       ),
        //       Padding(
        //         padding: const EdgeInsets.only(left: 5),
        //         child: AppImage(imagePath: AppAssets.dropDownArrow, height: 10, width: 10,),
        //       )
        //     ],
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.only(right: 55),

          child: Text(
            'Contact',
            style: AppTextStyles.textMedium14,
          ),
        ),
      ],
    );
  }
}

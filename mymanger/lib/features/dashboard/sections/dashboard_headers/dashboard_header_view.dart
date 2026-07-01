import 'package:flutter/material.dart';
import 'package:mymanger/features/dashboard/sections/dashboard_headers/widgets/header_buttons.dart';
import 'package:mymanger/features/dashboard/sections/dashboard_headers/widgets/header_login_section.dart';
import 'package:mymanger/features/dashboard/sections/dashboard_headers/widgets/header_logo_title.dart';
import 'package:mymanger/theme/app_colors.dart';


class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  const DashboardHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 1.5);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 45, right: 95, left: 95),
      child: AppBar(
        backgroundColor: AppColors.white,
        flexibleSpace: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [HeaderLogoTitle(), HeaderButtons(), HeaderLoginSection()]),
      ),
    );
  }
}

PreferredSizeWidget get dashboardHeader => const DashboardHeader();

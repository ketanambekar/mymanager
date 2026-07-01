import 'package:flutter/material.dart';
import 'package:mymanger/features/dashboard/sections/dashboard_headers/dashboard_header_view.dart';
import 'package:mymanger/theme/app_colors.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: DashboardHeader(),
      body: Padding(
        padding: const EdgeInsets.only(left: 95, right: 95, top: 14),
        child: SingleChildScrollView(
          child: Column(children: []),
        ),
      ),
    );
  }
}

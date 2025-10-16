import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/calander/calender_view.dart';
import 'package:mymanager/screen/create_project/create_project_binding.dart';
import 'package:mymanager/screen/create_project/create_project_view.dart';
import 'package:mymanager/screen/dashboard/dashboard_binding.dart';
import 'package:mymanager/screen/dashboard/dashboard_view.dart';
import 'package:mymanager/screen/profile/profile_view.dart';
import 'package:mymanager/screen/reports/reports_view.dart';

class AppRoutes {
  static const dashboard = '/dashboard';
  static const calender = '/calender';
  static const reports = '/reports';
  static const profile = '/profile';
  static const createProject = '/create-project';
}

class AppPages {
  static const initial = AppRoutes.dashboard;

  static final routes = [
    GetPage(
      name: AppRoutes.dashboard,
      page: () => DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(name: AppRoutes.calender, page: () => CalenderView()),
    GetPage(name: AppRoutes.reports, page: () => ReportsView()),
    GetPage(name: AppRoutes.profile, page: () => ProfileView()),
    GetPage(
      name: AppRoutes.createProject,
      page: () => CreateProjectView(),
      transition: Transition.downToUp,
      transitionDuration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      binding: CreateProjectBinding(),
    ),
  ];
}

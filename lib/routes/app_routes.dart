import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/calander/calender_view.dart';
import 'package:mymanager/screen/create_project/create_project_binding.dart';
import 'package:mymanager/screen/create_project/create_project_view.dart';
import 'package:mymanager/screen/dashboard/dashboard_binding.dart';
import 'package:mymanager/screen/dashboard/dashboard_view.dart';
import 'package:mymanager/screen/profile/profile_view.dart';
import 'package:mymanager/screen/reports/reports_view.dart';
import 'package:mymanager/screen/tasks/tasks_view.dart';
import 'package:mymanager/screen/task_group_detail/task_group_detail_view.dart';
import 'package:mymanager/screen/notifications/notifications_view.dart';
import 'package:mymanager/screen/task_listing/task_listing_view.dart';
import 'package:mymanager/screen/task_group_listing/task_group_listing_view.dart';

class AppRoutes {
  static const dashboard = '/dashboard';
  static const tasks = '/tasks';
  static const calender = '/calender';
  static const reports = '/reports';
  static const profile = '/profile';
  static const createProject = '/create-project';
  static const taskGroupDetail = '/task-group-detail';
  static const notifications = '/notifications';
  static const taskListing = '/task-listing';
  static const taskGroupListing = '/task-group-listing';
}

class AppPages {
  static const initial = AppRoutes.dashboard;

  static final routes = [
    GetPage(
      name: AppRoutes.dashboard,
      page: () => DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(name: AppRoutes.tasks, page: () => TasksView()),
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
    GetPage(
      name: AppRoutes.taskGroupDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return TaskGroupDetailView(
          projectId: args['projectId'],
          projectName: args['projectName'],
          projectColor: args['projectColor'],
        );
      },
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => NotificationsView(),
    ),
    GetPage(
      name: AppRoutes.taskListing,
      page: () => TaskListingView(),
    ),
    GetPage(
      name: AppRoutes.taskGroupListing,
      page: () => TaskGroupListingView(),
    ),
  ];
}

import 'package:flutter/material.dart';
import 'package:mymanager/routes/app_routes.dart';

final appBottomNavRoutes = [
  {
    'icon': Icons.home_outlined,
    'icon_selected': Icons.home,
    'label': 'Home',
    'route': AppRoutes.dashboard,
  },
  {
    'icon': Icons.calendar_today_outlined,
    'icon_selected': Icons.calendar_month_sharp,
    'label': 'Tasks',
    'route': AppRoutes.calender,
  },
  {
    'icon': Icons.add_circle_outline,
    'icon_selected': Icons.add_circle,
    'label': 'Create',
    'route': AppRoutes.calender,
  },
  {
    'icon': Icons.pie_chart_outline,
    'icon_selected': Icons.pie_chart,
    'label': 'Reports',
    'route': AppRoutes.reports,
  },
  {
    'icon': Icons.person_outline,
    'icon_selected': Icons.person,
    'label': 'Profile',
    'route': AppRoutes.profile,
  },
];

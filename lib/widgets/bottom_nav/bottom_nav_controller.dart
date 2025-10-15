import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/calander/calender_view.dart';
import 'package:mymanager/screen/dashboard/section/dashboard_body.dart';
import 'package:mymanager/screen/profile/profile_view.dart';
import 'package:mymanager/screen/reports/reports_view.dart';

class BottomNavController extends GetxController {
  final selectedIndex = 0.obs;

  final List<Widget Function()> _pageBuilders = [
    () => const DashboardContent(),
    () => const CalenderView(),
    () => const SizedBox.shrink(),
    () => const ReportsView(),
    () => ProfileView(),
  ];

  final Map<int, Widget> _cache = {};

  @override
  void onInit() {
    super.onInit();
    ensurePage(selectedIndex.value);
  }

  void ensurePage(int index) {
    if (index < 0 || index >= _pageBuilders.length) return;
    _cache.putIfAbsent(index, () => _pageBuilders[index]());
  }

  List<Widget> get createdPages {
    return _cache.entries.map((e) {
      final idx = e.key;
      final w = e.value;
      return Offstage(
        offstage: selectedIndex.value != idx,
        child: TickerMode(enabled: selectedIndex.value == idx, child: w),
      );
    }).toList();
  }

  int get length => _pageBuilders.length;

  void changeIndex(int i) {
    if (i < 0 || i >= _pageBuilders.length) return;
    if (selectedIndex.value == i) return;
    selectedIndex.value = i;
    ensurePage(i);
  }
}

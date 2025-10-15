import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glass/glass.dart';
import 'package:mymanager/widgets/bottom_nav/bottom_nav_controller.dart';

class NavItem {
  final IconData icon;
  final IconData iconSelected;
  final String label;
  final VoidCallback? onTap;
  final bool showBadge; // optional: show badge indicator
  final bool suppressChange;
  const NavItem({
    required this.icon,
    required this.iconSelected,
    required this.label,
    this.onTap,
    this.showBadge = false,
    this.suppressChange = false,
  });
}

class FloatingGlassBottomNav extends GetView<BottomNavController> {
  final double height;
  final double sidePadding;
  final double blurX;
  final double blurY;
  final BorderRadius borderRadius;
  final List<NavItem> items;
  final double iconSize;
  final bool showLabels;
  final Color tintColor;
  final VoidCallback? onFabPressed;

  const FloatingGlassBottomNav({
    super.key,
    this.height = 72,
    this.sidePadding = 16,
    this.blurX = 8,
    this.blurY = 8,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    required this.items,
    this.iconSize = 26,
    this.showLabels = false,
    this.tintColor = Colors.white,
    this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: sidePadding,
          right: sidePadding,
          bottom: 12,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child:
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                items.length,
                                (i) => _NavButton(
                                  item: items[i],
                                  index: i,
                                  iconSize: iconSize,
                                  showLabel: showLabels,
                                  tintColor: tintColor,
                                ),
                              ),
                            ),
                          ).asGlass(
                            tintColor: tintColor,
                            clipBorderRadius: borderRadius,
                            blurX: blurX,
                            blurY: blurY,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends GetView<BottomNavController> {
  final NavItem item;
  final int index;
  final double iconSize;
  final bool showLabel;
  final Color tintColor;

  const _NavButton({
    required this.item,
    required this.index,
    required this.iconSize,
    required this.showLabel,
    required this.tintColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedIndex.value == index;
      final color = selected ? Colors.white : Colors.white70;

      // small animated scale for selected item
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (index == 2) {
              item.onTap?.call();
            } else {
              controller.changeIndex(index);
              item.onTap?.call();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // animated icon
                AnimatedScale(
                  scale: selected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutBack,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          selected ? item.iconSelected : item.icon,
                          size: iconSize,
                          color: color,
                        ),
                      ),
                      if (item.showBadge)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (showLabel) const SizedBox(height: 6),

                if (showLabel)
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                    child: Text(item.label),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

FloatingGlassBottomNav withItemsFromMap({
  required List<Map<String, dynamic>> itemsData,
  double height = 72,
  double sidePadding = 16,
  double blurX = 8,
  double blurY = 8,
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  double iconSize = 26,
  bool showLabels = false,
  Color tintColor = Colors.white,
  VoidCallback? onFabPressed,
}) {
  final items = itemsData.map((m) {
    return NavItem(
      icon: m['icon'] as IconData,
      iconSelected: m['icon'] as IconData,
      label: m['label'] as String,
      onTap: m['onTap'] as VoidCallback?,
      showBadge: (m['showBadge'] as bool?) ?? false,
    );
  }).toList();

  return FloatingGlassBottomNav(
    height: height,
    sidePadding: sidePadding,
    blurX: blurX,
    blurY: blurY,
    borderRadius: borderRadius,
    items: items,
    iconSize: iconSize,
    showLabels: showLabels,
    tintColor: tintColor,
    onFabPressed: onFabPressed,
  );
}

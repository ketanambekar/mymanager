import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppGlassToggle extends StatelessWidget {
  final String label;
  final RxBool value;
  final Function(bool) onChanged;
  final EdgeInsets? padding;

  const AppGlassToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Obx(() => Switch(
                value: value.value,
                onChanged: onChanged,
                activeColor: Colors.green,
              )),
        ],
      ),
    );
  }
}

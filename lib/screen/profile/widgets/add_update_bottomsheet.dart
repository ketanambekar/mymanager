import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/profile/profile_controller.dart';
import 'package:mymanager/theme/app_text_styles.dart';
import 'package:mymanager/widgets/app_button.dart';

class AddUpdateBottomSheet extends StatelessWidget {
  final String initialName;
  final void Function(String name) onSave;

  const AddUpdateBottomSheet({
    super.key,
    this.initialName = '',
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController(
      text: initialName,
    );
    final controller = Get.find<ProfileController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text('Profile Name', style: AppTextStyles.headline2),
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Profile Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              controller.userName.value = value;
            },
          ),
          const SizedBox(height: 32),
          AppButton(text: 'Save & Confirm', onTap: () {
            controller.updateName();
            Get.back();
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

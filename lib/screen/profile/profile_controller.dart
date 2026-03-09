import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/apis/user_profile_api.dart';
import 'package:mymanager/routes/app_routes.dart';
import 'package:mymanager/services/backend_auth_service.dart';

class ProfileController extends GetxController {
  final RxString userName = ''.obs;
  final RxString appVersion = ''.obs;
  final RxString id = ''.obs;
  final RxString activeSince = ''.obs;
  final RxString lastActive = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getUserData();
  }

  Future<void> getUserData() async {
    try {
      final profileId = GetStorage().read(AppConstants.profileId)?.toString();
      if ((profileId ?? '').isEmpty) return;

      final fetched = await UserProfileApi.getProfile(profileId!);
      if (fetched != null) {
        userName.value = fetched.name ?? '';
        appVersion.value = fetched.appVersion ?? '';
        id.value = fetched.profileId;
        activeSince.value = fetched.createdAt ?? '';
        lastActive.value = fetched.updatedAt ?? '';
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error fetching user profile: $e', error: e, stackTrace: stack, name: 'ProfileController');
      }
    }
  }

  Future<void> updateName() async {
    try {
      final profileId = GetStorage().read(AppConstants.profileId)?.toString();
      if ((profileId ?? '').isEmpty) return;

      final fetched = await UserProfileApi.getProfile(profileId!);
      if (fetched != null) {
        final updated = fetched.copyWith(name: userName.value);
        await UserProfileApi.updateProfile(updated);
        await getUserData();
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error updating user profile: $e', error: e, stackTrace: stack, name: 'ProfileController');
      }
    }
  }

  Future<void> backupDatabase() async {
    Get.snackbar(
      'Not Available',
      'Local SQLite backup is disabled. Data is managed by backend MySQL.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF7C3AED),
      colorText: Colors.white,
    );
  }

  Future<void> importDatabase() async {
    Get.snackbar(
      'Not Available',
      'Local SQLite import is disabled. Use backend APIs for data management.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF7C3AED),
      colorText: Colors.white,
    );
  }

  Future<void> logout() async {
    await BackendAuthService.logout();
    Get.offAllNamed(AppRoutes.auth);
  }
}

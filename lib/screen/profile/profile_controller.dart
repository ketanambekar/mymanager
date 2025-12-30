import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/apis/user_profile_api.dart';

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
      final profileId = GetStorage().read(AppConstants.profileId);
      if (kDebugMode) {
        developer.log('ProfileId from storage: $profileId', name: 'ProfileController');
      }

      if (profileId != null) {
        final fetched = await UserProfileApi.getProfile(profileId);
        if (kDebugMode) {
          developer.log(
            'Fetched profile - Created: ${fetched?.createdAt}, Updated: ${fetched?.updatedAt}',
            name: 'ProfileController',
          );
        }

        if (fetched != null) {
          userName.value = fetched.name ?? '';
          appVersion.value = fetched.appVersion ?? '';
          id.value = fetched.profileId;
          activeSince.value = fetched.createdAt ?? '';
          lastActive.value = fetched.updatedAt ?? '';
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error fetching user profile: $e',
          error: e,
          stackTrace: stack,
          name: 'ProfileController',
        );
      }
    }
  }

  Future<void> updateName() async {
    try {
      final profileId = GetStorage().read(AppConstants.profileId);

      if (profileId != null) {
        final fetched = await UserProfileApi.getProfile(profileId);
        if (kDebugMode) {
          developer.log('Updating profile name', name: 'ProfileController');
        }

        if (fetched != null) {
          final updated = fetched.copyWith(name: userName.value);
          await UserProfileApi.updateProfile(updated);
          getUserData();
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error updating user profile: $e',
          error: e,
          stackTrace: stack,
          name: 'ProfileController',
        );
      }
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/apis/user_profile_api.dart';
import 'package:mymanager/database/tables/user_profile/models/user_profile_model.dart';
import 'package:mymanager/utils/global_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    checkUser();
  }

  Future<void> checkUser() async {
    final userId = await GetStorage().read(AppConstants.profileId);
    if (kDebugMode) {
      print("userId:>>$userId");
    }
    if (userId == null || userId == '') {
      await GetStorage().write(AppConstants.profileId, uuid.v4());
      final fetched = await UserProfileApi.getProfile(
        await GetStorage().read(AppConstants.profileId),
      );
      if (fetched == null) {
        final info = await PackageInfo.fromPlatform();
        final newProfile = UserProfile(
          profileId: GetStorage().read(AppConstants.profileId),
          name: '',
          appVersion: "${info.version}(${info.buildNumber})",
        );
        await UserProfileApi.createProfile(newProfile);
      }
    }

  }
}

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
      print('ProfileId from storage: $profileId');

      if (profileId != null) {
        final fetched = await UserProfileApi.getProfile(profileId);
        print('Fetched profile: ${fetched?.createdAt!}');
        print('Fetched profile: ${fetched?.updatedAt!}');

        if (fetched != null) {
          userName.value = fetched.name!;
          appVersion.value = fetched.appVersion!;
          id.value = fetched.profileId;
          activeSince.value = fetched.createdAt!;
          lastActive.value = fetched.updatedAt!;
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> updateName() async {
    try {
      final profileId = GetStorage().read(AppConstants.profileId);

      if (profileId != null) {
        final fetched = await UserProfileApi.getProfile(profileId);
        print('Fetched profile: $fetched');

        if (fetched != null) {
          final updated = fetched.copyWith(name: userName.value);
          await UserProfileApi.updateProfile(updated);
          getUserData();
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }
}

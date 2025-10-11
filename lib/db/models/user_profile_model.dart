import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/utils/global_utils.dart';

class UserProfileModel {
  final String userId;
  final String userName;
  final String appVersion;

  UserProfileModel({
    required this.userId,
    required this.userName,
    required this.appVersion,
  });

  UserProfileModel copyWith({
    String? userId,
    String? userName,
    String? appVersion,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] ?? makeId(AppConstants.userIdKey),
      userName: json['userName'] ?? '',
      appVersion: json['appVersion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'appVersion': appVersion,
  };
}

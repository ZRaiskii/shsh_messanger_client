import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String username;
  final String email;
  final String dateOfBirth;
  final String descriptionOfProfile;
  final bool isShshDeveloper;
  final String registrationDate;
  final String lastUpdated;
  final String status;
  final String gender;
  final bool isActive;
  final String avatarUrl;
  final String chatWallpaperUrl;
  final bool isPremium;
  final String premiumExpiresAt;
  final String nicknameEmoji;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.dateOfBirth,
    required this.descriptionOfProfile,
    required this.isShshDeveloper,
    required this.registrationDate,
    required this.lastUpdated,
    required this.status,
    required this.gender,
    required this.isActive,
    required this.avatarUrl,
    required this.chatWallpaperUrl,
    required this.isPremium,
    required this.premiumExpiresAt,
    required this.nicknameEmoji,
  });

  @override
  List<Object> get props => [
        id,
        username,
        email,
        dateOfBirth,
        descriptionOfProfile,
        isShshDeveloper,
        registrationDate,
        lastUpdated,
        status,
        gender,
        isActive,
        avatarUrl,
        chatWallpaperUrl,
        isPremium,
        premiumExpiresAt,
        nicknameEmoji,
      ];
}

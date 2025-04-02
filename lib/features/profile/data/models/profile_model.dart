// lib/features/profile/data/models/profile_model.dart
class ProfileModel {
  final String id;
  final String username;
  final String email;
  final DateTime? dateOfBirth;
  final String descriptionOfProfile;
  final DateTime registrationDate;
  final DateTime lastUpdated;
  final String? gender;
  final String avatarUrl;
  final String? chatWallpaperUrl;
  final DateTime? premiumExpiresAt;
  final String? nicknameEmoji;
  final bool active;
  final bool premium;
  final bool shshDeveloper;
  final bool isVerifiedEmail;

  ProfileModel({
    required this.id,
    required this.username,
    required this.email,
    this.dateOfBirth,
    required this.descriptionOfProfile,
    required this.registrationDate,
    required this.lastUpdated,
    this.gender,
    required this.avatarUrl,
    this.chatWallpaperUrl,
    this.premiumExpiresAt,
    this.nicknameEmoji,
    required this.active,
    required this.premium,
    required this.shshDeveloper,
    required this.isVerifiedEmail,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    print('json: $json');
    return ProfileModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      descriptionOfProfile: json['descriptionOfProfile'] ?? '',
      registrationDate: DateTime.parse(json['registrationDate']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      gender: json['gender'],
      avatarUrl: json['avatarUrl'] ?? '',
      chatWallpaperUrl: json['chatWallpaperUrl'],
      premiumExpiresAt: json['premiumExpiresAt'] != null
          ? DateTime.parse(json['premiumExpiresAt'])
          : null,
      nicknameEmoji: json['nicknameEmoji'],
      active: json['active'] ?? false,
      premium: json['premium'] ?? false,
      shshDeveloper: json['shshDeveloper'] ?? false,
      isVerifiedEmail: json['isVerifiedEmail'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'descriptionOfProfile': descriptionOfProfile,
      'registrationDate': registrationDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'gender': gender,
      'avatarUrl': avatarUrl,
      'chatWallpaperUrl': chatWallpaperUrl,
      'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
      'nicknameEmoji': nicknameEmoji,
      'active': active,
      'premium': premium,
      'shshDeveloper': shshDeveloper,
      'isVerifiedEmail': isVerifiedEmail,
    };
  }
}

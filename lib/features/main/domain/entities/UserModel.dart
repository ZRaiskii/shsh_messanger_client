class UserModelForChat {
  final String id;
  final String username;
  final String email;
  final DateTime? dateOfBirth;
  final String descriptionOfProfile;
  final DateTime registrationDate;
  final DateTime lastUpdated;
  final String? gender;
  final String? avatarUrl;
  final String? chatWallpaperUrl;
  final DateTime? premiumExpiresAt;
  final String? nicknameEmoji;
  final bool active;
  final bool premium;
  final bool shshDeveloper;
  final bool verifiedEmail;

  UserModelForChat({
    required this.id,
    required this.username,
    required this.email,
    this.dateOfBirth,
    required this.descriptionOfProfile,
    required this.registrationDate,
    required this.lastUpdated,
    this.gender,
    this.avatarUrl,
    this.chatWallpaperUrl,
    this.premiumExpiresAt,
    this.nicknameEmoji,
    required this.active,
    required this.premium,
    required this.shshDeveloper,
    required this.verifiedEmail,
  });

  factory UserModelForChat.fromJson(Map<String, dynamic> json) {
    return UserModelForChat(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      descriptionOfProfile: json['descriptionOfProfile'],
      registrationDate: DateTime.parse(json['registrationDate']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      gender: json['gender'],
      avatarUrl: json['avatarUrl'],
      chatWallpaperUrl: json['chatWallpaperUrl'],
      premiumExpiresAt: json['premiumExpiresAt'] != null
          ? DateTime.parse(json['premiumExpiresAt'])
          : null,
      nicknameEmoji: json['nicknameEmoji'],
      active: json['active'],
      premium: json['premium'],
      shshDeveloper: json['shshDeveloper'],
      verifiedEmail: json['verifiedEmail'],
    );
  }
}

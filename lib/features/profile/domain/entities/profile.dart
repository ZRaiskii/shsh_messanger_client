class Profile {
  final String id;
  String username;
  final String email;
  final DateTime? dateOfBirth;
  String descriptionOfProfile; // Убрали final
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

  Profile({
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

  Profile copyWith({
    String? id,
    String? username,
    String? email,
    DateTime? dateOfBirth,
    String? descriptionOfProfile,
    DateTime? registrationDate,
    DateTime? lastUpdated,
    String? gender,
    String? avatarUrl,
    String? chatWallpaperUrl,
    DateTime? premiumExpiresAt,
    String? nicknameEmoji,
    bool? active,
    bool? premium,
    bool? shshDeveloper,
    bool? isVerifiedEmail,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      descriptionOfProfile: descriptionOfProfile ?? this.descriptionOfProfile,
      registrationDate: registrationDate ?? this.registrationDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      chatWallpaperUrl: chatWallpaperUrl ?? this.chatWallpaperUrl,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      nicknameEmoji: nicknameEmoji ?? this.nicknameEmoji,
      active: active ?? this.active,
      premium: premium ?? this.premium,
      shshDeveloper: shshDeveloper ?? this.shshDeveloper,
      isVerifiedEmail: isVerifiedEmail ?? this.isVerifiedEmail,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      descriptionOfProfile: json['descriptionOfProfile'] ?? '',
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'])
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
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

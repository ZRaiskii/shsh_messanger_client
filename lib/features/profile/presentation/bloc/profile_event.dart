part of 'profile_bloc.dart';

abstract class ProfileEvent {}

class FetchProfileEvent extends ProfileEvent {
  final String userId;

  FetchProfileEvent({required this.userId});
}

class UpdateProfileEvent extends ProfileEvent {
  final UpdateProfileParams params;

  UpdateProfileEvent(this.params);
}

class UploadAvatarEvent extends ProfileEvent {
  final String userId;
  final File file;

  UploadAvatarEvent({required this.userId, required this.file});
}

class DeleteAvatarEvent extends ProfileEvent {
  final String userId;

  DeleteAvatarEvent({required this.userId});
}

class UpdateEmojiEvent extends ProfileEvent {
  final String userId;
  final String emoji;

  UpdateEmojiEvent({required this.userId, required this.emoji});
}

class UpdatePremiumEvent extends ProfileEvent {
  final String userId;
  final bool isPremium;

  UpdatePremiumEvent({required this.userId, required this.isPremium});
}

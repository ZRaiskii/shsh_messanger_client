import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import '../../domain/usecases/delete_avatar_usecase.dart';
import '../../domain/usecases/update_emoji_usecase.dart';
import '../../domain/usecases/update_premium_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;
  final DeleteAvatarUseCase deleteAvatarUseCase;
  final UpdateEmojiUseCase updateEmojiUseCase;
  final UpdatePremiumUseCase updatePremiumUseCase;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadAvatarUseCase,
    required this.deleteAvatarUseCase,
    required this.updateEmojiUseCase,
    required this.updatePremiumUseCase,
  }) : super(ProfileInitial()) {
    on<FetchProfileEvent>(_onFetchProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadAvatarEvent>(_onUploadAvatar);
    on<DeleteAvatarEvent>(_onDeleteAvatar);
    on<UpdateEmojiEvent>(_onUpdateEmoji);
    on<UpdatePremiumEvent>(_onUpdatePremium);
    add(FetchProfileEvent(
        userId: 'user_id')); // Add this event for initialization
  }
  Future<String> getCachedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('cached_user');
    if (cachedUser != null) {
      return UserModel.fromJson(json.decode(cachedUser) as Map<String, dynamic>)
          .id;
    }
    return '';
  }

  Future<void> _onFetchProfile(
      FetchProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await getProfileUseCase(
        GetProfileParams(userId: await getCachedUserId()));
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.toString())),
      (profile) => emit(ProfileSuccess(profile: profile)),
    );
  }

  Future<void> _onUpdateProfile(
      UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    try {
      await updateProfileUseCase(event.params);
      final result = await getProfileUseCase(
          GetProfileParams(userId: event.params.userId));
      result.fold(
        (failure) => emit(ProfileFailure(message: failure.toString())),
        (profile) => emit(ProfileSuccess(profile: profile)),
      );
    } catch (e) {
      emit(ProfileFailure(message: e.toString()));
    }
  }

  Future<void> _onUploadAvatar(
      UploadAvatarEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await uploadAvatarUseCase(UploadAvatarParams(
      userId: event.userId,
      file: event.file,
    ));
    result.fold(
      (failure) => emit(ProfileInitial()),
      (message) => emit(ProfileInitial()),
    );
  }

  Future<void> _onDeleteAvatar(
      DeleteAvatarEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await deleteAvatarUseCase(DeleteAvatarParams(
      userId: event.userId,
    ));
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.toString())),
      (_) => emit(ProfileSuccess()), // No message needed
    );
  }

  Future<void> _onUpdateEmoji(
      UpdateEmojiEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await updateEmojiUseCase(UpdateEmojiParams(
      userId: event.userId,
      emoji: event.emoji,
    ));
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.toString())),
      (_) => emit(ProfileInitial()), // No message needed
    );
  }

  Future<void> _onUpdatePremium(
      UpdatePremiumEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await updatePremiumUseCase(UpdatePremiumParams(
      userId: event.userId,
      isPremium: event.isPremium,
    ));
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.toString())),
      (_) => emit(ProfileSuccess()), // No message needed
    );
  }
}

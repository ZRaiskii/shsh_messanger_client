part of 'profile_bloc.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  final Profile? profile;
  final String? message;

  ProfileSuccess({this.profile, this.message});
}

class ProfileFailure extends ProfileState {
  final String message;

  ProfileFailure({required this.message});
}

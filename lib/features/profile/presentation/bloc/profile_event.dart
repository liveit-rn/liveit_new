import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

class ProfileDisplayNameChanged extends ProfileEvent {
  final String displayName;

  const ProfileDisplayNameChanged(this.displayName);

  @override
  List<Object?> get props => [displayName];
}

class ProfileAvatarChanged extends ProfileEvent {
  final String avatarUrl;

  const ProfileAvatarChanged(this.avatarUrl);

  @override
  List<Object?> get props => [avatarUrl];
}

class ProfileDeleteRequested extends ProfileEvent {
  const ProfileDeleteRequested();
}

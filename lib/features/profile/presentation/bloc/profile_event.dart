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
  final String profileImageId;

  const ProfileAvatarChanged(this.profileImageId);

  @override
  List<Object?> get props => [profileImageId];
}

class ProfileAvatarUploadRequested extends ProfileEvent {
  final List<int> fileBytes;
  final String fileName;

  const ProfileAvatarUploadRequested({
    required this.fileBytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [fileName, fileBytes.length];
}

class ProfileAvatarRemoveRequested extends ProfileEvent {
  const ProfileAvatarRemoveRequested();
}

class ProfileDeleteRequested extends ProfileEvent {
  const ProfileDeleteRequested();
}

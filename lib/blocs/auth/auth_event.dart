import 'package:equatable/equatable.dart';
import '../../models/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class PhoneNumberSubmitted extends AuthEvent {
  final String phoneNumber;

  const PhoneNumberSubmitted(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class OTPSubmitted extends AuthEvent {
  final String verificationId;
  final String smsCode;

  const OTPSubmitted({
    required this.verificationId,
    required this.smsCode,
  });

  @override
  List<Object?> get props => [verificationId, smsCode];
}

class LoggedOut extends AuthEvent {}

class ProfileUpdated extends AuthEvent {
  final String? displayName;
  final String? photoUrl;

  const ProfileUpdated({this.displayName, this.photoUrl});

  @override
  List<Object?> get props => [displayName, photoUrl];
}
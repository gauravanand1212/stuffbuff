import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<PhoneNumberSubmitted>(_onPhoneNumberSubmitted);
    on<OTPSubmitted>(_onOTPSubmitted);
    on<LoggedOut>(_onLoggedOut);
    on<ProfileUpdated>(_onProfileUpdated);
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    await emit.forEach(
      _authService.userStream,
      onData: (user) {
        if (user != null) {
          return Authenticated(user);
        }
        return Unauthenticated();
      },
      onError: (_, __) => Unauthenticated(),
    );
  }

  void _onPhoneNumberSubmitted(
    PhoneNumberSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    await _authService.verifyPhoneNumber(
      phoneNumber: event.phoneNumber,
      onCodeSent: (verificationId) {
        emit(PhoneVerificationSent(verificationId));
      },
      onError: (error) {
        emit(AuthError(error));
      },
    );
  }

  void _onOTPSubmitted(OTPSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final user = await _authService.verifyOTP(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );

      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Failed to verify OTP'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authService.signOut();
    emit(Unauthenticated());
  }

  void _onProfileUpdated(ProfileUpdated event, Emitter<AuthState> emit) async {
    if (state is Authenticated) {
      final currentUser = (state as Authenticated).user;
      emit(AuthLoading());

      try {
        await _authService.updateProfile(
          userId: currentUser.id,
          displayName: event.displayName,
          photoUrl: event.photoUrl,
        );
        
        final updatedUser = currentUser.copyWith(
          displayName: event.displayName,
          photoUrl: event.photoUrl,
        );
        emit(Authenticated(updatedUser));
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Authenticated(currentUser));
      }
    }
  }
}
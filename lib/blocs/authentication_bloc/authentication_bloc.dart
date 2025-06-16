import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:user_repository/user_repository.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final UserRepository userRepository;
  late final StreamSubscription<MyUser?> _userSubscription;

  AuthenticationBloc({required this.userRepository})
      : super(const AuthenticationState.unknown()) {
    _userSubscription = userRepository.user.listen((user) {
      log('UserRepository stream emitted user: $user');
      add(AuthenticationUserChanged(user));
    });

    on<AuthenticationUserChanged>((event, emit) {
      log('AuthenticationUserChanged event received: ${event.user}');
      if (event.user != MyUser.empty && event.user != null) {
        log('Emitting authenticated state');
        emit(AuthenticationState.authenticated(event.user!));
      } else {
        log('Emitting unauthenticated state');
        emit(const AuthenticationState.unauthenticated());
      }
    });

    on<LogoutRequested>((event, emit) async {
      await userRepository.logOut();
      emit(const AuthenticationState.unauthenticated());
    });
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}

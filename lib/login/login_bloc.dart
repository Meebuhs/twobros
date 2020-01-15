import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_event.dart';
import 'login_state.dart';
import 'login_view.dart';
import '../model/login_repo.dart';
import '../model/user_repo.dart';
import '../model/user.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  StreamSubscription<FirebaseUser> _authStateListener;

  void setupAuthStateListener(LoginWidget view) {
    if (_authStateListener == null) {
      _authStateListener =
          FirebaseAuth.instance.onAuthStateChanged.listen((user) {
        if (user != null) {
          final loginProvider = user.providerId;
          UserRepo.getInstance().setCurrentUser(User.fromFirebaseUser(user));
          if (loginProvider == "google") {
            // TODO analytics call for google login provider
          }
          view.navigateToMain();
        } else {
          add(LogoutEvent());
        }
      }, onError: (error) {
        add(LoginErrorEvent(error));
      });
    }
  }

  void onLoginGoogle(LoginWidget view) async {
    add(LoginEventInProgress());
    final googleSignInRepo = GoogleSignIn(
        signInOption: SignInOption.standard, scopes: ["profile", "email"]);
    final account = await googleSignInRepo.signIn();
    if (account != null) {
      LoginRepo.getInstance().signInWithGoogle(account);
    } else {
      add(LogoutEvent());
    }
  }

  void onLogout() async {
    add(LoginEventInProgress());
    bool result = await LoginRepo.getInstance().signOut();
    if (result) {
      add(LogoutEvent());
    }
  }

  @override
  LoginState get initialState => LoginState.initial();

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is LoginWithGoogleEvent) {
      yield LoginState.loading(false);
    } else if (event is LogoutEvent) {
      yield LoginState.loading(false);
    } else if (event is LoginEventInProgress) {
      yield LoginState.loading(true);
    } else if (event is LoginErrorEvent) {}
  }

  @override
  Future<void> close() {
    _authStateListener.cancel();
    return super.close();
  }
}

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_event.dart';
import 'login_state.dart';
import 'login_view.dart';
import '../model/login_repo.dart';
import '../model/user_repo.dart';
import '../model/user.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  StreamSubscription<FirebaseUser> _authStateListener;
  StreamController isLoginFormStream = StreamController<bool>.broadcast();

  void setupAuthStateListener(LoginWidget view) {
    if (_authStateListener == null) {
      _authStateListener =
          FirebaseAuth.instance.onAuthStateChanged.listen((user) {
        if (user != null) {
          UserRepo.getInstance().setCurrentUser(User.fromFirebaseUser(user));
          view.navigateToMain();
        } else {
          add(LogoutEvent());
        }
      }, onError: (error) {
        add(LoginErrorEvent(error));
      });
    }
  }

  // Perform login or signup
  void validateAndSubmit(LoginState state) async {
    state.errorMessage = "";
    state.loading = true;

    if (validateAndSave(state)) {
      try {
        if (state.isLogin) {
          await LoginRepo.getInstance().signIn(state.username, state.password);
        } else {
          await LoginRepo.getInstance().signUp(state.username, state.password);
        }
        state.loading = false;
      } catch (e) {
        print('Error: $e');
        state.formKey.currentState.reset();
        state.loading = false;
        state.errorMessage = e.message;
      }
    }
  }

  bool validateAndSave(LoginState state) {
    final form = state.formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  void toggleFormMode(LoginState state) {
    state.formKey.currentState.reset();
    state.errorMessage = "";
    state.isLogin = !state.isLogin;
    isLoginFormStream.add(state.isLogin);
    print("toggled ${state.isLogin}");
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
    if (event is LoginWithEmailEvent) {
      yield LoginState.loading(false, state);
    } else if (event is LogoutEvent) {
      yield LoginState.loading(false, state);
    } else if (event is LoginEventInProgress) {
      yield LoginState.loading(true, state);
    } else if (event is LoginErrorEvent) {}
  }

  @override
  Future<void> close() {
    _authStateListener.cancel();
    isLoginFormStream.close();
    return super.close();
  }
}

import 'package:assapp/models/Doctor/Base_Doctor_model.dart';
import 'package:assapp/services/authService/AuthServie.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Assuming your AuthService is in this path

part 'auths_event.dart';
part 'auths_state.dart';

class AuthsBloc extends Bloc<AuthsEvent, AuthsState> {
  // Dependency on AuthService
  final AuthService _authService;

  AuthsBloc({required AuthService authService}) 
      : _authService = authService,
        super(AuthsInitial()) {
    
    // Register the event handler for LoginReq
    on<LoginReq>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    LoginReq event,
    Emitter<AuthsState> emit,
  ) async {
    // 1. Emit loading state to notify the UI
    emit(AuthsLoading());

    try {
      // 2. Call the login method from the service
      final doctor = await _authService.doLogin(event.email);

      // 3. Check the result and emit success or failure
      if (doctor != null) {
        emit(AuthsSuccess(doctor: doctor));
      } else {
        emit(const AuthsFailure(error: 'Login failed. Please check your credentials.'));
      }
    } catch (e) {
      // 4. Handle any unexpected errors
      emit(AuthsFailure(error: 'An unexpected error occurred: $e'));
    }
  }
}
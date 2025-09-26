part of 'auths_bloc.dart';

sealed class AuthsState extends Equatable {
  const AuthsState();
  
  @override
  List<Object> get props => [];
}

/// The initial state before any action has been taken.
final class AuthsInitial extends AuthsState {}

/// The state when the login request is in progress.
final class AuthsLoading extends AuthsState {}

/// The state when the login was successful.
/// It holds the user data.
final class AuthsSuccess extends AuthsState {
  final BaseDoctorModel doctor;

  const AuthsSuccess({required this.doctor});

  @override
  List<Object> get props => [doctor];
}

/// The state when the login failed.
/// It holds an error message to be displayed to the user.
final class AuthsFailure extends AuthsState {
  final String error;

  const AuthsFailure({required this.error});

  @override
  List<Object> get props => [error];
}
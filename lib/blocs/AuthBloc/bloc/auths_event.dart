part of 'auths_bloc.dart';

sealed class AuthsEvent extends Equatable {
  const AuthsEvent();

  @override
  List<Object> get props => [];
}

class LoginReq extends AuthsEvent{
  final String email;
  const LoginReq({required this.email});
  @override
  List<Object> get props => [email];
}



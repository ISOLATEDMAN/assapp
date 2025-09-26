part of 'patient_handling_bloc.dart';

sealed class PatientHandlingState extends Equatable {
  const PatientHandlingState();
  
  @override
  List<Object> get props => [];
}

final class PatientHandlingInitial extends PatientHandlingState {}

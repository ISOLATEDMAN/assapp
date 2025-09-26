// patient_handling_state.dart
part of 'patient_handling_bloc.dart';

sealed class PatientHandlingState extends Equatable {
  const PatientHandlingState();
  
  @override
  List<Object> get props => [];
}

final class PatientHandlingInitial extends PatientHandlingState {}

final class PatientLoadingState extends PatientHandlingState {}

final class PatientLoadedState extends PatientHandlingState {
  final List<PatientModel> patients;
  
  const PatientLoadedState({required this.patients});
  
  @override
  List<Object> get props => [patients];
}

final class PatientCreatingState extends PatientHandlingState {}

final class PatientCreatedState extends PatientHandlingState {
  final PatientModel patient;
  final List<PatientModel> allPatients;
  
  const PatientCreatedState({
    required this.patient,
    required this.allPatients,
  });
  
  @override
  List<Object> get props => [patient, allPatients];
}

final class TranscriptSavingState extends PatientHandlingState {}

final class TranscriptSavedState extends PatientHandlingState {}

final class PatientDetailsLoadingState extends PatientHandlingState {}

final class PatientDetailsLoadedState extends PatientHandlingState {
  final PatientModel patient;
  
  const PatientDetailsLoadedState({required this.patient});
  
  @override
  List<Object> get props => [patient];
}

final class PatientErrorState extends PatientHandlingState {
  final String message;
  
  const PatientErrorState({required this.message});
  
  @override
  List<Object> get props => [message];
}
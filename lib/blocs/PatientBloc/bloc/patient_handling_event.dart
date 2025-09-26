
// patient_handling_event.dart
part of 'patient_handling_bloc.dart';

sealed class PatientHandlingEvent extends Equatable {
  const PatientHandlingEvent();
  
  @override
  List<Object> get props => [];
}

class LoadPatientsEvent extends PatientHandlingEvent {}

class RefreshPatientsEvent extends PatientHandlingEvent {}

class CreatePatientEvent extends PatientHandlingEvent {
  final String patientName;
  
  const CreatePatientEvent({required this.patientName});
  
  @override
  List<Object> get props => [patientName];
}

class SaveTranscriptEvent extends PatientHandlingEvent {
  final String patientId;
  final String sessionId;
  final String transcript;
  
  const SaveTranscriptEvent({
    required this.patientId,
    required this.sessionId,
    required this.transcript,
  });
  
  @override
  List<Object> get props => [patientId, sessionId, transcript];
}

class GetPatientDetailsEvent extends PatientHandlingEvent {
  final String patientId;
  
  const GetPatientDetailsEvent({required this.patientId});
  
  @override
  List<Object> get props => [patientId];
}

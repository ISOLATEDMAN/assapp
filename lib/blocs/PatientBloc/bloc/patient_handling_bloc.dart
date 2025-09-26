// patient_handling_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:assapp/models/Patient/Patient_model.dart';
import 'package:assapp/services/PatientService/PatientService.dart';

part 'patient_handling_event.dart';
part 'patient_handling_state.dart';

class PatientHandlingBloc extends Bloc<PatientHandlingEvent, PatientHandlingState> {
  final PatientService _patientService;

  PatientHandlingBloc({PatientService? patientService}) 
      : _patientService = patientService ?? PatientService(),
        super(PatientHandlingInitial()) {
    
    on<LoadPatientsEvent>(_onLoadPatients);
    on<CreatePatientEvent>(_onCreatePatient);
    on<RefreshPatientsEvent>(_onRefreshPatients);
    on<SaveTranscriptEvent>(_onSaveTranscript);
    on<GetPatientDetailsEvent>(_onGetPatientDetails);
  }

  Future<void> _onLoadPatients(
    LoadPatientsEvent event,
    Emitter<PatientHandlingState> emit,
  ) async {
    emit(PatientLoadingState());
    try {
      final patients = await _patientService.getPatients();
      emit(PatientLoadedState(patients: patients));
    } catch (error) {
      emit(PatientErrorState(message: 'Failed to load patients: $error'));
    }
  }

  Future<void> _onCreatePatient(
    CreatePatientEvent event,
    Emitter<PatientHandlingState> emit,
  ) async {
    emit(PatientCreatingState());
    try {
      final newPatient = await _patientService.createPatient(event.patientName);
      if (newPatient != null) {
        // Get current patients list and add the new one
        final currentState = state;
        List<PatientModel> updatedPatients = [];
        
        if (currentState is PatientLoadedState) {
          updatedPatients = List.from(currentState.patients)..add(newPatient);
        } else {
          updatedPatients = [newPatient];
        }
        
        emit(PatientCreatedState(
          patient: newPatient,
          allPatients: updatedPatients,
        ));
      } else {
        emit(PatientErrorState(message: 'Failed to create patient'));
      }
    } catch (error) {
      emit(PatientErrorState(message: 'Error creating patient: $error'));
    }
  }

  Future<void> _onRefreshPatients(
    RefreshPatientsEvent event,
    Emitter<PatientHandlingState> emit,
  ) async {

    final currentState = state;
    if (currentState is! PatientLoadedState) {
      emit(PatientLoadingState());
    }
    
    try {
      final patients = await _patientService.getPatients();
      emit(PatientLoadedState(patients: patients));
    } catch (error) {
      emit(PatientErrorState(message: 'Failed to refresh patients: $error'));
    }
  }

  Future<void> _onSaveTranscript(
    SaveTranscriptEvent event,
    Emitter<PatientHandlingState> emit,
  ) async {
    emit(TranscriptSavingState());
    try {
      final success = await _patientService.saveTranscript(
        patientId: event.patientId,
        sessionId: event.sessionId,
        transcript: event.transcript,
      );
      
      if (success) {
        emit(TranscriptSavedState());
      } else {
        emit(PatientErrorState(message: 'Failed to save transcript'));
      }
    } catch (error) {
      emit(PatientErrorState(message: 'Error saving transcript: $error'));
    }
  }

  Future<void> _onGetPatientDetails(
    GetPatientDetailsEvent event,
    Emitter<PatientHandlingState> emit,
  ) async {
    emit(PatientDetailsLoadingState());
    try {
      final patient = await _patientService.getPatientDetails(event.patientId);
      if (patient != null) {
        emit(PatientDetailsLoadedState(patient: patient));
      } else {
        emit(PatientErrorState(message: 'Patient not found'));
      }
    } catch (error) {
      emit(PatientErrorState(message: 'Failed to load patient details: $error'));
    }
  }
}

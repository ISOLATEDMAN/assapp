import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'patient_handling_event.dart';
part 'patient_handling_state.dart';

class PatientHandlingBloc extends Bloc<PatientHandlingEvent, PatientHandlingState> {
  PatientHandlingBloc() : super(PatientHandlingInitial()) {
    on<PatientHandlingEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
